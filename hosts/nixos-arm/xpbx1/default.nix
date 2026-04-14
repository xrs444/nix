# Summary: NixOS ARM host configuration for xpbx1 - Raspberry Pi 3B running Asterisk PBX
# Provisioning: TFTP server serves device configs by MAC address (DHCP option 66 → xpbx1)
# Replace MAC_* placeholders below with actual device MAC addresses (uppercase, no separators for
# Grandstream; lowercase no separators for Polycom; lowercase with colons for Sangoma).
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Disable only device tree overlays to avoid Python libfdt issue
  # Keep deviceTree enabled but clear overlays to bypass the broken builder
  hardware.deviceTree.overlays = lib.mkForce [];

  # Bootloader configuration for Raspberry Pi 3B
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi kernel
  boot.initrd.includeDefaultModules = false;

  # RPi3B kernel modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "mmc_block"
    "ext4"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/xpbx1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    tmux
  ];

  nixpkgs.config.allowUnfree = true;

  # Host-specific Asterisk configuration for extensions
  services.asterisk.confFiles = {
    # PJSIP endpoints for all extensions
    "pjsip.conf" = lib.mkForce ''
      ; PJSIP Configuration for xpbx1

      [transport-udp]
      type = transport
      protocol = udp
      bind = 0.0.0.0:5060

      ; Template for internal extensions
      [endpoint-internal](!)
      type = endpoint
      context = internal
      disallow = all
      allow = ulaw
      allow = alaw
      allow = g722
      direct_media = no
      ice_support = yes

      [auth-userpass](!)
      type = auth
      auth_type = userpass

      [aor-single](!)
      type = aor
      max_contacts = 1

      ; ===============================================
      ; Extension 801 - Home Assistant
      ; ===============================================
      [801](endpoint-internal)
      auth = 801
      aors = 801
      callerid = "Home Assistant" <801>

      [801](auth-userpass)
      username = 801
      password = CHANGE_ME_801

      [801](aor-single)

      ; ===============================================
      ; Extensions 810-814 - Sangoma P315 Phones (SIP, provisioned via TFTP)
      ; ===============================================
      [810](endpoint-internal)
      auth = 810
      aors = 810
      callerid = "RF Cabinet" <810>

      [810](auth-userpass)
      username = 810
      password = CHANGE_ME_810

      [810](aor-single)

      [811](endpoint-internal)
      auth = 811
      aors = 811
      callerid = "Greyson's Room" <811>

      [811](auth-userpass)
      username = 811
      password = CHANGE_ME_811

      [811](aor-single)

      [812](endpoint-internal)
      auth = 812
      aors = 812
      callerid = "Rowan's Room" <812>

      [812](auth-userpass)
      username = 812
      password = CHANGE_ME_812

      [812](aor-single)

      [813](endpoint-internal)
      auth = 813
      aors = 813
      callerid = "Garage" <813>

      [813](auth-userpass)
      username = 813
      password = CHANGE_ME_813

      [813](aor-single)

      [814](endpoint-internal)
      auth = 814
      aors = 814
      callerid = "Rack" <814>

      [814](auth-userpass)
      username = 814
      password = CHANGE_ME_814

      [814](aor-single)

      ; ===============================================
      ; Extensions 815-816 - Grandstream H802 (2-port ATA)
      ; ===============================================
      [815](endpoint-internal)
      auth = 815
      aors = 815
      callerid = "Thomas' Desk" <815>

      [815](auth-userpass)
      username = 815
      password = CHANGE_ME_815

      [815](aor-single)

      [816](endpoint-internal)
      auth = 816
      aors = 816
      callerid = "Samantha's Desk" <816>

      [816](auth-userpass)
      username = 816
      password = CHANGE_ME_816

      [816](aor-single)

      ; ===============================================
      ; Extension 817 - xstarfish (Polycom SoundStation IP 7000)
      ; ===============================================
      [817](endpoint-internal)
      auth = 817
      aors = 817
      callerid = "xstarfish Conference" <817>

      [817](auth-userpass)
      username = 817
      password = CHANGE_ME_817

      [817](aor-single)

      ; ===============================================
      ; Extension 818 - Grandstream H801 (1-port ATA)
      ; ===============================================
      [818](endpoint-internal)
      auth = 818
      aors = 818
      callerid = "Master Bedroom" <818>

      [818](auth-userpass)
      username = 818
      password = CHANGE_ME_818

      [818](aor-single)
    '';

  };
}
