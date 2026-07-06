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
  # Model port assignments follow the plan:
  #   qwen3-14b       → 8001 (alwaysOn, voice path)
  #   qwen3-30b-a3b   → 8002 (on-demand, text/agent path)
  #
  # sha256 fields are `lib.fakeHash`-style placeholders because the flake is
  # not yet evaluated on real Apple Silicon hardware. First `darwin-rebuild
  # build` on xcog1 will report the correct hashes; copy them in, commit, done.
  # Do not deploy this file to xcog1 with placeholder hashes.
  services.llm-stack = {
    enable = true;

    # Point at the external NVMe once mounted. During Phase A the internal SSD
    # is fine (models aren't pulled until first activation on real hardware).
    modelsDir = "/var/models";

    models = {
      qwen3-14b = {
        repo = "mlx-community/Qwen3-14B-Instruct-4bit";
        # TODO: pin a specific revision once verified; do not ship "main".
        revision = "main";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        port = 8001;
        alwaysOn = true; # Voice path — cold start is unacceptable
      };
      qwen3-30b-a3b = {
        repo = "mlx-community/Qwen3-30B-A3B-Instruct-4bit-DWQ";
        revision = "main";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        port = 8002;
        alwaysOn = false; # On-demand — text/agent path can absorb cold start
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
      # Default ports (10300/10200/10400) match the module defaults — HA
      # Assist Wyoming integration will reference these directly.
    };

    exporters.enable = true;
  };

  # ── ntp / logging niceties for a headless box ────────────────────────────
  # (Time Machine and xsvr1 SMB mounts intentionally omitted — this host is
  # backed by ZFS snapshots + Restic per the plan, not Time Machine.)
}
