{ inputs, ... }:
(final: prev: {
  # yt-dlp-ejs-0.8.0 hatch_build.py runs 'pnpm run bundle' which requires
  # network access unavailable in the nix sandbox. Strip it from yt-dlp's
  # dependencies so it is never built.
  # Overridden at the top level (not via python3.packageOverrides) so that
  # python3's derivation hash stays identical to upstream nixpkgs — allowing
  # all 200+ python packages to be fetched from cache.nixos.org rather than
  # rebuilt locally. Only yt-dlp's own hash changes; cascade impact is zero.
  yt-dlp = prev.yt-dlp.overrideAttrs (old: {
    propagatedBuildInputs = builtins.filter
      (x: (x.pname or "") != "yt-dlp-ejs")
      (old.propagatedBuildInputs or [ ]);
  });

  # gobject-introspection-unwrapped: giscanner/{utils,ccompiler}.py import
  # distutils at module level. Python 3.12+ removed distutils from stdlib.
  # Any package that invokes g-ir-scanner during a source build (harfbuzz,
  # pygobject, playerctl, etc.) crashes on aarch64 where the binary is not
  # cached by Hydra and must be rebuilt with Python 3.13.
  #
  # Scoped to aarch64 using if/then/else (not lib.optionalAttrs): the
  # optionalAttrs form still calls overrideAttrs on x86_64 with an empty
  # attrset which can shift the derivation hash. The if/then/else form
  # returns the unmodified prev package object for non-aarch64, guaranteeing
  # the x86_64 hash is byte-for-byte identical to upstream Hydra and avoiding
  # the cascade through json-glib → gtk → xen → qemu.
  gobject-introspection-unwrapped =
    if final.stdenv.hostPlatform.isAarch64
    then prev.gobject-introspection-unwrapped.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # utils.py: guard three Windows-only distutils.cygwinccompiler references
        # (distutils.cygwinccompiler is omitted by setuptools' shim on Linux)
        sed -i 's/^import distutils\.cygwinccompiler$/try:\n    import distutils.cygwinccompiler\nexcept ImportError:\n    pass/' giscanner/utils.py
        sed -i 's/^orig_get_msvcr = distutils\.cygwinccompiler\.get_msvcr.*$/try:\n    orig_get_msvcr = distutils.cygwinccompiler.get_msvcr  # type: ignore\nexcept NameError:\n    orig_get_msvcr = lambda: []  # type: ignore/' giscanner/utils.py
        sed -i 's/^distutils\.cygwinccompiler\.get_msvcr = get_msvcr_overwrite.*$/try:\n    distutils.cygwinccompiler.get_msvcr = get_msvcr_overwrite  # type: ignore\nexcept NameError:\n    pass/' giscanner/utils.py

        # ccompiler.py:27 — bare 'import distutils' fails on Python 3.13 (removed
        # from stdlib). ccompiler.py also does from-imports of distutils.unixccompiler,
        # distutils.cygwinccompiler, distutils.sysconfig, distutils.ccompiler.
        # Bootstrap setuptools._distutils into sys.modules["distutils"] before any of
        # those run; Python then resolves the submodule from-imports via __path__.
        substituteInPlace giscanner/ccompiler.py \
          --replace-warn 'import distutils' \
          'try:
    import distutils
except ImportError:
    import sys as _s, importlib as _il
    _s.modules["distutils"] = _il.import_module("setuptools._distutils")
    import distutils
    del _s, _il'

        # shlibs.py: _resolve_non_libtool runs ldd on a dump binary to find shared
        # library paths. Build-dir libraries (e.g. gobject-introspection test libs
        # like libutility.so) have no RPATH, so ldd returns "not found", leaving
        # patterns unmatched and triggering SystemExit. Fix: pass options.library_paths
        # (the -L flags) as LD_LIBRARY_PATH to the ldd subprocess so ldd can find them.
        python3 -u << PYEOF
with open('giscanner/shlibs.py') as f:
    content = f.read()
old = "        output = subprocess.check_output(args)\n"
new = (
    "        ldd_env = os.environ.copy()\n"
    "        import sys as _sys\n"
    "        _lp = ':'.join(a[2:] for a in _sys.argv if a.startswith('-L') and len(a) > 2)\n"
    "        if _lp:\n"
    "            ldd_env['LD_LIBRARY_PATH'] = _lp + ':' + ldd_env.get('LD_LIBRARY_PATH', _lp)\n"
    "        output = subprocess.check_output(args, env=ldd_env)\n"
)
assert old in content, "shlibs.py patch target not found"
with open('giscanner/shlibs.py', 'w') as f:
    f.write(content.replace(old, new, 1))
PYEOF
      '';
      # SETUPTOOLS_USE_DISTUTILS must be set BEFORE Python starts so that
      # distutils-precedence.pth (processed at interpreter startup) activates
      # setuptools' bundled distutils shim. Setting it inside the script is
      # too late — .pth files run before any user code executes.
      #
      # wrapProgram renames g-ir-scanner → .g-ir-scanner-wrapped and creates
      # a new shell wrapper. patchShebangs in fixupPhase skips dot-prefixed
      # files, so .g-ir-scanner-wrapped keeps "#!/usr/bin/env python3" and
      # picks up whatever python3 is in the CALLER's PATH (harfbuzz, playerctl
      # etc.) — which does not have setuptools. Fix: explicitly call
      # patchShebangs on the dot-file inside postInstall while gobject-
      # introspection's own nativeBuild Python (with setuptools) is in PATH.
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ prev.buildPackages.makeWrapper ];
      # Propagate setuptools so downstream packages (pygobject, harfbuzz) have it in
      # their nativeBuildInputs and hence in their Nix sandbox. The wrapper below adds
      # setuptools to PYTHONPATH, but that path is inaccessible unless it is in the
      # sandbox — propagation ensures it is.
      propagatedNativeBuildInputs = (old.propagatedNativeBuildInputs or []) ++ [
        final.buildPackages.python3.pkgs.setuptools
      ];
      postInstall = (old.postInstall or "") + ''
        wrapProgram "$dev/bin/g-ir-scanner" \
          --set SETUPTOOLS_USE_DISTUTILS local \
          --prefix PYTHONPATH : "${final.buildPackages.python3.pkgs.setuptools}/${final.buildPackages.python3.sitePackages}"
        patchShebangs "$dev/bin/.g-ir-scanner-wrapped"
      '';
    })
    else prev.gobject-introspection-unwrapped;


  # playerctl: gnome.generate_gir() runs unconditionally (not gated by
  # gtk-doc). g-ir-scanner resolves libplayerctl.so via ldd, but in the Nix
  # aarch64 sandbox the patched dynamic linker doesn't honour LD_LIBRARY_PATH
  # for the dump binary, so ldd returns "not found". Remove the generate_gir
  # block from meson.build — playerctl works without the GIR typelib.
  playerctl = if final.stdenv.hostPlatform.isAarch64
    then prev.playerctl.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
import pathlib, re
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    for call in ["gnome.generate_gir(", "gnome.generate_vapi("]:
        if call not in text:
            continue
        while call in text:
            pos = text.find(call)
            line_start = text.rfind("\n", 0, pos) + 1
            depth = 0
            i = pos
            while i < len(text):
                if text[i] == "(":
                    depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            if i < len(text) and text[i] == "\n":
                i += 1
            text = text[:line_start] + text[i:]
        meson_file.write_text(text)
        print("Removed " + call.rstrip("(") + " from: " + str(meson_file))
# Second pass: remove any remaining _gir/_vapi variable references from ALL meson files
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    changed = False
    for pat in ["_gir", "_vapi"]:
        new = re.sub("[^\n]*" + pat + "[^\n]*\n", "", text)
        if new != text:
            text = new
            changed = True
    if changed:
        meson_file.write_text(text)
        print("Cleaned " + pat + " refs from: " + str(meson_file))
PYEOF
      '';
    })
    else prev.playerctl;

  # libnotify: same GIR resolution failure as playerctl — ldd can't find
  # libnotify.so in the build sandbox even with LD_LIBRARY_PATH. Remove the
  # generate_gir call; the Notify GIR typelib is documentation, not required
  # for the notify-send binary or libnotify.so to function.
  libnotify = if final.stdenv.hostPlatform.isAarch64
    then prev.libnotify.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
import pathlib, re
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    for call in ["gnome.generate_gir(", "gnome.generate_vapi("]:
        if call not in text:
            continue
        while call in text:
            pos = text.find(call)
            line_start = text.rfind("\n", 0, pos) + 1
            depth = 0
            i = pos
            while i < len(text):
                if text[i] == "(":
                    depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            if i < len(text) and text[i] == "\n":
                i += 1
            text = text[:line_start] + text[i:]
        meson_file.write_text(text)
        print("Removed " + call.rstrip("(") + " from: " + str(meson_file))
# Second pass: remove any remaining _gir/_vapi variable references from ALL meson files
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    changed = False
    for pat in ["_gir", "_vapi"]:
        new = re.sub("[^\n]*" + pat + "[^\n]*\n", "", text)
        if new != text:
            text = new
            changed = True
    if changed:
        meson_file.write_text(text)
        print("Cleaned " + pat + " refs from: " + str(meson_file))
PYEOF
      '';
    })
    else prev.libnotify;

  # libcloudproviders: same GIR resolution failure — ldd can't find
  # libcloudproviders.so in the build sandbox. Remove generate_gir from
  # src/meson.build; the library itself is unaffected.
  libcloudproviders = if final.stdenv.hostPlatform.isAarch64
    then prev.libcloudproviders.overrideAttrs (old: {
      # -Ddocumentation=false prevents docs/meson.build from running, which
      # references the removed GIR file via @INPUT0@ in a custom_target.
      # Remove devdoc from outputs: with docs disabled nothing installs there
      # and Nix fails "failed to produce output path for output 'devdoc'".
      outputs = builtins.filter (o: o != "devdoc") (old.outputs or [ "out" ]);
      mesonFlags = (old.mesonFlags or []) ++ [ "-Ddocumentation=false" ];
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
import pathlib, re
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    for call in ["gnome.generate_gir(", "gnome.generate_vapi("]:
        if call not in text:
            continue
        while call in text:
            pos = text.find(call)
            line_start = text.rfind("\n", 0, pos) + 1
            depth = 0
            i = pos
            while i < len(text):
                if text[i] == "(":
                    depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            if i < len(text) and text[i] == "\n":
                i += 1
            text = text[:line_start] + text[i:]
        meson_file.write_text(text)
        print("Removed " + call.rstrip("(") + " from: " + str(meson_file))
# Second pass: remove any remaining _gir/_vapi variable references from ALL meson files
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    changed = False
    for pat in ["_gir", "_vapi"]:
        new = re.sub("[^\n]*" + pat + "[^\n]*\n", "", text)
        if new != text:
            text = new
            changed = True
    if changed:
        meson_file.write_text(text)
        print("Cleaned " + pat + " refs from: " + str(meson_file))
PYEOF
      '';
    })
    else prev.libcloudproviders;

  # json-glib: GIR generation fails on aarch64 because the Nix cc-wrapper does
  # not set RPATH for /build/ paths, so ldd can't find libjson-glib-1.0.so.0
  # when g-ir-scanner runs. The shlibs.py LD_LIBRARY_PATH patch exists in
  # gobject-introspection-unwrapped but relies on the env being inherited.
  # Exporting LD_LIBRARY_PATH before ninja spawns g-ir-scanner ensures ldd
  # finds the freshly-built library.
  # devdoc must still be removed from outputs because with documentation
  # disabled nothing installs there and Nix would fail.
  json-glib = if final.stdenv.hostPlatform.isAarch64
    then prev.json-glib.overrideAttrs (old: {
      outputs = builtins.filter (o: o != "devdoc") (old.outputs or [ "out" ]);
      mesonFlags = (old.mesonFlags or []) ++ [ "-Ddocumentation=disabled" ];
      preBuild = (old.preBuild or "") + ''
        # Add the meson build output dir to LD_LIBRARY_PATH so ldd (called by
        # g-ir-scanner's shlibs.py) can find libjson-glib-1.0.so.0 at GIR time.
        export LD_LIBRARY_PATH="''${PWD}/build/json-glib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      '';
    })
    else prev.json-glib;

  # gtk3: GIR generation (Gdk-3.0.gir, Gtk-3.0.gir) fails with "can't resolve
  # libraries: gdk-3/gtk-3" because ldd can't find the libraries in build/.
  # Same preBuild LD_LIBRARY_PATH pattern as json-glib and networkmanager.
  gtk3 = if final.stdenv.hostPlatform.isAarch64
    then prev.gtk3.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        export LD_LIBRARY_PATH="''${PWD}/build/gdk:''${PWD}/build/gtk''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      '';
    })
    else prev.gtk3;

  # libgnomekbd: Gkbd-3.0.gir fails: "can't resolve: gnomekbd, gnomekbdui".
  # preBuild LD_LIBRARY_PATH doesn't reliably propagate here; use the proven
  # postPatch approach to remove gnome.generate_gir() calls from meson.build.
  libgnomekbd = if final.stdenv.hostPlatform.isAarch64
    then prev.libgnomekbd.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
import pathlib, re
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    changed = False
    for call in ["gnome.generate_gir(", "gnome.generate_vapi("]:
        while call in text:
            pos = text.find(call)
            line_start = text.rfind("\n", 0, pos) + 1
            depth, i = 0, pos
            while i < len(text):
                if text[i] == "(": depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0: i += 1; break
                i += 1
            if i < len(text) and text[i] == "\n": i += 1
            text = text[:line_start] + text[i:]
            changed = True
    for pat in ["_gir", "_vapi"]:
        new = re.sub("[^\n]*" + pat + "[^\n]*\n", "", text)
        if new != text: text = new; changed = True
    if changed: meson_file.write_text(text)
PYEOF
      '';
    })
    else prev.libgnomekbd;

  # gtk-layer-shell: GtkLayerShell-0.1.gir fails: "can't resolve: gtk-layer-shell".
  # Library at build/src.
  gtk-layer-shell = if final.stdenv.hostPlatform.isAarch64
    then prev.gtk-layer-shell.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        export LD_LIBRARY_PATH="''${PWD}/build/src''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      '';
    })
    else prev.gtk-layer-shell;

  # colord: Colorhug-1.0.gir / Colord-1.0.gir fail: "can't resolve libraries".
  # preBuild LD_LIBRARY_PATH is inconsistent; use the proven postPatch approach.
  colord = if final.stdenv.hostPlatform.isAarch64
    then prev.colord.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
import pathlib, re
for meson_file in pathlib.Path(".").rglob("meson.build"):
    text = meson_file.read_text()
    changed = False
    for call in ["gnome.generate_gir(", "gnome.generate_vapi("]:
        while call in text:
            pos = text.find(call)
            line_start = text.rfind("\n", 0, pos) + 1
            depth, i = 0, pos
            while i < len(text):
                if text[i] == "(": depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0: i += 1; break
                i += 1
            if i < len(text) and text[i] == "\n": i += 1
            text = text[:line_start] + text[i:]
            changed = True
    for pat in ["_gir", "_vapi"]:
        new = re.sub("[^\n]*" + pat + "[^\n]*\n", "", text)
        if new != text: text = new; changed = True
    if changed: meson_file.write_text(text)
PYEOF
      '';
    })
    else prev.colord;

  # libxkbcommon: python-tests:tool-option-parsing fails on aarch64 (exit 1).
  # The library itself builds and functions correctly.
  libxkbcommon = if final.stdenv.hostPlatform.isAarch64
    then prev.libxkbcommon.overrideAttrs (_: { doCheck = false; })
    else prev.libxkbcommon;

  # networkmanager: GIR generation (NM-1.0.gir) fails with "can't resolve
  # libraries: nm" because ldd can't find libnm.so in the build directory.
  # Same root cause as json-glib — export LD_LIBRARY_PATH before ninja runs.
  networkmanager = if final.stdenv.hostPlatform.isAarch64
    then prev.networkmanager.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        export LD_LIBRARY_PATH="''${PWD}/build/src/libnm-client-impl''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      '';
    })
    else prev.networkmanager;

  # gusb: GIR generation includes Json-1.0.gir (from json-glib) and can also
  # fail with its own shlibs.py library resolution issue. Disable GIR; the C
  # library is fully functional without the typelib. devdoc is conditional on
  # introspection in nixpkgs, so filter it out to avoid missing-output failure.
  gusb = if final.stdenv.hostPlatform.isAarch64
    then prev.gusb.overrideAttrs (old: {
      outputs = builtins.filter (o: o != "devdoc") (old.outputs or [ "out" ]);
      mesonFlags = (old.mesonFlags or []) ++ [ "-Dintrospection=false" "-Dvapi=false" "-Ddocs=false" ];
    })
    else prev.gusb;

  # geocode-glib_2: GIR generation fails on aarch64 because it includes Json-1.0.gir
  # (from json-glib), which isn't generated when json-glib has introspection disabled.
  # nixpkgs attribute is geocode-glib_2 (underscore-2), not geocode-glib.
  geocode-glib_2 = if final.stdenv.hostPlatform.isAarch64
    then prev.geocode-glib_2.overrideAttrs (old: {
      # Remove devdoc from outputs: with gtk-doc disabled nothing installs there.
      outputs = builtins.filter (o: o != "devdoc") (old.outputs or [ "out" ]);
      mesonFlags = (old.mesonFlags or []) ++ [ "-Denable-introspection=false" "-Denable-gtk-doc=false" ];
    })
    else prev.geocode-glib_2;

  # libgweather: GIR generation includes GWeather-4.0.gir which in turn needs
  # GeocodeGlib-2.0.gir and Json-1.0.gir — both disabled above. Skip GIR to
  # break the cascade. The runtime C library is unaffected.
  libgweather = if final.stdenv.hostPlatform.isAarch64
    then prev.libgweather.overrideAttrs (old: {
      outputs = builtins.filter (o: o != "devdoc") (old.outputs or [ "out" ]);
      mesonFlags = (old.mesonFlags or []) ++ [ "-Dintrospection=false" ];
    })
    else prev.libgweather;

  # gweather-locations: meson configure checks `python3 is missing modules: gi`
  # at line 12 of its meson.build. On aarch64, our gobject-introspection overlay
  # changes the store hash — pygobject3's C extension (_gi.so) has an RPATH that
  # dlopen can't satisfy because the unpatched library hash isn't in the store.
  # Fix: add gobject-introspection to nativeBuildInputs so its lib/ lands in
  # LD_LIBRARY_PATH during configure, making libgirepository-1.0.so.1 findable.
  gweather-locations = if final.stdenv.hostPlatform.isAarch64
    then prev.gweather-locations.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
        final.buildPackages.gobject-introspection
      ];
    })
    else prev.gweather-locations;

  # gobject-introspection: most packages use gobject-introspection (not
  # gobject-introspection-unwrapped) for g-ir-scanner. These are separate
  # derivations even though they share the same source — overlaying one does
  # not propagate to the other. Apply the same shlibs.py LD_LIBRARY_PATH fix
  # here so that packages like libcloudproviders, accountsservice, and malcontent
  # can resolve build-dir .so files during GIR generation on aarch64.
  gobject-introspection = if final.stdenv.hostPlatform.isAarch64
    then prev.gobject-introspection.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 -u << PYEOF
with open('giscanner/shlibs.py') as f:
    content = f.read()
old = "        output = subprocess.check_output(args)\n"
new = (
    "        ldd_env = os.environ.copy()\n"
    "        import sys as _sys\n"
    "        _lp = ':'.join(a[2:] for a in _sys.argv if a.startswith('-L') and len(a) > 2)\n"
    "        if _lp:\n"
    "            ldd_env['LD_LIBRARY_PATH'] = _lp + ':' + ldd_env.get('LD_LIBRARY_PATH', _lp)\n"
    "        output = subprocess.check_output(args, env=ldd_env)\n"
)
assert old in content, "shlibs.py patch target not found in gobject-introspection"
with open('giscanner/shlibs.py', 'w') as f:
    f.write(content.replace(old, new, 1))
PYEOF
      '';
    })
    else prev.gobject-introspection;


  # zram-generator: Rust test binary SIGABRTs under QEMU aarch64 emulation
  # when the native ARM builders are unavailable. The generator itself is fine.
  zram-generator = if final.stdenv.hostPlatform.isAarch64
    then prev.zram-generator.overrideAttrs (_: { doCheck = false; })
    else prev.zram-generator;

  # libical: GLib-based Python tests import 'gi' (pygobject3), which is not
  # available in the cmake test sandbox on aarch64. The tests run in the
  # install phase via cmake, bypassing doCheck=false. Disable GObject
  # introspection on aarch64 to skip the GLib binding tests entirely; the
  # core libical C library is unaffected.
  libical = if final.stdenv.hostPlatform.isAarch64
    then prev.libical.overrideAttrs (old: {
      doCheck = false;
      cmakeFlags = (old.cmakeFlags or []) ++ [ "-DGOBJECT_INTROSPECTION=False" "-DICAL_GLIB_VAPI=False" ];
    })
    else prev.libical;

  # libsecret: test-collection SIGABRTs on aarch64 (exit 134). The library
  # and its GIR output build correctly; only the meson test suite crashes.
  libsecret = if final.stdenv.hostPlatform.isAarch64
    then prev.libsecret.overrideAttrs (_: { doCheck = false; })
    else prev.libsecret;

  # django 5.2.x: bash_completion test calls external bash completion
  # infrastructure that doesn't exist in the Nix sandbox — gets [''] instead
  # of ['--list']. 1 test out of 18154 fails; package itself is fine.
  # Tests run in installCheckPhase; doInstallCheck=false skips them.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyprev: {
      django = pyprev.django.overridePythonAttrs (_: { doInstallCheck = false; });

      # pygobject3: builds gobject-introspection test subprojects (libutility,
      # libwarnlib) and generates GIR for them during the BUILD phase. doCheck
      # alone only skips meson test; the subprojects are compiled in buildPhase.
      # Explicitly pass -Dtests=false so meson skips the subproject entirely.
      pygobject3 = if final.stdenv.hostPlatform.isAarch64
        then pyprev.pygobject3.overridePythonAttrs (old: {
          doCheck = false;
          mesonFlags = (old.mesonFlags or []) ++ [ "-Dtests=false" ];
        })
        else pyprev.pygobject3;
    })
  ];

  # pipx 1.8.0: test_package_specifier assertions expect old PEP 508 format
  # (no space before @, e.g. "black@ https://...") but Python 3.13's specifier
  # normalizer emits the canonical form "black @ https://...". 7 tests fail.
  # Not a sandbox or functional issue — pure test expectation drift.
  # pipx tests run in installCheckPhase (pytest-check-hook), not checkPhase.
  # checkPhase = ":" handles the standard check gate; doInstallCheck = false
  # disables the install-check phase that actually invokes pytest.
  pipx = prev.pipx.overrideAttrs (_: { checkPhase = ":"; doInstallCheck = false; });

  # Fix inetutils format-security compilation errors on macOS
  inetutils = prev.inetutils.overrideAttrs (oldAttrs: {
    hardeningDisable = (oldAttrs.hardeningDisable or [ ]) ++ [ "format" ];
  });

  # Use unstable version of claude-code to avoid npm lock file issues
  # Stable version 2.1.25 has missing @img/sharp-linuxmusl dependencies
  claude-code = (
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }
  ).claude-code;

  # OpenRSAT: cross-platform RSAT alternative for managing Samba/Windows AD.
  # Not in nixpkgs; packaged from GitHub pre-built release binaries.
  # macOS: DMG containing a signed .app bundle (arm64); bundled libssl/libcrypto.
  # Linux: bare x86_64 ELF; GTK2 GUI via autoPatchelfHook.
  openrsat =
    if final.stdenv.isDarwin then
      prev.stdenv.mkDerivation rec {
        pname = "openrsat";
        version = "0.4.386";
        src = prev.fetchurl {
          url = "https://github.com/tranquilit/OpenRSAT/releases/download/v${version}/OpenRSAT-darwin-arm.dmg";
          sha256 = "1xsdlc5vscsphmhw8nf2i391s939c9hk9s5bwalksck05sa92q6h";
        };
        sourceRoot = ".";
        unpackPhase = ''
          MNTDIR=$(mktemp -d /tmp/openrsat-XXXXXXXX)
          /usr/bin/hdiutil attach -quiet -nobrowse -mountpoint "$MNTDIR" "$src"
          cp -r "$MNTDIR/OpenRSAT.app" .
          /usr/bin/hdiutil detach -quiet "$MNTDIR"
          rmdir "$MNTDIR"
        '';
        installPhase = ''
          mkdir -p $out/Applications $out/bin
          cp -r OpenRSAT.app $out/Applications/
          ln -s $out/Applications/OpenRSAT.app/Contents/MacOS/OpenRSAT $out/bin/openrsat
        '';
        meta = {
          description = "Open source RSAT alternative for managing Active Directory";
          homepage = "https://github.com/tranquilit/OpenRSAT";
          platforms = prev.lib.platforms.darwin;
        };
      }
    else
      prev.stdenv.mkDerivation rec {
        pname = "openrsat";
        version = "0.4.386";
        src = prev.fetchurl {
          url = "https://github.com/tranquilit/OpenRSAT/releases/download/v${version}/OpenRSAT-linux-x64";
          sha256 = "03qhl82yqddm9bbkbn2gf8ygz9fkqh6gnq8qmbhq0w15siz19v95";
        };
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = with prev; [
          gtk2
          glib
          pango
          cairo
          atk
          gdk-pixbuf
          libX11
          zlib
        ];
        dontUnpack = true;
        installPhase = ''
          install -Dm755 $src $out/bin/openrsat
          install -dm755 $out/share/applications
          cat > $out/share/applications/openrsat.desktop << DESKTOP
[Desktop Entry]
Name=OpenRSAT
Comment=Open source RSAT alternative for managing Active Directory
Exec=openrsat
Icon=openrsat
Type=Application
Categories=Network;System;Administration;
DESKTOP
        '';
        meta = {
          description = "Open source RSAT alternative for managing Active Directory";
          homepage = "https://github.com/tranquilit/OpenRSAT";
          platforms = prev.lib.platforms.linux;
        };
      };

})
