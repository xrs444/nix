# overlays/gjs-fix.nix
# Workaround for gjs-1.86.0 build failures on CI/remote builders.
#
# Three layered problems in gjs-1.86.0:
#
# 1. wrapProgram failure: postFixup calls wrapProgram on
#    $installedTests/libexec/installed-tests/gjs/minijasmine which is not
#    executable. Fix: .override { installTests = false; } removes the
#    wrapProgram call entirely (it's gated by lib.optionalString installTests).
#
# 2. gobject-introspection-tests subproject: 1.86.0 changed the required:
#    keyword from false → implicit true. Removing the subproject dir/wrap is
#    not enough — meson still errors "Neither a subproject directory nor a
#    .wrap file was found." Fix: patch meson.build to insert required: false.
#
# 3. installed-tests/js/meson.build:78 get_variable failure: even with
#    -Dinstalled_tests=false, meson still *configures* installed-tests/js/
#    (the flag only controls installation, not configure-time processing).
#    Line 78 calls gi_tests.get_variable() on the now-disabled subproject →
#    "disabled can't get_variable on it". Fix: inject a subdir_done() guard
#    at the top of installed-tests/js/meson.build so meson exits immediately
#    when gi_tests is absent.
#
# 4. test/meson.build:45 unknown variable "libgjstesttools_dep": with
#    skip_gtk_tests=true the library that defines libgjstesttools_dep is
#    never built, but line 45 still references it unconditionally → meson
#    "Unknown variable" error. Fix: inject libgjstesttools_dep = disabler()
#    at the top of test/meson.build when skip_gtk_tests is set; disabler()
#    propagates through meson and silently skips any target that depends on
#    it without erroring.
{ inputs }:
final: prev: {
  gjs = (prev.gjs.override { installTests = false; }).overrideAttrs (oldAttrs: {
    doCheck = false;
    # The upstream mesonFlags uses `finalAttrs.finalPackage.doCheck` to set
    # skip_gtk_tests, but that self-reference doesn't propagate through the
    # override+overrideAttrs chain. Append explicitly so meson sees it last
    # (meson uses the last occurrence of a duplicate -D flag).
    mesonFlags = (oldAttrs.mesonFlags or [ ]) ++ [
      "-Dskip_gtk_tests=true"
      # Disable installed tests so installed-tests/js/meson.build is never
      # processed. That file calls gi_tests.get_variable() which fails when
      # the gobject-introspection-tests subproject is disabled (required:false).
      "-Dinstalled_tests=false"
    ];
    # Remove the gobject-introspection-tests subproject and patch meson.build.
    # gjs-1.86.0 changed this subproject from required:false (older versions)
    # to required:true, which means meson fails if neither the subproject
    # directory nor the .wrap file is present — even after removing both.
    postPatch = (oldAttrs.postPatch or "") + ''
      # Remove both the subproject directory AND the .wrap file so meson
      # does not attempt to download it (sandbox blocks all network access).
      # Previous versions had required: false; 1.86.0 changed it to required: true,
      # so leaving the .wrap file causes: "Automatic wrap-based subproject
      # downloading is disabled".
      rm -rf subprojects/gobject-introspection-tests
      rm -f subprojects/gobject-introspection-tests.wrap
      # gjs-1.86.0 meson.build declares gobject-introspection-tests with NO
      # required: keyword (defaults to required: true). Removing the directory
      # and .wrap is not enough; meson still errors "Neither a subproject
      # directory nor a .wrap file was found." Insert required: false, so meson
      # skips it cleanly when neither source nor wrap is present.
      sed -i "s/subproject('gobject-introspection-tests',/subproject('gobject-introspection-tests', required: false,/" meson.build
      # Even with -Dinstalled_tests=false, meson still processes
      # installed-tests/js/meson.build during configure and hits a
      # gi_tests.get_variable() call (line 78) on the now-disabled subproject,
      # producing "disabled can't get_variable on it". Add a subdir_done() guard
      # at the top of the file so meson exits it immediately when gi_tests is
      # absent, without needing to parse the rest of the file.
      if [ -f installed-tests/js/meson.build ]; then
        sed -i "1s|^|if not gi_tests.found()\n  subdir_done()\nendif\n|" installed-tests/js/meson.build
      fi
      # test/meson.build:45 references libgjstesttools_dep which is only
      # defined when the testtools library is actually built (i.e. when GTK
      # tests run). With skip_gtk_tests=true the definition is skipped but
      # the reference remains, causing "Unknown variable". Inject a
      # disabler() placeholder so meson silently skips all targets that
      # depend on it rather than erroring.
      if [ -f test/meson.build ]; then
        sed -i "1s|^|if get_option('skip_gtk_tests')\n  libgjstesttools_dep = disabler()\nendif\n|" test/meson.build
      fi
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
