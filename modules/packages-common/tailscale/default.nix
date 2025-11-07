{ config, hostname, isWorkstation, lib, pkgs, username, platform, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  tsClients = [ "xsvr1" "xsvr2" "xsvr3" "xtl1-t-nixos" "xlt1-t" ];
  enableTailscale = lib.elem "${hostname}" tsClients;
in
{
  config = lib.mkIf enableTailscale {
     environment.systemPackages = with pkgs; [ tailscale ];
  };
}
