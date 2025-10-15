#!/bin/bash

# Groq IP Ranges Downloader
# Resolves Groq API and console domains

set -euo pipefail
set -x

# Groq domains to resolve
GROQ_DOMAINS=(
    "groq.com"
    "api.groq.com"
    "console.groq.com"
)

# Clean up temp files
rm -f /tmp/groq-ipv4.txt /tmp/groq-ipv6.txt

# Resolve Groq domains
for domain in "${GROQ_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/groq-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/groq-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/groq-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/groq-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/groq-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/groq-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/groq-ipv4-final.txt ipv4.txt || cp /tmp/groq-ipv4-final.txt groq/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/groq-ipv6-final.txt ipv6.txt || cp /tmp/groq-ipv6-final.txt groq/ipv6.txt

echo "Done!"

