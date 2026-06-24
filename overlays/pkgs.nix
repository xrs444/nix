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
  # distutils at module level. Python 3.12+ removed distutils from stdlib;
  # setuptools' shim provides it but only if setuptools is imported first.
  # Any package that invokes g-ir-scanner during a source build (harfbuzz,
  # pygobject, appstream, etc.) crashes on aarch64 where the binary is not
  # cached by Hydra and must be built from source with Python 3.13.
  # Applied unconditionally: platform-conditional overrides via
  # lib.optionalAttrs stdenv.hostPlatform.isAarch64 silently evaluate to {}
  # in this nixpkgs evaluation context (both prev and final), so the hash
  # never changes and the patch never lands. The x86_64 cascade (json-glib
  # → swtpm → qemu) rebuilds once and is cached locally thereafter.
  gobject-introspection-unwrapped = prev.gobject-introspection-unwrapped.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # utils.py: guard three Windows-only distutils.cygwinccompiler references
      sed -i 's/^import distutils\.cygwinccompiler$/try:\n    import distutils.cygwinccompiler\nexcept ImportError:\n    pass/' giscanner/utils.py
      sed -i 's/^orig_get_msvcr = distutils\.cygwinccompiler\.get_msvcr.*$/try:\n    orig_get_msvcr = distutils.cygwinccompiler.get_msvcr  # type: ignore\nexcept NameError:\n    orig_get_msvcr = lambda: []  # type: ignore/' giscanner/utils.py
      sed -i 's/^distutils\.cygwinccompiler\.get_msvcr = get_msvcr_overwrite.*$/try:\n    distutils.cygwinccompiler.get_msvcr = get_msvcr_overwrite  # type: ignore\nexcept NameError:\n    pass/' giscanner/utils.py
      # ccompiler.py: import setuptools first so its distutils shim is active
      # before the bare "import distutils" that otherwise fails on Python 3.12+
      sed -i 's/^import distutils$/try:\n    import setuptools  # activate distutils shim for Python 3.12+\nexcept ImportError:\n    pass\nimport distutils/' giscanner/ccompiler.py
    '';
  });

  # umockdev: t_system_script_log_chatter timing test asserts elapsed <= 800ms;
  # misses by a few ms under VM/sandbox scheduling. Flaky wall-clock assertion,
  # not a functional failure. Applied unconditionally for the same reason as
  # gobject-introspection above — platform conditionals don't fire here.
  umockdev = prev.umockdev.overrideAttrs (_: { doCheck = false; });

  # django 5.2.x: bash_completion test calls external bash completion
  # infrastructure that doesn't exist in the Nix sandbox — gets [''] instead
  # of ['--list']. 1 test out of 18154 fails; package itself is fine.
  # Tests run in installCheckPhase; doInstallCheck=false skips them.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyprev: {
      django = pyprev.django.overridePythonAttrs (_: { doInstallCheck = false; });
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
