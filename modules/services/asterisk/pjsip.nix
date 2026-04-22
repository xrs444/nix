# Summary: Asterisk PJSIP endpoint/auth/AOR config for xpbx1 extensions, secrets-managed via sops
{
  lib,
  hostname,
  hostRoles ? [ ],
  config,
  ...
}:
let
  isXpbx1 = lib.elem "asterisk" hostRoles && hostname == "xpbx1";
in
{
  config = lib.mkIf isXpbx1 {
    # Sops secrets for PBX extension passwords
    sops.secrets =
      lib.genAttrs
        (map (e: "ext_${toString e}_password") [
          801
          810
          811
          812
          813
          814
          815
          816
          817
          818
        ])
        (_: {
          sopsFile = ../../../secrets/pbx-passwords.yaml;
        });

    # Generate pjsip.conf with real passwords at activation time via sops template
    sops.templates."pjsip.conf" = {
      content = ''
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
        identify_by = username,ip

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
        password = ${config.sops.placeholder.ext_801_password}

        [801](aor-single)

        [identify-801]
        type = identify
        endpoint = 801
        match = 172.18.7.1

        ; ===============================================
        ; Extensions 810-814 - Sangoma P315 Phones (SIP, provisioned via TFTP)
        ; ===============================================
        [810](endpoint-internal)
        auth = 810
        aors = 810
        callerid = "RF Cabinet" <810>

        [810](auth-userpass)
        username = 810
        password = ${config.sops.placeholder.ext_810_password}

        [810](aor-single)

        [identify-810]
        type = identify
        endpoint = 810
        match = 172.18.6.50

        [811](endpoint-internal)
        auth = 811
        aors = 811
        callerid = "Greyson's Room" <811>

        [811](auth-userpass)
        username = 811
        password = ${config.sops.placeholder.ext_811_password}

        [811](aor-single)

        [identify-811]
        type = identify
        endpoint = 811
        match = 172.18.6.49

        [812](endpoint-internal)
        auth = 812
        aors = 812
        callerid = "Rowan's Room" <812>

        [812](auth-userpass)
        username = 812
        password = ${config.sops.placeholder.ext_812_password}

        [812](aor-single)
        [identify-812]
        type = identify
        endpoint = 812
        match = 172.18.6.51

        [813](endpoint-internal)
        auth = 813
        aors = 813
        callerid = "Garage" <813>

        [813](auth-userpass)
        username = 813
        password = ${config.sops.placeholder.ext_813_password}

        [813](aor-single)

        [identify-813]
        type = identify
        endpoint = 813
        match = 172.18.6.52

        [814](endpoint-internal)
        auth = 814
        aors = 814
        callerid = "Rack" <814>

        [814](auth-userpass)
        username = 814
        password = ${config.sops.placeholder.ext_814_password}

        [814](aor-single)

        [identify-814]
        type = identify
        endpoint = 814
        match = 172.18.6.53

        ; ===============================================
        ; Extensions 815-816 - Grandstream HT802 (2-port ATA)
        ; ===============================================
        [815](endpoint-internal)
        auth = 815
        aors = 815
        callerid = "Thomas' Desk" <815>

        [815](auth-userpass)
        username = 815
        password = ${config.sops.placeholder.ext_815_password}

        [815](aor-single)

        [816](endpoint-internal)
        auth = 816
        aors = 816
        callerid = "Samantha's Desk" <816>

        [816](auth-userpass)
        username = 816
        password = ${config.sops.placeholder.ext_816_password}

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
        password = ${config.sops.placeholder.ext_817_password}

        [817](aor-single)

        [identify-817]
        type = identify
        endpoint = 817
        match = 172.18.6.54

        ; ===============================================
        ; Extension 818 - Grandstream HT801 (1-port ATA)
        ; ===============================================
        [818](endpoint-internal)
        auth = 818
        aors = 818
        callerid = "Master Bedroom" <818>

        [818](auth-userpass)
        username = 818
        password = ${config.sops.placeholder.ext_818_password}

        [818](aor-single)

        [identify-818]
        type = identify
        endpoint = 818
        match = 172.18.6.55
      '';
      owner = "asterisk";
      group = "asterisk";
      mode = "0440";
    };

    # Override the base pjsip.conf with the sops-rendered version
    services.asterisk.confFiles."pjsip.conf" = lib.mkForce "";
    environment.etc."asterisk/pjsip.conf".source = lib.mkForce config.sops.templates."pjsip.conf".path;
  };
}
