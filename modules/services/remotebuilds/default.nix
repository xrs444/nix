{ config, pkgs, lib, ... }:
let
  builder = [ "xsvr1" ];
  kanidmBuildUsers = [ "user1" "user2" ]; # Replace with your actual Kanidm build user names
in
{
  # Import SOPS secrets (not needed for clients, only for builder)

  ## Server configuration
  boot.binfmt.emulatedSystems = lib.mkIf (lib.elem config.networking.hostName builder) [ "aarch64-linux" ];

  # Create builders group for local organization
  users.groups.builders = lib.mkIf (lib.elem config.networking.hostName builder) {};

  # Keep the legacy builder user for backwards compatibility
  users.users.builder = lib.mkIf (lib.elem config.networking.hostName builder) {
    isNormalUser = true;
    home = "/home/builder";
    createHome = true;
    shell = pkgs.bash;
    extraGroups = [ "builders" ];
    openssh.authorizedKeys.keys = [
      # Add the public key content here
      (builtins.readFile ../../../secrets/builder_key.pub)
    ];
  };

  # Additional sudo rules specific to build server (supplement the common kanidm rules)
  security.sudo.extraRules = (
    lib.optional (lib.elem config.networking.hostName builder) {
      users = [ "builder" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ) ++ (
    map (username: {
      users = [ username ];
      commands = [
        {
          command = "/nix/store/*/bin/nix";
          options = [ "NOPASSWD" ];
        }
      ];
    }) kanidmBuildUsers
  );



  ## Combined nix configuration for both server and client
  nix = lib.mkMerge [
    # Server-specific settings
    (lib.mkIf (lib.elem config.networking.hostName builder) {
      settings = {
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        trusted-users = lib.mkBefore (kanidmBuildUsers ++ [ "builder" ]);
      };
    })

    # No client-specific settings needed; xsvr1 is the only build server
  ];
}