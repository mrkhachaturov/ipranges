#!/bin/bash

# Cohere IP Ranges Downloader
# Resolves Cohere domains

set -euo pipefail
set -x

# Cohere domains to resolve
COHERE_DOMAINS=(
    "cohere.com"
    "www.cohere.com"
    "cohere.ai"
    "www.cohere.ai"
    "cohere.io"
    "api.cohere.com"
    "api.cohere.ai"
    "production.api.cohere.com"
    "production.api.cohere.ai"
    "staging.api.cohere.com"
    "staging.api.cohere.ai"
    "stg.api.cohere.ai"
    "north.cohere.com"
    "dashboard.cohere.com"
    "dashboard.cohere.ai"
    "docs.cohere.com"
    "docs.cohere.ai"
    "coral.cohere.com"
    "coral.cohere.ai"
    "chat.cohere.com"
    "txt.cohere.com"
    "txt.cohere.ai"
    "status.cohere.com"
)

# Clean up temp files
rm -f /tmp/cohere-ipv4.txt /tmp/cohere-ipv6.txt

# Resolve Cohere domains
for domain in "${COHERE_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/cohere-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/cohere-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/cohere-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/cohere-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/cohere-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/cohere-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/cohere-ipv4-final.txt ipv4.txt || cp /tmp/cohere-ipv4-final.txt cohere/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/cohere-ipv6-final.txt ipv6.txt || cp /tmp/cohere-ipv6-final.txt cohere/ipv6.txt

echo "Done!"
