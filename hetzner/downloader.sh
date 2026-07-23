#!/usr/bin/env bash
#
# Hetzner — no official CIDR feed, so pull the prefixes announced by its ASNs
# via the RIPEstat API:
#   AS24940  - Hetzner Online GmbH
#   AS213230 - Hetzner Cloud
# Source: https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS<n>
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Hetzner ASNs to query
HETZNER_ASNS=(
    "24940"
    "213230"
)

# Fetch announced prefixes for each ASN. The RIPEstat feed mixes families in
# one list; write_ipv4 / write_ipv6 each keep only their own from the stream.
prefixes="$(
    for asn in "${HETZNER_ASNS[@]}"; do
        fetch "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS$asn" \
            | jq -r '.data.prefixes[].prefix'
    done
)"

printf '%s\n' "$prefixes" | write_ipv4 "$DIR"
printf '%s\n' "$prefixes" | write_ipv6 "$DIR"

log "hetzner: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
