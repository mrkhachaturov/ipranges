#!/bin/bash

# Hetzner IP Ranges Downloader
# Hetzner has no official published CIDR feed, so we pull the prefixes
# announced by its ASNs via the RIPEstat API:
#   AS24940  - Hetzner Online GmbH
#   AS213230 - Hetzner Cloud

set -euo pipefail
set -x

# Hetzner ASNs to query
HETZNER_ASNS=(
    "24940"
    "213230"
)

# Clean up temp files
rm -f /tmp/hetzner.txt /tmp/hetzner-ipv4.txt /tmp/hetzner-ipv6.txt
rm -f /tmp/hetzner-ipv4-final.txt /tmp/hetzner-ipv6-final.txt

# Fetch announced prefixes for each ASN
for asn in "${HETZNER_ASNS[@]}"; do
    echo "Fetching AS$asn..." >&2
    curl -s "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS$asn" \
        | jq -r '.data.prefixes[].prefix' >> /tmp/hetzner.txt || echo 'failed'
done

# save ipv4
grep -v ':' /tmp/hetzner.txt > /tmp/hetzner-ipv4.txt

# save ipv6
grep ':' /tmp/hetzner.txt > /tmp/hetzner-ipv6.txt

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/hetzner-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/hetzner-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/hetzner-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/hetzner-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/hetzner-ipv4-final.txt ipv4.txt || cp /tmp/hetzner-ipv4-final.txt hetzner/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/hetzner-ipv6-final.txt ipv6.txt || cp /tmp/hetzner-ipv6-final.txt hetzner/ipv6.txt

echo "Done!"
