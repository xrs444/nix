{
  lib,
  pkgs,
  username,
  ...
}:
let
  installFor = [ "xrs444" ];
in
lib.mkIf (lib.elem username installFor) {
  environment.systemPackages = with pkgs; [
    utm
  ];

  homebrew = {
    casks = [ "balenaetcher" ];
  };
}
