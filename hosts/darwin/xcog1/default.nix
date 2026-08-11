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

  # Dedicated minimal Homebrew (not the shared brew-packages.nix, which this
  # host's packages-darwin import skips entirely) — Firefox for diagnostics
  # only; no other casks/MAS apps.
  homebrew = {
    enable = true;
    casks = [ "firefox" ];
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none"; # see brew-packages.nix for why: brew bundle's --cleanup is a deprecated no-op that hangs on an unanswerable [y/n] prompt otherwise.
    };
  };

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

          # bug-531: nixpkgs' mlx is deliberately built CPU-only
          # (MLX_BUILD_METAL:BOOL=FALSE) — the `metal` shader compiler is
          # closed-source and unreachable from inside Nix's build sandbox
          # (see the NOTE in nixpkgs' pkgs/development/python-modules/mlx/
          # default.nix). Confirmed live on xcog1: mx.default_device() was
          # Device(cpu, 0), mx.metal.is_available() was False — every
          # mlx_lm.server request was running 30B-parameter matmuls on the
          # CPU, explaining minutes-per-token latency and the daemon crash
          # loop. This Mac's nix.custom.conf already sets `sandbox = false`
          # fleet-wide, so the stated blocker doesn't apply once a real
          # Xcode.app (not just Command Line Tools — `metal`/`metallib` only
          # ship inside the full Xcode bundle) is installed: flip the one
          # cmake flag and hand the build `xcrun` from a real Xcode via
          # nixpkgs' own `composeXcodeWrapper` (the same "sandbox escape
          # hatch" the upstream comment names). `__noChroot = true` makes
          # this explicit per-derivation regardless of the global sandbox
          # setting. Requires Xcode.app installed on xcog1 before this
          # builds — CLT alone will fail with "metal: command not found".
          mlx =
            let
              xcodeWrapper = final.xcodeenv.composeXcodeWrapper { };
              # bug-537: even with the real Xcode's xcrun reachable (bug-532)
              # and the Metal Toolchain downloaded (`xcodebuild
              # -downloadComponent MetalToolchain`), `xcrun -sdk macosx
              # metal`/`metallib` still can't find the tool from this
              # build's user — a documented Apple bug (FB20389216): a
              # cryptex-delivered component, once installed, isn't visible
              # via xcrun to users other than the one that triggered the
              # download. The stopgap (manually mounting the component's own
              # .dmg — christiantietze.de/posts/2026/01/manually-mount-metal-toolchain)
              # only fixes visibility for whoever ran `open` on it; it does
              # NOT make xcrun's own internal SDK/toolchain resolution find
              # it either, since that resolution isn't a plain PATH search.
              # Skip xcrun's resolution entirely for just these two
              # subcommands — exec the real binaries (confirmed present
              # under the manually-mounted volume) directly — and fall
              # through to the real xcrun for everything else.
              xcrunMetalWrapper = final.writeShellScriptBin "xcrun" ''
                if [ "$1" = "-sdk" ] && [ "$2" = "macosx" ] && [ "$3" = "metal" ]; then
                  shift 3
                  exec /Volumes/MetalToolchainCryptex/Metal.xctoolchain/usr/bin/metal "$@"
                elif [ "$1" = "-sdk" ] && [ "$2" = "macosx" ] && [ "$3" = "metallib" ]; then
                  shift 3
                  exec /Volumes/MetalToolchainCryptex/Metal.xctoolchain/usr/bin/metallib "$@"
                else
                  exec /usr/bin/xcrun "$@"
                fi
              '';
            in
            pyprev.mlx.overridePythonAttrs (old: {
              __noChroot = true;
              env = (old.env or { }) // {
                CMAKE_ARGS = builtins.replaceStrings [ "-DMLX_BUILD_METAL:BOOL=FALSE" ]
                  [ "-DMLX_BUILD_METAL:BOOL=TRUE" ]
                  old.env.CMAKE_ARGS
                  # Belt-and-suspenders on top of the PATH fix below: hand
                  # CMake the real compiler directly, bypassing its own
                  # xcrun-based auto-discovery (CMakeDetermineCCompiler) for
                  # the specific step that was hanging — confirmed even a
                  # brand-new build attempt (fresh PID, correct commit
                  # pulled) still invoked apple-sdk's broken xcrun for
                  # CMakeCCompilerId.c, meaning some nixpkgs cmake setup
                  # hook re-asserts apple-sdk's bin dir ahead of ours even
                  # after preBuild's export. Explicit CMAKE_<LANG>_COMPILER
                  # skips that discovery path entirely for C/C++.
                  + " -DCMAKE_C_COMPILER:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
                  + " -DCMAKE_CXX_COMPILER:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
                  # The C++ compiler-works check failed with `ld: library
                  # 'c++' not found` — CMake was still pointing -isysroot at
                  # nixpkgs' own apple-sdk sysroot (via CMAKE_OSX_SYSROOT
                  # default), which doesn't lay out libc++ the way a real
                  # Xcode linker expects. Now that the compiler itself is
                  # real Xcode, the SDK it links against needs to be too.
                  + " -DCMAKE_OSX_SYSROOT:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
                DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
                # bug-538: nixpkgs' own mlx derivation's CMAKE_CXX_FLAGS
                # only has -I.../nlohmann_json-3.12.0/include/nlohmann (one
                # dir too deep for `#include <nlohmann/adl_serializer.hpp>`-
                # style includes, e.g. json.hpp itself) — a latent bug
                # MLX_BUILD_METAL:BOOL=FALSE never exercised, since the
                # Metal-only translation units are the first thing here to
                # need nlohmann_json transitively. Tried just fixing the
                # existing -I to drop the trailing /nlohmann, but OTHER
                # files (mlx/distributed/ring/ring.cpp, mlx/io/safetensors.cpp)
                # do a bare #include "json.hpp"/<json.hpp>, which needs the
                # /nlohmann-suffixed path instead — the two styles coexist
                # in mlx's own source tree. CPATH is Clang's "extra include
                # dirs" env var, searched in ADDITION to -I flags rather
                # than replacing them, so both styles resolve at once
                # without touching (or fighting) the existing CMAKE_CXX_FLAGS.
                CPATH = "${final.nlohmann_json}/include";
              };
              # CMake's FetchContent step needs to download metal-cpp from
              # developer.apple.com mid-build (something the original
              # CPU-only mlx derivation never needed to do) and failed TLS
              # verification: "SSL peer certificate ... was not OK" — no CA
              # bundle was ever wired up for this derivation, since ordinary
              # (non-fixed-output) nix builds aren't expected to touch the
              # network at all. cacert's setup-hook sets
              # NIX_SSL_CERT_FILE/SSL_CERT_FILE automatically.
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                xcodeWrapper
                final.cacert
              ];
              # nativeBuildInputs alone isn't enough: Darwin's stdenv already
              # puts apple-sdk's own bin/xcrun on PATH ahead of it — that's
              # nixpkgs' xcbuild-based *reimplementation* of xcrun (Apple's
              # real one is closed-source, so nixpkgs ships a workalike for
              # sandboxed builds that never touch a real Xcode). It has no
              # idea how to reach an externally-installed Xcode.app, and
              # every xcrun call through it just hangs forever instead of
              # erroring — confirmed live: dozens of `apple-sdk-14.4/usr/bin/
              # xcrun clang -Aa CMakeCCompilerId.c` processes sitting at ~0%
              # CPU, reproduced even after this preBuild fix (see the
              # CMAKE_ARGS comment above for why it needed a second layer for
              # CMake's own compiler-id step). Still needed here for mlx's
              # own CMakeLists.txt (line ~200), which shells out to
              # `zsh -c "... | xcrun -sdk macosx metal ..."` to probe the
              # Metal shader-language version. That failed too, but with a
              # *different* symptom — "no such file or directory" — because
              # nix's build PATH has neither `zsh` nor `/bin` on it at all
              # (not sandbox-related; __noChroot only lifts filesystem
              # isolation, PATH is still just nativeBuildInputs' bin dirs).
              # `/bin` covers zsh itself; xcodeWrapper covers the xcrun that
              # zsh -c then invokes.
              preBuild = ''
                export PATH="${xcrunMetalWrapper}/bin:${xcodeWrapper}/bin:/bin:/usr/bin:$PATH"
              ''
              + (old.preBuild or "");
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
  # Weights live outside the Nix store (cerebrum Decision Log 2026-08-07),
  # but NOT on the external SSD despite the original plan — bug-528: macOS's
  # kTCCServiceSystemPolicyRemovableVolumes blocks ANY automated/headless
  # process (even root, even with diskutil enableOwnership) from writing to
  # an externally-connected volume, confirmed via `log show` TCC denials on
  # xcog1's first real activation. A symlink from the internal disk doesn't
  # help either — the sandbox resolves to the real target volume before the
  # policy check. The only fixes are a manual Full Disk Access grant per
  # nix-store binary (re-required every time nixpkgs bumps that binary — no
  # automation exists without either disabling SIP to hand-edit TCC.db, or
  # real MDM device enrollment for a PrivacyPreferencesPolicyControl profile
  # — both disproportionate for this), or the internal disk. User chose
  # internal (830GB free there) over accepting either tradeoff.
  # Revisions are immutable HF commit SHAs verified via the HF API (bug-522:
  # repo names must be checked — anonymous 401 = not found). If this box
  # turns out to have 24GB RAM, drop qwen3-14b and let the 30B MoE serve the
  # voice path too (plan §D9).
  services.llm-stack = {
    enable = true;
    # modelsDir/modelsVolume left at the module defaults (/var/models on the
    # internal disk, no mount guard needed).

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
