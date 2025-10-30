{ config, lib, pkgs, username, ... }:
{
  users.users.${username} = lib.mkMerge [
    {
      isNormalUser = true;
      description = "${username} user";
      extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        # Add your SSH public keys here
        # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-key-here"
      ];
    }
    # Set initial password for thomas-local specifically
    (lib.mkIf (username == "thomas-local") {
      initialPassword = "changeme"; # Change this on first login
      # Or use hashedPassword for better security:
      # hashedPassword = "$6$rounds=100000$salt$your_hashed_password_here";
    })
  ];

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true; # Set to true if you want password prompts
}