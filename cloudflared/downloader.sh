#!/bin/bash

# Cloudflare Argo Tunnel IP ranges
# Fetches IP addresses from various Argo Tunnel regions

set -euo pipefail
set -x

# Create temporary files
TMP_IPV4="/tmp/cloudflared-ipv4.txt"
TMP_IPV6="/tmp/cloudflared-ipv6.txt"

# Clear temporary files
> "$TMP_IPV4"
> "$TMP_IPV6"

# Argo Tunnel regions to query
REGIONS=("region1" "region2")

# Function to extract IPs from dig output
extract_ips() {
    local dig_output="$1"
    local ip_type="$2"
    
    echo "$dig_output" | grep -E "^[a-zA-Z0-9:.-]+\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+$ip_type[[:space:]]+" | awk '{print $NF}' | sort -V | uniq
}

# Query each region for both IPv4 and IPv6
for region in "${REGIONS[@]}"; do
    echo "Querying $region.v2.argotunnel.com..."
    
    # Get IPv4 addresses
    ipv4_output=$(dig A "${region}.v2.argotunnel.com" +short 2>/dev/null || true)
    if [ -n "$ipv4_output" ]; then
        # Append /32 to each IPv4 address
        echo "$ipv4_output" | sed 's/$/\/32/' >> "$TMP_IPV4"
    fi
    
    # Get IPv6 addresses
    ipv6_output=$(dig AAAA "${region}.v2.argotunnel.com" +short 2>/dev/null || true)
    if [ -n "$ipv6_output" ]; then
        # Append /128 to each IPv6 address
        echo "$ipv6_output" | sed 's/$/\/128/' >> "$TMP_IPV6"
    fi
done

# Sort and deduplicate
sort -V "$TMP_IPV4" | uniq > cloudflared/ipv4.txt
sort -V "$TMP_IPV6" | uniq > cloudflared/ipv6.txt

# Clean up
rm -f "$TMP_IPV4" "$TMP_IPV6"

echo "Cloudflare Argo Tunnel IP ranges downloaded successfully" 