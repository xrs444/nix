# Example ZFS Replication Configuration for xsvr2 (Target Host)
# Add this to hosts/nixos/xsvr2/default.nix

{
  # Enable ZFS replication as target
  services.zfsReplication = {
    enable = true;
    
    # IMPORTANT: After deploying xsvr1, get the public SSH key by running:
    #   ssh thomas-local@xsvr1
    #   sudo cat /var/lib/syncoid/.ssh/id_ed25519.pub
    #
    # Then paste that public key here:
    sshPublicKey = "ssh-ed25519 AAAAC3Nza... syncoid@xsvr1";  # <-- Replace with actual key from xsvr1
  };
}

# Deployment steps:
# 1. Deploy xsvr1 first with replication source configuration
# 2. Get the SSH public key from xsvr1 (command above)
# 3. Add the public key to this configuration
# 4. Deploy xsvr2
# 5. Test replication: ssh thomas-local@xsvr1; sudo systemctl start zfs-replication

