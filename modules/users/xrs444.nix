{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.fish.enable = true;

  users.users.xrs444 = {
    isNormalUser = true;
    description = "Thomas Letherby (xrs444)";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
    ];
    createHome = true;
    home = "/home/xrs444";
    group = "xrs444";
  };

  users.groups.xrs444 = { };

  # Provide thomas-local SSH private key to xrs444 user
  sops.secrets."thomas-local-ssh-key" = {
    sopsFile = ../../secrets/thomas-local-ssh-key.yaml;
    key = "thomas_local_private_key";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
    path = "/home/xrs444/.ssh/thomas-local_key";
  };
}
