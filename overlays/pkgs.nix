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
      postInstall = (old.postInstall or "") + ''
        wrapProgram "$dev/bin/g-ir-scanner" \
          --set SETUPTOOLS_USE_DISTUTILS local \
          --prefix PYTHONPATH : "${final.buildPackages.python3.pkgs.setuptools}/${final.buildPackages.python3.sitePackages}"
        patchShebangs "$dev/bin/.g-ir-scanner-wrapped"
      '';
    })
    else prev.gobject-introspection-unwrapped;


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
