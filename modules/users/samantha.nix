{ pkgs, ... }:

{
  users.users.samantha = {
    isNormalUser = true;
    description = "Samantha";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.bashInteractive;
    initialPassword = "changeme";
    createHome = true;
    home = "/home/samantha";
    group = "samantha";
  };

  users.groups.samantha = { };
}
