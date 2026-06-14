{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  # OBS writes to its config files at runtime (scenes, prefs), so these are
  # copied once on first deploy rather than symlinked from the store.
  # Guard: only seeds if the Webcam_On profile doesn't exist yet.
  home.activation.obsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      globalIni = pkgs.writeText "obs-global.ini" ''
        [General]
        Pre31Migrated=true
        MaxLogs=10
        InfoIncrement=-1
        ProcessPriority=Normal
        BrowserHWAccel=true

        [Video]
        Renderer=OpenGL

        [PropertiesWindow]
        cx=1600
        cy=1200
      '';

      basicIni = pkgs.writeText "obs-basic-webcam-on.ini" ''
        [General]
        Name=Webcam On

        [Output]
        Mode=Advanced
        FilenameFormatting=%CCYY-%MM-%DD %hh-%mm-%ss
        DelayEnable=false
        DelaySec=20
        DelayPreserve=true
        Reconnect=true
        RetryDelay=1
        MaxRetries=25
        BindIP=default
        IPFamily=IPv4+IPv6
        NewSocketLoopEnable=false
        LowLatencyEnable=false

        [Stream1]
        IgnoreRecommended=false
        EnableMultitrackVideo=false
        MultitrackVideoMaximumAggregateBitrateAuto=true
        MultitrackVideoMaximumVideoTracksAuto=true

        [SimpleOutput]
        FilePath=/home/xrs444
        RecFormat2=mkv
        VBitrate=2500
        ABitrate=192
        UseAdvanced=false
        Preset=veryfast
        NVENCPreset2=p5
        RecQuality=Stream
        RecRB=false
        RecRBTime=20
        RecRBSize=512
        RecRBPrefix=Replay
        StreamAudioEncoder=aac
        RecAudioEncoder=aac
        RecTracks=1
        StreamEncoder=x264
        RecEncoder=x264

        [AdvOut]
        ApplyServiceSettings=true
        UseRescale=false
        TrackIndex=1
        VodTrackIndex=2
        Encoder=obs_x264
        RecType=Standard
        RecFilePath=/home/xrs444
        RecFormat2=mkv
        RecUseRescale=false
        RecTracks=1
        RecEncoder=none
        FLVTrack=1
        StreamMultiTrackAudioMixes=1
        FFOutputToFile=true
        FFFilePath=/home/xrs444
        FFVBitrate=2500
        FFVGOPSize=250
        FFUseRescale=false
        FFIgnoreCompat=false
        FFABitrate=160
        FFAudioMixes=1
        Track1Bitrate=192
        Track2Bitrate=192
        Track3Bitrate=192
        Track4Bitrate=192
        Track5Bitrate=192
        Track6Bitrate=192
        RecSplitFileTime=15
        RecSplitFileSize=2048
        RecRB=false
        RecRBTime=20
        RecRBSize=512
        AudioEncoder=libfdk_aac
        RecAudioEncoder=libfdk_aac
        RescaleRes=960x720
        RecRescaleRes=960x720
        RecSplitFileType=Time
        FFFormat=
        FFFormatMimeType=
        FFRescaleRes=960x720
        FFVEncoderId=0
        FFVEncoder=
        FFAEncoderId=0
        FFAEncoder=
        FFExtension=mp4

        [Video]
        BaseCX=1920
        BaseCY=1080
        OutputCX=1920
        OutputCY=1080
        FPSType=0
        FPSCommon=30
        FPSInt=30
        FPSNum=30
        FPSDen=1
        ScaleType=bicubic
        ColorFormat=NV12
        ColorSpace=709
        ColorRange=Partial
        SdrWhiteLevel=300
        HdrNominalPeakLevel=1000

        [Audio]
        MonitoringDeviceId=combined-obs
        MonitoringDeviceName=Pebble + Schiit + SPDIF Out
        SampleRate=48000
        ChannelSetup=Stereo
        MeterDecayRate=23.53
        PeakMeterType=1

        [Panels]
        CookieId=DD38C8C7393B3F56

        [OBSWebSocket]
        ServerEnabled=true
        ServerPort=4455
        AuthRequired=false
        AlertsEnabled=false
      '';

      serviceJson = pkgs.writeText "obs-service.json" ''
        {"type":"rtmp_custom","settings":{"server":"","use_auth":false,"bwtest":false,"key":""}}
      '';

      streamEncoderJson = pkgs.writeText "obs-streamEncoder.json" "{}";

      # Scene collection from the flatpak import — copied as-is.
      # Audio/video device names may need reconfiguring in OBS if they differ
      # from the Bazzite flatpak device paths.
      scenesJson = ../../../../configimports/obs/obs-studio/basic/scenes/default.json;
    in
    ''
      obs_dir="$HOME/.config/obs-studio"
      if [ ! -d "$obs_dir/basic/profiles/Webcam_On" ]; then
        $DRY_RUN_CMD mkdir -p "$obs_dir/basic/profiles/Webcam_On"
        $DRY_RUN_CMD mkdir -p "$obs_dir/basic/scenes"

        $DRY_RUN_CMD cp ${globalIni} "$obs_dir/global.ini"
        $DRY_RUN_CMD chmod 644 "$obs_dir/global.ini"

        $DRY_RUN_CMD cp ${basicIni} "$obs_dir/basic/profiles/Webcam_On/basic.ini"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/basic.ini"

        $DRY_RUN_CMD cp ${serviceJson} "$obs_dir/basic/profiles/Webcam_On/service.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/service.json"

        $DRY_RUN_CMD cp ${streamEncoderJson} "$obs_dir/basic/profiles/Webcam_On/streamEncoder.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/streamEncoder.json"

        $DRY_RUN_CMD cp ${scenesJson} "$obs_dir/basic/scenes/default.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/scenes/default.json"
      fi

      # Ensure WebSocket section exists in global.ini (idempotent — runs every activation)
      if [ -f "$obs_dir/global.ini" ] && ! grep -q "\[OBSWebSocket\]" "$obs_dir/global.ini"; then
        printf '\n[OBSWebSocket]\nServerEnabled=true\nServerPort=4455\nAuthRequired=false\nAlertsEnabled=false\n' \
          | $DRY_RUN_CMD tee -a "$obs_dir/global.ini" > /dev/null
      fi
    ''
  );

  # Always patch the monitoring device, even if the profile was seeded before this change.
  home.activation.obsMonitoringDevice = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "obsConfig" ] ''
      obs_ini="$HOME/.config/obs-studio/basic/profiles/Webcam_On/basic.ini"
      if [ -f "$obs_ini" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
          -e 's|^MonitoringDeviceId=.*|MonitoringDeviceId=combined-obs|' \
          -e 's|^MonitoringDeviceName=.*|MonitoringDeviceName=Pebble + Schiit + SPDIF Out|' \
          "$obs_ini"
      fi
    ''
  );
}
