# Summary: NixOS module for remote builds, configures builder hosts and SOPS secrets for distributed builds.
{
  config,
  pkgs,
  lib,
  minimalImage ? false,
  ...
}:
let
  builder = [ "xsvr1" ];
  isBuilder = lib.elem config.networking.hostName builder;
in
{
  # Import SOPS secrets (not needed for clients, only for builder)

  ## Server configuration
  # Use emulatedSystems to get the base binfmt registration (magic bytes, etc),
  # then override specific settings below for sandbox compatibility.
  boot.binfmt.emulatedSystems = lib.mkIf isBuilder [
    "aarch64-linux"
  ];

  # Use fixBinary (F flag) so binfmt works inside Nix's sandboxed build environments.
  # The default P flag loses interpreter visibility when the sandbox creates a new mount
  # namespace; F pre-opens the interpreter fd at registration time, surviving namespace changes.
  # We must disable preserveArgvZero (P flag) because it conflicts with F - only F should be used.
  # Explicitly set the interpreter to the unwrapped QEMU binary to avoid the binfmt-P wrapper.
  # Wrap the whole attrset in mkIf so the submodule is not instantiated on non-builder hosts
  # (instantiating it without magicOrExtension causes a flake check evaluation error).
  boot.binfmt.registrations = lib.mkIf isBuilder {
    "aarch64-linux" = {
      fixBinary = lib.mkForce true;
      preserveArgvZero = lib.mkForce false;
      wrapInterpreterInShell = lib.mkForce false;
      interpreter = lib.mkForce "${pkgs.qemu}/bin/qemu-aarch64";
    };
  };

  # Create builders group for local organization
  users.groups.builders = lib.mkIf isBuilder { };

  # The builder user is now defined globally in modules/users/builder.nix

  # Additional sudo rules specific to build server
  security.sudo.extraRules = lib.optional isBuilder {
    users = [ "builder" ];
    commands = [
      {
        command = "ALL";
        options = [ "NOPASSWD" ];
      }
    ];
  };

  # Deploy the deploy SSH private key on the builder so CI can push to target hosts
  sops.secrets.deploy_private_key = lib.mkIf (isBuilder && !minimalImage) {
    sopsFile = ../../../secrets/deploy-ssh-key.yaml;
    path = "/home/builder/.ssh/id_deploy";
    owner = "builder";
    mode = "0600";
  };

  ## Combined nix configuration for both server and client
  nix = lib.mkMerge [
    # Server-specific settings
    (lib.mkIf isBuilder {
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
    (lib.mkIf (!isBuilder) {
      distributedBuilds = true;
      # Don't build locally — delegate everything to xsvr1.
      # Without this, Nix uses local jobs first and never touches the remote builder.
      settings = {
        max-jobs = 0;
        # Use xsvr1's binary cache as primary substituter before falling back to cache.nixos.org.
        # Paths built by CI on xsvr1 (including ARM cross-compiled configs) are pre-populated
        # here, so deploy-rs activations require no local building at all.
        substituters = [
          "http://xsvr1.lan"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          # Run: sudo cat /run/secrets/nixcache_signing_key | nix key convert-secret-to-public
          # then paste the result here.
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI="
        ];
      };
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
  # Write extra-platforms and trusted-substituters directly to nix.custom.conf so Determinate Nix picks it up
  # Note: Using extra-trusted-substituters instead of trusted-users for better security
  environment.etc."nix/nix.custom.conf" = lib.mkIf isBuilder {
    text = ''
      # Custom Nix configuration for builder
      extra-platforms = aarch64-linux i686-linux
      extra-sandbox-paths = /run/binfmt ${pkgs.qemu}
      extra-trusted-substituters = file:///zfs/nixcache/cache
      extra-trusted-public-keys =
    '';
  };

  # Deploy builder SSH key on all non-builder hosts
  sops.secrets.builder_private_key = lib.mkIf (!isBuilder) {
    sopsFile = ../../../secrets/builder-ssh-key.yaml;
    path = "/root/.ssh/id_builder";
    mode = "0600";
  };

  # SSH config so nixos-rebuild --build-host finds the right key
  programs.ssh.extraConfig = lib.mkIf (!isBuilder) ''
    Host xsvr1.lan
      User builder
      IdentityFile /root/.ssh/id_builder
  '';
}
