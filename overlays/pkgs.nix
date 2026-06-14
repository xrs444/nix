{ inputs, ... }:
(final: prev: {
  # Fix gobject-introspection distutils import error with Python 3.13+
  # Python 3.13 removed distutils from stdlib entirely. g-ir-scanner's
  # giscanner/utils.py does `import distutils.cygwinccompiler`. setuptools
  # provides the distutils shim, but it must be on PYTHONPATH at runtime.
  #
  # Key architecture insight: `gobject-introspection` (nixpkgs) is actually
  # `gobject-introspection-wrapped`, built by wrapper.nix. Its buildCommand
  # does `eval fixupPhase` BEFORE `lndir`, so any postFixup on the wrapper
  # package runs on empty directories — completely ineffective.
  #
  # The scanner binary lives in `gobject-introspection-unwrapped`. Fixing
  # postFixup there ensures the scanner is wrapped before lndir symlinks it
  # into gobject-introspection-wrapped.
  #
  # We write the wrapper manually (no makeWrapper/wrapProgram) to avoid adding
  # to nativeBuildInputs, which caused meson configure to fail with
  # "python3 is missing modules: setuptools" during the gobject-introspection
  # build itself. postFixup runs after install and does not affect meson.
  #
  # Nix string escaping note: in '' strings, \${...} is NOT a Nix escape —
  # only ''${...} produces a literal ${...}. printf is used instead of echo so
  # that ${PYTHONPATH} is not expanded by bash at postFixup time.
  #
  # IMPORTANT: in Nix '' strings, ''' (three single-quotes) is the escape
  # sequence for a literal '' (two single-quotes) — so Python triple-quoted
  # strings like '''stub''' inside a '' string become ''stub'' in the shell,
  # which is a Python SyntaxError. Use \n-escaped single-quoted strings instead.
  "gobject-introspection-unwrapped" = prev."gobject-introspection-unwrapped".overrideAttrs (oldAttrs: {
    # gobject-introspection's meson.build:29 calls
    # find_installation('python3', modules: ['setuptools']). Our python3
    # overlay changes the python3 hash, causing a fresh rebuild. The fresh
    # build environment doesn't have setuptools accessible to python3 (the
    # nixpkgs 25.11 package doesn't add it). Add it explicitly.
    #
    # python3.pkgs.distutils installs distutils/ as real Python files in
    # site-packages (not via .pth hooks). The Python setup hook adds it to
    # PYTHONPATH so `import distutils` works in all giscanner modules
    # (ccompiler.py, utils.py, etc.) without needing a .pth activation shim.
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
      final.python3.pkgs.setuptools
      final.python3.pkgs.distutils
    ];
    # Under QEMU aarch64, ldd may not resolve libgobject-2.0.so from the dump
    # binary's dynamic section alone. Pre-populate LD_LIBRARY_PATH so ldd can
    # find it directly. Use pkg-config at build time (no Nix store reference)
    # to avoid circular dep: gobject-introspection → glib → gobject-introspection.
    preBuild = (oldAttrs.preBuild or "") + ''
      if _glib_libdir=$(pkg-config --variable=libdir glib-2.0 2>/dev/null) && [ -n "$_glib_libdir" ]; then
        export LD_LIBRARY_PATH="$_glib_libdir''${LD_LIBRARY_PATH:+:}''${LD_LIBRARY_PATH:-}"
      fi
    '';
    postPatch = (oldAttrs.postPatch or "") + ''
      # giscanner/utils.py does a bare `import distutils.cygwinccompiler` at
      # module level. setuptools' distutils shim omits cygwinccompiler on
      # non-Windows platforms even when distutils itself is available.
      # Wrap it in a try/except so non-Windows platforms continue without it.
      # NOTE: stub uses \n-escaped single-quoted string (not triple-quotes) because
      # in Nix indented strings, two single-quotes end the string and three produce
      # a literal two-single-quote sequence -- both corrupt the embedded Python.
      python3 -c "
import pathlib
p = pathlib.Path('giscanner/utils.py')
t = p.read_text()
stub = 'try:\n    import distutils.cygwinccompiler\nexcept ImportError:\n    import types as _types\n    distutils = _types.SimpleNamespace(\n        cygwinccompiler=_types.SimpleNamespace(get_msvcr=lambda: [])\n    )\n'
t = t.replace('import distutils.cygwinccompiler\n', stub)
p.write_text(t)
"

      # giscanner/shlibs.py: add fallback for resolve_from_ldd_output.
      #
      # Two bugs prevent library resolution under QEMU aarch64:
      #
      # Bug 1 (nixpkgs patch API change): absolute_shlib_path.patch changes
      # patterns[lib] from a plain regex to a (pattern, nix_pattern) tuple.
      # Any code calling patterns[lib].match() throws AttributeError on the tuple.
      # Fix: use a fresh _lib_re built from re.escape(lib) instead.
      #
      # Bug 2 (pattern character class): nixpkgs' _ldd_library_pattern uses
      # [^A-Za-z0-9_.] (excludes dot) which cannot match "libgirepository-1.0.so.0"
      # because the character after the matched "1.0" is "." (start of ".so").
      # This only affects non-nix-store paths (build-dir libraries like girepository).
      # The nix_pattern (used for /nix/store lines) correctly allows "." via
      # [^A-Za-z0-9_-]. Our _lib_re uses the same permissive set.
      #
      # Fix for Bug 2: re-parse the ldd output variable (in-scope) to extract
      # absolute non-nix paths and match basenames with our corrected regex.
      # This handles libraries in the build directory (e.g. libgirepository-1.0.so.0)
      # that ldd resolves via RPATH but the main loop can't match due to Bug 2.
      python3 << 'PYEOF'
import pathlib
p = pathlib.Path('giscanner/shlibs.py')
t = p.read_text()
old = (
    '    if len(patterns) > 0:\n'
    '        raise SystemExit(\n'
    '            "ERROR: can\'t resolve libraries to shared libraries: " +\n'
    '            ", ".join(patterns.keys()))\n'
)
new = (
    '    if len(patterns) > 0:\n'
    '        import subprocess as _subp, os as _os, re as _re\n'
    '        for lib in list(patterns.keys()):\n'
    '            _found = False\n'
    '            _lib_re = _re.compile(r\'lib\' + _re.escape(lib) + r\'[^A-Za-z0-9_-]\')\n'
    '            # Pass 1: re-scan ldd output for non-nix absolute paths.\n'
    '            # _ldd_library_pattern uses [^A-Za-z0-9_.] which excludes "." and\n'
    '            # cannot match filenames like libgirepository-1.0.so.0 (dot after\n'
    '            # version). Our _lib_re uses [^A-Za-z0-9_-] which allows ".".\n'
    '            for _line in output.split("\\n"):\n'
    '                for _word in _line.split():\n'
    '                    if _word.startswith("/") and not _word.startswith("/nix/store"):\n'
    '                        _bn = _os.path.basename(_word)\n'
    '                        if _lib_re.match(_bn) and _os.path.isfile(_word):\n'
    '                            del patterns[lib]\n'
    '                            shlibs.append(_word)\n'
    '                            _found = True\n'
    '                            break\n'
    '                if _found:\n'
    '                    break\n'
    '            if not _found:\n'
    '                # Pass 2: search pkg-config, NIX_LDFLAGS, LIBRARY_PATH.\n'
    '                _search_dirs = []\n'
    '                try:\n'
    '                    _d = _subp.check_output(\n'
    '                        ["pkg-config", "--variable=libdir", lib],\n'
    '                        stderr=_subp.DEVNULL).decode().strip()\n'
    '                    if _d: _search_dirs.append(_d)\n'
    '                except Exception:\n'
    '                    pass\n'
    '                for _lf in _os.environ.get("NIX_LDFLAGS", "").split():\n'
    '                    if _lf.startswith("-L"): _search_dirs.append(_lf[2:])\n'
    '                _search_dirs += [p for p in _os.environ.get("LIBRARY_PATH", "").split(":") if p]\n'
    '                for _d in _search_dirs:\n'
    '                    try:\n'
    '                        for _f in _os.listdir(_d):\n'
    '                            if _lib_re.match(_f):\n'
    '                                del patterns[lib]\n'
    '                                shlibs.append(_os.path.join(_d, _f))\n'
    '                                _found = True\n'
    '                                break\n'
    '                    except Exception:\n'
    '                        pass\n'
    '                    if _found:\n'
    '                        break\n'
    '                if not _found:\n'
    '                    # Pass 3: search $NIX_BUILD_TOP for libs built in-tree.\n'
    '                    # Under QEMU aarch64, ldd reports freshly-compiled libs\n'
    '                    # (e.g. libgirepository-1.0.so.0) as "not found" rather\n'
    '                    # than an absolute path, so pass 1 cannot extract them.\n'
    '                    import glob as _glob\n'
    '                    _nbt = _os.environ.get("NIX_BUILD_TOP", "/build")\n'
    '                    for _fp in _glob.glob(\n'
    '                        _os.path.join(_nbt, "**", "lib" + lib + ".so*"),\n'
    '                        recursive=True):\n'
    '                        if _lib_re.match(_os.path.basename(_fp)) and _os.path.isfile(_fp):\n'
    '                            del patterns[lib]\n'
    '                            shlibs.append(_fp)\n'
    '                            _found = True\n'
    '                            break\n'
    '    if len(patterns) > 0:\n'
    '        raise SystemExit(\n'
    '            "ERROR: can\'t resolve libraries to shared libraries: " +\n'
    '            ", ".join(patterns.keys()))\n'
)
t2 = t.replace(old, new)
p.write_text(t2)
PYEOF
    '';
    postFixup = (oldAttrs.postFixup or "") + ''
      # g-ir-scanner is installed to $dev/bin (outputBin = "dev"). Wrap it to
      # put setuptools on PYTHONPATH so `import distutils` works on Python 3.13+.
      if [ -f "$dev/bin/g-ir-scanner" ]; then
        mv "$dev/bin/g-ir-scanner" "$dev/bin/.g-ir-scanner-wrapped"
        printf '#!/bin/sh\n' > "$dev/bin/g-ir-scanner"
        printf 'export PYTHONPATH=%s''${PYTHONPATH:+:}''${PYTHONPATH}\n' \
          "${final.python3.pkgs.setuptools}/${final.python3.sitePackages}" \
          >> "$dev/bin/g-ir-scanner"
        printf 'exec %s "$@"\n' \
          "$dev/bin/.g-ir-scanner-wrapped" \
          >> "$dev/bin/g-ir-scanner"
        chmod +x "$dev/bin/g-ir-scanner"
      fi
    '';
  });

  # NOTE: gtk4, libadwaita, gst-plugins-bad, and gjs introspection overrides
  # have been moved to xdash1-specific config since other hosts need GIR files

  # Fix gupnp context-manager test failure in sandboxed builds
  # test-context-manager tries to bind 127.0.0.1:port but the port is already
  # in use in the CI runner's network namespace. Disable tests to skip.
  gupnp = prev.gupnp.overrideAttrs (_: {
    doCheck = false;
  });

  # Fix dconf test failure in sandboxed builds
  # test dconf:dconf runs `dconf write` which requires a real D-Bus session bus
  # not available in the Nix sandbox.
  dconf = prev.dconf.overrideAttrs (_: {
    doCheck = false;
  });

  # Fix ibus parallel install race in sandboxed builds
  # bindings/pygobject installs IBus.py twice in parallel: second install fails
  # with "File exists". Disabling parallel build/install serialises the make.
  ibus = prev.ibus.overrideAttrs (_: {
    enableParallelBuilding = false;
  });

  # Fix libcanberra parallel install race in sandboxed builds
  # make install runs plugin relink steps in parallel: libcanberra-multi.la tries
  # to relink against -lcanberra before libcanberra.so has been installed to its
  # output path, causing ld to fail with "cannot find -lcanberra". Serialising
  # the install ensures libcanberra.so is present before plugins try to link it.
  libcanberra = prev.libcanberra.overrideAttrs (_: {
    enableParallelBuilding = false;
  });

  # Fix edk2 BaseTools parallel build race
  # VfrCompile runs ANTLR to generate VfrLexer.h, but parallel make starts
  # compiling VfrSyntax.o before VfrLexer.h exists. Single-threaded build
  # serialises the ANTLR step before the compilation that depends on it.
  edk2 = prev.edk2.overrideAttrs (_: {
    enableParallelBuilding = false;
  });

  # Fix upower self-test SIGABRT in sandboxed builds
  # test 7/86 "self-test" is killed by signal 6 (SIGABRT) — requires a real
  # D-Bus system bus and hardware access not available in the Nix sandbox.
  upower = prev.upower.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix xdg-desktop-portal USB integration test failure in sandboxed builds
  # test_queries[2-template_params3-vnd:0001] in test_usb.py fails because
  # the sandbox has no D-Bus USB device session bus / real USB device access.
  xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix libsecret test failures in sandboxed builds
  # https://github.com/NixOS/nixpkgs/issues/370724
  libsecret = prev.libsecret.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

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

  # Fix pipewire test-support timeout in sandboxed builds
  # logger_debug_env_invalid test hangs in sandbox environment
  # Also disable roc-toolkit and ffado support which require i686-linux
  pipewire = (prev.pipewire.override {
    rocSupport = false;   # Disable roc-toolkit (requires i686-linux via scons)
    ffadoSupport = false; # Disable ffado (requires i686-linux via scons)
  }).overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Override wireplumber to disable docs (requires Python sphinx modules)
  # Use override instead of overrideAttrs to set feature flags properly
  wireplumber = prev.wireplumber.override {
    pipewire = final.pipewire;
    # Meson feature options need to be set via override, not mesonFlags
    enableDocs = false;
  };

  # Fix sdl3 test timeouts (testthread, testsem, testtimer, testprocess) in sandboxed builds
  # Tests run via CMake build target, not checkPhase, so doCheck doesn't help
  # Keep tests off but create empty installedTests output to satisfy the derivation
  sdl3 = prev.sdl3.overrideAttrs (oldAttrs: {
    cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
      "-DSDL_TESTS=OFF"
    ];
    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $installedTests
    '';
  });

  # Use unstable version of claude-code to avoid npm lock file issues
  # Stable version 2.1.25 has missing @img/sharp-linuxmusl dependencies
  claude-code = (
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }
  ).claude-code;

  # Fix tinysparql test_notifier SIGABRT in sandboxed builds
  # test_notifier requires a real D-Bus session / notification infrastructure
  # not available in the Nix sandbox
  tinysparql = prev.tinysparql.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix nbd TLS test timeouts (tlshuge, tlswrongcert) in sandboxed builds
  # Tests require real TLS socket timing that doesn't work in the sandbox
  nbd = prev.nbd.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix openvswitch test failures in sandboxed builds
  # Tests require real network interfaces / kernel modules not available in sandbox
  openvswitch = prev.openvswitch.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix swtpm test failures in sandboxed builds
  # test_tpm2_swtpm_setup_create_cert and pkcs11-related tests require softhsm2
  # which is not available in the nix sandbox environment
  swtpm = prev.swtpm.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix inetutils format-security compilation errors on macOS
  # https://github.com/NixOS/nixpkgs/issues/XXXXX
  inetutils = prev.inetutils.overrideAttrs (oldAttrs: {
    hardeningDisable = (oldAttrs.hardeningDisable or [ ]) ++ [ "format" ];
  });

  # Fix flac test_streams.sh hang in sandboxed builds
  # test_streams.sh runs multi-hour compression tests that stall in the Nix
  # sandbox. flac is a build-time dep of libsndfile — skipping tests is safe.
  flac = prev.flac.overrideAttrs (_: { doCheck = false; });

  # Fix gtkmm3/gtkmm4 test failures in sandboxed builds
  # Tests call Gdk::Display::get_default() which requires a live display
  # server (X11/Wayland). The Nix sandbox has none, causing "failed to get
  # display" / "failed to get children" test failures.
  gtkmm3 = prev.gtkmm3.overrideAttrs (_: { doCheck = false; });
  gtkmm4 = prev.gtkmm4.overrideAttrs (_: { doCheck = false; });
})
