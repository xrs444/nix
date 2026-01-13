# ZFS Replication Configuration for xsvr2 (Target Host)
# Receives replicated datasets from xsvr1
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

  # Configure sops secret to read the public key
  sops.secrets.syncoid-public-key = {
    sopsFile = ../../../secrets/syncoid-ssh-key.yaml;
    key = "syncoid_public_key";
  };

  # Enable ZFS replication as target
  services.zfsReplication = {
    enable = true;

    # SSH public key from sops secret
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqkKlOzh/vBBtSh39UpdadSng9CVf3e6WfbUE0bp4cg syncoid@xsvr1";
  };
}
