# Summary: HTTPS provisioning server config for xpbx1; serves phone configs by MAC address via DHCP option 66.
# DHCP option 66 points to https://xpbx1.xrs444.net — nginx serves configs over HTTPS (cert pushed from xsvr1).
# Sangoma P315 configs use Sangoma XML format (<accounts><account>...</account></accounts>).
# Grandstream configs use P-value XML: port1: P271=active, P47=SIP server, P35=user ID, P36=auth ID, P34=password, P3=display name.
# Port 2 (HT802 only): P401=active, P747=SIP server, P735=user ID, P736=auth ID, P734=password, P703=display name.
# Polycom SoundStation IP 7000 (Mink 4.0.15): <mac>.cfg for provisioning params; <mac>-phone.cfg for SIP config (dot-notation).
# All configs use the static IP 172.18.6.1 directly to avoid DNS resolution on the phone.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Grandstream HT802 (2-port ATA): exts 815 (Thomas' Desk) + 816 (Samantha's Desk)
  # MAC: EC:74:D7:22:C9:11 → cfgec74d722c911.xml
  # Grandstream firmware requests lowercase MAC: cfg<mac-lowercase-no-colons>.xml
  sops.templates."cfgec74d722c911.xml" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT802>
        <!-- Disable Grandstream GDMS/TR069 cloud management — it overwrites P34 via ACS -->
        <P4506>0</P4506>
        <P4503></P4503>

        <!-- FXS Port 1 — Extension 815 Thomas' Desk -->
        <P271>1</P271>
        <P47>172.18.6.1:5060</P47>
        <P35>815</P35>
        <P36>815</P36>
        <P34>${config.sops.placeholder.ext_815_password}</P34>
        <P3>Thomas Desk</P3>

        <!-- FXS Port 2 — Extension 816 Samantha's Desk -->
        <P401>1</P401>
        <P747>172.18.6.1:5060</P747>
        <P735>816</P735>
        <P736>816</P736>
        <P734>${config.sops.placeholder.ext_816_password}</P734>
        <P703>Samantha Desk</P703>
      </HT802>
    '';
  };
  environment.etc."tftp/cfgec74d722c911.xml".source =
    config.sops.templates."cfgec74d722c911.xml".path;

  # Grandstream HT801 (1-port ATA): ext 818 (Master Bedroom)
  # Grandstream firmware requests lowercase MAC: cfg<mac-lowercase-no-colons>.xml
  # MAC: EC:74:D7:52:11:CF → cfgec74d75211cf.xml
  sops.templates."cfgec74d75211cf.xml" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <HT801>
        <!-- Disable Grandstream GDMS/TR069 cloud management — it overwrites P34 via ACS -->
        <P4506>0</P4506>
        <P4503></P4503>

        <!-- FXS Port 1 — Extension 818 Master Bedroom -->
        <P271>1</P271>
        <P47>172.18.6.1:5060</P47>
        <P35>818</P35>
        <P36>818</P36>
        <P34>${config.sops.placeholder.ext_818_password}</P34>
        <P3>Master Bedroom</P3>
      </HT801>
    '';
  };
  environment.etc."tftp/cfgec74d75211cf.xml".source = config.sops.templates."cfgec74d75211cf.xml".path;

  # Polycom SoundStation IP 7000: ext 817 (xstarfish Conference)
  # Phone runs UC Software 4.0.15 — uses dot-notation params, NOT old uppercase Mink params.
  # Fetches 000000000000.cfg first, then <mac-lowercase-no-colons>.cfg
  environment.etc."tftp/000000000000.cfg".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!-- Polycom master config: loaded by all Polycom devices before per-device config -->
    <!-- SoundStation IP 7000 runs Mink 4.0.15 firmware -- HTTP provisioning, internal LAN only. -->
    <!-- Mink provisioning params: PROV_SERVER_ADDR/TRANS/PORT are the correct names. -->
    <PHONE_CONFIG>
      <ALL
        PROV_SERVER_ADDR="172.18.6.1"
        PROV_SERVER_TRANS="HTTP"
        PROV_SERVER_PORT="80"
        voice.codecPref.1="G722"
        voice.codecPref.2="PCMU"
        voice.codecPref.3="PCMA"
      />
    </PHONE_CONFIG>
  '';

  # Polycom SoundStation IP 7000 — ext 817 xstarfish — MAC: 00:04:F2:F9:E4:72
  # Firmware: Mink 4.0.15 (UC Software 4.0).
  # Provisioning uses dual-file approach:
  #   <mac>.cfg  — parsed by Mink provisioning parser; sets PROV_SERVER_* (UPPERCASE OK here)
  #   <mac>-phone.cfg — parsed by UC Software application parser; requires dot-notation for SIP
  # UPPERCASE SIP params (DISPLAY_NAME, SIP_ADDRESS, etc.) are rejected by both parsers.
  # The -phone.cfg UC Software parser accepts dot-notation (reg.1.*, voIpProt.server.1.*).
  environment.etc."tftp/0004f2f9e472.cfg".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!-- Per-device config for SoundStation IP 7000 -- ext 817 xstarfish (Mink 4.0.15) -->
    <!-- This file is parsed by the Mink provisioning parser. -->
    <!-- SIP registration is configured in 0004f2f9e472-phone.cfg via dot-notation. -->
    <PHONE_CONFIG>
      <ALL />
    </PHONE_CONFIG>
  '';
  sops.templates."0004f2f9e472-phone.cfg" = {
    mode = "0444";
    content = ''
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <!-- SIP application config for SoundStation IP 7000 -- ext 817 xstarfish -->
      <!-- Parsed by UC Software application parser (dot-notation). -->
      <PHONE_CONFIG>
        <ALL
          reg.1.address="817"
          reg.1.auth.userId="817"
          reg.1.auth.password="${config.sops.placeholder.ext_817_password}"
          reg.1.displayName="xstarfish Conference"
          reg.1.label="817"
          voIpProt.server.1.address="172.18.6.1"
          voIpProt.server.1.port="5060"
          voIpProt.server.1.register="1"
        />
      </PHONE_CONFIG>
    '';
  };
  environment.etc."tftp/0004f2f9e472-phone.cfg".source =
    config.sops.templates."0004f2f9e472-phone.cfg".path;

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
  sops.templates."000fd3cfd9e7.cfg" = {
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
  environment.etc."tftp/000fd3cfd9e7.cfg".source = config.sops.templates."000fd3cfd9e7.cfg".path;

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
        # Grandstream ATAs POST to / as a check-in before fetching their config file.
        # Return 200 so they proceed to GET cfg<mac>.xml.
        location = / {
          return 200;
        }
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
  # tmpfiles `z` runs early in activation; the acme module may reset the dir to
  # 700 afterward. Use an activation script to ensure 750 survives every deploy.
  system.activationScripts.acme-dir-perms = {
    deps = [ "users" "groups" ];
    text = "chmod 750 /var/lib/acme";
  };

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

  # sops-nix appends a trailing newline to every secret value it writes to /run/secrets/.
  # Asterisk strips trailing whitespace from config file values, so its password is clean.
  # Grandstream reads XML element content literally — <P34>pass\n</P34> — so it
  # authenticates with password+newline, which never matches. Strip the newline from
  # P-value elements in rendered Grandstream configs after sops activates.
  # Polycom -phone.cfg uses XML attribute format — strip \n before the closing quote.
  system.activationScripts.trim-phone-xml-passwords = {
    deps = [ "setupSecrets" ];
    text = ''
      # Grandstream: strip trailing \n from XML element content (<P\d+>pass\n</P\d+>)
      for f in ${lib.escapeShellArg config.sops.templates."cfgec74d75211cf.xml".path} \
                ${lib.escapeShellArg config.sops.templates."cfgec74d722c911.xml".path}; do
        [ -f "$f" ] || continue
        chmod u+w "$f"
        ${pkgs.perl}/bin/perl -0777 -i -pe \
          's|(<P\d+>)([^<\n]*)\n(</P\d+>)|$1$2$3|g' "$f"
        chmod u-w "$f"
      done
      # Polycom -phone.cfg: strip trailing \n from XML attribute values (pass\n" -> pass")
      f=${lib.escapeShellArg config.sops.templates."0004f2f9e472-phone.cfg".path}
      if [ -f "$f" ]; then
        chmod u+w "$f"
        ${pkgs.perl}/bin/perl -0777 -i -pe \
          's|([^"]*)\n(")|\1\2|g' "$f"
        chmod u-w "$f"
      fi
    '';
  };
}
