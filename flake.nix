# Summary: Nix flake entrypoint for HomeProd, defines inputs, outputs, and configuration for NixOS and Darwin systems.
{
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Increase download buffer to avoid warnings during flake evaluation
    download-buffer-size = 134217728; # 128 MiB (default is 64 MiB)
  };
  description = "nixos configuration";
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix/63c423c"; # pin: last commit before opencode support (incompatible with home-manager 25.11)
    deploy-rs.url = "github:serokell/deploy-rs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    # Use main branch which has fix for nix-dev path issue
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";
    nixos-needsreboot.url = "https://codeberg.org/Mynacol/nixos-needsreboot/archive/main.tar.gz";
    nixos-needsreboot.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/*";
    nix-snapd.url = "https://flakehub.com/f/io12/nix-snapd/*";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
    quickemu.url = "https://flakehub.com/f/quickemu-project/quickemu/*";
    quickemu.inputs.nixpkgs.follows = "nixpkgs";
    quickgui.url = "https://flakehub.com/f/quickemu-project/quickgui/*";
    quickgui.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1.887.tar.gz";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      stateVersion = "25.05";

      # Import overlays as a list from a single file
      allOverlays = import ./overlays/all.nix { inherit inputs; };

      # Unified host definitions with role-based service assignments
      hosts = {
        xsvr1 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          generateManCache = true;
          roles = [
            "kvm"
            "samba"
            "zfs"
            "zfs-replication-source"
            "iprouting"
            "talos"
            "kanidm-primary"
            "letsencrypt-primary"
            "cockpit"
            "tailscale-package"
            "monitoring-server"
            "github-runner"
            "bind"
            "auto-upgrade"
          ];
        };
        xsvr2 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          generateManCache = true;
          roles = [
            "kvm"
            "samba"
            "zfs"
            "zfs-replication-target"
            "iprouting"
            "talos"
            "kanidm-replica"
            "letsencrypt-host"
            "tailscale-package"
            "monitoring-client"
            "bind"
            "auto-upgrade"
          ];
        };
        xsvr3 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          generateManCache = true;
          desktop = "xfce";
          roles = [
            "kvm"
            "samba"
            "iprouting"
            "talos"
            "letsencrypt-host"
            "tailscale-package"
            "monitoring-client"
            "auto-upgrade"
          ];
        };
        xlabmgmt = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          desktop = "gnome";
          enableHomeManager = false;
          roles = [
            "bind"
            "monitoring-client"
            "auto-upgrade"
          ];
        };
        xts1 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "iprouting"
            "letsencrypt-host"
            "tailscale-exit-node"
            "monitoring-client"
            "auto-upgrade"
          ];
        };
        xts2 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "letsencrypt-host"
            "tailscale-exit-node"
            "monitoring-client"
            "auto-upgrade"
          ];
        };
        xcomm1 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          desktop = "gnome";
          roles = [
            "letsencrypt-host"
            "monitoring-client"
            "auto-upgrade"
          ];
        };
        cmrpi1 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "adguard"
            "tailscale-package"
            "monitoring-client"
            "letsencrypt-host"
            "auto-upgrade"
          ];
        };
        xpbx1 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "asterisk"
            "monitoring-client"
            "letsencrypt-host"
            "auto-upgrade"
          ];
        };
        xlt1-t-vnixos = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          desktop = "gnome";
          roles = [ "auto-upgrade" ];
        };
        xlt1-t = {
          user = "xrs444";
          platform = "aarch64-darwin";
          type = "darwin";
          desktop = "aqua";
          enableHomeManager = true;
          roles = [ "tailscale-client" ];
        };
      };

      lib = import ./lib {
        inherit
          inputs
          outputs
          stateVersion
          hosts
          ;
        overlays = allOverlays;
      };

    in
    let
      allHomes = lib.mkAllHomes;
      # All NixOS configs except xsvr1, which self-deploys via nixos-rebuild in CI.
      remoteNixosConfigs = builtins.removeAttrs lib.mkAllNixosConfigs [ "xsvr1" ];
    in
    {
      homeConfigurations = allHomes;
      nixosConfigurations = lib.mkAllNixosConfigs // lib.forAllHosts lib.mkMinimalNixosConfig;
      darwinConfigurations = lib.mkAllDarwinConfigs;

      # deploy-rs deployment configuration.
      # xsvr1 is excluded — it runs nixos-rebuild switch locally in CI as the final step.
      deploy = {
        sshUser = "deploy";
        sshOpts = [
          "-4"                          # Force IPv4 — hosts like xcomm1 have many IPv6 addresses
          "-i"                          # that may be unreachable from xsvr1 (different subnet)
          "/run/secrets/deploy_private_key"
          "-o"
          "StrictHostKeyChecking=no"
          "-o"
          "UserKnownHostsFile=/dev/null"
          "-o"
          "ConnectTimeout=30"
        ];
        nodes = builtins.mapAttrs (hostname: cfg: {
          hostname = "${hostname}.lan";
          # fastConnection = false so deploy-rs passes --substitute-on-destination to nix copy.
          # Remote hosts fetch paths from http://xsvr1.lan (nixcache) where paths are signed
          # via nix.settings.secret-key-files, rather than receiving unsigned paths pushed
          # directly from the local nix store on xsvr1.
          fastConnection = false;
          profiles.system = {
            user = "root";
            path = inputs.deploy-rs.lib.${cfg.pkgs.stdenv.hostPlatform.system}.activate.nixos cfg;
            magicRollback = true;
            confirmTimeout = 60;
          };
        }) remoteNixosConfigs;
      };

      devShells = lib.forAllSystems (system: {
        default = inputs.nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with inputs.nixpkgs.legacyPackages.${system}; [
            nixfmt-rfc-style
            sops
            age
            git
          ];
        };
        qmk = import ./shells/qmk.nix { pkgs = inputs.nixpkgs.legacyPackages.${system}; };
      });

      checks = lib.forAllSystems (
        system:
        let
          validHomes = inputs.nixpkgs.lib.filterAttrs (
            _: cfg: cfg ? config && cfg.config ? activationPackage
          ) (inputs.nixpkgs.lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) allHomes);
          homeChecks = inputs.nixpkgs.lib.mapAttrs' (name: cfg: {
            name = name;
            value = cfg.config.activationPackage;
          }) validHomes;
          # Validate deploy-rs node configuration for the current system.
          deployChecks =
            if inputs.deploy-rs.lib ? ${system} then
              inputs.deploy-rs.lib.${system}.deployChecks self.deploy
            else
              { };
        in
        homeChecks // deployChecks
      );

      nixosModules = {
        asterisk = import ./modules/services/asterisk;
        cockpit = import ./modules/packages-nixos/cockpit;
        zfs = import ./modules/services/zfs;
        letsencrypt = import ./modules/services/letsencrypt;
        kanidm = import ./modules/services/kanidm;
        Samba = import ./modules/services/Samba;
        bind = import ./modules/services/bind;
        ffr = import ./modules/services/ffr;
        iprouting = import ./modules/services/iprouting;
        keepalived = import ./modules/services/keepalived;
        kvm = import ./modules/services/kvm;
        nfs = import ./modules/services/nfs;
        nixcache = import ./modules/services/nixcache;
        openssh = import ./modules/services/openssh;
        remotebuilds = import ./modules/services/remotebuilds;
        talos = import ./modules/services/talos;
        tailscale = import ./modules/services/tailscale;
        github-runner = import ./modules/services/github-runner;
      };
      formatter = lib.forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      overlays = {
        kanidm = import ./overlays/kanidm.nix { inherit inputs; };
        pkgs = import ./overlays/pkgs.nix { inherit inputs; };
        unstable = import ./overlays/unstable.nix { inherit inputs; };
      };
    };
}
