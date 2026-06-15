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

  # Fix inetutils format-security compilation errors on macOS
  # https://github.com/NixOS/nixpkgs/issues/XXXXX
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
