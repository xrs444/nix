{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Only xsvr1 and xsvr2 should run kanidm servers
  isKanidmServer = builtins.elem hostname ["xsvr1" "xsvr2"];
  
  # Only xsvr1 should run provisioning
  isProvisioningHost = hostname == "xsvr1";
  
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
in
lib.mkMerge [

  # Temporarily disable EVERYTHING Kanidm related
  # (lib.mkIf isProvisioningHost
  #   (import ./provision.nix { inherit config hostname lib pkgs; }))

  # (lib.mkIf isKanidmServer {
  #   services.kanidm.package = lib.mkForce pkgs.kanidmProvision;
  # })

  # (lib.mkIf isKanidmServer {
  #   services.kanidm = {
  #     enableServer = true;
  #     enableClient = false;
  #     enablePam = false;
  #     serverSettings = { ... };
  #   };
  # })

]