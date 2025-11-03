{ inputs, outputs, stateVersion, hostUsers ? {} }:

let
  inherit (inputs) nixpkgs home-manager nix-darwin;
  
  # Helper function to determine platform and directory for a host
  getHostInfo = hostname: 
    let
      # Check if host exists in different platform directories
      nixosArmPath = ../hosts/nixos-arm/${hostname};
      darwinPath = ../hosts/darwin/${hostname};
    in
    if builtins.pathExists nixosArmPath then 
      { platform = "aarch64-linux"; dir = "nixos-arm"; }
    else if builtins.pathExists darwinPath then 
      { platform = "aarch64-darwin"; dir = "darwin"; }
    else 
      { platform = "x86_64-linux"; dir = "nixos"; };
  
  # Helper function to create Home Manager configurations
  mkHome = { hostname, username ? null, platform ? null, system ? null }: 
    let
      # Use provided username, fallback to host mapping, then fallback to default
      defaultUser = if username != null then username 
                   else if hostUsers ? ${hostname} then hostUsers.${hostname}
                   else "thomas-local";
      # Use provided platform, or auto-detect from host directory structure
      defaultPlatform = if platform != null then platform
                       else (getHostInfo hostname).platform;
      usedSystem = if system != null then system else defaultPlatform;
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${usedSystem};
      extraSpecialArgs = { 
        inherit inputs outputs stateVersion hostname;
        platform = defaultPlatform;
        username = defaultUser;
        desktop = null;  # Add desktop parameter for home-manager
      };
      modules = [
        ../homemanager
        ../homemanager/users/${defaultUser}
      ];
    };
in
{
  # Helper function to generate all home configurations from hostUsers mapping
  mkAllHomes = nixpkgs.lib.forAllSystems (system:
    nixpkgs.lib.mapAttrs' (hostname: username: {
      name = "${username}@${hostname}";
      value = mkHome { inherit hostname system; };
    }) hostUsers
  );

  # Helper function to generate system configurations for all supported architectures
  forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  # Helper function to create NixOS configurations
  mkNixos = { hostname, desktop ? null, platform ? null, username ? null, isInstall ? true, isWorkstation ? false }: 
    let
      # Use provided username, fallback to host mapping, then fallback to default
      defaultUser = if username != null then username 
                   else if hostUsers ? ${hostname} then hostUsers.${hostname}
                   else "thomas-local";
      # Auto-detect platform and directory from host directory structure
      hostInfo = if platform != null then 
        { platform = platform; dir = if platform == "aarch64-linux" then "nixos-arm" else "nixos"; }
      else 
        getHostInfo hostname;
      defaultPlatform = hostInfo.platform;
      platformDir = hostInfo.dir;
    in
    nixpkgs.lib.nixosSystem {
      system = defaultPlatform;
      modules = [
        # Apply overlays to nixpkgs
        {
          nixpkgs.overlays = builtins.attrValues outputs.overlays;
          nixpkgs.config.allowUnfree = true;
        }
        ../hosts/${platformDir}
        ../hosts/${platformDir}/${hostname}
      ] ++ nixpkgs.lib.optionals (desktop != null) [
        ../hosts/${platformDir}/${hostname}/desktop.nix
      ];
      specialArgs = {
        inherit inputs outputs stateVersion hostname desktop isInstall isWorkstation;
        pkgs = nixpkgs.legacyPackages.${defaultPlatform};
        platform = defaultPlatform;
        username = defaultUser;
      };
    };

  # Helper function to create Darwin configurations
  mkDarwin = { hostname, username ? null, desktop ? null, platform ? null }: 
    let
      # Use provided username, fallback to host mapping, then fallback to default
      defaultUser = if username != null then username 
                   else if hostUsers ? ${hostname} then hostUsers.${hostname}
                   else "thomas-local";
      # Auto-detect platform from host directory structure  
      defaultPlatform = if platform != null then platform
                       else (getHostInfo hostname).platform;
    in
    nix-darwin.lib.darwinSystem {
      system = defaultPlatform;
      specialArgs = { 
        inherit inputs outputs stateVersion hostname desktop;
        platform = defaultPlatform;
        username = defaultUser;
      };
      modules = [
        # Apply overlays to nixpkgs for Darwin too
        {
          nixpkgs.overlays = builtins.attrValues outputs.overlays;
          nixpkgs.config.allowUnfree = true;
        }
        ../hosts/darwin
        ../hosts/darwin/${hostname}
      ];
    };
}