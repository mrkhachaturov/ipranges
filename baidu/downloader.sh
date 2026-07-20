#!/bin/bash

# Baidu IP Ranges Downloader
# Baidu publishes no official CIDR feed, so we pull the prefixes announced
# by its ASNs via the RIPEstat API. Covers Baidu Cloud (BCE/BOS), the search
# properties and the overseas entities.
#
# NOTE: a large share of Baidu-fronted hostnames (*.bcebos.com among them)
# resolves into China Telecom / China Unicom IDC space that is NOT announced
# by these ASNs. Those addresses are picked up by the `paddle` provider's
# domain resolution instead — keep both if you need full coverage.

set -euo pipefail
set -x

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

# Clean up temp files
rm -f /tmp/baidu.txt /tmp/baidu-ipv4.txt /tmp/baidu-ipv6.txt
rm -f /tmp/baidu-ipv4-final.txt /tmp/baidu-ipv6-final.txt

# Fetch announced prefixes for each ASN
for asn in "${BAIDU_ASNS[@]}"; do
    echo "Fetching AS$asn..." >&2
    curl -s "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS$asn" \
        | jq -r '.data.prefixes[].prefix' >> /tmp/baidu.txt || echo 'failed'
done

# save ipv4
grep -v ':' /tmp/baidu.txt > /tmp/baidu-ipv4.txt

# save ipv6
grep ':' /tmp/baidu.txt > /tmp/baidu-ipv6.txt

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/baidu-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/baidu-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/baidu-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/baidu-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/baidu-ipv4-final.txt ipv4.txt || cp /tmp/baidu-ipv4-final.txt baidu/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/baidu-ipv6-final.txt ipv6.txt || cp /tmp/baidu-ipv6-final.txt baidu/ipv6.txt

echo "Done!"
