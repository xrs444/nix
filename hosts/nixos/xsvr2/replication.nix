# ZFS Replication Configuration for xsvr2 (Target Host)
# Receives replicated datasets from xsvr1
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

  # Enable ZFS replication as target
  services.zfsReplication = {
    enable = true;
    
    # SSH public key from xsvr1's syncoid user will be added after first deployment
    # Get it by running on xsvr1: sudo cat /var/lib/syncoid/.ssh/id_ed25519.pub
    sshPublicKey = null;  # Will be updated after xsvr1 deployment
  };
}
