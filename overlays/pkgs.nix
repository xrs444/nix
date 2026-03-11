{ inputs, ... }:
(final: prev: {
  # Fix gobject-introspection distutils import error with Python 3.13+
  # Python 3.12+ removed distutils from stdlib, g-ir-scanner needs setuptools at runtime
  # Add setuptools to propagatedBuildInputs so it's available when g-ir-scanner runs
  # https://bugs.gentoo.org/865183
  # https://github.com/pypa/setuptools/issues/4871
  # https://gitlab.archlinux.org/archlinux/packaging/packages/gobject-introspection/-/issues/1
  gobject-introspection = prev.gobject-introspection.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [
      final.python3Packages.setuptools
    ];
  });

  # Fix gst-plugins-bad distutils error by disabling introspection and docs
  # GStreamer packages try to generate GIR files using g-ir-scanner
  # For minimal kiosk builds, we don't need GIR files or documentation
  gst_all_1 = prev.gst_all_1.overrideScope (gself: gsuper: {
    gst-plugins-bad = gsuper.gst-plugins-bad.overrideAttrs (oldAttrs: {
      mesonFlags = (oldAttrs.mesonFlags or []) ++ [
        "-Dintrospection=disabled"
        "-Ddoc=disabled"
      ];
    });
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

  # Fix inetutils format-security compilation errors on macOS
  # https://github.com/NixOS/nixpkgs/issues/XXXXX
  inetutils = prev.inetutils.overrideAttrs (oldAttrs: {
    hardeningDisable = (oldAttrs.hardeningDisable or [ ]) ++ [ "format" ];
  });
})
