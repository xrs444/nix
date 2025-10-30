# NixOS ARM Common Configuration

This directory contains common configuration modules for NixOS ARM systems.

## Files

- `default.nix` - Main common configuration module that imports other common modules
- `boot.nix` - Boot loader and kernel configuration optimized for ARM systems
- `performance.nix` - Performance and power management settings for ARM platforms

## ARM-Specific Considerations

### Boot Configuration
- Many ARM systems don't support UEFI/systemd-boot and require specific boot loaders
- SD card and eMMC storage is common, requiring appropriate kernel modules
- Console configuration may need adjustment for serial consoles

### Performance
- Power efficiency is often more important than peak performance
- Memory is often more limited, so zswap/zram can be beneficial
- CPU governors like "ondemand" or "schedutil" are often preferred over "performance"

### Hardware Support
- GPIO and device tree considerations for single-board computers
- Different storage interfaces (SD, eMMC, SATA, NVMe)
- Various network interfaces and wireless modules

## Usage

These common modules are automatically imported by the main nixos-arm configuration and provide sensible defaults that can be overridden by specific host configurations.