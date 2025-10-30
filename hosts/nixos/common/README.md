# NixOS Common Modules

This directory contains common configuration modules that can be shared across NixOS hosts to reduce duplication and maintain consistency.

## Available Modules

### `default.nix`
Base NixOS configuration that includes common boot and performance settings. Automatically imported by the main NixOS configuration.

### `boot.nix`
Common boot configuration including:
- systemd-boot loader (enabled by default)
- EFI variables support
- Common kernel modules (xhci_pci, ahci, usbhid, usb_storage, sd_mod)

### `hardware-amd.nix`
AMD-specific hardware configuration including:
- AMD hardware modules from nixos-hardware
- AMD microcode updates
- KVM-AMD and AMDGPU kernel modules
- Platform set to x86_64-linux

### `hardware-intel.nix`
Intel-specific hardware configuration including:
- Intel hardware modules from nixos-hardware  
- KVM-Intel kernel modules
- Platform set to x86_64-linux

### `audio-pipewire.nix`
PipeWire audio configuration including:
- Disables PulseAudio
- Enables PipeWire with ALSA and PulseAudio compatibility
- Disables rtkit (forced)

### `performance.nix`
Performance-related settings including:
- CPU frequency governor set to "performance"

### `vm-guest.nix`
Virtual machine guest configuration including:
- SPICE VD agent
- QEMU guest agent

## Usage

### For AMD Systems
```nix
{
  imports = [
    ../common/hardware-amd.nix
    # other host-specific modules
  ];
}
```

### For Intel Systems
```nix
{
  imports = [
    ../common/hardware-intel.nix
    # other host-specific modules
  ];
}
```

### For Systems with Audio
```nix
{
  imports = [
    ../common/audio-pipewire.nix
    # other modules
  ];
}
```

### For Virtual Machines
```nix
{
  imports = [
    ../common/vm-guest.nix
    # other modules
  ];
}
```

## Host-Specific Overrides

All common settings use `lib.mkDefault` where appropriate, allowing individual hosts to override settings when needed.

For example, to change the CPU frequency governor on a specific host:
```nix
{
  powerManagement.cpuFreqGovernor = lib.mkForce "ondemand";
}
```