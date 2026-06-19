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
    { name = "xsvr1"; maxJobs = 8; speedFactor = 4; aarch64 = true;  native = false; } # Ryzen 7 7700 — primary builder, binfmt confirmed working
    { name = "xsvr2"; maxJobs = 6; speedFactor = 1; aarch64 = false; native = false; } # Atom C3758 — binfmt unreliable under QEMU aarch64
    { name = "xsvr3"; maxJobs = 4; speedFactor = 2; aarch64 = false; native = false; } # i5-8500 — binfmt unreliable under QEMU aarch64
    { name = "xdt1-t"; maxJobs = 4; speedFactor = 4; aarch64 = false; native = false; } # Ryzen 7 9700X — gaming workstation, capped to avoid OOM
    { name = "xlt1-t-vnixos"; maxJobs = 4; speedFactor = 8; aarch64 = true; native = true; } # Native aarch64 VM — builds aarch64 without QEMU
    { name = "vocibuild"; maxJobs = 4; speedFactor = 6; aarch64 = true; native = true; } # Oracle Cloud A1 Flex (4 OCPUs, Neoverse N1) — native aarch64, no QEMU
  ];
  isBuilder = lib.elem config.networking.hostName (map (b: b.name) buildHosts);
  thisHost = lib.findFirst (b: b.name == config.networking.hostName) { native = false; } buildHosts;
  # Native builders (real aarch64 hardware/VMs) don't need binfmt/QEMU setup.
  isQemuBuilder = isBuilder && !thisHost.native;
  isNativeBuilder = isBuilder && thisHost.native;

  # vocibuild is on Oracle Cloud and reachable only via Tailscale MagicDNS (not .lan)
  buildHostname = b: if b.name == "vocibuild" then "vocibuild.corgi-squeaker.ts.net" else "${b.name}.lan";

  mkBuildMachine = b: {
    hostName = buildHostname b;
    sshUser = "builder";
    sshKey = "/root/.ssh/id_builder";
    # Native aarch64 builders (native=true) cannot build x86_64-linux — they have no binfmt
    # for the reverse direction. Only x86_64 hosts (native=false) get x86_64-linux in systems.
    # Adding x86_64-linux to a native aarch64 builder causes Nix to delegate x86_64 builds there,
    # which the remote correctly rejects, and Nix gives up without falling back to local.
    systems = lib.optionals (!b.native) [ "x86_64-linux" ] ++ lib.optionals b.aarch64 [ "aarch64-linux" ];
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
  # binfmt/QEMU: only for x86 hosts that emulate aarch64 via QEMU.
  # Native aarch64 builders (xlt1-t-vnixos) must NOT register a binfmt handler
  # for aarch64-linux — the kernel already executes it natively, and registering
  # a QEMU binfmt entry would intercept native binaries and run them under QEMU.
  boot.binfmt.emulatedSystems = lib.mkIf isQemuBuilder [
    "aarch64-linux"
  ];

  # Use fixBinary (F flag) so binfmt works inside Nix's sandboxed build environments.
  # The default P flag loses interpreter visibility when the sandbox creates a new mount
  # namespace; F pre-opens the interpreter fd at registration time, surviving namespace changes.
  # We must disable preserveArgvZero (P flag) because it conflicts with F - only F should be used.
  # Explicitly set the interpreter to the unwrapped QEMU binary to avoid the binfmt-P wrapper.
  # Wrap the whole attrset in mkIf so the submodule is not instantiated on non-builder hosts
  # (instantiating it without magicOrExtension causes a flake check evaluation error).
  boot.binfmt.registrations = lib.mkIf isQemuBuilder {
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

  # Deploy the deploy SSH private key on the builder so CI can push to target hosts.
  # Key lives at /run/secrets/deploy_private_key (default sops path) so the github
  # runner service can access it — ProtectHome=true blocks /home/builder/.ssh/.
  sops.secrets.deploy_private_key = lib.mkIf (isBuilder && !minimalImage) {
    sopsFile = ../../../secrets/deploy-ssh-key.yaml;
    owner = "builder";
    mode = "0600";
  };

  # Deploy the nix cache signing key on all builder hosts so the Nix daemon can
  # sign store paths after building them (nix.custom.conf: secret-key-files).
  # xsvr1 also gets this via the nixcache module; identical attrs merge cleanly.
  sops.secrets.nixcache_signing_key = lib.mkIf (isBuilder && !minimalImage) {
    sopsFile = ../../../secrets/nixcache-signing-key.yaml;
    key = "nixcache_signing_key";
    owner = "root";
    group = "builders";
    mode = "0440";
  };

  ## Combined nix configuration for both server and client
  nix = lib.mkMerge [
    # Settings common to all builder hosts (QEMU and native)
    (lib.mkIf isBuilder {
      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        # builder must be a trusted-user so it can build input-addressed derivations
        # sent by remote clients (nix-store --serve --write requires this privilege).
        trusted-users = [ "root" "builder" ];
        trusted-substituters = [ "file:///zfs/nixcache/cache" ];
      };
    })

    # QEMU builder: disable seccomp filter so sandboxed aarch64 builds can use
    # the syscalls (clone3, personality) that QEMU user-mode emulation requires.
    (lib.mkIf isQemuBuilder {
      settings.filter-syscalls = false;
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

    # xsvr1 is the CI runner — distribute builds to the other pool members while
    # continuing to build locally (max-jobs stays at default, not zeroed).
    # builders-use-substitutes lets remote machines pull inputs from substituters
    # directly rather than having xsvr1 copy every dependency over the wire first.
    (lib.mkIf (config.networking.hostName == "xsvr1") {
      distributedBuilds = true;
      settings.builders-use-substitutes = true;
      buildMachines = map mkBuildMachine (lib.filter (b: b.name != "xsvr1") buildHosts);
    })
  ];

  # Determinate Nix reads nix.custom.conf for runtime daemon settings (trusted-public-keys,
  # require-sigs, substituters, secret-key-files, filter-syscalls) and ignores nix.conf for
  # these settings. Both builder and client hosts need this file — without it, Determinate
  # Nix daemons have no xsvr1.lan-1 key trusted and reject signed paths from the binary cache.
  environment.etc."nix/nix.custom.conf" = lib.mkMerge [
    (lib.mkIf isQemuBuilder {
      text = ''
        # Custom Nix configuration for QEMU (x86) builder
        extra-platforms = aarch64-linux i686-linux
        extra-sandbox-paths = /run/binfmt ${pkgs.qemu}
        extra-trusted-substituters = file:///zfs/nixcache/cache
        extra-trusted-public-keys = xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
        require-sigs = false
        secret-key-files = /run/secrets/nixcache_signing_key
        filter-syscalls = false
        system-features = nixos-test benchmark big-parallel kvm
        trusted-users = root builder
      '';
    })
    (lib.mkIf isNativeBuilder {
      text = ''
        # Custom Nix configuration for native aarch64 builder
        extra-trusted-substituters = file:///zfs/nixcache/cache
        extra-trusted-public-keys = xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
        require-sigs = false
        secret-key-files = /run/secrets/nixcache_signing_key
        system-features = nixos-test benchmark big-parallel
        trusted-users = root builder
      '';
    })
    (lib.mkIf (!isBuilder) {
      text = ''
        # Determinate Nix ignores nix.conf for these settings — must be set here so the
        # daemon trusts xsvr1.lan-1 signatures and can substitute from the binary cache.
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI=
        substituters = http://xsvr1.lan https://cache.nixos.org
      '';
    })
  ];

  # Deploy builder SSH key on all non-builder hosts AND on xsvr1.
  # xsvr1 is a builder itself but also acts as the CI runner; it needs
  # id_builder to SSH to xsvr2/xsvr3/xdt1-t/xlt1-t-vnixos for distributed builds.
  sops.secrets.builder_private_key = lib.mkIf (!isBuilder || config.networking.hostName == "xsvr1") {
    sopsFile = ../../../secrets/builder-ssh-key.yaml;
    path = "/root/.ssh/id_builder";
    mode = "0600";
  };

  # SSH config so nixos-rebuild --build-host and nix distributed builds find the right key
  programs.ssh.extraConfig = lib.mkIf (!isBuilder || config.networking.hostName == "xsvr1") ''
    Host ${lib.concatStringsSep " " (map buildHostname buildHosts)}
      User builder
      IdentityFile /root/.ssh/id_builder

    # VM host — skip strict key checking since it's rebuilt frequently and its
    # host key changes after each nixos-install.
    Host xlt1-t-vnixos.lan xlt1-t-vnixos
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';

  # Known host keys for the build machines — prevents host key verification failures
  # after a client host is rebuilt fresh. Refresh with: ssh-keyscan -t ed25519 xsvr1 xsvr2 xsvr3
  programs.ssh.knownHosts = lib.mkIf (!isBuilder || config.networking.hostName == "xsvr1") {
    "xsvr1.lan" = {
      hostNames = [ "xsvr1.lan" "xsvr1" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPi6pOq7wjkPhbRs19XO1g9oud5JTq6O46KuEqVnKp09";
    };
    "xsvr2.lan" = {
      hostNames = [ "xsvr2.lan" "xsvr2" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILqV1INQL4xXMLnypfJQrB/R/i+xl4UR4dWdYTa8Ghae";
    };
    "xsvr3.lan" = {
      hostNames = [ "xsvr3.lan" "xsvr3" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3iLniG9niDNFxK3Z3INcwqc6N6R1+2v/PfD88klFAX";
    };
    "xdt1-t.lan" = {
      hostNames = [ "xdt1-t.lan" "xdt1-t" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDGFg8FIT5bB7OU3ihOBLvHlRs6hAxOSB3BopiV1O2J0";
    };
    # vocibuild is on Oracle Cloud, reachable via Tailscale MagicDNS.
    # After first boot: ssh-keyscan -t ed25519 vocibuild  →  paste result here.
    # "vocibuild" = {
    #   hostNames = [ "vocibuild" ];
    #   publicKey = "ssh-ed25519 AAAA...";
    # };
  };
}
