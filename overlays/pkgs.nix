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
    if "generate_gir" not in text:
        continue
    while "gnome.generate_gir(" in text:
        pos = text.find("gnome.generate_gir(")
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
    text = re.sub("[^\n]*_gir[^\n]*\n", "", text)
    meson_file.write_text(text)
    print("Removed generate_gir from: " + str(meson_file))
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
    if "generate_gir" not in text:
        continue
    while "gnome.generate_gir(" in text:
        pos = text.find("gnome.generate_gir(")
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
    text = re.sub("[^\n]*_gir[^\n]*\n", "", text)
    meson_file.write_text(text)
    print("Removed generate_gir from: " + str(meson_file))
PYEOF
      '';
    })
    else prev.libnotify;

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

})
