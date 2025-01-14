{ pkgs, comin, system, lib, inputs, ... }:

{
  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://gitlab.com/xrs444/nix.git";
      branches.main.name = "main";
      }];
  };
}
