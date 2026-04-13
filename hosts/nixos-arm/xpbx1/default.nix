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

  # ---------------------------------------------------------------------------
  # TFTP provisioning server
  # DHCP option 66 points phones at this host; they fetch config by MAC address.
  # ---------------------------------------------------------------------------
  services.atftpd = {
    enable = true;
    root = "/etc/tftp";
  };

  networking.firewall.allowedUDPPorts = [ 69 ]; # TFTP

  # Grandstream HT802 (2-port ATA): exts 815 (Thomas' Desk) + 816 (Samantha's Desk)
  # MAC: EC:74:D7:22:C9:11 → cfgEC74D722C911.xml
  environment.etc."tftp/cfgEC74D722C911.xml".text = ''
    <?xml version="1.0" encoding="UTF-8" ?>
    <HT802>
      <!-- FXS Port 1 — Extension 815 Thomas' Desk -->
      <P47>0</P47>
      <P270>${hostname}.lan</P270>
      <P271>5060</P271>
      <P35>815</P35>
      <P36>CHANGE_ME_815</P36>
      <P3>Thomas Desk</P3>
      <P2342>0</P2342>

      <!-- FXS Port 2 — Extension 816 Samantha's Desk -->
      <P2047>0</P2047>
      <P2270>${hostname}.lan</P2270>
      <P2271>5060</P2271>
      <P2035>816</P2035>
      <P2036>CHANGE_ME_816</P2036>
      <P23>Samantha Desk</P23>
    </HT802>
  '';

  # Grandstream HT801 (1-port ATA): ext 818 (Master Bedroom)
  # Filename: cfg<MAC-UPPERCASE-NO-COLONS>.xml
  environment.etc."tftp/cfgMAC_HT801.xml".text = ''
    <?xml version="1.0" encoding="UTF-8" ?>
    <HT801>
      <!-- FXS Port 1 — Extension 818 Master Bedroom -->
      <P47>0</P47>
      <P270>${hostname}.lan</P270>
      <P271>5060</P271>
      <P35>818</P35>
      <P36>CHANGE_ME_818</P36>
      <P3>Master Bedroom</P3>
    </HT801>
  '';

  # Polycom SoundStation IP 7000: ext 817 (xstarfish Conference)
  # Phones fetch 000000000000.cfg first, then <mac-lowercase-no-colons>.cfg
  environment.etc."tftp/000000000000.cfg".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!-- Polycom master config: loaded by all Polycom devices before per-device config -->
    <PHONE_CONFIG>
      <ALL
        VOIP_PROT_SIP_OUTBOUND_PROXY="${hostname}.lan"
        VOIP_PROT_SIP_OUTBOUND_PROXY_PORT="5060"
        VOICE_CODEC_PREFERENCE="G722,PCMU,PCMA"
        PROV_SERVER_ADDR="${hostname}.lan"
        PROV_SERVER_TRANS="TFTP"
      />
    </PHONE_CONFIG>
  '';

  # Polycom SoundStation IP 7000 — ext 817 xstarfish — MAC: 00:04:F2:F9:E4:72
  environment.etc."tftp/0004f2f9e472.cfg".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!-- Per-device config for SoundStation IP 7000 — ext 817 xstarfish -->
    <PHONE_CONFIG>
      <ALL
        DISPLAY_NAME="xstarfish Conference"
        SIP_ADDRESS="817"
        AUTH_USER_ID="817"
        AUTH_PASSWORD="CHANGE_ME_817"
        LABEL="817"
        VOIP_PROT_SIP_PROXY_ADDRESS="${hostname}.lan"
        VOIP_PROT_SIP_PROXY_PORT="5060"
      />
    </PHONE_CONFIG>
  '';

  # Sangoma P315 phones: exts 810-814
  # Without DPMA (proprietary), P315s use standard SIP provisioning via TFTP.
  # Filename: <mac-lowercase-with-colons>.cfg (e.g. 00:08:5d:aa:bb:cc.cfg)
  # One file per phone — replace each MAC_P315_8xx placeholder.
  environment.etc."tftp/MAC_P315_810.cfg".text = ''
    [settings]
    sip_server=${hostname}.lan
    sip_port=5060
    username=810
    password=CHANGE_ME_810
    display_name=RF Cabinet
    codec_list=g722,ulaw,alaw
  '';

  # Sangoma P315 — ext 811 Greyson's Room — MAC: 00:0F:D3:CF:D9:D3
  # NOTE: filename format unconfirmed — watch atftpd logs on first boot to verify
  # what the phone actually requests, then rename accordingly.
  environment.etc."tftp/000fd3cfd9d3.cfg".text = ''
    [settings]
    sip_server=${hostname}.lan
    sip_port=5060
    username=811
    password=CHANGE_ME_811
    display_name=Greyson Room
    codec_list=g722,ulaw,alaw
  '';

  environment.etc."tftp/MAC_P315_812.cfg".text = ''
    [settings]
    sip_server=${hostname}.lan
    sip_port=5060
    username=812
    password=CHANGE_ME_812
    display_name=Rowan Room
    codec_list=g722,ulaw,alaw
  '';

  environment.etc."tftp/MAC_P315_813.cfg".text = ''
    [settings]
    sip_server=${hostname}.lan
    sip_port=5060
    username=813
    password=CHANGE_ME_813
    display_name=Garage
    codec_list=g722,ulaw,alaw
  '';

  environment.etc."tftp/MAC_P315_814.cfg".text = ''
    [settings]
    sip_server=${hostname}.lan
    sip_port=5060
    username=814
    password=CHANGE_ME_814
    display_name=Rack
    codec_list=g722,ulaw,alaw
  '';

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

  };
}
