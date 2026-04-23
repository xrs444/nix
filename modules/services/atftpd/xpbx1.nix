# Summary: TFTP provisioning server config for xpbx1; serves phone configs by MAC address via DHCP option 66.
{ hostname, config, ... }:
{
  services.atftpd = {
    enable = true;
    root = "/etc/tftp";
  };

  networking.firewall.allowedUDPPorts = [ 69 ]; # TFTP

  # Grandstream HT802 (2-port ATA): exts 815 (Thomas' Desk) + 816 (Samantha's Desk)
  # MAC: EC:74:D7:22:C9:11 → cfgEC74D722C911.xml
  sops.templates."cfgEC74D722C911.xml" = {
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT802>
        <!-- FXS Port 1 — Extension 815 Thomas' Desk -->
        <P47>0</P47>
        <P270>${hostname}.lan</P270>
        <P271>5060</P271>
        <P35>815</P35>
        <P36>${config.sops.placeholder.ext_815_password}</P36>
        <P3>Thomas Desk</P3>
        <P2342>0</P2342>
        <P157>f1=440@-13,c=300/10000;</P157>

        <!-- FXS Port 2 — Extension 816 Samantha's Desk -->
        <P2047>0</P2047>
        <P2270>${hostname}.lan</P2270>
        <P2271>5060</P2271>
        <P2035>816</P2035>
        <P2036>${config.sops.placeholder.ext_816_password}</P2036>
        <P23>Samantha Desk</P23>
        <P2157>f1=440@-13,c=300/10000;</P2157>
      </HT802>
    '';
  };
  environment.etc."tftp/cfgEC74D722C911.xml".source = config.sops.templates."cfgEC74D722C911.xml".path;

  # Grandstream HT801 (1-port ATA): ext 818 (Master Bedroom)
  # Filename: cfg<MAC-UPPERCASE-NO-COLONS>.xml — replace MAC_HT801 with actual MAC
  sops.templates."cfgMAC_HT801.xml" = {
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT801>
        <!-- FXS Port 1 — Extension 818 Master Bedroom -->
        <P47>0</P47>
        <P270>${hostname}.lan</P270>
        <P271>5060</P271>
        <P35>818</P35>
        <P36>${config.sops.placeholder.ext_818_password}</P36>
        <P3>Master Bedroom</P3>
      </HT801>
    '';
  };
  environment.etc."tftp/cfgMAC_HT801.xml".source = config.sops.templates."cfgMAC_HT801.xml".path;

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
  sops.templates."0004f2f9e472.cfg" = {
    content = ''
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <!-- Per-device config for SoundStation IP 7000 — ext 817 xstarfish -->
      <PHONE_CONFIG>
        <ALL
          DISPLAY_NAME="xstarfish Conference"
          SIP_ADDRESS="817"
          AUTH_USER_ID="817"
          AUTH_PASSWORD="${config.sops.placeholder.ext_817_password}"
          LABEL="817"
          VOIP_PROT_SIP_PROXY_ADDRESS="${hostname}.lan"
          VOIP_PROT_SIP_PROXY_PORT="5060"
        />
      </PHONE_CONFIG>
    '';
  };
  environment.etc."tftp/0004f2f9e472.cfg".source = config.sops.templates."0004f2f9e472.cfg".path;

  # Sangoma P315 phones: exts 810-814
  # Without DPMA (proprietary), P315s use standard SIP provisioning via TFTP.
  # Filename: <mac-lowercase-with-colons>.cfg (e.g. 00:08:5d:aa:bb:cc.cfg)
  # One file per phone — replace each MAC_P315_8xx placeholder with actual MAC.
  sops.templates."MAC_P315_810.cfg" = {
    content = ''
      [settings]
      sip_server=${hostname}.lan
      sip_port=5060
      username=810
      password=${config.sops.placeholder.ext_810_password}
      display_name=RF Cabinet
      codec_list=g722,ulaw,alaw
    '';
  };
  environment.etc."tftp/MAC_P315_810.cfg".source = config.sops.templates."MAC_P315_810.cfg".path;

  # Sangoma P315 — ext 811 Greyson's Room — MAC: 00:0F:D3:CF:D9:D3
  sops.templates."000fd3cfd9d3.cfg" = {
    content = ''
      [settings]
      sip_server=${hostname}.lan
      sip_port=5060
      username=811
      password=${config.sops.placeholder.ext_811_password}
      display_name=Greyson Room
      codec_list=g722,ulaw,alaw
    '';
  };
  environment.etc."tftp/000fd3cfd9d3.cfg".source = config.sops.templates."000fd3cfd9d3.cfg".path;

  # Sangoma P315 — ext 812 Rowan's Room — MAC: 00:0F:D3:CF:D8:A7
  sops.templates."000fd3cfd8a7.cfg" = {
    content = ''
      [settings]
      sip_server=${hostname}.lan
      sip_port=5060
      username=812
      password=${config.sops.placeholder.ext_812_password}
      display_name=Rowan Room
      codec_list=g722,ulaw,alaw
    '';
  };
  environment.etc."tftp/000fd3cfd8a7.cfg".source = config.sops.templates."000fd3cfd8a7.cfg".path;

  sops.templates."MAC_P315_813.cfg" = {
    content = ''
      [settings]
      sip_server=${hostname}.lan
      sip_port=5060
      username=813
      password=${config.sops.placeholder.ext_813_password}
      display_name=Garage
      codec_list=g722,ulaw,alaw
    '';
  };
  environment.etc."tftp/MAC_P315_813.cfg".source = config.sops.templates."MAC_P315_813.cfg".path;

  sops.templates."MAC_P315_814.cfg" = {
    content = ''
      [settings]
      sip_server=${hostname}.lan
      sip_port=5060
      username=814
      password=${config.sops.placeholder.ext_814_password}
      display_name=Rack
      codec_list=g722,ulaw,alaw
    '';
  };
  environment.etc."tftp/MAC_P315_814.cfg".source = config.sops.templates."MAC_P315_814.cfg".path;
}
