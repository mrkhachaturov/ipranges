#!/bin/bash

# CloudFront IP Ranges Downloader
# Fetches all AWS CloudFront IP ranges from official AWS IP ranges JSON

set -euo pipefail
set -x

echo "Fetching CloudFront IP ranges from AWS..." >&2

# Fetch CloudFront IP ranges from AWS
curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | \
    jq -r '.prefixes[] | select(.service == "CLOUDFRONT") | .ip_prefix' > ipv4.txt

# Also fetch IPv6 CloudFront ranges if any
curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | \
    jq -r '.ipv6_prefixes[]? | select(.service == "CLOUDFRONT") | .ipv6_prefix' > ipv6.txt 2>/dev/null || touch ipv6.txt

# Create merged versions
if [ -f "downloader.sh" ]; then
    # We're in the cloudfront directory
    python3 ../utils/merge.py --source ipv4.txt > ipv4_merged.txt
    if [ -s ipv6.txt ]; then
        python3 ../utils/merge.py --source ipv6.txt > ipv6_merged.txt
    else
        touch ipv6_merged.txt
    fi
else
    # We're running from parent directory
    python3 utils/merge.py --source cloudfront/ipv4.txt > cloudfront/ipv4_merged.txt
    if [ -s cloudfront/ipv6.txt ]; then
        python3 utils/merge.py --source cloudfront/ipv6.txt > cloudfront/ipv6_merged.txt
    else
        touch cloudfront/ipv6_merged.txt
    fi
fi

echo "CloudFront IP ranges updated successfully!" >&2
