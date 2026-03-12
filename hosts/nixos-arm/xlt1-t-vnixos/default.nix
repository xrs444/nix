# Summary: NixOS ARM host configuration for xlt1-t-vnixos, imports hardware, disk, and desktop modules.
{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  config,
  ...
}:
{
  # xlt1-t-vnixos-specific package overrides
  # Disable introspection for packages that fail with Python 3.13 distutils
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

      # Fix gjs distutils error by disabling introspection
      gjs = prev.gjs.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddoc=disabled"
        ];
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
