{ pkgs, comin, system, lib, inputs, ... }:

{
  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/xrs444/nix.git";
      branches.main.name = "main";
      }];
  };
}
