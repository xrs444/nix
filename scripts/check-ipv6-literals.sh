#!/usr/bin/env bash
set -euo pipefail

# Fails if the Cox-delegated GUA prefix appears hardcoded anywhere in the repo
# outside docs/. That prefix renumbers without warning — confirmed live
# 2026-09-13, with no CPE reboot in between — so a hardcoded copy in config,
# DNS, or a firewall rule goes stale silently. See docs/ipv6-addressing.md
# for the full addressing model (ULA for stable infra, GUA for client
# egress) and why this rule exists.
#
# Scoped specifically to Cox's block (2600:8800), not "any GUA-looking
# address" — legitimate stable public IPv6 literals (e.g. Cloudflare's
# 2606:4700:4700::1111, Google's 2001:4860:4860::8888 DNS resolvers) are not
# ISP-delegated and don't renumber, so they're fine to hardcode and must not
# false-positive here.
#
# Split across two string literals so this script's own source text never
# contains the literal substring being searched for.
PATTERN="2600:8800"":"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MATCHES=$(git grep -lI "$PATTERN" -- \
  ':!docs/' \
  ':!scripts/check-ipv6-literals.sh' \
  ':!.github/workflows/check-ipv6-literals.yml' \
  || true)

if [ -n "$MATCHES" ]; then
  echo "ERROR: hardcoded Cox GUA IPv6 literal(s) found outside docs/:"
  echo "$MATCHES"
  echo
  echo "The delegated prefix renumbers without warning. Reference it via"
  echo "docs/ipv6-addressing.md instead of hardcoding a literal, or use the"
  echo "ULA prefix (fd66:150f:7361::/48) if what you need is a stable"
  echo "internal address."
  exit 1
fi

echo "No hardcoded Cox GUA literals found outside docs/."
