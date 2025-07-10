{
  lib,
  pkgs,
  username,
  platform,
  ...
}:
let
  installFor = [ "xrs444" ];
in
lib.mkIf (lib.elem username installFor && platform == "aarch64-linux") {
  environment.systemPackages = with pkgs; [
    utm
  ];

  homebrew = {
    casks = [ "balenaetcher" ];
  };
}
