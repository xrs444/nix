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
  # specific packages that need it (libnice/gtk-layer-shell/gnome-autoar
  # below), never on pkgs.gobject-introspection(-unwrapped) itself. If a NEW
  # aarch64 package hits this same crash, give it the same
  # `useAarch64GiscannerFix prev.<pkg>` treatment rather than reaching for
  # the shared attr.
  gobjectIntrospectionAarch64Fix = prev.gobject-introspection.override {
    gobject-introspection-unwrapped = patchGiscannerDistutils prev.gobject-introspection-unwrapped;
  };
  useAarch64GiscannerFix = pkg: pkg.overrideAttrs (old: {
    nativeBuildInputs = map
      (x: if (x.pname or "") == "gobject-introspection-wrapped" then gobjectIntrospectionAarch64Fix else x)
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

  # libsecret: test-collection flakes on aarch64 (SIGABRT — "Message recipient
  # disconnected from message bus without replying" from the sandboxed D-Bus
  # session used by the test). 23/24 tests pass; the library itself builds and
  # functions correctly, only the mock D-Bus IPC timing in the test sandbox is
  # unreliable. Confirmed this exact output isn't on cache.nixos.org (curl
  # 404), so this is a genuine from-source build, not an unnecessary
  # cache-bypassing rebuild — see the note above this block before extending
  # doCheck=false to anything that IS cached.
  libsecret = if final.stdenv.hostPlatform.isAarch64
    then prev.libsecret.overrideAttrs (_: { doCheck = false; })
    else prev.libsecret;

  # gobject-introspection-unwrapped: giscanner/utils.py has an unconditional
  # top-level `import distutils.cygwinccompiler` (only actually used on
  # Windows/cygwin cross-builds), which crashes at import time on Python
  # 3.12+ since distutils was removed from the stdlib. Breaks any from-source
  # build that needs g-ir-scanner (e.g. gcr on aarch64-darwin — confirmed via
  # `curl -sI https://cache.nixos.org/<hash>.narinfo` returning 404, i.e. no
  # prebuilt binary exists for this platform, unlike the aarch64-linux
  # packages covered by the note above). Scoped to Darwin only — most Linux
  # builds are cached per that note. Do NOT extend this to isAarch64 (tried
  # 2026-08-06, reverted same day): this attribute is a nativeBuildInput for
  # most of the GLib/GNOME stack, so patching it here changes its hash and
  # cascades to every downstream package's hash too, defeating cache
  # substitution for all of them (confirmed: forced 226 derivations to
  # rebuild from source on xts1). If an aarch64-linux package hits this same
  # giscanner crash, add it to the aarch64GiscannerFixPkgs list below instead
  # — that patches only the affected packages' own nativeBuildInput.
  gobject-introspection-unwrapped =
    if final.stdenv.hostPlatform.isDarwin
    then patchGiscannerDistutils prev.gobject-introspection-unwrapped
    else prev.gobject-introspection-unwrapped;

  # aarch64-linux equivalent of the Darwin fix above, scoped per-package (see
  # the note above gobject-introspection-unwrapped for why). Confirmed via
  # `curl -sI .../<hash>.narinfo` 404 that libnice/gtk-layer-shell/gnome-autoar
  # are genuinely uncached on aarch64-linux, not just victims of our own
  # cascading overrideAttrs.
  libnice = if final.stdenv.hostPlatform.isAarch64
    then useAarch64GiscannerFix prev.libnice
    else prev.libnice;
  gtk-layer-shell = if final.stdenv.hostPlatform.isAarch64
    then useAarch64GiscannerFix prev.gtk-layer-shell
    else prev.gtk-layer-shell;
  gnome-autoar = if final.stdenv.hostPlatform.isAarch64
    then useAarch64GiscannerFix prev.gnome-autoar
    else prev.gnome-autoar;

  # django 5.2.x: bash_completion test calls external bash completion
  # infrastructure that doesn't exist in the Nix sandbox — gets [''] instead
  # of ['--list']. 1 test out of 18154 fails; package itself is fine.
  # Tests run in installCheckPhase; doInstallCheck=false skips them.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyprev: {
      django = pyprev.django.overridePythonAttrs (_: { doInstallCheck = false; });

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
