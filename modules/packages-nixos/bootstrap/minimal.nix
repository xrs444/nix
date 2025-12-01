# Minimal bootstrap module for ARM SD image
# Only enables networking and comin for initial provisioning

{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Only enable the absolute minimum for remote provisioning
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault true;

  # Enable SSH for debugging and remote builds
  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = lib.mkDefault "yes";
    PubkeyAuthentication = lib.mkDefault true;
    AuthorizedKeysFile = ".ssh/authorized_keys";
  };

  # builder user is now defined globally in modules/users/builder.nix

  # Enable comin for remote configuration
  services.comin.enable = true;
  services.comin.remotes = [
    {
      name = "origin";
      url = "https://github.com/xrs444/nix.git";
      branches.main.name = "main";
    }
  ];

  # Optionally, set a minimal hostname
  networking.hostName = lib.mkDefault "bootstrap-arm";

}
