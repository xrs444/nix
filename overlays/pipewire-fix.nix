# overlays/pipewire-fix.nix
# Disables roc-toolkit support in pipewire to avoid i686-linux dependency
{ inputs }:
final: prev: {
  pipewire = prev.pipewire.override {
    # Disable roc-toolkit support which requires i686-linux
    # roc-toolkit pulls in scons which requires python3.13-distutils for i686-linux
    # This is not available on our builders and not needed for our use case
    rocSupport = false;
  };
}
