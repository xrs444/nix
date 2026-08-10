{ pkgs, ... }:
{
  # Standard GNOME desktop.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.libinput.enable = true;

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  environment.systemPackages = with pkgs; [
    file-roller # Archive manager
    gparted # Partition editor
    prismlauncher # Minecraft launcher
  ];
}
