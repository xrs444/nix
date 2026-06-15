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

  # Fix sdl3 testrwlock timeout in sandboxed / QEMU builds.
  # Tests run via CMake (not checkPhase), so doCheck=false alone doesn't help.
  # -DSDL_TESTS=OFF prevents tests from being compiled at all. The postInstall
  # creates the empty installedTests output path that the derivation declares.
  sdl3 = prev.sdl3.overrideAttrs (oldAttrs: {
    cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
      "-DSDL_TESTS=OFF"
    ];
    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $installedTests
    '';
  });

  # The following packages are NOT available in cache.nixos.org for aarch64 at
  # our nixpkgs pin (verified: they appear in "will be built" not "will be fetched"
  # during nixos-install). When built from source, their tests fail in the Nix
  # sandbox. doCheck=false restores upstream drv hash equivalence once Hydra
  # catches up, but avoids build failures until then.
  # Packages confirmed FROM cache (don't need doCheck=false): dconf, gupnp, flac.

  # libsecret: test-collection SIGABRT — requires D-Bus session bus
  # https://github.com/NixOS/nixpkgs/issues/370724
  libsecret = prev.libsecret.overrideAttrs (_: { doCheck = false; });

  # upower: self-test SIGABRT — requires D-Bus system bus + hardware access
  upower = prev.upower.overrideAttrs (_: { doCheck = false; });

  # xdg-desktop-portal: USB test failure — requires D-Bus USB device session
  xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs (_: { doCheck = false; });

  # tinysparql: test_notifier SIGABRT — requires D-Bus notification infrastructure
  tinysparql = prev.tinysparql.overrideAttrs (_: { doCheck = false; });

  # gtkmm3/gtkmm4: tests require live display server (X11/Wayland)
  gtkmm3 = prev.gtkmm3.overrideAttrs (_: { doCheck = false; });
  gtkmm4 = prev.gtkmm4.overrideAttrs (_: { doCheck = false; });

  # nbd: TLS test timeouts — real TLS socket timing doesn't work in sandbox
  nbd = prev.nbd.overrideAttrs (_: { doCheck = false; });

  # openvswitch: requires real network interfaces / kernel modules
  openvswitch = prev.openvswitch.overrideAttrs (_: { doCheck = false; });

  # swtpm: requires softhsm2 not available in nix sandbox
  swtpm = prev.swtpm.overrideAttrs (_: { doCheck = false; });

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
