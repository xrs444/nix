{
  inputs,
  outputs,
  stateVersion,
  ...
}:
{
  # Helper function for generating home-manager configs
  mkHome =
    {
      hostname,
      username ? "thomas-local",
      desktop ? null,
      platform ? "x86_64-linux",
    }:
    let
      isISO = builtins.substring 0 4 hostname == "iso-";
      isInstall = !isISO;
      isLaptop = hostname != "xhac-radio" && hostname != "xsvr1" && hostname != "xsvr2" && hostname != "xsvr3";
      isWorkstation = builtins.isString desktop;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${platform};
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          desktop
          hostname
          platform
          username
          stateVersion
          isInstall
          isLaptop
          isISO
          isWorkstation
          ;
      };
      modules = [ ../home ];
    };

  # Helper function for generating NixOS configs
  mkNixos =
    {
      hostname,
      username ? "thomas-local",
      desktop ? null,
      platform ? "x86_64-linux",
    }:
    let
      isISO = builtins.substring 0 4 hostname == "iso-";
      isInstall = !isISO;
      isLaptop = hostname != "xhac-radio" && hostname != "xsvr1" && hostname != "xsvr2" && hostname != "xsvr3";
      isWorkstation = builtins.isString desktop;
      tailNet = "corgi-squeaker.ts.net";
    in
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          outputs
          desktop
          hostname
          platform
          username
          stateVersion
          isInstall
          isISO
          isLaptop
          isWorkstation
          tailNet
          ;
      };
      modules = [ ../nixos ] ++ (if isISO then [
        (if (desktop == null)
          then inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          else inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
        )
      ] else []);
    };

  mkDarwin =
    {
      desktop ? "aqua",
      hostname,
      username ? "xrs444",
      platform ? "aarch64-darwin",
    }:
    let
      isISO = false;
      isInstall = true;
      isLaptop = true;
      isWorkstation = true;
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit
          inputs
          outputs
          desktop
          hostname
          platform
          username
          isInstall
          isISO
          isLaptop
          isWorkstation
          ;
      };
      modules = [ ../darwin ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
