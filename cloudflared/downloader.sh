#!/usr/bin/env bash
#
# Cloudflare Argo Tunnel — edge IPs for the tunnel regions.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

REGIONS=(region1 region2)
DOMAINS=()
for region in "${REGIONS[@]}"; do
    DOMAINS+=("${region}.v2.argotunnel.com")
done

resolve_a    8.8.8.8 "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "cloudflared: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
