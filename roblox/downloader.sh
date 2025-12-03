#!/bin/bash

# Roblox IP Ranges Downloader
# 1. Fetches ALL IPs from ASNs (AS22697, AS11281, AS136766)
# 2. Finds missing IPs from logs (not in ASN)
# 3. Resolves domains from logs and adds IPs not in ASN
# 4. Merges everything together

set -euo pipefail
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Roblox ASNs
ROBLOX_ASNS=("AS22697" "AS11281" "AS136766")

# Function to fetch IP prefixes from ASN using bgpq3 (preferred), whois, or API
fetch_asn_prefixes() {
    local asn=$1
    local output_file=$2
    local asn_num=${asn#AS}  # Remove "AS" prefix if present
    
    # Try bgpq3 first (most professional tool)
    if command -v bgpq3 &> /dev/null; then
        if timeout 30 bgpq3 -4 -b -l "temp" "AS${asn_num}" 2>/dev/null | \
           grep -E "^[[:space:]]*[0-9]" | \
           sed 's/^[[:space:]]*//; s/,$//; s/;$//' | \
           grep -v ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched $asn using bgpq3" >&2
                return 0
            fi
        fi
    fi
    
    # Fallback to whois
    if command -v whois &> /dev/null; then
        if timeout 30 whois -h whois.radb.net -- "-i origin $asn" 2>/dev/null | \
           grep -E "^route:" | \
           awk '{print $2}' | \
           grep -v ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched $asn using whois" >&2
                return 0
            fi
        fi
    fi
    
    # Fallback to RIPE RIS API
    if command -v curl &> /dev/null; then
        if curl -s --max-time 30 "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS${asn_num}" 2>/dev/null | \
           grep -oE '"prefix":"[^"]+"' | \
           sed 's/"prefix":"//; s/"//' | \
           grep -v ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched $asn using RIPE RIS API" >&2
                return 0
            fi
        fi
    fi
    
    echo "Warning: Failed to fetch prefixes for $asn" >&2
    return 1
}

# Fetch ASN prefixes and merge them
echo "Fetching Roblox ASN prefixes..." >&2
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

for asn in "${ROBLOX_ASNS[@]}"; do
    fetch_asn_prefixes "$asn" "${TEMP_DIR}/${asn}.tmp" || true
done

# Merge all ASN prefixes - these will ALL be included in final output
cat "${TEMP_DIR}"/*.tmp 2>/dev/null | sort -u > "${TEMP_DIR}/asn_prefixes.txt"

# Check if we got any ASN prefixes
if [ ! -s "${TEMP_DIR}/asn_prefixes.txt" ]; then
    echo "Warning: No ASN prefixes fetched. Will use logs only." >&2
    > "${TEMP_DIR}/asn_prefixes.txt"  # Create empty file
fi

ASN_COUNT=$(wc -l < "${TEMP_DIR}/asn_prefixes.txt" | tr -d ' ')
echo "Fetched $ASN_COUNT CIDR ranges from ASNs" >&2

# Parse logs to find IPs/domains and compare with ASN
echo "Parsing logs to find IPs/domains not in ASN..." >&2
python3 "${SCRIPT_DIR}/parse_logs.py" "${TEMP_DIR}/asn_prefixes.txt" >&2

# Start with ALL ASN prefixes (convert to /32 if needed, but keep CIDR notation)
echo "Including all ASN prefixes..." >&2
cat "${TEMP_DIR}/asn_prefixes.txt" > /tmp/roblox-ipv4.txt

# Read missing IPs from logs (IPs not in ASN prefixes)
MISSING_IPS=()
if [ -f "${SCRIPT_DIR}/ips_missing.txt" ]; then
    while IFS= read -r ip; do
        [ -n "$ip" ] && MISSING_IPS+=("$ip")
    done < "${SCRIPT_DIR}/ips_missing.txt"
fi

# Add missing IPs from logs
for ip in "${MISSING_IPS[@]}"; do
    echo "$ip" >> /tmp/roblox-ipv4.txt
    echo "Adding missing IP from logs: $ip" >&2
done

# Read ALL domains from logs (we'll resolve them all to catch any IPs not in ASN)
ROBLOX_DOMAINS=()
if [ -f "${SCRIPT_DIR}/domains.txt" ]; then
    while IFS= read -r domain; do
        [ -n "$domain" ] && ROBLOX_DOMAINS+=("$domain")
    done < "${SCRIPT_DIR}/domains.txt"
fi

# Resolve domains using multiple DNS servers to get all CDN IPs
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9" "77.88.8.8")
for domain in "${ROBLOX_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    for dns in "${DNS_SERVERS[@]}"; do
        # Query multiple times to catch round-robin IPs
        for i in {1..3}; do
            dig +short A "$domain" @"$dns" >> /tmp/roblox-ipv4-resolved.txt || true
            dig +short AAAA "$domain" @"$dns" >> /tmp/roblox-ipv6.txt || true
            sleep 0.1  # Small delay between queries
        done
    done
done

# Filter resolved IPs - only keep those NOT already in ASN prefixes
if [ -s /tmp/roblox-ipv4-resolved.txt ]; then
    echo "Filtering resolved domain IPs (keeping only those not in ASN)..." >&2
    python3 "${SCRIPT_DIR}/filter_ips.py" "${TEMP_DIR}/asn_prefixes.txt" < /tmp/roblox-ipv4-resolved.txt >> /tmp/roblox-ipv4.txt
else
    echo "No IPs resolved from domains" >&2
fi

# Process IPv4 addresses
# Convert all to proper CIDR notation (keep existing CIDR, add /32 to plain IPs)
cat /tmp/roblox-ipv4.txt 2>/dev/null | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            # Already has CIDR or is just IP
            if [[ "$line" =~ / ]]; then
                echo "$line"
            else
                echo "${line}/32"
            fi
        fi
    done | \
    sort -V | uniq > /tmp/roblox-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/roblox-ipv6.txt 2>/dev/null | \
    grep ':' | \
    while IFS= read -r line; do
        if [[ "$line" =~ / ]]; then
            echo "$line"
        else
            echo "${line}/128"
        fi
    done | \
    sort -V | uniq > /tmp/roblox-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/roblox-ipv4-final.txt ipv4.txt || cp /tmp/roblox-ipv4-final.txt roblox/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/roblox-ipv6-final.txt ipv6.txt || cp /tmp/roblox-ipv6-final.txt roblox/ipv6.txt

FINAL_IPV4_COUNT=$(wc -l < /tmp/roblox-ipv4-final.txt | tr -d ' ')
FINAL_IPV6_COUNT=$(wc -l < /tmp/roblox-ipv6-final.txt | tr -d ' ')
echo "Final output: $FINAL_IPV4_COUNT IPv4 addresses, $FINAL_IPV6_COUNT IPv6 addresses" >&2
