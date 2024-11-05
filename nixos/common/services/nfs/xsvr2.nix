_: {
  services.nfs.server.exports = ''
    /data  172.16.0.0/12 (rw,fsid=0,no_subtree_check)
  '';
}