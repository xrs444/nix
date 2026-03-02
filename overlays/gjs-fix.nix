# overlays/gjs-fix.nix
# Workaround for gjs build issues in CI/remote builds
# The gjs build requires GTK 3 or 4 for tests, which may not be available
# in all build environments. This overlay disables GTK tests and the full
# test suite since gjs is well-tested upstream.
{ inputs }:
final: prev: {
  gjs = prev.gjs.overrideAttrs (oldAttrs: {
    doCheck = false;
    mesonFlags = (oldAttrs.mesonFlags or []) ++ [
      "-Dskip_gtk_tests=true"  # Skip GTK tests when GTK is not available
    ];
    # Keep the meta to explain why tests are disabled
    meta = oldAttrs.meta // {
      description = oldAttrs.meta.description or "" + " (tests disabled, GTK tests skipped)";
    };
  });
}
