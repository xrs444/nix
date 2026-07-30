# Summary: Docker + NVIDIA container runtime for Automatic Ripping Machine (ARM).
# Static host setup only — the ARM container itself is started/stopped on
# demand via rip.justfile (arm-start/arm-stop), not boot-persistent. xdt1-t only.
{ hostname, lib, ... }:
let
  isArmHost = lib.elem hostname [ "xdt1-t" ];
in
lib.mkIf isArmHost {
  virtualisation.docker.enable = true;

  # CDI-based GPU-in-container support (the modern replacement for the
  # deprecated virtualisation.docker.enableNvidia) so `docker run --gpus all`
  # reaches the GPU — needed for HandBrake NVENC transcoding in the ARM
  # container. Requires the nvidia driver in services.xserver.videoDrivers,
  # already set by hardware-nvidia.nix.
  hardware.nvidia-container-toolkit.enable = true;

  # so rip.justfile's arm-start/arm-stop/arm-status recipes need no sudo.
  users.users.xrs444.extraGroups = [ "docker" ];

  # MakeMKV license key + OMDb API key — both obtained by the user, not
  # generated here. Fill in nix/secrets/arm.yaml via `sops nix/secrets/arm.yaml`
  # before first `arm-start`.
  sops.secrets."arm-makemkv-key" = {
    sopsFile = ../../../secrets/arm.yaml;
    key = "makemkv_key";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
  };

  sops.secrets."arm-omdb-key" = {
    sopsFile = ../../../secrets/arm.yaml;
    key = "omdb_api_key";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
  };

  # Local staging only — NOT the xsvr1 NFS mount. Transfer to xsvr1 is a
  # separate, deferred step once this pipeline is proven.
  systemd.tmpfiles.rules = [
    "d /home/xrs444/rips/arm/config 0750 xrs444 xrs444 -"
    "d /home/xrs444/rips/arm/logs 0750 xrs444 xrs444 -"
    "d /home/xrs444/rips/arm/raw 0750 xrs444 xrs444 -"
    "d /home/xrs444/rips/arm/completed 0750 xrs444 xrs444 -"
    "d /home/xrs444/rips/arm/music 0750 xrs444 xrs444 -"
  ];
}
