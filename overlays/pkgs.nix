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

  # zram-generator: test_cases calls unshare(NEWUSER) which returns EINVAL under
  # QEMU aarch64 cross-compilation. The process aborts with SIGABRT. The binary
  # itself is fine; the test exercises kernel namespace APIs that QEMU user-mode
  # does not implement.
  zram-generator = prev.zram-generator.overrideAttrs (_: { doCheck = false; });

  # grafana-alloy: otel_engine test binary is too large to link on the CI
  # builder's tmpfs — Go linker fails with "no space left on device" during
  # checkPhase. The binary builds and runs correctly; only the test link fails.
  grafana-alloy = prev.grafana-alloy.overrideAttrs (_: { doCheck = false; });

  # umockdev: t_system_script_log_chatter timing test asserts elapsed <= 800ms;
  # the sandbox build environment misses by a few ms (e.g. 804ms) due to load
  # variance. This is a flaky wall-clock assertion, not a functional failure.
  umockdev = prev.umockdev.overrideAttrs (_: { doCheck = false; });

  # sdl3: testrwlock (test #11) times out in any VM environment — the test has a
  # hardcoded deadline calibrated for physical hardware; VM thread scheduling
  # (whether QEMU-emulated or native aarch64 VM) adds enough overhead to miss it.
  # Hydra's aarch64 builders are also VM-based, so sdl3 is never cached at our
  # nixpkgs pin. doCheck=false alone doesn't work because sdl3 uses CMake and
  # test targets are compiled unconditionally; -DSDL_TESTS=OFF prevents them from
  # being compiled at all. xlt1-t-vnixos (native aarch64 VM) builds this once and
  # pushes to nixcache.xrs444.net so no other host ever needs to rebuild it.
  sdl3 = prev.sdl3.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DSDL_TESTS=OFF" ];
    postInstall = (old.postInstall or "") + ''
      mkdir -p $installedTests
    '';
  });

  # pipx 1.8.0: test_package_specifier assertions expect old PEP 508 format
  # (no space before @, e.g. "black@ https://...") but Python 3.13's specifier
  # normalizer emits the canonical form "black @ https://...". 7 tests fail.
  # Not a sandbox or functional issue — pure test expectation drift.
  # pipx tests run in installCheckPhase (pytest-check-hook), not checkPhase.
  # checkPhase = ":" handles the standard check gate; doInstallCheck = false
  # disables the install-check phase that actually invokes pytest.
  pipx = prev.pipx.overrideAttrs (_: { checkPhase = ":"; doInstallCheck = false; });

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

  # Bypass the lib.warnOnInstantiate wrapper added to linux-rpi kernels in nixpkgs 26.05.
  # nixpkgs wraps linux_rpi4 (and linux_rpi{1,2,3}) with a deprecation warning that fires
  # whenever any attribute of the derivation is accessed. Our RPi4/5 hardware modules and
  # nixos-hardware's own RPi4 module both reference pkgs.linuxKernel.packages.linux_rpi4,
  # which triggers the warning transitively via linuxKernel.kernels.linux_rpi4.
  # Rebuilding via callPackage here produces the same derivation (same hash, same cache hits)
  # but without the evaluation-time warning. The override also fixes pkgs.linux_rpi4.override
  # used by our RPi5 module.
  linux_rpi4 = final.callPackage "${inputs.nixpkgs}/pkgs/os-specific/linux/kernel/linux-rpi.nix" {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 4;
  };
  linuxKernel = prev.linuxKernel // {
    kernels = prev.linuxKernel.kernels // { linux_rpi4 = final.linux_rpi4; };
    packages = prev.linuxKernel.packages // {
      linux_rpi4 = final.linuxPackagesFor final.linux_rpi4;
    };
  };
})
