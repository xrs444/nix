# Summary: TFTP provisioning server config for xpbx1; serves phone configs by MAC address via DHCP option 66.
{ hostname, ... }:
{
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
}
