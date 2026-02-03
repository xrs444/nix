# Summary: NixOS module to enable Determinate Nix on hosts
{ config, lib, inputs, ... }:

let
  cfg = config.services.determinate-nix;
in
{
  options.services.determinate-nix = {
    enable = lib.mkEnableOption "Determinate Nix - enterprise-grade Nix distribution";
  };

  config = lib.mkIf cfg.enable {
    # Import Determinate Nix module
    imports = [ inputs.determinate.nixosModules.default ];

    # Enable Determinate Nix
    services.determinate-nix.enable = true;
  };
}
