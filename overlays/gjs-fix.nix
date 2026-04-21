# overlays/gjs-fix.nix
# Workaround for gjs build failures on CI/remote builders.
#
# The upstream gjs-1.86.0 postFixup calls wrapProgram on
# $installedTests/libexec/installed-tests/gjs/minijasmine, but the meson
# build installs that file without the executable bit, causing:
#   "Cannot wrap ... because it is not an executable file"
#
# Root cause: `installTests` is a *function parameter* (default true) in the
# upstream package.nix, not a derivation attribute. overrideAttrs cannot
# change it, so the wrapProgram call was always present regardless of what
# we put in postFixup/preFixup. The fix is to use .override to set
# installTests=false, which makes lib.optionalString produce "" and removes
# the wrapProgram call entirely.
{ inputs }:
final: prev: {
  gjs = (prev.gjs.override { installTests = false; }).overrideAttrs (oldAttrs: {
    doCheck = false;
    # Make the glib-2.0 mv conditional in case it is absent (e.g. when doCheck=false
    # causes the test schemas not to be installed).
    postInstall = ''
      installedTestsSchemaDatadir="$installedTests/share/gsettings-schemas/gjs-${oldAttrs.version}"
      mkdir -p "$installedTestsSchemaDatadir"
      if [ -d "$installedTests/share/glib-2.0" ]; then
        mv "$installedTests/share/glib-2.0" "$installedTestsSchemaDatadir"
      fi
    '';
  });
}
