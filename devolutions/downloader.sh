#!/bin/bash

# Devolutions IP Ranges Downloader
# Resolves Devolutions domains

set -euo pipefail
set -x

# Devolutions domains to resolve
DEVOLUTIONS_DOMAINS=(
    "devolutions.net"
    "portal.devolutions.com"
)

# Clean up temp files
rm -f /tmp/devolutions-ipv4.txt /tmp/devolutions-ipv6.txt

# Resolve Devolutions domains
for domain in "${DEVOLUTIONS_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/devolutions-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/devolutions-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/devolutions-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/devolutions-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/devolutions-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/devolutions-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/devolutions-ipv4-final.txt ipv4.txt || cp /tmp/devolutions-ipv4-final.txt devolutions/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/devolutions-ipv6-final.txt ipv6.txt || cp /tmp/devolutions-ipv6-final.txt devolutions/ipv6.txt

echo "Done!"
