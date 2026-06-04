# Automation user for Windmill — SSH executor for bare-metal NixOS jobs.
# Imported from nix/hosts/common/default.nix so every NixOS host gets it.
# The corresponding SSH private key lives in flux/apps/windmill/sealedsecret-windmill-ssh-key.yaml
{ lib, minimalImage, ... }:
{
  config = lib.mkIf (!minimalImage) {
    users.users.automation = {
      isNormalUser = true;
      description = "Windmill automation executor";
      home = "/var/lib/automation";
      createHome = true;
      shell = "/run/current-system/sw/bin/bash";
      openssh.authorizedKeys.keys = [
        # Public key for the windmill-ssh-key SealedSecret.
        # Replace AAAA... with the actual public key after running:
        #   ssh-keygen -t ed25519 -C "windmill@cluster" -f /tmp/windmill_ssh_key -N ""
        "ssh-ed25519 PLACEHOLDER_REPLACE_WITH_PUBKEY windmill@cluster"
      ];
    };

    security.sudo.extraRules = [
      {
        users = [ "automation" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
