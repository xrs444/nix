{ config, pkgs, ... }:
{
  # common/hardware-amd.nix enables amdgpu + kvm-amd via mkDefault; keep
  # those by not using mkForce here. nvme is added in default.nix so the
  # lists merge cleanly rather than one overriding the other.
  boot.initrd.kernelModules = [ "kvm-amd" "amdgpu" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver   # VA-API via NVDEC/NVENC for hardware video decode/encode
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;   # required for Wayland / niri
    open = true;                 # recommended for Blackwell (RTX 5000 series)
    nvidiaSettings = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";              # nvidia-vaapi-driver: use direct backend on Wayland
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
