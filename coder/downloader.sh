#!/bin/bash

# Coder IP Ranges Downloader
# Resolves Coder domains (coder.com, registry.coder.com, etc.)

set -euo pipefail
set -x

# Coder domains to resolve
CODER_DOMAINS=(
    "coder.com"
    "www.coder.com"
    "registry.coder.com"
    "docs.coder.com"
    "dev.coder.com"
)

# Clean up temp files
rm -f /tmp/coder-ipv4.txt /tmp/coder-ipv6.txt

# Resolve Coder domains
for domain in "${CODER_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/coder-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/coder-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/coder-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/coder-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/coder-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/coder-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/coder-ipv4-final.txt ipv4.txt || cp /tmp/coder-ipv4-final.txt coder/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/coder-ipv6-final.txt ipv6.txt || cp /tmp/coder-ipv6-final.txt coder/ipv6.txt

echo "Done!"
