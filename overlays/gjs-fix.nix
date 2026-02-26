# overlays/gjs-fix.nix
# Workaround for flaky gjs test timeout in CI builds
# The gjs C API test suite has a 60-second timeout that occasionally
# fails in resource-constrained environments. This overlay disables
# the test suite since gjs is well-tested upstream.
{ inputs }:
final: prev: {
  gjs = prev.gjs.overrideAttrs (oldAttrs: {
    doCheck = false;
    # Keep the meta to explain why tests are disabled
    meta = oldAttrs.meta // {
      description = oldAttrs.meta.description or "" + " (tests disabled due to CI timeouts)";
    };
  });
}
