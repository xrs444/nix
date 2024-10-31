{ pkgs, config, ... }:
let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.thomas-local = {
    isNormalUser = true;
    extraGroups =
      [
        "networkmanager"
        "users"
        "wheel"
      ]

    packages = [ pkgs.home-manager ];
  };
}