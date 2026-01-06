# Summary: NixOS module for Nix binary cache service, sets up cache directory and server configuration for selected hosts.
{
  hostname,
  lib,
  pkgs,
  ...
}:
let
  ncRunCache = [
    "xsvr1"
  ];

  isServer = lib.elem "${hostname}" ncRunCache;
in
{
  config = lib.mkIf isServer {
    # Create the cache directory with builder ownership, nginx in builder group for read access
    systemd.tmpfiles.rules = [
      "d /var/public-nix-cache 0775 builder builder -"
      "d /tmp/pkgcache 0755 nginx nginx -"
    ];

    # Add nginx user to builder group so it can read the cache
    users.users.nginx.extraGroups = [ "builder" ];

    # Cleanup old cache entries
    systemd.services.nixcache-cleanup = {
      description = "Clean up old Nix binary cache entries";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "nixcache-cleanup" ''
          set -euo pipefail
          CACHE_DIR="/var/public-nix-cache"
          MAX_AGE_DAYS=30
          MAX_SIZE_GB=100

          echo "Starting cache cleanup..."

          # Remove files older than MAX_AGE_DAYS
          echo "Removing files older than $MAX_AGE_DAYS days..."
          ${pkgs.findutils}/bin/find "$CACHE_DIR" -type f -mtime +$MAX_AGE_DAYS -delete

          # Check cache size and remove oldest files if over limit
          CURRENT_SIZE=$(${pkgs.coreutils}/bin/du -sb "$CACHE_DIR" | ${pkgs.coreutils}/bin/cut -f1)
          MAX_SIZE_BYTES=$((MAX_SIZE_GB * 1024 * 1024 * 1024))

          if [ "$CURRENT_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
            echo "Cache size $CURRENT_SIZE bytes exceeds limit of $MAX_SIZE_BYTES bytes"
            echo "Removing oldest files..."
            # Remove oldest 20% of files
            ${pkgs.findutils}/bin/find "$CACHE_DIR" -type f -printf '%T+ %p\n' | \
              ${pkgs.coreutils}/bin/sort | \
              ${pkgs.coreutils}/bin/head -n $(( $(${pkgs.findutils}/bin/find "$CACHE_DIR" -type f | ${pkgs.coreutils}/bin/wc -l) / 5 )) | \
              ${pkgs.coreutils}/bin/cut -d' ' -f2- | \
              ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
          fi

          # Remove empty directories
          ${pkgs.findutils}/bin/find "$CACHE_DIR" -type d -empty -delete

          echo "Cache cleanup completed"

          # Clean up builder's build results (keep only result symlinks, GC handles rest)
          echo "Cleaning builder work directory..."
          BUILDER_DIR="/home/builder/nix"
          if [ -d "$BUILDER_DIR" ]; then
            ${pkgs.findutils}/bin/find "$BUILDER_DIR" -name 'result*' -type l -mtime +7 -delete
          fi
        ''}";
      };
    };

    # Run cleanup weekly
    systemd.timers.nixcache-cleanup = {
      description = "Timer for Nix binary cache cleanup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        proxy_cache_path /tmp/pkgcache levels=1:2 keys_zone=cachecache:100m max_size=20g inactive=365d use_temp_path=off;
        # Cache only success status codes; in particular we don't want to cache 404s.
        # See https://serverfault.com/a/690258/128321
        map $status $cache_header {
          200     "public";
          302     "public";
          default "no-cache";
        }
        access_log /var/log/nginx/access.log;
      '';

      virtualHosts."xsvr1.lan" = {
        locations."/" = {
          root = "/var/public-nix-cache";
          extraConfig = ''
            expires max;
            add_header Cache-Control $cache_header always;
            # Ask the upstream server if a file isn't available locally
            error_page 404 = @fallback;
          '';
        };

        extraConfig = ''
          # Using a variable for the upstream endpoint to ensure that it is
          # resolved at runtime as opposed to once when the config file is loaded
          # and then cached forever (we don't want that):
          # see https://tenzer.dk/nginx-with-dynamic-upstreams/
          # This fixes errors like
          #   nginx: [emerg] host not found in upstream "upstream.example.com"
          # when the upstream host is not reachable for a short time when
          # nginx is started.
          resolver 172.22.10.250;
          set $upstream_endpoint http://cache.nixos.org;
        '';

        locations."@fallback" = {
          proxyPass = "$upstream_endpoint";
          extraConfig = ''
            proxy_cache cachecache;
            proxy_cache_valid  200 302  60d;
            expires max;
            add_header Cache-Control $cache_header always;
          '';
        };

        # We always want to copy cache.nixos.org's nix-cache-info file,
        # and ignore our own, because `nix-push` by default generates one
        # without `Priority` field, and thus that file by default has priority
        # 50 (compared to cache.nixos.org's `Priority: 40`), which will make
        # download clients prefer `cache.nixos.org` over our binary cache.
        locations."= /nix-cache-info" = {
          # Note: This is duplicated with the `@fallback` above,
          # would be nicer if we could redirect to the @fallback instead.
          proxyPass = "$upstream_endpoint";
          extraConfig = ''
            proxy_cache cachecache;
            proxy_cache_valid  200 302  60d;
            expires max;
            add_header Cache-Control $cache_header always;
          '';
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
