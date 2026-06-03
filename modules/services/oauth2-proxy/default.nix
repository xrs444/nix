# Summary: OAuth2-proxy service for Kanidm SSO integration with monitoring services
{
  config,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  hasReverseProxy = lib.elem "reverse-proxy" hostRoles;
  domain = "xrs444.net";
in

{
  config = lib.mkIf hasReverseProxy {
    # Secrets for OAuth2 proxy
    sops.secrets = {
      oauth2_proxy_client_id = {
        sopsFile = ../../../secrets/oauth2-proxy.yaml;
        key = "client_id";
        owner = "oauth2-proxy";
        group = "oauth2-proxy";
        mode = "0400";
      };
      oauth2_proxy_client_secret = {
        sopsFile = ../../../secrets/oauth2-proxy.yaml;
        key = "client_secret";
        owner = "oauth2-proxy";
        group = "oauth2-proxy";
        mode = "0400";
      };
      oauth2_proxy_cookie_secret = {
        sopsFile = ../../../secrets/oauth2-proxy.yaml;
        key = "cookie_secret";
        owner = "oauth2-proxy";
        group = "oauth2-proxy";
        mode = "0400";
      };
    };

    # Create oauth2-proxy user and group
    users.users.oauth2-proxy = {
      isSystemUser = true;
      group = "oauth2-proxy";
      description = "OAuth2 Proxy service user";
    };

    users.groups.oauth2-proxy = { };

    # OAuth2 Proxy systemd service
    systemd.services.oauth2-proxy = {
      description = "OAuth2 Proxy for Kanidm SSO";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "oauth2-proxy";
        Group = "oauth2-proxy";
        ExecStart = ''
          ${pkgs.oauth2-proxy}/bin/oauth2-proxy \
            --provider=oidc \
            --provider-display-name="Kanidm SSO" \
            --client-id=$(cat ${config.sops.secrets.oauth2_proxy_client_id.path}) \
            --client-secret=$(cat ${config.sops.secrets.oauth2_proxy_client_secret.path}) \
            --cookie-secret=$(cat ${config.sops.secrets.oauth2_proxy_cookie_secret.path}) \
            --oidc-issuer-url=https://idm.${domain}/oauth2/openid/monitoring \
            --redirect-url=https://auth.${domain}/oauth2/callback \
            --cookie-secure=true \
            --cookie-domain=.${domain} \
            --whitelist-domain=.${domain} \
            --email-domain=* \
            --http-address=127.0.0.1:4180 \
            --reverse-proxy=true \
            --pass-host-header=true \
            --set-xauthrequest=true \
            --pass-access-token=true \
            --pass-authorization-header=true \
            --skip-provider-button=true \
            --code-challenge-method=S256
        '';
        Restart = "always";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ ];
      };
    };
  };
}
