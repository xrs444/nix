{
  hostname,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  outputs = { self, nixpkgs, comin }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          comin.nixosModules.comin
          ({...}: {
            services.comin = {
              enable = true;
              remotes = [{
                name = "origin";
                url = "https://github.com/xrs444/nix.git";
                branches.main.name = "main";
              }];
            };
          })
        ];
      };
    };
  };
}