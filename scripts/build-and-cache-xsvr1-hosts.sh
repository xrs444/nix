#!/usr/bin/env bash
# Build all NixOS host configurations on xsvr1 and copy to the local nix cache.
# Called by comin postDeploymentCommand after main branch updates.
set -euo pipefail

CACHE_URL="http://nixcache.xrs444.net"
HOSTS=(xsvr1 xsvr2 xsvr3 xcomm1 xlabmgmt xdash1 xhac-radio xlt1-t-vnixos xts1 xts2)
FLAKE_DIR="/var/lib/comin/repository"
APPRISE_URL="https://apprise.xrs444.net/notify"

FAILED=()
SUCCEEDED=()

cd "$FLAKE_DIR"

for host in "${HOSTS[@]}"; do
  echo "Building $host..."
  if nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link 2>&1; then
    echo "Copying $host to cache..."
    nix copy --to "$CACHE_URL" ".#nixosConfigurations.$host.config.system.build.toplevel" || true
    SUCCEEDED+=("$host")
    echo "$host: SUCCESS"
  else
    FAILED+=("$host")
    echo "$host: FAILED"
  fi
done

# Send notification via Apprise
if [ ${#FAILED[@]} -gt 0 ]; then
  curl -sf -X POST "$APPRISE_URL" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Post-Deploy Build: Partial Failure\",\"body\":\"Failed: ${FAILED[*]}. Succeeded: ${SUCCEEDED[*]}\",\"type\":\"warning\"}" || true
  echo "FAILED HOSTS: ${FAILED[*]}"
  exit 1
else
  curl -sf -X POST "$APPRISE_URL" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Post-Deploy Build: Complete\",\"body\":\"All ${#SUCCEEDED[@]} hosts built and cached successfully.\",\"type\":\"success\"}" || true
  echo "All hosts built and cached successfully"
fi
