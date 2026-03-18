# Summary: Orange Pi vendor Linux kernel 6.1.31 with uwe5622 WiFi driver support
{
  lib,
  buildLinux,
  fetchgit,
  ...
}@args:

buildLinux (
  args
  // rec {
    version = "6.1.31-sun50iw9";
    modDirVersion = version;

    src = fetchgit {
      url = "https://github.com/orangepi-xunlong/linux-orangepi.git";
      rev = "f23614d875ba18f7eb5d4818fd0e92f9e536a99f";
      hash = "sha256-kVQOoBSaa3EPtFH/83Q8SavLzT8p+6vPSf2vfOpH3Uk=";
    };

    # Custom defconfig for sun50iw9 (H616/H618) with WiFi drivers enabled
    defconfig = "sun50iw9_defconfig";

    # Point to the defconfig in this directory
    structuredExtraConfig = with lib.kernel; {
      # The defconfig file handles most configuration
      # These patches will fix deterministic build issues
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

    # Copy our custom defconfig to the kernel source
    preConfigure = ''
      cp ${./sun50iw9_defconfig} arch/arm64/configs/sun50iw9_defconfig
    '';

    extraMeta.branch = "6.1";
  }
  // (args.argsOverride or { })
)
