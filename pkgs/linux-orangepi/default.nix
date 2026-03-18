# Summary: Orange Pi vendor Linux kernel 6.1.31 with uwe5622 WiFi driver support
{
  buildLinux,
  fetchgit,
  ...
}@args:

buildLinux (
  args
  // {
    version = "6.1.31-sun50iw9";
    modDirVersion = "6.1.31";  # Must match actual kernel version

    src = fetchgit {
      url = "https://github.com/orangepi-xunlong/linux-orangepi.git";
      rev = "f23614d875ba18f7eb5d4818fd0e92f9e536a99f";
      hash = "sha256-kVQOoBSaa3EPtFH/83Q8SavLzT8p+6vPSf2vfOpH3Uk=";
    };

    # Point directly to our custom defconfig file
    kernelBaseConfig = ./sun50iw9_defconfig;

    # Additional kernel configuration overrides
    structuredExtraConfig = {
      # The base defconfig file handles most configuration
      # Add any runtime overrides here if needed
    };

    # Patches to make uwe5622 WiFi driver build deterministically
    kernelPatches = [
      {
        name = "uwe5622-Makefile-remove-monkeying";
        patch = ./uwe5622-Makefile-remove-monkeying.patch;
      }
      {
        name = "uwe5622-unisocwcn-Makefile-remove-monkeying";
        patch = ./uwe5622-unisocwcn-Makefile-remove-monkeying.patch;
      }
      {
        name = "uwe5622-unisocwcn-wcn_boot.c-remove-monkeying";
        patch = ./uwe5622-unisocwcn-wcn_boot.c-remove-monkeying.patch;
      }
    ];

    extraMeta.branch = "6.1";
  }
  // (args.argsOverride or { })
)
