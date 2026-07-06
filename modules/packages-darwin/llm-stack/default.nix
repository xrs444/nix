# LLM stack module for Darwin — MLX-lm + LiteLLM + Wyoming voice pipeline.
#
# Owns:
#   - one launchd daemon per served MLX model (mlx-lm.server per port)
#   - LiteLLM launchd daemon fronting the MLX ports + upstream cloud tiers
#   - Wyoming Whisper (STT), Kokoro (TTS), Resemblyzer (speaker ID) launchd daemons
#   - Prometheus exporters: node_exporter, apple_silicon_exporter
#
# Does NOT own:
#   - model file downloads. Nix derivations pin repo + revision + sha256; if
#     mlx-community publishes a new revision, bump revision + rehash.
#   - LiteLLM upstream secrets (DeepSeek/Anthropic keys). Provided via sops-nix
#     and passed as environment variables at launchd time.
#
# Design notes:
#   - MLX-lm has no single-daemon model registry (unlike Ollama); one launchd
#     unit per served model on a distinct port. LiteLLM routes between them by
#     model name.
#   - Voice paths need low latency — voice model (Qwen3 14B) is alwaysOn.
#     30B-A3B runs on-demand: KeepAlive.SuccessfulExit=false so launchd starts
#     it once a request lands but doesn't respawn if it exits cleanly (idle).
#   - Runs as system daemons (launchd.daemons, root-owned) not user agents,
#     because they need to survive user logout and expose network ports.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.llm-stack;

  # Fetches an mlx-community model repo from HuggingFace pinned to a specific
  # revision. LFS blobs come from HuggingFace's LFS endpoint (fetchgit + fetchLFS).
  # NOTE: For any model whose sha256 is `lib.fakeHash` below, the first `nix build`
  # will fail with the correct hash — copy it into the definition. Standard Nix
  # workflow. Do not commit `lib.fakeHash` values to main.
  mkMlxModel =
    {
      name,
      repo,
      revision,
      sha256,
    }:
    pkgs.fetchgit {
      name = "mlx-model-${name}";
      url = "https://huggingface.co/${repo}";
      rev = revision;
      inherit sha256;
      fetchLFS = true;
    };

  # LiteLLM YAML config generated from the model attrset + upstream tier config.
  # Each MLX model becomes a local upstream; DeepSeek is added as `tier: hard`.
  litellmConfigFile = pkgs.writeText "litellm-config.yaml" (
    builtins.toJSON {
      model_list =
        # Local MLX-served models
        (lib.mapAttrsToList (name: m: {
          model_name = name;
          litellm_params = {
            model = "openai/${name}";
            api_base = "http://127.0.0.1:${toString m.port}/v1";
            api_key = "not-used";
          };
        }) cfg.models)
        # Cloud fallback tier (DeepSeek) — API key injected via env at launchd time
        ++ lib.optional cfg.cloudTier.enable {
          model_name = cfg.cloudTier.modelName;
          litellm_params = {
            model = cfg.cloudTier.upstreamModel;
            api_base = cfg.cloudTier.apiBase;
            api_key = "os.environ/DEEPSEEK_API_KEY";
          };
        };

      # LiteLLM router: prefer local for routine, cloud for `tier: hard`
      router_settings = {
        routing_strategy = "usage-based-routing-v2";
        model_group_alias = { };
      };

      # /metrics for Prometheus scraping (also drives §6 alert rules)
      general_settings = {
        telemetry = false;
        store_model_in_db = false;
      };
      litellm_settings = {
        set_verbose = false;
        json_logs = true;
      };
    }
  );

  # launchd daemon for a single mlx-lm.server serving one model.
  mkMlxDaemon =
    modelName: modelCfg:
    let
      modelDrv = mkMlxModel {
        name = modelName;
        inherit (modelCfg) repo revision sha256;
      };
    in
    {
      name = "mlx-lm-${modelName}";
      value = {
        # mlx-lm.server is a Python entry point. Runs as root; binds 127.0.0.1
        # so only LiteLLM (also on the Mac) can reach it directly. External
        # traffic goes through LiteLLM on cfg.litellmPort.
        command = "${cfg.mlxLmPackage}/bin/mlx_lm.server --model ${modelDrv} --host 127.0.0.1 --port ${toString modelCfg.port}";
        serviceConfig = {
          Label = "net.xrs444.mlx-lm-${modelName}";
          # alwaysOn models: KeepAlive=true — respawn always.
          # on-demand models: KeepAlive.SuccessfulExit=false — respawn only on
          # crash, exit cleanly when idle-timeout fires (mlx-lm has --idle-timeout).
          KeepAlive =
            if modelCfg.alwaysOn then
              true
            else
              {
                SuccessfulExit = false;
              };
          RunAtLoad = modelCfg.alwaysOn;
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
      type = types.path;
      default = "/var/models";
      description = ''
        Filesystem root for MLX model derivations. Point at the external NVMe
        (typical for xcog1: /Volumes/xcog1-models or /var/models symlinked to it)
        so the 512GB internal SSD isn't consumed by the model library.
      '';
    };

    # ── MLX inference ──────────────────────────────────────────────────────

    mlxLmPackage = mkOption {
      type = types.package;
      default = pkgs.python3.withPackages (ps: with ps; [
        # TODO: verify mlx-lm attribute exists in the nixpkgs revision pinned by
        # the flake. If not, add via overlay (see nix/overlays/pkgs.nix pattern
        # for openrsat) — mlx-lm is a straightforward PyPI wheel with an mlx
        # dependency. Fallback: use pkgs.python3.pkgs.buildPythonApplication with
        # a src fetched from GitHub (ml-explore/mlx-lm).
        # ps.mlx-lm
      ]);
      description = "Python environment providing mlx_lm.server entrypoint.";
    };

    models = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          repo = mkOption {
            type = types.str;
            example = "mlx-community/Qwen3-14B-Instruct-4bit";
            description = "HuggingFace repo path (org/name).";
          };
          revision = mkOption {
            type = types.str;
            default = "main";
            description = "Git revision (commit sha or tag). Pin explicitly; don't leave as 'main'.";
          };
          sha256 = mkOption {
            type = types.str;
            description = "Nix hash of the fetched repo. Use lib.fakeHash until nix reports the real value.";
          };
          port = mkOption {
            type = types.port;
            description = "Localhost port for this model's mlx-lm.server.";
          };
          alwaysOn = mkOption {
            type = types.bool;
            default = false;
            description = "Pin resident (KeepAlive=true). Use for voice-path models where cold start latency is unacceptable.";
          };
        };
      });
      default = { };
      description = "MLX models to serve. Each becomes an mlx-lm.server launchd daemon on its own port.";
    };

    # ── LiteLLM router ─────────────────────────────────────────────────────

    litellmPackage = mkOption {
      type = types.package;
      default = pkgs.python3.withPackages (ps: with ps; [
        # TODO: verify litellm attribute in pinned nixpkgs; add via overlay if not.
        # ps.litellm
      ]);
      description = "Python environment providing the litellm CLI.";
    };

    litellmPort = mkOption {
      type = types.port;
      default = 4000;
      description = "Port LiteLLM exposes on the LAN (Hermes, Grafana LLM app, and app-to-LLM integrations all point here).";
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
      # DEEPSEEK_API_KEY is delivered via sops-nix and referenced by LiteLLM
      # config through os.environ/ — no key material in the nix store.
    };

    # ── Voice pipeline (Wyoming) ───────────────────────────────────────────

    voice = {
      enable = mkEnableOption "Wyoming voice services (Whisper STT, Kokoro TTS, Resemblyzer speaker ID)";

      whisper = {
        package = mkOption {
          type = types.package;
          # TODO: pkgs.wyoming-whisper or pkgs.openai-whisper-cpp — verify availability
          default = pkgs.hello;
          description = "Wyoming-wrapped Whisper package.";
        };
        port = mkOption {
          type = types.port;
          default = 10300;
        };
        model = mkOption {
          type = types.str;
          default = "large-v3";
        };
      };

      kokoro = {
        package = mkOption {
          type = types.package;
          # TODO: Kokoro TTS packaging — likely needs a custom derivation in
          # overlays/pkgs.nix (Python + torch + kokoro-onnx / kokoro-fastapi).
          default = pkgs.hello;
          description = "Wyoming-wrapped Kokoro TTS package.";
        };
        port = mkOption {
          type = types.port;
          default = 10200;
        };
      };

      resemblyzer = {
        package = mkOption {
          type = types.package;
          # TODO: Speaker embedding service. Not in nixpkgs — will need a
          # Python wrapper derivation (resemblyzer OR pyannote ECAPA-TDNN).
          # Small model (~50-80MB); the wrapper just needs to expose an HTTP
          # or Wyoming endpoint that HA Assist calls with an audio chunk.
          default = pkgs.hello;
          description = "Speaker ID service (Resemblyzer or ECAPA-TDNN).";
        };
        port = mkOption {
          type = types.port;
          default = 10400;
        };
      };
    };

    # ── Observability exporters ────────────────────────────────────────────

    exporters = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Prometheus exporters — node_exporter and apple_silicon_exporter.";
      };
      nodeExporterPort = mkOption {
        type = types.port;
        default = 9100;
      };
      appleSiliconExporterPort = mkOption {
        type = types.port;
        default = 9101;
      };
    };
  };

  # ── Implementation ───────────────────────────────────────────────────────

  config = lib.mkIf cfg.enable {
    # Log directory for all daemons in this module.
    system.activationScripts.llm-stack-dirs.text = ''
      /bin/mkdir -p /var/log/llm-stack
      /bin/mkdir -p ${cfg.modelsDir}
      /usr/sbin/chown root:wheel /var/log/llm-stack ${cfg.modelsDir}
      /bin/chmod 755 /var/log/llm-stack ${cfg.modelsDir}
    '';

    # One launchd.daemon per MLX-served model.
    launchd.daemons = lib.mkMerge [
      (lib.listToAttrs (
        lib.mapAttrsToList (name: mCfg: mkMlxDaemon name mCfg) cfg.models
      ))

      # LiteLLM router — depends on the MLX daemons being started but launchd
      # has no ordering primitives; LiteLLM must retry its upstream connections
      # (it does by default). RunAtLoad + KeepAlive so LiteLLM survives model
      # daemon restarts.
      {
        litellm = {
          command = "${cfg.litellmPackage}/bin/litellm --config ${litellmConfigFile} --port ${toString cfg.litellmPort} --host 0.0.0.0";
          serviceConfig = {
            Label = "net.xrs444.litellm";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/litellm.stderr";
            StandardOutPath = "/var/log/llm-stack/litellm.stdout";
            # sops-nix delivers DEEPSEEK_API_KEY into /run/secrets/deepseek-api-key
            # at activation. Read into env at launchd time via EnvironmentVariables
            # with the file contents. For now, template — actual sops wiring is
            # a separate step when the Mac lands (secrets can't be tested pre-arrival).
            # TODO: EnvironmentVariables = { DEEPSEEK_API_KEY = "<from sops>"; };
          };
        };
      }

      # Wyoming voice services.
      (lib.mkIf cfg.voice.enable {
        wyoming-whisper = {
          command = "${cfg.voice.whisper.package}/bin/wyoming-faster-whisper --model ${cfg.voice.whisper.model} --uri tcp://0.0.0.0:${toString cfg.voice.whisper.port}";
          serviceConfig = {
            Label = "net.xrs444.wyoming-whisper";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/wyoming-whisper.stderr";
            StandardOutPath = "/var/log/llm-stack/wyoming-whisper.stdout";
          };
        };
        wyoming-kokoro = {
          command = "${cfg.voice.kokoro.package}/bin/wyoming-kokoro --uri tcp://0.0.0.0:${toString cfg.voice.kokoro.port}";
          serviceConfig = {
            Label = "net.xrs444.wyoming-kokoro";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/wyoming-kokoro.stderr";
            StandardOutPath = "/var/log/llm-stack/wyoming-kokoro.stdout";
          };
        };
        speaker-id = {
          command = "${cfg.voice.resemblyzer.package}/bin/resemblyzer-wyoming --uri tcp://0.0.0.0:${toString cfg.voice.resemblyzer.port}";
          serviceConfig = {
            Label = "net.xrs444.speaker-id";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/speaker-id.stderr";
            StandardOutPath = "/var/log/llm-stack/speaker-id.stdout";
          };
        };
      })

      # Prometheus exporters.
      (lib.mkIf cfg.exporters.enable {
        node-exporter = {
          command = "${pkgs.prometheus-node-exporter}/bin/node_exporter --web.listen-address=:${toString cfg.exporters.nodeExporterPort}";
          serviceConfig = {
            Label = "net.xrs444.node-exporter";
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/var/log/llm-stack/node-exporter.stderr";
            StandardOutPath = "/var/log/llm-stack/node-exporter.stdout";
          };
        };
        # apple_silicon_exporter isn't in nixpkgs — see overlays/pkgs.nix TODO.
        # Placeholder daemon definition; wire the real command after the package
        # is added.
        # apple-silicon-exporter = {
        #   command = "${pkgs.apple-silicon-exporter}/bin/apple-silicon-exporter --port ${toString cfg.exporters.appleSiliconExporterPort}";
        #   serviceConfig = { ... };
        # };
      })
    ];
  };
}
