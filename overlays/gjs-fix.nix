# overlays/gjs-fix.nix
# Workaround for gjs build issues in CI/remote builds.
# The upstream gjs-1.86.0 build calls wrapProgram on
# $installedTests/libexec/installed-tests/gjs/minijasmine, but that file
# is installed without the executable bit, causing the build to die with
# "Cannot wrap ... because it is not an executable file."
# Fix: chmod +x in preFixup — wrapProgram runs via an implicit fixup hook
# (make-shell-wrapper-hook) that fires before postFixup, so preFixup is needed.
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
    # wrapProgram on minijasmine is called by an implicit fixup hook (make-shell-wrapper-hook)
    # which runs BEFORE postFixup. chmod +x must be in preFixup to run first.
    preFixup = (oldAttrs.preFixup or "") + ''
      if [ -f "$installedTests/libexec/installed-tests/gjs/minijasmine" ]; then
        chmod +x "$installedTests/libexec/installed-tests/gjs/minijasmine"
      fi
    '';
    postFixup = (oldAttrs.postFixup or "") + ''
      rm -rf "$installedTests/libexec"
    '';
  });
}
