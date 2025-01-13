{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  ...
}:
let
  # Declare which hosts have Tailscale enabled.
  installOn = [
    "xsvr1"
    "xsvr1"
    "xsvr3"
  ];
  tsExitNodes = [
    "xsvr3"
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {
  environment.systemPackages = with pkgs; lib.optionals isWorkstation [ trayscale ];

  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--operator=${username}"
    ] ++ lib.optional (lib.elem "${hostname}" tsExitNodes) "--advertise-exit-node";
    extraSetFlags = [
      "--operator=${username}"
    ] ++ lib.optional (lib.elem "${hostname}" tsExitNodes) "--advertise-exit-node";
    openFirewall = true;
    useRoutingFeatures = "both";
  };
}