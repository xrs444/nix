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
    # The upstream mesonFlags uses `finalAttrs.finalPackage.doCheck` to set
    # skip_gtk_tests, but that self-reference doesn't propagate through the
    # override+overrideAttrs chain. Append explicitly so meson sees it last
    # (meson uses the last occurrence of a duplicate -D flag).
    mesonFlags = (oldAttrs.mesonFlags or [ ]) ++ [ "-Dskip_gtk_tests=true" ];
    # Remove the gobject-introspection-tests subproject before meson configure.
    # The subproject is declared `required: false` in gjs's meson.build, so meson
    # skips it cleanly when the directory is absent. Without this, the build tries
    # to generate .gir files by running g-ir-scanner, which fails on Python 3.13
    # with "No module named 'distutils'".
    #
    # Root cause: gjs-fix.nix uses prev.gjs, so gjs's gobject-introspection
    # nativeBuildInput comes from prev (pre-overlay) and does NOT get the
    # setuptools PYTHONPATH fix applied to final.gobject-introspection in pkgs.nix.
    postPatch = (oldAttrs.postPatch or "") + ''
      # Remove both the subproject directory AND the .wrap file so meson
      # does not attempt to download it (sandbox blocks all network access).
      # Previous versions had required: false; 1.86.0 changed it to required: true,
      # so leaving the .wrap file causes: "Automatic wrap-based subproject
      # downloading is disabled".
      rm -rf subprojects/gobject-introspection-tests
      rm -f subprojects/gobject-introspection-tests.wrap
    '';
    # Make the glib-2.0 mv conditional in case it is absent when doCheck=false.
    postInstall = ''
      installedTestsSchemaDatadir="$installedTests/share/gsettings-schemas/gjs-${oldAttrs.version}"
      mkdir -p "$installedTestsSchemaDatadir"
      if [ -d "$installedTests/share/glib-2.0" ]; then
        mv "$installedTests/share/glib-2.0" "$installedTestsSchemaDatadir"
      fi
    '';
  });
}
