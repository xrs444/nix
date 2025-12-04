# Raspberry Pi hardware configuration
# Suitable for Raspberry Pi 4 and later models
{
  lib,
  ...
}:
{
  # Raspberry Pi specific boot configuration
  boot = {
    loader = {
      grub.enable = lib.mkForce false;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;

      # Use the generic extlinux compatible loader for Raspberry Pi
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };

    # Enable hardware-specific features
    kernelParams = [
      "console=ttyS1,115200n8"
      "console=tty0"
    ];
  };

  # Power management for Raspberry Pi
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Enable hardware features
  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = lib.mkDefault true;
  };
}
