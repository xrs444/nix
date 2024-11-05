_: {
  services.nfs.server.exports = ''
    /zfs/containers 172.20.1.0/24 (rw,fsid=0,no_subtree_check)
    /zfs/clientbackup 172.16.0.0/12 (rw,fsid=0,no_subtree_check)
  '';
    options = [ "nfsvers=4.2" ];
}
