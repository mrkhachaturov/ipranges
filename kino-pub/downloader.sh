#!/bin/bash

# Kino.pub IP Ranges Downloader
# Downloads Kino.pub IPs by resolving domains

set -euo pipefail
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kino.pub domains to resolve
KINO_DOMAINS=(
    "kino.pub"
    "www.kino.pub"
    "api.kino.pub"
)

# Resolve domains using multiple DNS servers to get all CDN IPs
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9" "77.88.8.8")
for domain in "${KINO_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    for dns in "${DNS_SERVERS[@]}"; do
        # Query multiple times to catch round-robin IPs
        for i in {1..3}; do
            dig +short A "$domain" @"$dns" 2>/dev/null | sed 's/$/\/32/' >> /tmp/kino-pub-ipv4.txt || true
            dig +short AAAA "$domain" @"$dns" 2>/dev/null | sed 's/$/\/128/' >> /tmp/kino-pub-ipv6.txt || true
            sleep 0.1  # Small delay between queries
        done
    done
done

# Process IPv4 addresses and exclude MTS blocks
cat /tmp/kino-pub-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    grep -v "^172\.66\.40\.229/32$" | \
    grep -v "^172\.66\.43\.27/32$" | \
    sort -V | uniq > /tmp/kino-pub-ipv4-final.txt

# Process IPv6 addresses
cat /tmp/kino-pub-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sort -V | uniq > /tmp/kino-pub-ipv6-final.txt

# Save results
cp /tmp/kino-pub-ipv4-final.txt "${SCRIPT_DIR}/ipv4.txt"
cp /tmp/kino-pub-ipv6-final.txt "${SCRIPT_DIR}/ipv6.txt"

FINAL_IPV4_COUNT=$(wc -l < /tmp/kino-pub-ipv4-final.txt 2>/dev/null | tr -d ' ' || echo "0")
FINAL_IPV6_COUNT=$(wc -l < /tmp/kino-pub-ipv6-final.txt 2>/dev/null | tr -d ' ' || echo "0")
echo "Final output: $FINAL_IPV4_COUNT IPv4 addresses, $FINAL_IPV6_COUNT IPv6 addresses" >&2

# Clean up temporary files
rm -f /tmp/kino-pub-ipv4.txt /tmp/kino-pub-ipv6.txt /tmp/kino-pub-ipv4-final.txt /tmp/kino-pub-ipv6-final.txt
