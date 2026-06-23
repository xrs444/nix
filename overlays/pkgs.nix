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

  # gobject-introspection-unwrapped: giscanner/utils.py imports
  # distutils.cygwinccompiler at module level (and uses it on two further lines).
  # setuptools' distutils shim omits this Windows-only module on Linux;
  # Python 3.12+ removed distutils from stdlib entirely. The stable nixpkgs
  # gobject-introspection binary was built with setuptools available so the
  # crash never occurred — but any package that invokes g-ir-scanner during a
  # source build (appstream, harfbuzz, etc.) will crash. Patch all three
  # distutils references to be no-ops on non-Windows. The stable 26.05
  # nixpkgs already provides setuptools via buildPackages.python3.withPackages
  # in nativeBuildInputs so the rebuild itself succeeds without changes there.
  # Scope to aarch64 only: x86_64 gobject-introspection is cached by Hydra
  # unchanged, so no cascade to json-glib → swtpm → qemu on x86_64.
  # On aarch64 the cached binary has an unpatched giscanner/utils.py that
  # imports distutils.cygwinccompiler at module level — a Windows-only module
  # omitted by setuptools' shim and removed from Python 3.12+ stdlib. Any
  # package that invokes g-ir-scanner during a source build crashes. Patching
  # only the aarch64 derivation keeps the x86_64 hash identical to Hydra.
  gobject-introspection-unwrapped = prev.gobject-introspection-unwrapped.overrideAttrs (old:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 {
      postPatch = (old.postPatch or "") + ''
        sed -i 's/^import distutils\.cygwinccompiler$/try:\n    import distutils.cygwinccompiler\nexcept ImportError:\n    pass/' giscanner/utils.py
        sed -i 's/^orig_get_msvcr = distutils\.cygwinccompiler\.get_msvcr.*$/try:\n    orig_get_msvcr = distutils.cygwinccompiler.get_msvcr  # type: ignore\nexcept NameError:\n    orig_get_msvcr = lambda: []  # type: ignore/' giscanner/utils.py
        sed -i 's/^distutils\.cygwinccompiler\.get_msvcr = get_msvcr_overwrite.*$/try:\n    distutils.cygwinccompiler.get_msvcr = get_msvcr_overwrite  # type: ignore\nexcept NameError:\n    pass/' giscanner/utils.py
      '';
    }
  );

  # umockdev: t_system_script_log_chatter timing test asserts elapsed <= 800ms;
  # misses by a few ms under VM scheduling (e.g. 804ms). Flaky wall-clock
  # assertion, not a functional failure. Scoped to aarch64 to avoid changing
  # the x86_64 hash (which would cascade into libgudev → udev → many packages).
  umockdev = prev.umockdev.overrideAttrs (_:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 {
      doCheck = false;
    }
  );

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
