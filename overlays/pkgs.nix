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
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.python3.pkgs.setuptools ];
    # meson invokes giscanner Python modules at build time. Adding setuptools to
    # nativeBuildInputs is not sufficient — Python may not process .pth files if
    # invoked without site-packages (e.g. from the meson build dir). Exporting
    # PYTHONPATH explicitly ensures `import distutils` resolves via setuptools'
    # shim regardless of how Python is invoked during the build.
    preBuild = (oldAttrs.preBuild or "") + ''
      export PYTHONPATH="${final.python3.pkgs.setuptools}/${final.python3.sitePackages}''${PYTHONPATH:+:$PYTHONPATH}"
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

  # Fix python3.13-distutils test_concurrent_safe failure in sandboxed builds
  # test_msvccompiler::TestSpawn::test_concurrent_safe fails with "can't start new thread"
  python3 = prev.python3.override {
    packageOverrides = pfinal: pprev: {
      distutils = pprev.distutils.overrideAttrs (oldAttrs: {
        doCheck = false;
        doInstallCheck = false;
      });
      # yt-dlp-ejs-0.8.0 hatch_build.py runs 'pnpm run bundle' which requires
      # network access unavailable in the nix sandbox. Strip it from yt-dlp's
      # dependencies so it is never built.
      yt-dlp = pprev.yt-dlp.overrideAttrs (old: {
        propagatedBuildInputs = builtins.filter
          (x: (x.pname or "") != "yt-dlp-ejs")
          (old.propagatedBuildInputs or [ ]);
      });
    };
  };
  python3Packages = final.python3.pkgs;

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
})
