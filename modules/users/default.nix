{ config, lib, pkgs, ... }:

lib.mkMerge [
  # Import user configs
  (import ./thomas-local.nix { inherit config lib pkgs; })
  (import ./acme.nix { inherit config lib pkgs; })

  # Global/non-user-specific settings
  {
    # Enable sudo for wheel group
    security.sudo.wheelNeedsPassword = true;

    # Enable SSH service
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        PubkeyAuthentication = true;
      };
    };

    # Ensure bash is available and properly configured
    environment.systemPackages = with pkgs; [ bashInteractive ];
    environment.shells = with pkgs; [ bashInteractive ];
    users.defaultUserShell = pkgs.bashInteractive;
  }
]