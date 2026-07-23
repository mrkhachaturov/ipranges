#!/usr/bin/env bash
#
# Twitter / X — announced ASN route prefixes plus resolved service domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

ASNS=(AS13414 AS35995 AS54888 AS63179)
DOMAINS=(
    t.co twimg.com twitter.com x.com ads-twitter.com
    pscp.tv twtrdns.net twttr.net twttr.com abs.twimg.com
)

# Query the IRRs once — asn_routes emits both route (v4) and route6 (v6)
# prefixes; each write_* keeps only its own family.
routes="$(for asn in "${ASNS[@]}"; do asn_routes "$asn"; done)"

{ printf '%s\n' "$routes"; resolve_a 8.8.8.8 "${DOMAINS[@]}"; } | write_ipv4 "$DIR"
{ printf '%s\n' "$routes"; resolve_aaaa 8.8.8.8 "${DOMAINS[@]}"; } | write_ipv6 "$DIR"

log "twitter: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
