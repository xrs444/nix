{ pkgs, config, username... }:
let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.thomas-local = {
    extraGroups =
      [
        "networkmanager"
        "wheel"
      ];
  };
}