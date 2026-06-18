{ ... }:
{
  # WirePlumber: rename ALSA nodes to stable names so combine-stream can reference them
  # by name rather than the auto-generated names (which include Unicode serial for Pebble).
  services.pipewire.wireplumber.extraConfig."51-xdt1t-audio-nodes" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "api.alsa.card.id" = "V3";
            "api.alsa.card.name" = "Pebble V3";
            "media.class" = "Audio/Sink";
          }
        ];
        actions = {
          "update-props" = {
            "node.name" = "pebble-out";
            "node.description" = "Pebble V3";
          };
        };
      }
      {
        matches = [
          {
            "api.alsa.card.id" = "Schiit";
            "api.alsa.card.name" = "I'm Fulla Schiit";
            "media.class" = "Audio/Sink";
          }
        ];
        actions = {
          "update-props" = {
            "node.name" = "schiit-out";
            "node.description" = "Schiit Fulla";
          };
        };
      }
      {
        matches = [
          {
            "api.alsa.card.id" = "Receiver";
            "api.alsa.card.name" = "Cubilux SPDIF Receiver";
            "media.class" = "Audio/Source";
          }
        ];
        actions = {
          "update-props" = {
            "node.name" = "spdif-in";
            "node.description" = "SPDIF Input";
          };
        };
      }
      {
        # ALC1220 Digital (onboard SPDIF): card "Generic_1", PCM device 1 (pcm1p)
        matches = [
          {
            "api.alsa.card.id" = "Generic_1";
            "api.alsa.device" = "1";
            "media.class" = "Audio/Sink";
          }
        ];
        actions = {
          "update-props" = {
            "node.name" = "spdif-out";
            "node.description" = "SPDIF Output";
          };
        };
      }
    ];
  };

  # WirePlumber: set combined-main as the default sink
  services.pipewire.wireplumber.extraConfig."52-xdt1t-default-sink" = {
    "wireplumber.settings" = {
      "default.audio.sink" = "combined-main";
    };
  };

  # PipeWire: combined sinks and SPDIF input loopback
  services.pipewire.extraConfig.pipewire."51-xdt1t-audio" = {
    "context.modules" = [
      # combined-main: Pebble + Schiit — system default, all apps play here
      {
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.props" = {
            "node.name" = "combined-main";
            "node.description" = "Pebble + Schiit";
            "media.class" = "Audio/Sink";
            "object.linger" = true;
          };
          nodes = [
            { "target.object" = "pebble-out"; "audio.position" = [ "FL" "FR" ]; }
            { "target.object" = "schiit-out"; "audio.position" = [ "FL" "FR" ]; }
          ];
        };
      }
      # combined-obs: Pebble + Schiit + SPDIF out — used as OBS monitoring device
      {
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.props" = {
            "node.name" = "combined-obs";
            "node.description" = "Pebble + Schiit + SPDIF Out";
            "media.class" = "Audio/Sink";
            "object.linger" = true;
          };
          nodes = [
            { "target.object" = "pebble-out"; "audio.position" = [ "FL" "FR" ]; }
            { "target.object" = "schiit-out"; "audio.position" = [ "FL" "FR" ]; }
            { "target.object" = "spdif-out"; "audio.position" = [ "FL" "FR" ]; }
          ];
        };
      }
      # Loopback: SPDIF input → combined-main (passes SPDIF audio through to Pebble + Schiit)
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "SPDIF Input Passthrough";
          "capture.props" = {
            "node.name" = "spdif-loopback-cap";
            "target.object" = "spdif-in";
            "stream.dont-remix" = true;
          };
          "playback.props" = {
            "node.name" = "spdif-loopback-play";
            "target.object" = "combined-main";
            "stream.dont-remix" = true;
          };
        };
      }
    ];
  };
}
