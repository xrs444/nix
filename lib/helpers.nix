{
  self,
  inputs,
  outputs,
  stateVersion,
  username,
  ...
}:
{
  # Helper function for generating home-manager configs
  mkHome =
    {
      hostname,
      user ? username,
      desktop ? null,
      system ? "x86_64-linux",
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.unstable.legacyPackages.${system};
      extraSpecialArgs = {
        inherit
          self
          inputs
          outputs
          stateVersion
          hostname
          desktop
          ;
        username = user;
      };
    };

  # Helper function for generating host configs
  mkHost =
    {
      hostname,
      desktop ? null,
      pkgsInput ? inputs.unstable,
      system ? "x86_64-linux",
    }:
    pkgsInput.lib.nixosSystem {
      specialArgs = {
        inherit
          self
          inputs
          outputs
          stateVersion
          username
          hostname
          desktop
          ;
      };
      modules = [
        ../nixos
      ];
    };

  mkSystemManager =
    {
      system ? "x86_64-linux",
    }:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [
        inputs.nix-system-graphics.systemModules.default
        ({
          config = {
            nixpkgs.hostPlatform = system;
            system-manager.allowAnyDistro = true;
#            system-graphics.enable = true;
          };
        })
      ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
