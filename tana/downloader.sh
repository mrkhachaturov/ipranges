#!/bin/bash

# Tana IP Ranges Downloader
# Resolves Tana domains

set -euo pipefail
set -x

# Tana domains to resolve
TANA_DOMAINS=(
    "tana.inc"
    "app.tana.inc"
    "be.tana.inc"
    "desktop-update.tana.inc"
    "outliner.tana.inc"
)

# Clean up temp files
rm -f /tmp/tana-ipv4.txt /tmp/tana-ipv6.txt

# Resolve Tana domains
for domain in "${TANA_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/tana-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/tana-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/tana-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/tana-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/tana-ipv6.txt 2>/dev/null | \
    grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/tana-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/tana-ipv4-final.txt ipv4.txt || cp /tmp/tana-ipv4-final.txt tana/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/tana-ipv6-final.txt ipv6.txt || cp /tmp/tana-ipv6-final.txt tana/ipv6.txt

echo "Done!"
