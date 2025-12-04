{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.builder = {
    isNormalUser = true;
    description = "Remote Nix builder user";
    shell = lib.mkForce pkgs.bashInteractive;
    createHome = true;
    home = "/home/builder";
    group = "builder";
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../secrets/builder_key.pub)
    ];
    ignoreShellProgramCheck = true;
  };

  users.groups.builder = { };
}
