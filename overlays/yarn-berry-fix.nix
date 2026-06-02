# overlays/yarn-berry-fix.nix
# Work around kernel io_uring deadlock (confirmed in nixpkgs #353709) that
# causes yarn/Node.js builds to hang indefinitely with near-zero CPU usage.
# Affects kernel 6.6.57+ and 6.12.x (via libuv's io_uring backend).
# UV_USE_IO_URING=0 forces libuv to fall back to epoll for all I/O.
{ inputs }:
final: prev: {
  yarn-berry-offline = prev.yarn-berry-offline.overrideAttrs (old: {
    preBuild = (old.preBuild or "") + "\nexport UV_USE_IO_URING=0\n";
  });
  yarn-berry = prev.yarn-berry.overrideAttrs (old: {
    preBuild = (old.preBuild or "") + "\nexport UV_USE_IO_URING=0\n";
  });
}
