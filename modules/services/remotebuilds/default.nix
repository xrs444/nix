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
  # Use emulatedSystems to get the base binfmt registration (magic bytes, etc),
  # then override specific settings below for sandbox compatibility.
  boot.binfmt.emulatedSystems = lib.mkIf (lib.elem config.networking.hostName builder) [
    "aarch64-linux"
  ];

  # Use fixBinary (F flag) so binfmt works inside Nix's sandboxed build environments.
  # The default P flag loses interpreter visibility when the sandbox creates a new mount
  # namespace; F pre-opens the interpreter fd at registration time, surviving namespace changes.
  # We must disable preserveArgvZero (P flag) because it conflicts with F - only F should be used.
  # Explicitly set the interpreter to the unwrapped QEMU binary to avoid the binfmt-P wrapper.
  # Wrap the whole attrset in mkIf so the submodule is not instantiated on non-builder hosts
  # (instantiating it without magicOrExtension causes a flake check evaluation error).
  boot.binfmt.registrations = lib.mkIf (lib.elem config.networking.hostName builder) {
    "aarch64-linux" = {
      fixBinary = lib.mkForce true;
      preserveArgvZero = lib.mkForce false;
      wrapInterpreterInShell = lib.mkForce false;
      interpreter = lib.mkForce "${pkgs.qemu}/bin/qemu-aarch64";
    };
  };

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
        # Use trusted-substituters instead of trusted-users for better security
        # This allows the cache to be used without granting full trusted-user privileges
        trusted-substituters = [ "file:///zfs/nixcache/cache" ];
        # QEMU user-mode emulation (used for aarch64 cross-builds via binfmt) requires
        # syscalls that Nix's default seccomp filter blocks (e.g. clone3, personality).
        # Disable filter-syscalls so sandboxed aarch64 builds can succeed on this builder.
        filter-syscalls = false;
      };
    })

    # Client configuration: deploy builder SSH key and SSH config for all non-builder hosts
    (lib.mkIf (!lib.elem config.networking.hostName builder) {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "xsvr1.lan";
          sshUser = "builder";
          sshKey = "/root/.ssh/id_builder";
          systems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          maxJobs = 8;
          speedFactor = 2;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
        }
      ];
    })
  ];

  # Determinate Nix uses /etc/nix/nix.custom.conf for user settings
  # Write extra-platforms directly to nix.custom.conf so Determinate Nix picks it up
  # Note: trusted-substituters is set in nix.settings above instead of trusted-users for security
  environment.etc."nix/nix.custom.conf" = lib.mkIf (lib.elem config.networking.hostName builder) {
    text = ''
      # Custom Nix configuration for builder
      extra-platforms = aarch64-linux i686-linux
      extra-sandbox-paths = /run/binfmt ${pkgs.qemu}
    '';
  };

  # Deploy builder SSH key on all non-builder hosts
  sops.secrets.builder_private_key = lib.mkIf (!lib.elem config.networking.hostName builder) {
    sopsFile = ../../../secrets/builder-ssh-key.yaml;
    path = "/root/.ssh/id_builder";
    mode = "0600";
  };

  # SSH config so nixos-rebuild --build-host finds the right key
  programs.ssh.extraConfig = lib.mkIf (!lib.elem config.networking.hostName builder) ''
    Host xsvr1.lan
      User builder
      IdentityFile /root/.ssh/id_builder
  '';
}
