{ pkgs, config, username... }:
let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.txdash1 = {
    extraGroups =
      [
      ];
  };
}