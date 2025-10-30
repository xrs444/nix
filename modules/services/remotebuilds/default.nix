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
  
  # Kanidm authenticated users allowed for remote builds
  kanidmBuildUsers = [
    "xrs444"
    "samantha"
    "greyson"
    "rowan"
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

  # Create builders group for local organization
  users.groups.builders = {};

  # Keep the legacy builder user for backwards compatibility
  users.users.builder = {
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
  security.sudo.extraRules = [
    # Legacy builder user - keep for backwards compatibility
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
    buildMachines = [
      # Legacy builder with SSH key authentication (for backwards compatibility)
      ({ 
        hostName = "xsvr1.lan"; 
        systems = [ "x86_64-linux" "aarch64-linux" ];
        protocol = "ssh-ng";
        maxJobs = 1;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        sshUser = "builder";
      } // lib.optionalAttrs (config.sops.secrets ? builder-ssh-key) {
        sshKey = config.sops.secrets.builder-ssh-key.path;
      })
    ] ++ 
    # Kanidm authenticated users - these will authenticate via external kanidm
    # SSH authentication will be handled by kanidm PAM integration
    (map (username: {
      hostName = "xsvr1.lan";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      sshUser = username;
      # No SSH key specified - will use kanidm authentication
      # Users need to be logged in with kanidm session or use SSH agent forwarding
    }) kanidmBuildUsers);
    
    distributedBuilds = true;
    settings.cores = 0;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

}