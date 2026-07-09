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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZl+FgtqBk0oqWhbDaDLm8wZ85n/9IR39YhqhO/4i2j windmill@cluster"
      ];
    };

    # No NOPASSWD sudo here on purpose: audited 2026-07-08 (Windmill MCP listScripts/
    # listFlows across the whole xrs444 workspace, plus a grep of flux/windmill-workspace)
    # and found zero scripts or flows that SSH in as this user — f/sre/alert-ingest is the
    # only flow that will eventually need runbook execution here, and it's explicitly
    # stubbed ("No autonomous execution... wires in Phase C"). Add a scoped
    # security.sudo.extraRules entry with the specific commands a runbook needs once one
    # actually exists — don't restore NOPASSWD ALL as a placeholder for future use.
  };
}
