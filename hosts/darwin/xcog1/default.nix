# xcog1 — Mac Mini M4 Pro cognition node.
# Hosts the family agent LLM stack (MLX + LiteLLM), Wyoming voice pipeline,
# and Prometheus exporters. Headless server (no dock/Finder tweaks — that's
# xlt1-t territory). See the family-agent plan for the full architecture.

{
  hostname,
  pkgs,
  ...
}:
{
  imports = [
    ../default.nix
    ../../../modules/packages-darwin/llm-stack
  ];

  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = "xrs444";

  # arrow-azurefs-test spins up a local azurite (node.js) TLS mock whose
  # self-signed cert fails verification ("unable to get local issuer
  # certificate") — hit on this host's first darwin-rebuild switch; the other
  # 96/97 arrow tests passed. arrow-cpp blocks pyarrow → datasets/tokenizers
  # → mlx-lm + faster-whisper, i.e. the whole LLM stack. Host-scoped overlay
  # (not hosts/darwin common) so no other host's cache hits are disturbed;
  # aarch64-darwin arrow isn't cached upstream anyway.
  # django's 18k-test suite (~30min) failed one timing-sensitive perf test
  # (test_crafted_xml_performance, "not quadratic") while the box was busy
  # compiling the rest of the closure. django is only here as a *test* dep of
  # debugpy, itself a dep of the VS Code ms-python extension in home-manager.
  # (django = self.django_5, so the alias picks this up too.)
  nixpkgs.overlays = [
    (final: prev: {
      arrow-cpp = prev.arrow-cpp.overrideAttrs (old: {
        doInstallCheck = false;
      });
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          django_5 = pyprev.django_5.overridePythonAttrs (old: {
            doCheck = false;
          });
        })
      ];
    })
  ];

  # ── Server-appropriate macOS defaults ────────────────────────────────────
  # No dock/Finder theming — this is a headless daemon host. Only the minimum
  # needed for the rare interactive session (Screen Sharing / SSH).
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      # Fast key repeat for any interactive SSH session
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
    # Prevent the display from sleeping when a monitor is attached during
    # setup; irrelevant once headless. `pmset` handles the long-term policy.
    loginwindow.GuestEnabled = false;
  };

  # ── PAM / Touch ID for sudo (matches xlt1-t pattern) ─────────────────────
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';

  # ── Shells (fish is the primary; zsh kept as a fallback) ─────────────────
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    fish_add_path --prepend --global $HOME/.nix-profile/bin
    set -gx EDITOR micro
    set -gx SOPS_AGE_KEY_FILE $HOME/.config/sops/age/keys.txt
    set -gx KUBECONFIG $HOME/k8s/kubeconfig
    set -gx TALOSCONFIG $HOME/k8s/talosconfig
  '';

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  # ── Remote builders (same as xlt1-t — offload Linux/ARM builds) ──────────
  nix.buildMachines = [
    {
      hostName = "xsvr1.lan";
      sshUser = "builder";
      sshKey = "/Users/xrs444/.ssh/builder_key";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
  ];
  nix.distributedBuilds = true;

  # ── LLM stack — the reason this host exists ──────────────────────────────
  #
  # Model port assignments:
  #   qwen3-14b       → 8001 (voice path; hybrid thinking — HA prompt uses /no_think)
  #   qwen3-30b-a3b   → 8002 (text/agent path; non-thinking 2507 MoE)
  #
  # Both models are resident (launchd can't start-on-request — bug-523).
  # Weights live on the external SSD, NOT the Nix store (cerebrum Decision
  # Log 2026-08-07); revisions are immutable HF commit SHAs verified via the
  # HF API (bug-522: repo names must be checked — anonymous 401 = not found).
  # If this box turns out to have 24GB RAM, drop qwen3-14b and let the 30B
  # MoE serve the voice path too (plan §D9).
  services.llm-stack = {
    enable = true;

    # External SSD, APFS volume "xcog1-models" (Phase A formats it and runs
    # `diskutil enableOwnership`). Daemons wait for this mount before writing.
    modelsDir = "/Volumes/xcog1-models";
    modelsVolume = "/Volumes/xcog1-models";

    models = {
      qwen3-14b = {
        repo = "mlx-community/Qwen3-14B-4bit";
        revision = "a4d9b2df59d2c150bef02fcbe0d91046b7ca33a4";
        port = 8001;
      };
      qwen3-30b-a3b = {
        repo = "mlx-community/Qwen3-30B-A3B-Instruct-2507-4bit-DWQ";
        revision = "53bfb233acb2e50f6060c3c5709f23fac547827f";
        port = 8002;
      };
    };

    litellmPort = 4000;

    cloudTier = {
      enable = true;
      modelName = "deepseek-hard";
      upstreamModel = "deepseek/deepseek-chat";
      apiBase = "https://api.deepseek.com";
    };

    voice = {
      enable = true;
      # Default ports (10300 whisper / 10200 piper) match the module — HA
      # Assist Wyoming integrations reference these directly.
    };

    exporters.enable = true;
  };

  # ── Secrets (decrypted with the shared user_xrs444 age key, see
  # hosts/darwin/default.nix). Placed at /run/secrets/* where the llm-stack
  # wrappers read them. secrets/llm.yaml: litellm_master_key is real;
  # deepseek_api_key starts as a placeholder — paste the household key via
  # `sops secrets/llm.yaml` before relying on the cloud tier.
  sops.secrets."litellm-master-key" = {
    sopsFile = ../../../secrets/llm.yaml;
    key = "litellm_master_key";
    mode = "0400";
  };
  sops.secrets."deepseek-api-key" = {
    sopsFile = ../../../secrets/llm.yaml;
    key = "deepseek_api_key";
    mode = "0400";
  };

  # ── Headless server power policy ─────────────────────────────────────────
  # autorestart: come back after any power failure without a button press.
  # Sleep disabled — this box serves the voice path 24/7.
  system.activationScripts.extraActivation.text = ''
    /usr/bin/pmset -a sleep 0 disksleep 0 displaysleep 10 autorestart 1 womp 1
  '';

  # ── ntp / logging niceties for a headless box ────────────────────────────
  # (Time Machine and xsvr1 SMB mounts intentionally omitted — nothing on
  # this host is unreproducible: config is git, weights are pinned re-downloads,
  # secrets are sops.)
}
