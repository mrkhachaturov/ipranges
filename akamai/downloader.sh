#!/bin/bash

# Akamai IP Ranges Downloader
# Fetches ALL IPs from Akamai ASNs (AS16625, AS20940, AS32787, AS21342)

set -euo pipefail
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Akamai ASNs
AKAMAI_ASNS=("AS16625" "AS20940" "AS32787" "AS21342")

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

# Function to fetch IPv6 prefixes from ASN
fetch_asn_prefixes_v6() {
    local asn=$1
    local output_file=$2
    local asn_num=${asn#AS}  # Remove "AS" prefix if present
    
    # Try bgpq3 first
    if command -v bgpq3 &> /dev/null; then
        if timeout 30 bgpq3 -6 -b -l "temp" "AS${asn_num}" 2>/dev/null | \
           grep -E "^[[:space:]]*[0-9a-fA-F:]" | \
           sed 's/^[[:space:]]*//; s/,$//; s/;$//' | \
           grep ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched IPv6 for $asn using bgpq3" >&2
                return 0
            fi
        fi
    fi
    
    # Fallback to whois
    if command -v whois &> /dev/null; then
        if timeout 30 whois -h whois.radb.net -- "-i origin $asn" 2>/dev/null | \
           grep -E "^route6:" | \
           awk '{print $2}' | \
           grep ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched IPv6 for $asn using whois" >&2
                return 0
            fi
        fi
    fi
    
    # Fallback to RIPE RIS API
    if command -v curl &> /dev/null; then
        if curl -s --max-time 30 "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS${asn_num}" 2>/dev/null | \
           grep -oE '"prefix":"[^"]+"' | \
           sed 's/"prefix":"//; s/"//' | \
           grep ":" | \
           sort -u > "$output_file" 2>/dev/null; then
            if [ -s "$output_file" ]; then
                echo "Fetched IPv6 for $asn using RIPE RIS API" >&2
                return 0
            fi
        fi
    fi
    
    echo "Warning: Failed to fetch IPv6 prefixes for $asn" >&2
    return 1
}

# Fetch ASN prefixes and merge them
echo "Fetching Akamai ASN prefixes..." >&2
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Fetch IPv4 prefixes
for asn in "${AKAMAI_ASNS[@]}"; do
    fetch_asn_prefixes "$asn" "${TEMP_DIR}/${asn}_ipv4.tmp" || true
done

# Fetch IPv6 prefixes
for asn in "${AKAMAI_ASNS[@]}"; do
    fetch_asn_prefixes_v6 "$asn" "${TEMP_DIR}/${asn}_ipv6.tmp" || true
done

# Merge all IPv4 ASN prefixes
cat "${TEMP_DIR}"/*_ipv4.tmp 2>/dev/null | sort -u > "${TEMP_DIR}/asn_ipv4.txt"

# Merge all IPv6 ASN prefixes
cat "${TEMP_DIR}"/*_ipv6.tmp 2>/dev/null | sort -u > "${TEMP_DIR}/asn_ipv6.txt"

# Check if we got any ASN prefixes
if [ ! -s "${TEMP_DIR}/asn_ipv4.txt" ]; then
    echo "Warning: No IPv4 ASN prefixes fetched." >&2
    > "${TEMP_DIR}/asn_ipv4.txt"  # Create empty file
fi

if [ ! -s "${TEMP_DIR}/asn_ipv6.txt" ]; then
    echo "Warning: No IPv6 ASN prefixes fetched." >&2
    > "${TEMP_DIR}/asn_ipv6.txt"  # Create empty file
fi

IPV4_COUNT=$(wc -l < "${TEMP_DIR}/asn_ipv4.txt" | tr -d ' ')
IPV6_COUNT=$(wc -l < "${TEMP_DIR}/asn_ipv6.txt" | tr -d ' ')
echo "Fetched $IPV4_COUNT IPv4 CIDR ranges and $IPV6_COUNT IPv6 CIDR ranges from ASNs" >&2

# Process IPv4 addresses - ensure proper CIDR notation
cat "${TEMP_DIR}/asn_ipv4.txt" 2>/dev/null | \
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
    sort -V | uniq > /tmp/akamai-ipv4-normalized.txt

# Process IPv6 addresses - ensure proper CIDR notation
cat "${TEMP_DIR}/asn_ipv6.txt" 2>/dev/null | \
    grep ':' | \
    while IFS= read -r line; do
        if [[ "$line" =~ / ]]; then
            echo "$line"
        else
            echo "${line}/128"
        fi
    done | \
    sort -V | uniq > /tmp/akamai-ipv6-normalized.txt

# Aggregate CIDRs using Python (Akamai-specific aggregation)
echo "Aggregating CIDR ranges..." >&2
python3 << 'PYTHON_SCRIPT'
import sys
try:
    import netaddr
except ImportError:
    print("Warning: netaddr not available, skipping aggregation", file=sys.stderr)
    import shutil
    shutil.copy('/tmp/akamai-ipv4-normalized.txt', '/tmp/akamai-ipv4-final.txt')
    shutil.copy('/tmp/akamai-ipv6-normalized.txt', '/tmp/akamai-ipv6-final.txt')
    sys.exit(0)
import sys
import netaddr

def aggregate_cidrs(cidr_list, is_ipv6=False):
    """
    Aggregate CIDR ranges by:
    1. First merging overlapping ranges
    2. Then aggregating adjacent ranges into larger blocks where possible
    """
    if not cidr_list:
        return []
    
    # Parse all CIDRs
    networks = []
    for cidr_str in cidr_list:
        cidr_str = cidr_str.strip()
        if not cidr_str:
            continue
        try:
            networks.append(netaddr.IPNetwork(cidr_str))
        except:
            continue
    
    if not networks:
        return []
    
    # Step 1: Merge overlapping ranges
    merged = list(netaddr.cidr_merge(networks))
    
    # Step 2: Aggregate adjacent ranges into larger blocks
    # For IPv4: Try to aggregate /24s into /16s or /12s
    # For IPv6: Try to aggregate smaller blocks into larger ones
    if is_ipv6:
        # For IPv6, try aggregating /48s into /32s or /40s
        min_prefix = 48
        target_prefixes = [40, 32]
    else:
        # For IPv4, try aggregating /24s into /16s or /12s
        min_prefix = 24
        target_prefixes = [16, 12]
    
    result = []
    i = 0
    while i < len(merged):
        current = merged[i]
        aggregated = False
        
        # If current range is small enough, try to aggregate with adjacent ranges
        if current.prefixlen >= min_prefix:
            # Try each target prefix size
            for target_prefix in target_prefixes:
                if current.prefixlen > target_prefix:
                    # Get the parent network at target_prefix
                    try:
                        parent = current.supernet(prefixlen=target_prefix)
                        
                        # Check if we can aggregate multiple ranges into this parent
                        # Collect all ranges that fit within this parent
                        candidates = [current]
                        j = i + 1
                        while j < len(merged):
                            if merged[j] in parent:
                                candidates.append(merged[j])
                                j += 1
                            else:
                                break
                        
                        # If we have enough coverage of the parent, use the parent
                        # Calculate coverage: if we have most of the parent covered, aggregate
                        total_candidates_size = sum(c.size for c in candidates)
                        parent_size = parent.size
                        coverage = total_candidates_size / parent_size
                        
                        # If coverage is high (>= 0.8), aggregate into parent
                        if coverage >= 0.8:
                            result.append(parent)
                            i = j
                            aggregated = True
                            break
                    except:
                        pass
        
        if not aggregated:
            result.append(current)
            i += 1
    
    # Final merge to handle any new overlaps from aggregation
    return list(netaddr.cidr_merge(result))

# Process IPv4
try:
    with open('/tmp/akamai-ipv4-normalized.txt', 'r') as f:
        ipv4_lines = [line.strip() for line in f if line.strip()]
    
    if ipv4_lines:
        aggregated_ipv4 = aggregate_cidrs(ipv4_lines, is_ipv6=False)
        with open('/tmp/akamai-ipv4-final.txt', 'w') as f:
            for cidr in sorted(aggregated_ipv4):
                f.write(str(cidr) + '\n')
        print(f"Aggregated IPv4: {len(ipv4_lines)} -> {len(aggregated_ipv4)} ranges", file=sys.stderr)
    else:
        open('/tmp/akamai-ipv4-final.txt', 'w').close()
except Exception as e:
    print(f"Error aggregating IPv4: {e}", file=sys.stderr)
    # Fallback to non-aggregated
    import shutil
    shutil.copy('/tmp/akamai-ipv4-normalized.txt', '/tmp/akamai-ipv4-final.txt')

# Process IPv6
try:
    with open('/tmp/akamai-ipv6-normalized.txt', 'r') as f:
        ipv6_lines = [line.strip() for line in f if line.strip()]
    
    if ipv6_lines:
        aggregated_ipv6 = aggregate_cidrs(ipv6_lines, is_ipv6=True)
        with open('/tmp/akamai-ipv6-final.txt', 'w') as f:
            for cidr in sorted(aggregated_ipv6):
                f.write(str(cidr) + '\n')
        print(f"Aggregated IPv6: {len(ipv6_lines)} -> {len(aggregated_ipv6)} ranges", file=sys.stderr)
    else:
        open('/tmp/akamai-ipv6-final.txt', 'w').close()
except Exception as e:
    print(f"Error aggregating IPv6: {e}", file=sys.stderr)
    # Fallback to non-aggregated
    import shutil
    shutil.copy('/tmp/akamai-ipv6-normalized.txt', '/tmp/akamai-ipv6-final.txt')
PYTHON_SCRIPT

# Save results
cp /tmp/akamai-ipv4-final.txt "${SCRIPT_DIR}/ipv4.txt"
cp /tmp/akamai-ipv6-final.txt "${SCRIPT_DIR}/ipv6.txt"

FINAL_IPV4_COUNT=$(wc -l < /tmp/akamai-ipv4-final.txt | tr -d ' ')
FINAL_IPV6_COUNT=$(wc -l < /tmp/akamai-ipv6-final.txt | tr -d ' ')
echo "Final output: $FINAL_IPV4_COUNT IPv4 addresses, $FINAL_IPV6_COUNT IPv6 addresses" >&2

