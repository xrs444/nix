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
  "gobject-introspection-unwrapped" = prev."gobject-introspection-unwrapped".overrideAttrs (oldAttrs: {
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
