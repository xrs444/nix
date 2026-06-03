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

  # Create parent container datasets that syncoid cannot create automatically.
  # zpool-xsvr2-media/media must exist before receiving media/movies, media/tvshows, etc.
  systemd.services.syncoid-target-create-parents = {
    description = "Create parent container datasets for syncoid receive on xsvr2";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /run/current-system/sw/bin/zfs create -o mountpoint=/zfs/media zpool-xsvr2-media/media 2>/dev/null || true
    '';
  };
}
