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

  # Add builder user for remote builds
  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # xsvr1 builder_key.pub
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJlAKBOsKmCa0yY0FKOD3dr8uEq4elGokEpWZYVMVkp builder@remote-builds"
    ];
    # Optionally add to wheel for sudo if needed:
    # extraGroups = [ "wheel" ];
  };

  # Enable comin for remote configuration
  services.comin.enable = true;
  services.comin.remotes = [
    {
      name = "origin";
      url = "https://github.com/xrs444/nix.git";
      branches.main.name = "main";
    }
  ];

  # Do not disable all services; allow comin and others to run
  users.users.root.password = ""; # No password for root (use SSH keys)

  # Optionally, set a minimal hostname
  networking.hostName = lib.mkDefault "bootstrap-arm";

}
