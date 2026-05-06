#!/bin/bash

# Sunsama IP Ranges Downloader
# Resolves Sunsama domains

set -euo pipefail
set -x

# Sunsama domains to resolve
SUNSAMA_DOMAINS=(
    "sunsama.com"
    "www.sunsama.com"
    "app.sunsama.com"
    "api.sunsama.com"
    "beta.sunsama.com"
    "help.sunsama.com"
    "sunsama.net"
    "www.sunsama.net"
    "app.sunsama.net"
    "api.sunsama.net"
)

# Clean up temp files
rm -f /tmp/sunsama-ipv4.txt /tmp/sunsama-ipv6.txt

# Resolve Sunsama domains
for domain in "${SUNSAMA_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/sunsama-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/sunsama-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/sunsama-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/sunsama-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/sunsama-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/sunsama-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/sunsama-ipv4-final.txt ipv4.txt || cp /tmp/sunsama-ipv4-final.txt sunsama/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/sunsama-ipv6-final.txt ipv6.txt || cp /tmp/sunsama-ipv6-final.txt sunsama/ipv6.txt

echo "Done!"
