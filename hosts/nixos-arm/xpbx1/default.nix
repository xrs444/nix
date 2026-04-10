# Summary: NixOS ARM host configuration for xpbx1 - Raspberry Pi 3B running Asterisk PBX
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

  # Disable device tree overlays to avoid Python libfdt issue
  # Raspberry Pi 3B works fine with the default device tree
  hardware.deviceTree.enable = lib.mkForce false;

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
      ; Extensions 810-814 - Sangoma P315 Phones (DPMA)
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

    # Dialplan for internal extensions
    "extensions.conf" = lib.mkForce ''
      ; Dialplan configuration for xpbx1

      [general]
      static = yes
      writeprotect = no

      [internal]
      ; Direct extension dialing
      exten => 801,1,NoOp(Calling Home Assistant)
      same => n,Dial(PJSIP/801,30)
      same => n,Hangup()

      exten => 810,1,NoOp(Calling RF Cabinet)
      same => n,Dial(PJSIP/810,30)
      same => n,Hangup()

      exten => 811,1,NoOp(Calling Greyson's Room)
      same => n,Dial(PJSIP/811,30)
      same => n,Hangup()

      exten => 812,1,NoOp(Calling Rowan's Room)
      same => n,Dial(PJSIP/812,30)
      same => n,Hangup()

      exten => 813,1,NoOp(Calling Garage)
      same => n,Dial(PJSIP/813,30)
      same => n,Hangup()

      exten => 814,1,NoOp(Calling Rack)
      same => n,Dial(PJSIP/814,30)
      same => n,Hangup()

      exten => 815,1,NoOp(Calling Thomas' Desk)
      same => n,Dial(PJSIP/815,30)
      same => n,Hangup()

      exten => 816,1,NoOp(Calling Samantha's Desk)
      same => n,Dial(PJSIP/816,30)
      same => n,Hangup()

      exten => 817,1,NoOp(Calling xstarfish)
      same => n,Dial(PJSIP/817,30)
      same => n,Hangup()

      exten => 818,1,NoOp(Calling Master Bedroom)
      same => n,Dial(PJSIP/818,30)
      same => n,Hangup()

      ; Pattern for invalid extensions
      exten => _X.,1,NoOp(Invalid extension: ''${EXTEN})
      same => n,Playback(invalid)
      same => n,Hangup()
    '';

    # DPMA configuration for Sangoma P315 phones
    # Note: Replace MAC addresses with actual phone MAC addresses
    "dpma.conf" = ''
      [general]
      enabled = yes
      ; VoIP network range
      network = 172.18.6.0/24
      port = 2000

      ; Default settings for all Sangoma P315 phones
      [default-p315](!)
      type = P315
      full_name = Sangoma P315
      encryption = no
      line1_enabled = yes
      blf1_enabled = yes
      blf2_enabled = yes
      blf3_enabled = yes
      blf4_enabled = yes

      ; 810 - RF Cabinet
      [810](default-p315)
      mac = 00:00:00:00:00:00
      line1_exten = 810
      line1_label = RF Cabinet
      blf1_exten = 811
      blf1_label = Greyson
      blf2_exten = 812
      blf2_label = Rowan
      blf3_exten = 815
      blf3_label = Thomas
      blf4_exten = 816
      blf4_label = Samantha

      ; 811 - Greyson's Room
      [811](default-p315)
      mac = 00:00:00:00:00:00
      line1_exten = 811
      line1_label = Greyson's Room
      blf1_exten = 812
      blf1_label = Rowan
      blf2_exten = 815
      blf2_label = Thomas
      blf3_exten = 816
      blf3_label = Samantha
      blf4_exten = 810
      blf4_label = RF Cabinet

      ; 812 - Rowan's Room
      [812](default-p315)
      mac = 00:00:00:00:00:00
      line1_exten = 812
      line1_label = Rowan's Room
      blf1_exten = 811
      blf1_label = Greyson
      blf2_exten = 815
      blf2_label = Thomas
      blf3_exten = 816
      blf3_label = Samantha
      blf4_exten = 810
      blf4_label = RF Cabinet

      ; 813 - Garage
      [813](default-p315)
      mac = 00:00:00:00:00:00
      line1_exten = 813
      line1_label = Garage
      blf1_exten = 815
      blf1_label = Thomas
      blf2_exten = 816
      blf2_label = Samantha
      blf3_exten = 818
      blf3_label = Master BR
      blf4_exten = 810
      blf4_label = RF Cabinet

      ; 814 - Rack
      [814](default-p315)
      mac = 00:00:00:00:00:00
      line1_exten = 814
      line1_label = Rack
      blf1_exten = 810
      blf1_label = RF Cabinet
      blf2_exten = 815
      blf2_label = Thomas
      blf3_exten = 816
      blf3_label = Samantha
      blf4_exten = 801
      blf4_label = Home Asst
    '';
  };
}
