# overlays/gjs-fix.nix
# Workaround for gjs build issues in CI/remote builds.
# The upstream gjs-1.86.0 postFixup calls wrapProgram on
# $installedTests/libexec/installed-tests/gjs/minijasmine, but that file
# is installed without the executable bit, causing the build to die with
# "Cannot wrap ... because it is not an executable file."
# Fix: chmod +x in postFixup before the upstream wrapProgram runs.
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
    # The upstream postFixup calls wrapProgram on minijasmine, but the file is
    # installed without the executable bit. chmod +x it first so wrapProgram
    # succeeds. Also clear installedTests/libexec afterward so strip doesn't
    # choke on any non-ELF leftover files.
    postFixup = ''
      if [ -f "$installedTests/libexec/installed-tests/gjs/minijasmine" ]; then
        chmod +x "$installedTests/libexec/installed-tests/gjs/minijasmine"
      fi
    '' + (oldAttrs.postFixup or "") + ''
      rm -rf "$installedTests/libexec"
    '';
  });
}
