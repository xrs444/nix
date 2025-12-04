# Summary: NixOS module for remote builds, configures builder hosts and SOPS secrets for distributed builds.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  builder = [ "xsvr1" ];
in
{
  # Import SOPS secrets (not needed for clients, only for builder)

  ## Server configuration
  boot.binfmt.emulatedSystems = lib.mkIf (lib.elem config.networking.hostName builder) [
    "aarch64-linux"
  ];

  # Create builders group for local organization
  users.groups.builders = lib.mkIf (lib.elem config.networking.hostName builder) { };

  # The builder user is now defined globally in modules/users/builder.nix

  # Additional sudo rules specific to build server
  security.sudo.extraRules = lib.optional (lib.elem config.networking.hostName builder) {
    users = [ "builder" ];
    commands = [
      {
        command = "ALL";
        options = [ "NOPASSWD" ];
      }
    ];
  };

  ## Combined nix configuration for both server and client
  nix = lib.mkMerge [
    # Server-specific settings
    (lib.mkIf (lib.elem config.networking.hostName builder) {
      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        trusted-users = [ "builder" ];
      };
    })

    # No client-specific settings needed; xsvr1 is the only build server
  ];
}
