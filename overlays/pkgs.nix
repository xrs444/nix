{ inputs, ... }:
(final: prev: {
  # Fix libsecret test failures in sandboxed builds
  # https://github.com/NixOS/nixpkgs/issues/370724
  libsecret = prev.libsecret.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  # Fix python3.13-distutils test_concurrent_safe failure in sandboxed builds
  # test_msvccompiler::TestSpawn::test_concurrent_safe fails with "can't start new thread"
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pfinal: pprev: {
      distutils = pprev.distutils.overrideAttrs (oldAttrs: {
        doCheck = false;
      });
    })
  ];
})
