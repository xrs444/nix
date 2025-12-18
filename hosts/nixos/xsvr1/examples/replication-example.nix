# Example ZFS Replication Configuration for xsvr1 (Source Host)
# Add this to hosts/nixos/xsvr1/default.nix or create a separate replication.nix file

{
  # Enable ZFS replication
  services.zfsReplication = {
    enable = true;
    
    # Specify which ZFS datasets to replicate from xsvr1 to xsvr2
    sourceDatasets = [
      # Example datasets - adjust these to match your actual ZFS datasets
      "zpool-xsvr1/data"
      "zpool-xsvr1/backups"
      # "zpool-xsvr1/media/movies"
      # "zpool-xsvr1/media/tvshows"
      # "zpool-xsvr1/vms"
      
      # To see your datasets, run: zfs list
    ];
    
    # Target host for replication
    # Can use hostname (if DNS works), IP address, or Tailscale hostname
    targetHost = "xsvr2";  # or "192.168.x.x" or "xsvr2.your-tailnet.ts.net"
    
    # Replication interval (systemd timer format)
    interval = "hourly";  # Options: hourly, daily, "*-*-* 02:00:00" (2 AM daily), etc.
  };
}

