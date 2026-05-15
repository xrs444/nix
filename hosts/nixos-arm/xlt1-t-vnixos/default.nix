# Summary: NixOS ARM host configuration for xlt1-t-vnixos, imports hardware, disk, and desktop modules.
{
  hostname,
  platform,
  ...
}:
{
  # xlt1-t-vnixos-specific package overrides
  # Disable introspection for packages that fail under QEMU aarch64 emulation.
  # The gobject-introspection / Python 3.13 distutils fix is handled globally
  # in overlays/pkgs.nix (python3 override + distutils doCheck=false). We do
  # NOT re-patch gobject-introspection here — doing so creates a host-unique
  # derivation hash for glib that is not in any binary cache, forcing a rebuild
  # under QEMU which then fails because g-ir-scanner exits 1 in that environment.
  # Instead we rely on the global overlay's gobject-introspection (same hash as
  # xts1/xts2/xpbx1) which is already in the local nixcache from prior CI runs.
  nixpkgs.overlays = [
    (final: prev: {
      # Fix gtk4 distutils error by disabling introspection
      gtk4 = prev.gtk4.overrideAttrs (oldAttrs: {
        outputs = builtins.filter (x: x != "devdoc") oldAttrs.outputs;
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddocumentation=false"
        ];
      });

      # Fix libadwaita distutils error by disabling introspection
      libadwaita = prev.libadwaita.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddocumentation=false"
        ];
      });

      # Fix gst-plugins-bad distutils error by disabling introspection
      gst_all_1 = prev.gst_all_1.overrideScope (gself: gsuper: {
        gst-plugins-bad = gsuper.gst-plugins-bad.overrideAttrs (oldAttrs: {
          mesonFlags = (oldAttrs.mesonFlags or []) ++ [
            "-Dintrospection=disabled"
            "-Ddoc=disabled"
          ];
        });
      });

      # Fix gnome-desktop distutils error by disabling introspection
      gnome-desktop = prev.gnome-desktop.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
        ];
      });

      # Fix libsecret distutils error by disabling introspection
      # NOTE: libsecret uses `type: 'boolean'` for introspection in meson.build;
      # meson 1.9.1 enforces this strictly — 'disabled' is rejected. Use false.
      libsecret = prev.libsecret.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=false"
          "-Dgtk_doc=false"
        ];
      });

      # Fix gcr distutils error by disabling introspection
      # gcr also uses `type: 'boolean'` for introspection — use false, not 'disabled'.
      gcr = prev.gcr.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=false"
          "-Dgtk_doc=false"
        ];
      });

      # Fix wireplumber missing lxml module by disabling documentation
      wireplumber = prev.wireplumber.overrideAttrs (oldAttrs: {
        mesonFlags = builtins.map
          (flag: if flag == "-Ddoc=enabled" then "-Ddoc=disabled" else flag)
          (oldAttrs.mesonFlags or []);
      });
    })
  ];

  imports = [
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ./disks.nix
    ./desktop.nix
    #    ./network.nix
    ../../common
  ];

  nixpkgs.hostPlatform = platform;

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;
}
