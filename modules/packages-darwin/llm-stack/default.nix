# LLM stack module for Darwin — MLX-lm + LiteLLM + Wyoming voice pipeline.
#
# Owns:
#   - one launchd daemon per served MLX model (mlx_lm.server per port)
#   - LiteLLM launchd daemon fronting the MLX ports + upstream cloud tier
#   - Wyoming faster-whisper (STT) and Piper (TTS) launchd daemons
#   - Prometheus node_exporter
#
# Does NOT own:
#   - model weights in the Nix store. Weights live under `modelsDir` (the
#     internal disk by default — bug-528: macOS blocks headless/automated
#     processes, even root, from writing to externally-connected volumes via
#     kTCCServiceSystemPolicyRemovableVolumes, with no scriptable way around
#     it short of disabling SIP or real MDM enrollment, so `modelsVolume`
#     support exists but isn't used on xcog1) and are downloaded at daemon
#     start by a self-healing wrapper pinned to an immutable HuggingFace
#     commit SHA (see .wolf/cerebrum.md Decision Log 2026-08-07: large
#     single-host data stays out of the store so builds/cache/remote
#     builders never carry it).
#   - secrets. sops-nix delivers the LiteLLM master key and DeepSeek API key
#     as files under /run/secrets; wrappers read them into env at exec time
#     (launchd has no file-to-env primitive).
#
# Design notes:
#   - MLX-lm has no single-daemon model registry (unlike Ollama); one launchd
#     unit per served model on a distinct port. LiteLLM routes between them by
#     model name. All models are resident (KeepAlive) — launchd cannot do
#     start-on-request without socket activation, which mlx_lm.server does not
#     support (bug-523). Residency is a RAM decision made in the host config.
#   - Every daemon that touches modelsDir first waits for the backing volume
#     to be mounted. Writing to /Volumes/<name> before mount would create a
#     plain directory on the internal disk and block the volume from mounting.
#   - Runs as system daemons (launchd.daemons) not user agents, because they
#     must survive user logout and expose network ports. Every daemon runs as
#     the dedicated `_llm` service user (Phase B hardening, plan §S3) rather
#     than root — these parse untrusted network input (LiteLLM's HTTP API,
#     Wyoming's audio protocol) with Python/C++ stacks.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.llm-stack;

  # Shell fragment equivalent to nix-darwin's own `/bin/wait4path /nix/store`
  # guard (see bug-705 below) — inlined into each daemon's own script instead
  # of relying on nix-darwin's auto-generated `/bin/sh -c "wait4path && exec
  # ..."` wrapper, which invokes /bin/sh directly as the posix_spawn target.
  nixStoreGuard = "/bin/wait4path /nix/store";

  # Shell fragment: block until the models volume is mounted (no-op when
  # modelsVolume is null, e.g. models on the boot disk).
  mountGuard =
    lib.optionalString (cfg.modelsVolume != null) ''
      until /sbin/mount | /usr/bin/grep -q " on ${cfg.modelsVolume} "; do
        echo "llm-stack: waiting for ${cfg.modelsVolume} to mount..." >&2
        /bin/sleep 5
      done
    '';

  # Shell fragment: block until a sops-nix secret file exists and is
  # non-empty. sops-install-secrets runs as its own launchd service
  # (org.nixos.sops-install-secrets) with no ordering guarantee relative to
  # other launchd.daemons — on a cold boot, a RunAtLoad daemon that reads a
  # secret can start (and read a missing/empty file) before sops has
  # populated /run/secrets, then run with a broken key for its whole
  # KeepAlive lifetime (bug-555, found live on xcog1 after a reboot).
  secretGuard = file: ''
    until [ -s "${file}" ]; do
      echo "llm-stack: waiting for secret ${file} (sops-install-secrets)..." >&2
      /bin/sleep 2
    done
  '';

  # LiteLLM YAML config generated from the model attrset + upstream tier
  # config (JSON is valid YAML). Secrets arrive via os.environ/ references —
  # no key material in the nix store.
  litellmConfigFile = pkgs.writeText "litellm-config.yaml" (
    builtins.toJSON {
      model_list =
        # Local MLX-served models
        (lib.mapAttrsToList (name: m: {
          # model_name is the consumer-facing alias LiteLLM routes on
          # (picks which api_base/port to hit). The forwarded litellm_params
          # `model` value is deliberately NOT this name: mlx_lm.server only
          # recognizes the literal string "default_model" for its single
          # CLI-loaded model (its _model_map has no other alias) — any other
          # value falls through and mlx_lm.server tries to fetch it fresh
          # from HuggingFace as a bare repo id (bug-530, found live: it
          # attempted "https://huggingface.co/api/models/qwen3-30b-a3b/...").
          model_name = name;
          litellm_params = {
            model = "openai/default_model";
            api_base = "http://127.0.0.1:${toString m.port}/v1";
            api_key = "not-used";
          };
        }) cfg.models)
        # Cloud fallback tier (DeepSeek) — key injected via env at exec time
        ++ lib.optional cfg.cloudTier.enable {
          model_name = cfg.cloudTier.modelName;
          litellm_params = {
            model = cfg.cloudTier.upstreamModel;
            api_base = cfg.cloudTier.apiBase;
            api_key = "os.environ/DEEPSEEK_API_KEY";
          };
        };

      general_settings = {
        # Reject unauthenticated requests — consumers present this as a
        # Bearer token. Without a DB there are no per-consumer virtual keys;
        # one household master key is the accepted tier (plan §S1).
        master_key = "os.environ/LITELLM_MASTER_KEY";
        telemetry = false;
        store_model_in_db = false;
        # Without this, LiteLLM's auth path still probes for a Postgres
        # connection on every request (even master-key-only requests) and
        # fails closed with "No connected db" when none exists — bug-529,
        # found live on xcog1's first end-to-end test. We deliberately run
        # DB-less (store_model_in_db = false, single household master key,
        # no per-consumer virtual keys) so this must be explicit.
        allow_requests_on_db_unavailable = true;
      };
      litellm_settings = {
        set_verbose = false;
        json_logs = true;
      };
    }
  );

  # launchd daemon for a single mlx_lm.server serving one model. The wrapper
  # downloads the pinned revision into modelsDir on first start (or after a
  # revision bump) and is a fast no-op otherwise. KeepAlive + ThrottleInterval
  # make an interrupted download self-retry without hammering HuggingFace.
  mkMlxDaemon = modelName: m: {
    name = "mlx-lm-${modelName}";
    value = {
      serviceConfig = {
        Label = "net.xrs444.mlx-lm-${modelName}";
        # Direct ProgramArguments, not nix-darwin's `command` option (bug-705):
        # `command` auto-wraps in `/bin/sh -c "wait4path && exec ..."`, and
        # `/bin/sh` itself carries a macOS Launch Constraint (LWCR, Sequoia
        # 15.1+ AMFI hardening) that denies posix_spawn when the calling
        # chain goes through xpcproxy for a non-root UserName daemon —
        # confirmed via `log show`: "Service could not initialize:
        # posix_spawn(/bin/sh), error 0xd - Permission denied", identical and
        # deterministic across every attempt (env, cwd, password hash, and a
        # full reboot all ruled out first). Invoking the wrapper script
        # directly (a real Mach-O-independent, directly-executable
        # #!/nix/store/.../bash script) as the sole ProgramArguments entry
        # avoids /bin/sh as a posix_spawn target entirely. wait4path is still
        # run, just from inside this script rather than the outer shell.
        ProgramArguments = [
          "${pkgs.writeShellScript "mlx-lm-${modelName}" ''
            set -euo pipefail
            ${nixStoreGuard}
            ${mountGuard}
            dir="${cfg.modelsDir}/${modelName}"
            if [ ! -f "$dir/.revision" ] || [ "$(/bin/cat "$dir/.revision")" != "${m.revision}" ]; then
              echo "llm-stack: fetching ${m.repo} @ ${m.revision}" >&2
              /bin/rm -rf "$dir"
              export HF_HOME="${cfg.modelsDir}/.hf-cache"
              export HF_HUB_DISABLE_TELEMETRY=1
              ${cfg.hfPackage}/bin/hf download ${m.repo} --revision ${m.revision} --local-dir "$dir"
              printf '%s' "${m.revision}" > "$dir/.revision"
            fi
            exec ${cfg.mlxLmPackage}/bin/mlx_lm.server --model "$dir" --host 127.0.0.1 --port ${toString m.port}
          ''}"
        ];
        # Always world-traversable — daemons otherwise inherit whatever cwd
        # they were spawned from (bug-703: httpx→rich calls os.getcwd() at
        # import time, unconditionally, and crashes with EX_CONFIG if _llm
        # can't traverse into it).
        WorkingDirectory = "/";
        # bug-704: _llm's real home (not /var/empty) for HF/tiktoken/rich
        # caches that assume a writable $HOME.
        EnvironmentVariables = {
          HOME = "/var/lib/llm-stack";
        };
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 30;
        StandardErrorPath = "/var/log/llm-stack/mlx-lm-${modelName}.stderr";
        StandardOutPath = "/var/log/llm-stack/mlx-lm-${modelName}.stdout";
        ProcessType = "Adaptive"; # macOS scheduler hint: not a background-only task
      };
    };
  };
in

{
  options.services.llm-stack = with lib; {
    enable = mkEnableOption "MLX + LiteLLM + Wyoming voice pipeline for family agent";

    modelsDir = mkOption {
      type = types.str;
      default = "/var/models";
      description = ''
        Filesystem root for model weights (MLX models, whisper/piper caches).
        Deliberately NOT a Nix store path — weights are host-local data.
        Defaults to the internal disk: bug-528 found that macOS's
        kTCCServiceSystemPolicyRemovableVolumes blocks headless/automated
        writes (even as root) to externally-connected volumes with no
        scriptable workaround, so an external `modelsVolume` isn't viable
        for an unattended host without either disabling SIP or real MDM
        enrollment. Left configurable in case a future host's storage layout
        differs (e.g. genuinely internal-only expansion storage).
      '';
    };

    modelsVolume = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/Volumes/xcog1-models";
      description = ''
        Mount point backing modelsDir, if it lives on a separate volume.
        Daemons wait for this mount before touching modelsDir, preventing the
        macOS trap of writing to an unmounted /Volumes path (which creates a
        plain directory on the boot disk and blocks the real mount). NOTE:
        this does not help with EXTERNALLY-connected (USB/Thunderbolt)
        volumes specifically — see modelsDir's description (bug-528).
      '';
    };

    # ── MLX inference ──────────────────────────────────────────────────────

    mlxLmPackage = mkOption {
      type = types.package;
      default = pkgs.python3.withPackages (ps: [ ps.mlx-lm ]);
      description = "Python environment providing the mlx_lm.server entrypoint.";
    };

    hfPackage = mkOption {
      type = types.package;
      default = pkgs.python3.withPackages (ps: [ ps.huggingface-hub ]);
      description = "Python environment providing the `hf` download CLI.";
    };

    models = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            repo = mkOption {
              type = types.str;
              example = "mlx-community/Qwen3-14B-4bit";
              description = "HuggingFace repo path (org/name). Verify existence via the HF API before pinning.";
            };
            revision = mkOption {
              type = types.str;
              description = "Immutable HF commit SHA. Never a branch name — the wrapper re-downloads on change.";
            };
            port = mkOption {
              type = types.port;
              description = "Localhost port for this model's mlx_lm.server.";
            };
          };
        }
      );
      default = { };
      description = ''
        MLX models to serve, one resident mlx_lm.server launchd daemon each.
        Which models to include is a host-level RAM decision (all are pinned
        resident; launchd cannot start-on-request — bug-523).
      '';
    };

    # ── LiteLLM router ─────────────────────────────────────────────────────

    litellmPackage = mkOption {
      type = types.package;
      default = pkgs.python3.withPackages (
        ps: [ ps.litellm ] ++ ps.litellm.optional-dependencies.proxy
      );
      description = "Python environment providing the litellm proxy CLI (needs the proxy extras).";
    };

    litellmPort = mkOption {
      type = types.port;
      default = 4000;
      description = "Port LiteLLM exposes on the LAN (hermes, HA, and app-to-LLM integrations all point here).";
    };

    masterKeyFile = mkOption {
      type = types.str;
      default = "/run/secrets/litellm-master-key";
      description = "File containing the LiteLLM master key (sops-delivered). Read into env at exec time.";
    };

    cloudTier = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Register DeepSeek as `tier: hard` upstream and failure fallback.";
      };
      modelName = mkOption {
        type = types.str;
        default = "deepseek-hard";
        description = "LiteLLM model name that maps to the cloud tier.";
      };
      upstreamModel = mkOption {
        type = types.str;
        default = "deepseek/deepseek-chat";
        description = "LiteLLM provider/model identifier for the cloud upstream.";
      };
      apiBase = mkOption {
        type = types.str;
        default = "https://api.deepseek.com";
      };
      apiKeyFile = mkOption {
        type = types.str;
        default = "/run/secrets/deepseek-api-key";
        description = "File containing the DeepSeek API key (sops-delivered).";
      };
    };

    # ── Voice pipeline (Wyoming) ───────────────────────────────────────────

    voice = {
      enable = mkEnableOption "Wyoming voice services (faster-whisper STT, Piper TTS)";

      whisper = {
        package = mkOption {
          type = types.package;
          default = pkgs.wyoming-faster-whisper;
          description = "Wyoming faster-whisper package.";
        };
        port = mkOption {
          type = types.port;
          default = 10300;
        };
        model = mkOption {
          type = types.str;
          # CTranslate2 is CPU-only on macOS — turbo keeps voice latency sane
          # at near-identical accuracy for command STT (plan §D6).
          default = "large-v3-turbo";
        };
        language = mkOption {
          type = types.str;
          default = "en";
        };
      };

      piper = {
        package = mkOption {
          type = types.package;
          # withTrain drags in pysilero-vad (broken on darwin: GNU-ld flag) and
          # torch/lightning — inference needs none of it.
          default = pkgs.wyoming-piper.override {
            piper-tts = pkgs.piper-tts.override { withTrain = false; };
          };
          description = "Wyoming Piper TTS package (bundles piper-tts, inference-only; Kokoro upgrade is plan §D7/Phase D).";
        };
        port = mkOption {
          type = types.port;
          default = 10200;
        };
        voice = mkOption {
          type = types.str;
          default = "en_US-lessac-medium";
          description = "Piper voice name; downloaded into modelsDir/piper on first start.";
        };
      };
    };

    # ── Observability exporters ────────────────────────────────────────────

    exporters = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Prometheus node_exporter. (Apple-silicon GPU/ANE exporter is unpackaged — plan §D4, Phase D.)";
      };
      nodeExporterPort = mkOption {
        type = types.port;
        default = 9100;
      };
    };
  };

  # ── Implementation ───────────────────────────────────────────────────────

  config = lib.mkIf cfg.enable {
    # Dedicated service account, reserved but currently UNUSED by any daemon
    # (plan §S3 — attempted, reverted; see bug-702 through bug-705 in
    # buglog.json and the matching cerebrum.md entries for the full
    # investigation). Running these daemons as `_llm` instead of root hit an
    # Apple-documented, unfixable limitation: a LaunchDaemon with a non-root
    # `UserName` runs in a "mixed execution context" (BSD UID/GID switches,
    # but other macOS security-context components — notably Local Network
    # access, which LiteLLM's :4000 listener needs — stay in the root/daemon
    # context), confirmed via Apple DTS on the developer forums, with root
    # explicitly recommended for daemons needing local network access. Every
    # daemon in this module was reverted to running as root. Left defined
    # (rather than removed) because nix-darwin hard-errors an activation that
    # tries to delete/modify an existing account's core attributes — safer
    # to leave uid/gid 442 permanently reserved and dormant than risk another
    # failed switch. Revisit only if Apple changes this behavior upstream.
    # Fixed uid/gid 442: the gap between macOS's own last system account
    # (`_oahd`, 441) and the first human account (`xrs444`, 501) on xcog1,
    # confirmed free via `dscl . -list /Users UniqueID` before picking it.
    # `knownUsers`/`knownGroups` are required by nix-darwin before it's
    # allowed to manage a user/group via dscl.
    users.knownUsers = [ "_llm" ];
    users.knownGroups = [ "_llm" ];
    users.groups._llm = {
      gid = 442;
      description = "LLM stack service group (MLX/LiteLLM/Wyoming daemons)";
    };
    users.users._llm = {
      uid = 442;
      gid = 442;
      # /var/empty (bug-704): nix-darwin refuses to change an EXISTING
      # user's home directory declaratively ("nix-darwin does not support
      # changing the home directory of existing users" — hard-errors the
      # whole activation rather than applying it), so this can't be fixed by
      # changing the account's registered home. Instead, every Python-based
      # daemon below sets EnvironmentVariables.HOME explicitly to a real
      # writable directory — Python's os.path.expanduser (and most ML
      # libraries' cache-path resolution: rich, huggingface_hub/tiktoken-
      # adjacent code in mlx-lm and the Wyoming daemons) reads the $HOME env
      # var first, before ever consulting the account's actual dscl home, so
      # this is sufficient without needing to touch this attribute.
      home = "/var/empty";
      shell = "/usr/bin/false";
      description = "LLM stack service user (MLX/LiteLLM/Wyoming daemons)";
    };

    # Log directory for all daemons in this module. modelsDir is only
    # created here when it's NOT on a separate mounted volume — touching the
    # path before an external volume mounts would shadow the mount point
    # (see modelsVolume). When modelsVolume is null (bug-528: external
    # volumes are TCC-blocked for headless writes, so this is the common
    # case), each daemon's own `mkdir -p`/`parents=True` would create it
    # anyway, but doing it once here up front is cheaper and keeps ownership
    # consistent from the start. Owned by `_llm` (not root:wheel) since every
    # daemon writing here now runs as `_llm` (§S3).
    #
    # MUST be wired into `postActivation`, not a made-up custom key
    # (bug-702): nix-darwin's actual activation script
    # (modules/system/activation-scripts.nix `system.activationScripts.script.text`)
    # hardcodes an explicit list of ~24 named slots it interpolates
    # (preActivation, checks, createRun, extraActivation, groups, users,
    # applications, pam, patches, openssh, etc, defaults, userDefaults,
    # launchd, userLaunchd, nix-daemon, time, networking, power, keyboard,
    # fonts, nvram, homebrew, postActivation) — any OTHER attribute name
    # under `system.activationScripts.<name>` evaluates fine (the option
    # type is an open attrsOf) but is silently never executed, since nothing
    # in the master script references it. `postActivation` is the correct
    # hook here: it runs dead last (after `users`, so `_llm` exists for the
    # chown to succeed, and after `launchd`, so even the daemons' very first
    # KeepAlive load attempt — which may still race ahead of this fix within
    # the same switch — gets corrected permissions in place well before the
    # ThrottleInterval retry).
    system.activationScripts.postActivation.text = ''
      /bin/mkdir -p /var/log/llm-stack
      /usr/sbin/chown root:wheel /var/log/llm-stack
      /bin/chmod 755 /var/log/llm-stack
      /bin/mkdir -p /var/lib/llm-stack
      /usr/sbin/chown root:wheel /var/lib/llm-stack
      /bin/chmod 755 /var/lib/llm-stack
    ''
    + lib.optionalString (cfg.modelsVolume == null) ''
      /bin/mkdir -p ${cfg.modelsDir}
      /usr/sbin/chown root:wheel ${cfg.modelsDir}
      /bin/chmod 755 ${cfg.modelsDir}
    '';

    # Rotate daemon logs: 10MB per file, 5 bzip2'd archives (G = glob entry).
    environment.etc."newsyslog.d/llm-stack.conf".text = ''
      # logfilename                      mode count size(KB) when flags
      /var/log/llm-stack/*.stdout        644  5     10240    *    GJ
      /var/log/llm-stack/*.stderr        644  5     10240    *    GJ
    '';

    launchd.daemons = lib.mkMerge [
      # One daemon per MLX-served model.
      (lib.listToAttrs (lib.mapAttrsToList mkMlxDaemon cfg.models))

      # LiteLLM router — launchd has no ordering primitives; LiteLLM retries
      # its upstream connections by default, so model daemons may come up
      # after it. KeepAlive so it survives model daemon restarts.
      {
        litellm = {
          serviceConfig = {
            Label = "net.xrs444.litellm";
            # bug-705: direct ProgramArguments, bypassing nix-darwin's
            # `command`-derived `/bin/sh -c "wait4path && exec ..."` wrapper
            # — /bin/sh itself is denied by a macOS Launch Constraint for
            # this xpcproxy-mediated, non-root-UserName spawn path.
            ProgramArguments = [
              "${pkgs.writeShellScript "litellm-wrapped" ''
                set -euo pipefail
                ${nixStoreGuard}
                ${secretGuard cfg.masterKeyFile}
                export LITELLM_MASTER_KEY="$(/bin/cat ${cfg.masterKeyFile})"
                ${lib.optionalString cfg.cloudTier.enable ''
                  ${secretGuard cfg.cloudTier.apiKeyFile}
                  export DEEPSEEK_API_KEY="$(/bin/cat ${cfg.cloudTier.apiKeyFile})"
                ''}
                exec ${cfg.litellmPackage}/bin/litellm --config ${litellmConfigFile} \
                  --port ${toString cfg.litellmPort} --host 0.0.0.0
              ''}"
            ];
            # bug-703: httpx→rich calls os.getcwd() at import time — must
            # not inherit an ambient cwd it can't traverse.
            WorkingDirectory = "/";
            # bug-704: real writable $HOME for HF/tiktoken/rich caches.
            EnvironmentVariables = {
              HOME = "/var/lib/llm-stack";
            };
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 15;
            StandardErrorPath = "/var/log/llm-stack/litellm.stderr";
            StandardOutPath = "/var/log/llm-stack/litellm.stdout";
          };
        };
      }

      # Wyoming voice services. Both cache their model data under modelsDir,
      # so they carry the same mount guard as the MLX daemons.
      (lib.mkIf cfg.voice.enable {
        wyoming-whisper = {
          serviceConfig = {
            Label = "net.xrs444.wyoming-whisper";
            # bug-705: direct ProgramArguments (see litellm's comment above).
            ProgramArguments = [
              "${pkgs.writeShellScript "wyoming-whisper" ''
                set -euo pipefail
                ${nixStoreGuard}
                ${mountGuard}
                /bin/mkdir -p ${cfg.modelsDir}/whisper
                exec ${cfg.voice.whisper.package}/bin/wyoming-faster-whisper \
                  --model ${cfg.voice.whisper.model} \
                  --language ${cfg.voice.whisper.language} \
                  --uri tcp://0.0.0.0:${toString cfg.voice.whisper.port} \
                  --data-dir ${cfg.modelsDir}/whisper
              ''}"
            ];
            WorkingDirectory = "/";
            EnvironmentVariables = {
              HOME = "/var/lib/llm-stack";
            };
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 30;
            StandardErrorPath = "/var/log/llm-stack/wyoming-whisper.stderr";
            StandardOutPath = "/var/log/llm-stack/wyoming-whisper.stdout";
          };
        };
        wyoming-piper = {
          serviceConfig = {
            Label = "net.xrs444.wyoming-piper";
            # bug-705: direct ProgramArguments (see litellm's comment above).
            ProgramArguments = [
              "${pkgs.writeShellScript "wyoming-piper" ''
                set -euo pipefail
                ${nixStoreGuard}
                ${mountGuard}
                /bin/mkdir -p ${cfg.modelsDir}/piper
                exec ${cfg.voice.piper.package}/bin/wyoming-piper \
                  --voice ${cfg.voice.piper.voice} \
                  --uri tcp://0.0.0.0:${toString cfg.voice.piper.port} \
                  --data-dir ${cfg.modelsDir}/piper
              ''}"
            ];
            WorkingDirectory = "/";
            EnvironmentVariables = {
              HOME = "/var/lib/llm-stack";
            };
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 30;
            StandardErrorPath = "/var/log/llm-stack/wyoming-piper.stderr";
            StandardOutPath = "/var/log/llm-stack/wyoming-piper.stdout";
          };
        };
      })

      # Prometheus node_exporter.
      (lib.mkIf cfg.exporters.enable {
        node-exporter = {
          serviceConfig = {
            Label = "net.xrs444.node-exporter";
            # bug-705: direct ProgramArguments straight at the binary — no
            # shell/wrapper needed here at all, which also means no /bin/sh
            # posix_spawn target (see litellm's comment above for why that
            # matters).
            ProgramArguments = [
              "${pkgs.prometheus-node-exporter}/bin/node_exporter"
              "--web.listen-address=:${toString cfg.exporters.nodeExporterPort}"
            ];
            WorkingDirectory = "/";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/node-exporter.stderr";
            StandardOutPath = "/var/log/llm-stack/node-exporter.stdout";
          };
        };
      })
    ];
  };
}
