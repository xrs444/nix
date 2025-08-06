{ config, pkgs, lib, ... }:

let
  builder= [
    "xsvr1"
  ];
  buildclient = [
    "xts1"
    "xts2"
    "xdash1"
  ];
in

{
  # Import SOPS secrets
  sops.secrets.builder-ssh-key = lib.mkIf (lib.elem config.networking.hostName buildclient) {
    sopsFile = ../../../secrets/builder-ssh-key.yaml;
    owner = "root";
    group = "root";
    mode = "0600";
  };
} //

lib.mkIf (lib.elem config.networking.hostName builder) {

## Server

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    createHome = true;
    shell = pkgs.bash;
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [
      # Add the public key content here
      (builtins.readFile ../../../secrets/builder_key.pub)
    ];
  };

  # Explicitly block su for builder user
  security.sudo.extraRules = [
    {
      users = [ "builder" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" "!su" ];
        }
      ];
    }
  ];

} //

lib.mkIf (lib.elem config.networking.hostName buildclient) {

## Client

  nix = {
    buildMachines = [ ({ 
      hostName = "xsvr1.lan"; 
      systems = [ "x86_64-linux" "aarch64-linux" ];
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      sshUser = "builder";
    } // lib.optionalAttrs (config.sops.secrets ? builder-ssh-key) {
      sshKey = config.sops.secrets.builder-ssh-key.path;
    }) ];
    distributedBuilds = true;
    buildCores = 0;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

}