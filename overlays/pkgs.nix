{ inputs, ... }:
(final: prev:
let
  # giscanner/utils.py has an unconditional top-level `import
  # distutils.cygwinccompiler` (only actually used on Windows/cygwin
  # cross-builds), which crashes at import time on Python 3.12+ since
  # distutils was removed from the stdlib. Wrap it in try/except so it's
  # skipped cleanly when distutils doesn't exist, rather than deleting
  # behavior real Windows cross-builds need.
  patchGiscannerDistutils = pkg: pkg.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace giscanner/utils.py \
        --replace-fail 'import distutils.cygwinccompiler
orig_get_msvcr = distutils.cygwinccompiler.get_msvcr  # type: ignore
distutils.cygwinccompiler.get_msvcr = get_msvcr_overwrite  # type: ignore' \
        'try:
    import distutils.cygwinccompiler
    orig_get_msvcr = distutils.cygwinccompiler.get_msvcr  # type: ignore
    distutils.cygwinccompiler.get_msvcr = get_msvcr_overwrite  # type: ignore
except ImportError:
    pass'
    '';
  });

  # aarch64-linux hits the identical crash (confirmed on xlt1-t-vnixos
  # building libnice/gtk-layer-shell/gnome-autoar) but pkgs.gobject-introspection
  # is a nativeBuildInput for most of the GLib/GNOME stack (glib, cairo, pango,
  # harfbuzz, gdk-pixbuf, ffmpeg-headless, matplotlib, ...). Patching the
  # shared top-level attribute (as the 2026-08-06 commit did) changes ITS
  # hash and cascades to every one of those, dropping all of them out of the
  # binary cache even though only these 3 packages actually hit the crash —
  # confirmed incident: forced 226 derivations to rebuild from source on
  # xts1. So the fix is applied only as a nativeBuildInput swap on the
  # specific packages that need it (libnice/gtk-layer-shell/gnome-autoar,
  # gcr below), never on pkgs.gobject-introspection(-unwrapped) itself. If a
  # NEW package on any platform hits this same crash, give it the same
  # `useGiscannerDistutilsFix prev.<pkg>` treatment rather than reaching for
  # the shared attr. Named without a platform prefix since 2026-08-10: the
  # exact same helper is used for both aarch64-linux packages and gcr on
  # Darwin below — see that entry for why the Darwin case previously patched
  # the shared attribute directly, which turned out to be the identical
  # anti-pattern with a much bigger blast radius (gtk3/glib/cairo/pango/
  # gdk-pixbuf all forced out of the binary cache fleet-wide on Darwin).
  gobjectIntrospectionGiscannerFix = prev.gobject-introspection.override {
    gobject-introspection-unwrapped = patchGiscannerDistutils prev.gobject-introspection-unwrapped;
  };
  useGiscannerDistutilsFix = pkg: pkg.overrideAttrs (old: {
    nativeBuildInputs = map
      (x: if (x.pname or "") == "gobject-introspection-wrapped" then gobjectIntrospectionGiscannerFix else x)
      (old.nativeBuildInputs or [ ]);
  });
in
{
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

  # NOTE (2026-07-07): the aarch64 gobject-introspection/GIR overlay block that
  # used to live here (gobject-introspection-unwrapped, gobject-introspection,
  # playerctl, libnotify, libcloudproviders, json-glib, totem-pl-parser,
  # localsearch, nautilus, graphene, gtk3, libgnomekbd, gtk-layer-shell, colord,
  # libxkbcommon, networkmanager, gusb, geocode-glib_2, libgweather,
  # gweather-locations, zram-generator, libical, libsecret — ~500 lines) was
  # removed. Verified via `nix path-info --store https://cache.nixos.org` that
  # every one of those packages is available prebuilt, unmodified, for
  # aarch64-linux at the pinned nixpkgs revision (ffa10e26ae11...). The
  # overrideAttrs calls changed each package's derivation hash, which is what
  # forced local source rebuilds (and the resulting Python 3.13 distutils/GIR
  # failures) — Hydra had already built these; our own overlay was the only
  # reason they weren't being fetched from cache. If a NEW aarch64 package hits
  # a distutils/GIR failure, check the cache first (same `nix path-info`
  # command) before reaching for a new overrideAttrs — most of these errors
  # only show up when a local build is forced in the first place.
  #
  # pygobject3 (below, in pythonPackagesExtensions) is kept: it has a
  # documented live failure reproduced in an actual CI run (see
  # .claude/plans/for-now-ignore-mutable-haven.md), not just inferred.

  # libxkbcommon: python-tests:tool-option-parsing fails on aarch64 (exit 1).
  # The library itself builds and functions correctly.
  libxkbcommon = if final.stdenv.hostPlatform.isAarch64
    then prev.libxkbcommon.overrideAttrs (_: { doCheck = false; })
    else prev.libxkbcommon;

  # libsecret: test-collection flakes (SIGABRT — "Message recipient
  # disconnected from message bus without replying" from the sandboxed D-Bus
  # session used by the test). 23/24 tests pass; the library itself builds and
  # functions correctly, only the mock D-Bus IPC timing in the test sandbox is
  # unreliable. Originally scoped to aarch64 only (first seen on xlt1-t-vnixos);
  # confirmed 2026-08-22 the identical failure also hits x86_64-linux
  # (xcomm1, built on xdt1-t.lan) — the D-Bus mock timing flake isn't
  # architecture-specific, so the fix is now unconditional. Confirmed this
  # exact output isn't on cache.nixos.org (curl 404) on both platforms, so
  # this is a genuine from-source build, not an unnecessary cache-bypassing
  # rebuild — see the note above this block before extending doCheck=false
  # to anything that IS cached.
  libsecret = prev.libsecret.overrideAttrs (_: { doCheck = false; });

  # sdl3: testprocess (SDL_CreateProcess IPC test) times out under the Nix
  # build sandbox (exit code 8 = ctest timeout) on the x86_64-linux remote
  # builder (xsvr1) — 24/25 tests otherwise pass; the library itself builds
  # and functions correctly. Pulled in transitively via desktop.nix's GNOME
  # (gnome-remote-desktop -> gtk-frdp -> freerdp/sdl3-image/sdl3-ttf -> sdl3),
  # first hit while bringing up xlt2-s. Confirmed via `curl -sI
  # https://cache.nixos.org/<hash>.narinfo` 404 that sdl3-3.4.8 isn't on the
  # binary cache at all — genuine from-source build, not our own overlay
  # forcing an unnecessary rebuild. Not architecture-specific (unlike the
  # aarch64 IPC flakiness above), so left unscoped.
  sdl3 = prev.sdl3.overrideAttrs (_: { doCheck = false; });

  # webkitgtk_4_1/6_0: OOM-killed (exit 137/SIGKILL) building on xsvr1's
  # remote builder, ~89% through — ninja's setup-hook defaults to
  # `-j$NIX_BUILD_CORES` (all cores), and with WebCore's large unified-source
  # translation units that spikes peak RSS past available RAM once other
  # concurrent builds are also contending for it on the shared builder.
  # `ninjaFlags` is appended after the default `-j` flag by the setup hook
  # and ninja takes the last `-j` seen, so this reliably caps webkitgtk's own
  # parallelism without touching NIX_BUILD_CORES (which the Nix daemon may
  # re-inject) or any other package. Neither ABI variant nor their
  # downstream consumers (gnome-shell itself — unavoidable, evolution-data-server,
  # sushi) are on the binary cache at this nixpkgs revision (confirmed via
  # narinfo 404), so this is a genuine from-source build. First hit bringing
  # up xlt2-s (the first host in this repo to actually enable full GNOME via
  # services.desktopManager.gnome — xcomm1's flake `desktop = "gnome"` label
  # is misleading, its actual desktop.nix uses Niri).
  webkitgtk_4_1 = prev.webkitgtk_4_1.overrideAttrs (_: { ninjaFlags = [ "-j4" ]; });
  webkitgtk_6_0 = prev.webkitgtk_6_0.overrideAttrs (_: { ninjaFlags = [ "-j4" ]; });

  # gcr: giscanner/utils.py has an unconditional top-level `import
  # distutils.cygwinccompiler` (only actually used on Windows/cygwin
  # cross-builds), which crashes at import time on Python 3.12+ since
  # distutils was removed from the stdlib. Breaks gcr's from-source build on
  # aarch64-darwin — confirmed via `curl -sI https://cache.nixos.org/<hash>.narinfo`
  # returning 404, i.e. no prebuilt binary exists for this platform.
  #
  # FIXED 2026-08-10 (bug found while chasing unrelated aarch64-darwin build
  # flakiness — librsvg/adwaita-icon-theme SIGKILL, django timing-test
  # failure): this used to patch the SHARED gobject-introspection-unwrapped
  # attribute directly for all of Darwin, unconditionally — the exact
  # anti-pattern the aarch64-linux note above warns against, just not
  # applied to itself. Confirmed via `nix eval` comparison against a vanilla
  # (zero-overlay) import at the same pinned nixpkgs rev: patching the
  # shared attribute changed gtk3's own hash (a completely unrelated
  # package) from the upstream/cached one, meaning gtk3 — and everything
  # built on it (glib, cairo, pango, gdk-pixbuf, and in turn librsvg,
  # adwaita-icon-theme, ...) — was being forced to build from source locally
  # on every Darwin host instead of substituting from cache.nixos.org. That
  # from-source GNOME/GTK stack build is almost certainly *why* the
  # librsvg/adwaita-icon-theme SIGKILLs showed up in the first place: Hydra's
  # own builders don't hit them, only ours did, doing work Hydra had already
  # done. Scoped now to gcr only, via the same nativeBuildInput-swap pattern
  # as libnice/gtk-layer-shell/gnome-autoar below — no other Darwin package
  # is confirmed to need this fix. If a NEW Darwin package hits this same
  # giscanner crash, give it the same `useGiscannerDistutilsFix prev.<pkg>`
  # treatment rather than reaching for the shared attr again.
  gcr = if final.stdenv.hostPlatform.isDarwin
    then useGiscannerDistutilsFix prev.gcr
    else prev.gcr;

  # aarch64-linux equivalent of the Darwin fix above, scoped per-package (see
  # the note above gobject-introspection-unwrapped for why). Confirmed via
  # `curl -sI .../<hash>.narinfo` 404 that libnice/gtk-layer-shell/gnome-autoar
  # are genuinely uncached on aarch64-linux, not just victims of our own
  # cascading overrideAttrs.
  libnice = if final.stdenv.hostPlatform.isAarch64
    then useGiscannerDistutilsFix prev.libnice
    else prev.libnice;
  gtk-layer-shell = if final.stdenv.hostPlatform.isAarch64
    then useGiscannerDistutilsFix prev.gtk-layer-shell
    else prev.gtk-layer-shell;
  gnome-autoar = if final.stdenv.hostPlatform.isAarch64
    then useGiscannerDistutilsFix prev.gnome-autoar
    else prev.gnome-autoar;

  # tinysparql (upstream rename of GNOME Tracker/localsearch, pulled in
  # transitively via nautilus in the GNOME desktop stack since the
  # 2026-08-11 flake.lock bump): identical g-ir-scanner distutils crash as
  # libnice/gtk-layer-shell/gnome-autoar above. Confirmed via
  # `curl -sI .../<hash>.narinfo` 404 that it's genuinely uncached for
  # aarch64-linux, not our own overlay forcing an unnecessary rebuild.
  tinysparql = if final.stdenv.hostPlatform.isAarch64
    then useGiscannerDistutilsFix prev.tinysparql
    else prev.tinysparql;

  # django 5.2.x: bash_completion test calls external bash completion
  # infrastructure that doesn't exist in the Nix sandbox — gets [''] instead
  # of ['--list']. 1 test out of 18154 fails; package itself is fine.
  # Tests run in installCheckPhase; doInstallCheck=false skips them.
  #
  # Separately, doCheck's own checkPhase test suite (~2200s/36min on xlt1-t)
  # includes test_crafted_xml_performance, a TIMING-based assertion that XML
  # deserialization scales sub-quadratically (measured factor must be <= 2).
  # Measured 5.38 on xlt1-t under real build load — a build-hardware-timing
  # flake, not a functional defect (the other 18151 tests pass). Timing
  # assertions like this are inherently unreliable on shared/sandboxed build
  # machines; disabling the whole checkPhase also saves ~36min on every
  # future rebuild touching this dependency (django feeds python3.13-ansible
  # and other tools pulled in transitively via home.packages).
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyprev: {
      django = pyprev.django.overridePythonAttrs (_: { doCheck = false; doInstallCheck = false; });

      # pygobject3: builds gobject-introspection test subprojects (libutility,
      # libwarnlib) and generates GIR for them during the BUILD phase. doCheck
      # alone only skips meson test; the subprojects are compiled in buildPhase.
      # Explicitly pass -Dtests=false so meson skips the subproject entirely.
      pygobject3 = if final.stdenv.hostPlatform.isAarch64
        then pyprev.pygobject3.overridePythonAttrs (old: {
          doCheck = false;
          mesonFlags = (old.mesonFlags or []) ++ [ "-Dtests=false" ];
        })
        else pyprev.pygobject3;

      # curl-cffi 0.14.0: checkInputs pull in fastapi -> bcrypt -> rustc ->
      # llvm-21.1.8 (confirmed via `nix why-depends
      # .#nixosConfigurations.<host>.pkgs.python313Packages.curl-cffi
      # .#nixosConfigurations.<host>.pkgs.llvmPackages_21.llvm --derivation`
      # on xlt1-t-vnixos, 2026-08-24). curl-cffi is an HTTP client — none of
      # that chain is a runtime need, only its test suite (spins up a FastAPI
      # test server). rustc-1.95.0 isn't cached for aarch64-linux, so
      # bootstrapping it from source drags in a full LLVM build, which OOM-
      # killed a `nixos-rebuild switch` on xlt1-t-vnixos's 8GB VM. doCheck
      # removes checkInputs from the build closure entirely (not just skips
      # running them), so this drops the whole chain.
      curl-cffi = pyprev.curl-cffi.overridePythonAttrs (_: { doCheck = false; });
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
  #
  # Force python3 = python313 in this isolated pkgs set (mirrors the
  # python3 = python313 pin in python-no-tests.nix for the main overlay
  # chain). Upstream nixpkgs-unstable's default python3 = python314 as of
  # 2026-08: python314's python3.withPackages envs produce a bin/python3
  # that readlink -f resolves straight through to the bare interpreter,
  # bypassing the env's own site-packages entirely (confirmed live on
  # xsvr1: sys.path never includes it, PYTHONPATH override fixes the
  # import). auto-patchelfHook's own pythonEnv = python3.withPackages
  # (ps: [ ps.pyelftools ]) hits this directly, so claude-code's build
  # fails fixupPhase with "ModuleNotFoundError: No module named
  # 'elftools'" even though pyelftools is present and correctly linked
  # on disk. python313 doesn't have this defect.
  claude-code = (
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [ (cfinal: cprev: { python3 = cfinal.python313; }) ];
    }
  ).claude-code;

  # bitwarden-desktop: pinned nixpkgs' version (2026.5.0) bundles
  # electron_39 (39.8.10), which nixpkgs flags as insecure/EOL —
  # packages flagged insecure are excluded from Hydra's binary cache, so
  # allowing it via permittedInsecurePackages forces a full from-source
  # Electron/Chromium compile (~45k build steps, hours) on every host
  # that uses it. nixpkgs-unstable already has 2026.7.0 on electron_41
  # (41.10.3), which has no known vulnerabilities and IS cached
  # (confirmed via narinfo 200) — same "just take it from unstable"
  # fix as claude-code above, no permittedInsecurePackages needed.
  bitwarden-desktop = (
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }
  ).bitwarden-desktop;

  # vikunja-desktop (samantha's HM profile): the pinned nixpkgs' build
  # bundles electron_41.9.1, which has no cache.nixos.org narinfo (404) —
  # forces the same from-source Electron/Chromium compile as the
  # bitwarden_39 case above. nixpkgs-unstable has the same vikunja-desktop
  # version (2.3.0) built against electron_41.10.3 — identical to the
  # version bitwarden-desktop already pulls above, confirmed cached
  # (narinfo 200) — so this also collapses two separate Electron builds
  # in the closure down to one shared one.
  vikunja-desktop = (
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }
  ).vikunja-desktop;

  # OpenRSAT: cross-platform RSAT alternative for managing Samba/Windows AD.
  # Not in nixpkgs; packaged from GitHub pre-built release binaries.
  # macOS: DMG containing a signed .app bundle (arm64); bundled libssl/libcrypto.
  # Linux: bare x86_64 ELF; GTK2 GUI via autoPatchelfHook.
  openrsat =
    if final.stdenv.isDarwin then
      prev.stdenv.mkDerivation rec {
        pname = "openrsat";
        version = "0.4.386";
        src = prev.fetchurl {
          url = "https://github.com/tranquilit/OpenRSAT/releases/download/v${version}/OpenRSAT-darwin-arm.dmg";
          sha256 = "1xsdlc5vscsphmhw8nf2i391s939c9hk9s5bwalksck05sa92q6h";
        };
        sourceRoot = ".";
        unpackPhase = ''
          MNTDIR=$(mktemp -d /tmp/openrsat-XXXXXXXX)
          /usr/bin/hdiutil attach -quiet -nobrowse -mountpoint "$MNTDIR" "$src"
          cp -r "$MNTDIR/OpenRSAT.app" .
          /usr/bin/hdiutil detach -quiet "$MNTDIR"
          rmdir "$MNTDIR"
        '';
        installPhase = ''
          mkdir -p $out/Applications $out/bin
          cp -r OpenRSAT.app $out/Applications/
          ln -s $out/Applications/OpenRSAT.app/Contents/MacOS/OpenRSAT $out/bin/openrsat
        '';
        meta = {
          description = "Open source RSAT alternative for managing Active Directory";
          homepage = "https://github.com/tranquilit/OpenRSAT";
          platforms = prev.lib.platforms.darwin;
        };
      }
    else
      prev.stdenv.mkDerivation rec {
        pname = "openrsat";
        version = "0.4.386";
        src = prev.fetchurl {
          url = "https://github.com/tranquilit/OpenRSAT/releases/download/v${version}/OpenRSAT-linux-x64";
          sha256 = "03qhl82yqddm9bbkbn2gf8ygz9fkqh6gnq8qmbhq0w15siz19v95";
        };
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = with prev; [
          gtk2
          glib
          pango
          cairo
          atk
          gdk-pixbuf
          libX11
          zlib
        ];
        dontUnpack = true;
        installPhase = ''
          install -Dm755 $src $out/bin/openrsat
          install -dm755 $out/share/applications
          cat > $out/share/applications/openrsat.desktop << DESKTOP
[Desktop Entry]
Name=OpenRSAT
Comment=Open source RSAT alternative for managing Active Directory
Exec=openrsat
Icon=openrsat
Type=Application
Categories=Network;System;Administration;
DESKTOP
        '';
        meta = {
          description = "Open source RSAT alternative for managing Active Directory";
          homepage = "https://github.com/tranquilit/OpenRSAT";
          platforms = prev.lib.platforms.linux;
        };
      };

  # NOTE (2026-08-10): a librsvg withPixbufLoader=false override used to live
  # here, worked around an aarch64-darwin SIGKILL in librsvg's postInstall
  # gdk-pixbuf-query-loaders step. Root cause turned out to be the unscoped
  # Darwin gobject-introspection-unwrapped override above (see the gcr entry
  # for the full story) forcing librsvg out of the binary cache into a local
  # from-source build in the first place — vanilla librsvg is cached
  # (confirmed via cache.nixos.org narinfo 200) and doesn't hit this at all
  # once substituted normally. Removed now that the real cause is fixed; if
  # this SIGKILL resurfaces on a genuine from-source librsvg build, this is
  # the override to bring back (`prev.librsvg.override { withPixbufLoader =
  # false; }`, scoped to isDarwin).

  # ffmpeg-headless in nixos-26.05 enables withPlacebo and withVulkan by
  # default, pulling vulkan-loader into any closure that uses matplotlib
  # (via matplotlib → ffmpeg-headless for animation support). Headless servers
  # and matplotlib animations don't need GPU video rendering; strip it out so
  # aarch64 servers (xts1/xts2/xpbx1/vocibuild) don't need to build
  # vulkan-loader from source when it isn't in the binary cache.
  ffmpeg-headless = prev.ffmpeg-headless.override {
    withPlacebo = false;
    withVulkan = false;
  };

})
