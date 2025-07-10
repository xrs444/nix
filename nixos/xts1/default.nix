{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ./disks.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.05";

  assertions = [
    {
      assertion = true;
      message = "platform for ${hostname} is ${platform}";
    }
    {
    assertion = pkgs != null;
    message = "pkgs is not set!";
    }  
    {
    assertion = platform != null;
    message = "platform is not set!";
    }
  ];
}