#!/usr/bin/env bash
#
# Baidu — no official CIDR feed, so we pull the prefixes announced by its ASNs
# via the RIPEstat API. Covers Baidu Cloud (BCE/BOS), the search properties and
# the overseas entities.
#
# NOTE: a large share of Baidu-fronted hostnames (*.bcebos.com among them)
# resolves into China Telecom / China Unicom IDC space that is NOT announced
# by these ASNs. Those addresses are picked up by the `paddle` provider's
# domain resolution instead — keep both if you need full coverage.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Baidu ASNs to query
BAIDU_ASNS=(
    "38365"   # Beijing Baidu Netcom Science and Technology
    "38627"   # Baidu, Inc. (JP)
    "45076"   # Beijing Baidu Netcom Science and Technology
    "45085"   # Beijing Baidu Netcom Science and Technology
    "55967"   # Beijing Baidu Netcom Science and Technology (Baidu Cloud)
    "63288"   # Baidu USA LLC
    "63728"   # Beijing Baidu Netcom Science and Technology
    "63729"   # Beijing Baidu Netcom Science and Technology
    "131138"  # Beijing Baidu Netcom Science and Technology
    "131139"  # Beijing Baidu Netcom Science and Technology
    "131140"  # Beijing Baidu Netcom Science and Technology
    "131141"  # Beijing Baidu Netcom Science and Technology
    "133746"  # Baidu (Hong Kong) Limited
    "199506"  # Baidu Global EU / Baidu (Hong Kong) Limited
)

# Fetch announced prefixes for each ASN. A single ASN failing must not abort the
# run; write_ipv4/write_ipv6 keep only their own family from the combined list.
prefixes="$(for asn in "${BAIDU_ASNS[@]}"; do
    log "Fetching AS$asn..."
    fetch "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS$asn" \
        | jq -r '.data.prefixes[].prefix' || true
done)"

printf '%s\n' "$prefixes" | write_ipv4 "$DIR"
printf '%s\n' "$prefixes" | write_ipv6 "$DIR"

log "baidu: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
