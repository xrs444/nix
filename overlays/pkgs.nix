{ inputs, ... }:
(final: prev: {
  # Fix libsecret test failures in sandboxed builds
  # https://github.com/NixOS/nixpkgs/issues/370724
  libsecret = prev.libsecret.overrideAttrs (oldAttrs: {
    doCheck = false;
  });
})
