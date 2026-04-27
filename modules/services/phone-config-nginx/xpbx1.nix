# Summary: HTTPS provisioning server config for xpbx1; serves phone configs by MAC address via DHCP option 66.
# DHCP option 66 points to https://xpbx1.xrs444.net — nginx serves configs over HTTPS (cert pushed from xsvr1).
# Sangoma P315 configs use Sangoma XML format (<accounts><account>...</account></accounts>).
# Grandstream configs use Grandstream P-value XML: P2=SIP User ID, P3=Auth ID, P34=Auth Password, P35=Name (port 2 adds 2000). Polycom uses PHONE_CONFIG XML.
# All configs use the static IP 172.18.6.1 directly to avoid DNS resolution on the phone.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Grandstream HT802 (2-port ATA): exts 815 (Thomas' Desk) + 816 (Samantha's Desk)
  # MAC: EC:74:D7:22:C9:11 → cfgEC74D722C911.xml
  sops.templates."cfgEC74D722C911.xml" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT802>
        <!-- FXS Port 1 — Extension 815 Thomas' Desk -->
        <P47>0</P47>
        <P270>172.18.6.1</P270>
        <P271>5060</P271>
        <P2>815</P2>
        <P3>815</P3>
        <P34>${config.sops.placeholder.ext_815_password}</P34>
        <P35>Thomas Desk</P35>
        <P2342>0</P2342>
        <P157>f1=440@-13,c=300/10000;</P157>

        <!-- FXS Port 2 — Extension 816 Samantha's Desk -->
        <P2047>0</P2047>
        <P2270>172.18.6.1</P2270>
        <P2271>5060</P2271>
        <P2002>816</P2002>
        <P2003>816</P2003>
        <P2034>${config.sops.placeholder.ext_816_password}</P2034>
        <P2035>Samantha Desk</P2035>
        <P2157>f1=440@-13,c=300/10000;</P2157>
      </HT802>
    '';
  };
  environment.etc."tftp/cfgEC74D722C911.xml".source =
    config.sops.templates."cfgEC74D722C911.xml".path;

  # Grandstream HT801 (1-port ATA): ext 818 (Master Bedroom)
  # Filename MUST be cfg<MAC-UPPERCASE-NO-COLONS>.xml — note the required 'cfg' prefix.
  # MAC: EC:74:D7:52:11:CF → cfgEC74D75211CF.xml
  sops.templates."cfgEC74D75211CF.xml" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT801>
        <!-- FXS Port 1 — Extension 818 Master Bedroom -->
        <P47>0</P47>
        <P270>172.18.6.1</P270>
        <P271>5060</P271>
        <P2>818</P2>
        <P3>818</P3>
        <P34>${config.sops.placeholder.ext_818_password}</P34>
        <P35>Master Bedroom</P35>
      </HT801>
    '';
  };
  environment.etc."tftp/cfgEC74D75211CF.xml".source = config.sops.templates."cfgEC74D75211CF.xml".path;

  # Polycom SoundStation IP 7000: ext 817 (xstarfish Conference)
  # Phone runs UC Software 4.0.15 — uses dot-notation params, NOT old uppercase Mink params.
  # Fetches 000000000000.cfg first, then <mac-lowercase-no-colons>.cfg
  environment.etc."tftp/000000000000.cfg".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!-- Polycom master config: loaded by all Polycom devices before per-device config -->
    <!-- SoundStation IP 7000 runs UC Software 4.0.15 — HTTP provisioning, internal LAN only. -->
    <PHONE_CONFIG>
      <ALL
        prov.serverName="172.18.6.1"
        prov.serverType="0"
        prov.serverPort="80"
        voIpProt.SIP.outboundProxy.address="172.18.6.1"
        voIpProt.SIP.outboundProxy.port="5060"
        voice.codecPref.1="G722"
        voice.codecPref.2="PCMU"
        voice.codecPref.3="PCMA"
      />
    </PHONE_CONFIG>
  '';

  # Polycom SoundStation IP 7000 — ext 817 xstarfish — MAC: 00:04:F2:F9:E4:72
  # UC Software 4.0.x uses reg.1.* dot-notation params for registration.
  sops.templates."0004f2f9e472.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <!-- Per-device config for SoundStation IP 7000 — ext 817 xstarfish (UC Software 4.0.15) -->
      <PHONE_CONFIG>
        <ALL
          reg.1.address="817"
          reg.1.auth.userId="817"
          reg.1.auth.password="${config.sops.placeholder.ext_817_password}"
          reg.1.displayName="xstarfish Conference"
          reg.1.label="xstarfish Conference"
          reg.1.server.1.address="172.18.6.1"
          reg.1.server.1.port="5060"
          reg.1.server.1.transport="UDPOnly"
          reg.1.server.1.expires="3600"
        />
      </PHONE_CONFIG>
    '';
  };
  environment.etc."tftp/0004f2f9e472.cfg".source = config.sops.templates."0004f2f9e472.cfg".path;

  # Sangoma P315 phones: exts 810-814
  # Config format: Sangoma XML (<config><accounts><account>))
  # Filename: <mac-lowercase-no-colons>.cfg
  # Placeholder filenames (MAC_P315_8xx) will be renamed once actual MACs are known.

  # Sangoma P315 — ext 810 RF Cabinet — MAC: pending
  sops.templates."000fd3cfd9a3.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" ?>
      <config>
        <accounts>
          <account index="0" status="1" register="1" account_id="810"
                   username="810" authname="810"
                   password="${config.sops.placeholder.ext_810_password}"
                   line_label="RF Cabinet"
                   caller_id="RF Cabinet &lt;810&gt;">
            <host_primary server="172.18.6.1" port="5060" transport="udp" reregister="300" />
          </account>
        </accounts>
      </config>
    '';
  };
  environment.etc."tftp/000fd3cfd9a3.cfg".source = config.sops.templates."000fd3cfd9a3.cfg".path;

  # Sangoma P315 — ext 811 Greyson's Room — MAC: 00:0F:D3:CF:D9:D3
  sops.templates."000fd3cfd9d3.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" ?>
      <config>
        <accounts>
          <account index="0" status="1" register="1" account_id="811"
                   username="811" authname="811"
                   password="${config.sops.placeholder.ext_811_password}"
                   line_label="Greyson Room"
                   caller_id="Greyson Room &lt;811&gt;">
            <host_primary server="172.18.6.1" port="5060" transport="udp" reregister="300" />
          </account>
        </accounts>
      </config>
    '';
  };
  environment.etc."tftp/000fd3cfd9d3.cfg".source = config.sops.templates."000fd3cfd9d3.cfg".path;

  # Sangoma P315 — ext 812 Rowan's Room — MAC: 00:0F:D3:CF:DA:34
  sops.templates."000fd3cfda34.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" ?>
      <config>
        <accounts>
          <account index="0" status="1" register="1" account_id="812"
                   username="812" authname="812"
                   password="${config.sops.placeholder.ext_812_password}"
                   line_label="Rowan Room"
                   caller_id="Rowan Room &lt;812&gt;">
            <host_primary server="172.18.6.1" port="5060" transport="udp" reregister="300" />
          </account>
        </accounts>
      </config>
    '';
  };
  environment.etc."tftp/000fd3cfda34.cfg".source = config.sops.templates."000fd3cfda34.cfg".path;

  # Sangoma P315 — ext 813 Garage — MAC: pending
  sops.templates."000fd3cfd9e7cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" ?>
      <config>
        <accounts>
          <account index="0" status="1" register="1" account_id="813"
                   username="813" authname="813"
                   password="${config.sops.placeholder.ext_813_password}"
                   line_label="Garage"
                   caller_id="Garage &lt;813&gt;">
            <host_primary server="172.18.6.1" port="5060" transport="udp" reregister="300" />
          </account>
        </accounts>
      </config>
    '';
  };
  environment.etc."tftp/000fd3cfd9e7cfg".source = config.sops.templates."000fd3cfd9e7cfg".path;

  # Sangoma P315 — ext 814 Rack — MAC: 00:0F:D3:CF:D8:A7
  sops.templates."000fd3cfd8a7.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" ?>
      <config>
        <accounts>
          <account index="0" status="1" register="1" account_id="814"
                   username="814" authname="814"
                   password="${config.sops.placeholder.ext_814_password}"
                   line_label="Rack"
                   caller_id="Rack &lt;814&gt;">
            <host_primary server="172.18.6.1" port="5060" transport="udp" reregister="300" />
          </account>
        </accounts>
      </config>
    '';
  };
  environment.etc."tftp/000fd3cfd8a7.cfg".source = config.sops.templates."000fd3cfd8a7.cfg".path;

  # HTTPS provisioning server — phones fetch configs from https://xpbx1.xrs444.net/<mac>.cfg
  # Cert is generated on xsvr1 and rsynced here after each renewal via the acme postRun hook.
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts."xpbx1.xrs444.net" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/xpbx1.xrs444.net/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/xpbx1.xrs444.net/key.pem";
      root = "/etc/tftp";
      extraConfig = ''
        autoindex off;
      '';
    };
    # HTTP vhost for Polycom SoundStation IP 7000 (Mink 4.0): only supports TLS 1.0
    # which OpenSSL 3.x rejects. HTTP provisioning is acceptable — internal LAN only.
    virtualHosts."xpbx1-http" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      serverName = "_";
      root = "/etc/tftp";
      extraConfig = ''
        autoindex off;
      '';
    };
  };

  # Add nginx to the acme group so it can traverse the 750 cert directory.
  # Set from the group side (members) rather than extraGroups to avoid merge ambiguity.
  users.groups.acme.members = [ "nginx" ];

  # /var/lib/acme is the acme user's home dir, created 700 by NixOS.
  # nginx (in the acme group) can't traverse it unless we widen the group bit.
  systemd.tmpfiles.rules = [
    "z /var/lib/acme 0750 acme acme -"
  ];

  # Reload nginx automatically when xsvr1 rsyncs a renewed cert
  systemd.paths.nginx-cert-reload = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/var/lib/acme/xpbx1.xrs444.net/fullchain.pem";
      Unit = "nginx-cert-reload.service";
    };
  };

  systemd.services.nginx-cert-reload = {
    description = "Reload nginx after certificate update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe' pkgs.systemd "systemctl"} reload nginx.service";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
