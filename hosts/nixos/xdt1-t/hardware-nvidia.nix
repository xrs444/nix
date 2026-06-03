{ config, lib, pkgs, ... }:
{
  # common/hardware-amd.nix enables amdgpu via mkDefault — override it since
  # the GPU is NVIDIA. Keep kvm-amd for the AMD CPU's virtualisation support.
  boot.initrd.kernelModules = lib.mkForce [ "kvm-amd" ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland / niri
    open = false;              # switch to true if stable causes issues on Turing+
    nvidiaSettings = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland env vars expected by NVIDIA + Wayland compositors
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1"; # some NVIDIA setups need this
  };
}
