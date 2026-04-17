# Summary: NixOS module for remote builds, configures builder hosts and SOPS secrets for distributed builds.
{
  config,
  pkgs,
  lib,
  minimalImage ? false,
  ...
}:
let
  buildHosts = [
    { name = "xsvr1"; maxJobs = 8; speedFactor = 4; } # Ryzen 7 7700 — primary builder
    { name = "xsvr2"; maxJobs = 6; speedFactor = 1; } # Atom C3758 — leave 2 cores for ZFS/k8s
    { name = "xsvr3"; maxJobs = 4; speedFactor = 2; } # i5-8500 — leave 2 cores for VMs/Samba
  ];
  isBuilder = lib.elem config.networking.hostName (map (b: b.name) buildHosts);

  mkBuildMachine = b: {
    hostName = "${b.name}.lan";
    sshUser = "builder";
    sshKey = "/root/.ssh/id_builder";
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maxJobs = b.maxJobs;
    speedFactor = b.speedFactor;
    supportedFeatures = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
  };
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
      # Don't build locally — delegate everything to the builder pool.
      # Without this, Nix uses local jobs first and never touches remote builders.
      settings = {
        max-jobs = 0;
        # Let builders fetch their own inputs from substituters directly, rather than
        # requiring the client to copy every dependency across the wire first.
        builders-use-substitutes = true;
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
      buildMachines = map mkBuildMachine buildHosts;
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
      # QEMU user-mode emulation requires syscalls (clone3, personality) that Nix's
      # default seccomp filter blocks. Disable the filter so sandboxed aarch64 builds
      # can succeed. Duplicated from nix.settings because Determinate Nix reads
      # nix.custom.conf instead of nix.conf for runtime settings.
      filter-syscalls = false
      system-features = nixos-test benchmark big-parallel kvm
    '';
  };

  # Deploy builder SSH key on all non-builder hosts
  sops.secrets.builder_private_key = lib.mkIf (!isBuilder) {
    sopsFile = ../../../secrets/builder-ssh-key.yaml;
    path = "/root/.ssh/id_builder";
    mode = "0600";
  };

  # SSH config so nixos-rebuild --build-host and nix distributed builds find the right key
  programs.ssh.extraConfig = lib.mkIf (!isBuilder) ''
    Host ${lib.concatStringsSep " " (map (b: "${b.name}.lan") buildHosts)}
      User builder
      IdentityFile /root/.ssh/id_builder
  '';
}
