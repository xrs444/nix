# Summary: Nginx reverse proxy configuration for monitoring and management services with OAuth2 authentication
{
  config,
  hostRoles ? [ ],
  lib,
  pkgs,
  hostname,
  ...
}:

let
  hasReverseProxy = lib.elem "reverse-proxy" hostRoles;
  domain = "xrs444.net";

  # Services to proxy with their configurations
  services = {
    prometheus = {
      subdomain = "prometheus";
      port = 9090;
      description = "Prometheus Metrics Server";
    };
    alertmanager = {
      subdomain = "alertmanager";
      port = 9093;
      description = "Alertmanager Alert Management";
    };
    grafana = {
      subdomain = "grafana";
      port = 3000;
      description = "Grafana Metrics Visualization";
    };
    cockpit = {
      subdomain = "cockpit";
      port = 9091;
      description = "Cockpit System Management";
    };
  };

  # Helper to create OAuth2 proxy location
  mkOAuth2ProxyLocation = upstream: {
    proxyPass = "http://127.0.0.1:4180";
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Scheme $scheme;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
    '';
  };

  # Helper to create authenticated service location
  mkAuthenticatedLocation = port: {
    proxyPass = "http://127.0.0.1:${toString port}";
    extraConfig = ''
      auth_request /oauth2/auth;
      error_page 401 = /oauth2/sign_in;

      # Pass user information from OAuth2 proxy
      auth_request_set $user $upstream_http_x_auth_request_user;
      auth_request_set $email $upstream_http_x_auth_request_email;
      auth_request_set $auth_header $upstream_http_authorization;

      proxy_set_header X-User $user;
      proxy_set_header X-Email $email;
      proxy_set_header Authorization $auth_header;

      # Standard proxy headers
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      # WebSocket support
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";

      # Timeouts
      proxy_connect_timeout 300s;
      proxy_send_timeout 300s;
      proxy_read_timeout 300s;
    '';
  };

  # Helper to create virtual host for a service
  mkServiceVHost = name: cfg: {
    "${cfg.subdomain}.${domain}" = {
      forceSSL = true;
      enableACME = true;

      locations = {
        # OAuth2 proxy endpoints
        "/oauth2/" = mkOAuth2ProxyLocation "oauth2";

        # Main service
        "/" = mkAuthenticatedLocation cfg.port;
      };

      extraConfig = ''
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Service description
        # ${cfg.description}
      '';
    };
  };

  # Auth subdomain for OAuth2 proxy redirect URL
  authVHost = {
    "auth.${domain}" = {
      forceSSL = true;
      enableACME = true;

      locations = {
        "/oauth2/" = {
          proxyPass = "http://127.0.0.1:4180";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Scheme $scheme;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };
in

{
  config = lib.mkIf hasReverseProxy {
    services.nginx = {
      enable = true;

      # Recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # Additional HTTP config
      appendHttpConfig = ''
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

        # Logging
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
      '';

      # Virtual hosts for each service
      virtualHosts = lib.mkMerge ([
        authVHost
      ] ++ (lib.mapAttrsToList mkServiceVHost services));
    };

    # Ensure nginx has access to certificates
    users.users.nginx.extraGroups = [ "acme" ];

    # Open HTTPS port
    networking.firewall.allowedTCPPorts = [ 443 ];

    # Ensure oauth2-proxy starts before nginx
    systemd.services.nginx = {
      after = [ "oauth2-proxy.service" ];
      wants = [ "oauth2-proxy.service" ];
    };
  };
}
