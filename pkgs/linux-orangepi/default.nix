# Summary: Orange Pi vendor Linux kernel 6.1.31 with uwe5622 WiFi driver support
{
  lib,
  buildLinux,
  fetchgit,
  ...
}@args:

buildLinux (
  args
  // {
    version = "6.1.31-sun50iw9-noalt";  # -noalt: Altera platform disabled
    modDirVersion = "6.1.31";  # Must match actual kernel version

    src = fetchgit {
      url = "https://github.com/orangepi-xunlong/linux-orangepi.git";
      rev = "f23614d875ba18f7eb5d4818fd0e92f9e536a99f";
      hash = "sha256-kVQOoBSaa3EPtFH/83Q8SavLzT8p+6vPSf2vfOpH3Uk=";
    };

    # Point directly to our custom defconfig file
    kernelBaseConfig = ./sun50iw9_defconfig;

    # Don't build device tree blobs - NixOS handles these separately
    installsDtbs = false;

    # Make DTB warnings non-fatal
    makeFlags = [ "DTC_FLAGS=-Wno-error" ];

    # Additional kernel configuration overrides
    structuredExtraConfig = with lib.kernel; {
      # The base defconfig file handles most configuration
      # Disable Altera/Intel SoCFPGA platform to skip problematic Altera DTBs
      ARCH_INTEL_SOCFPGA = lib.mkForce no;
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
