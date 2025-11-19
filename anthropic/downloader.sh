#!/bin/bash

# Anthropic IP Ranges Downloader
# Downloads Anthropic/Claude IPs from documentation and resolves domains

set -euo pipefail
set -x

# Anthropic/Claude domains to resolve
ANTHROPIC_DOMAINS=(
    "claude.ai"
    "api.anthropic.com"
    "console.anthropic.com"
    "www.anthropic.com"
    "anthropic.com"
)

# Static IPs from Anthropic documentation
# Inbound IPs
echo "160.79.104.0/23" > /tmp/anthropic-ipv4.txt
echo "2607:6bc0::/48" > /tmp/anthropic-ipv6.txt

# Outbound IPs (for MCP tool calls)
echo "34.162.46.92/32" >> /tmp/anthropic-ipv4.txt
echo "34.162.102.82/32" >> /tmp/anthropic-ipv4.txt
echo "34.162.136.91/32" >> /tmp/anthropic-ipv4.txt
echo "34.162.142.92/32" >> /tmp/anthropic-ipv4.txt
echo "34.162.183.95/32" >> /tmp/anthropic-ipv4.txt

# Resolve additional domains (use multiple DNS servers to get all CDN IPs)
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9" "77.88.8.8")
for domain in "${ANTHROPIC_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    for dns in "${DNS_SERVERS[@]}"; do
        dig +short A "$domain" @"$dns" | sed 's/$/\/32/' >> /tmp/anthropic-ipv4.txt || true
        dig +short AAAA "$domain" @"$dns" | sed 's/$/\/128/' >> /tmp/anthropic-ipv6.txt || true
    done
done

# Process IPv4 addresses
cat /tmp/anthropic-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sort -V | uniq > /tmp/anthropic-ipv4-final.txt

# Process IPv6 addresses
cat /tmp/anthropic-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sort -V | uniq > /tmp/anthropic-ipv6-final.txt

# sort & uniq
sort -V /tmp/anthropic-ipv4-final.txt | uniq > anthropic/ipv4.txt
sort -V /tmp/anthropic-ipv6-final.txt | uniq > anthropic/ipv6.txt

