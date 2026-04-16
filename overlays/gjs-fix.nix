# overlays/gjs-fix.nix
# Workaround for gjs build issues in CI/remote builds
# The gjs build requires GTK 3 or 4 for tests, which may not be available
# in all build environments. This overlay disables GTK tests and the full
# test suite since gjs is well-tested upstream.
# Also disables installed tests which try to generate introspection files
# that fail with Python 3.13+ distutils errors.
{ inputs }:
final: prev: {
  gjs = prev.gjs.overrideAttrs (oldAttrs: {
    doCheck = false;
    mesonFlags = (oldAttrs.mesonFlags or []) ++ [
      "-Dskip_gtk_tests=true"      # Skip GTK tests when GTK is not available
      "-Dinstalled_tests=false"    # Disable installed tests (avoid introspection build)
    ];
    # With installed_tests=false, $installedTests/share/glib-2.0 is never created.
    # The upstream postInstall unconditionally tries to mv it, which fails.
    # Make the mv conditional so the build succeeds without installed tests.
    postInstall = ''
      installedTestsSchemaDatadir="$installedTests/share/gsettings-schemas/gjs-${oldAttrs.version}"
      mkdir -p "$installedTestsSchemaDatadir"
      if [ -d "$installedTests/share/glib-2.0" ]; then
        mv "$installedTests/share/glib-2.0" "$installedTestsSchemaDatadir"
      fi
    '';
  });
}
