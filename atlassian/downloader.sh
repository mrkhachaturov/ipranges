#!/bin/bash

# Atlassian IP Ranges Downloader
# Downloads Atlassian IPs from https://ip-ranges.atlassian.com/

set -euo pipefail
set -x

# Function to download and parse JSON from Atlassian endpoint
download_and_parse_json() {
    echo "Downloading Atlassian IP ranges from $1..." >&2
    curl --connect-timeout 60 --retry 3 --retry-delay 15 -s "${1}" \
    -H 'accept: application/json' \
    -H 'accept-language: en' \
    -H 'cache-control: no-cache' \
    -H 'pragma: no-cache' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36' \
    > /tmp/atlassian.json

    # Extract IPv4 addresses (CIDR format)
    jq '.items[] | select(.network | test("^[0-9]")) | .cidr' -r /tmp/atlassian.json > /tmp/atlassian-ipv4.txt

    # Extract IPv6 addresses (CIDR format)
    jq '.items[] | select(.network | test(":")) | .cidr' -r /tmp/atlassian.json > /tmp/atlassian-ipv6.txt

    sleep 5
}

# Download from Atlassian endpoint
download_and_parse_json "https://ip-ranges.atlassian.com/"

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/atlassian-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/atlassian-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/atlassian-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sort -V | uniq > /tmp/atlassian-ipv6-final.txt

# Save IPv4
[ -f "downloader.sh" ] && cp /tmp/atlassian-ipv4-final.txt ipv4.txt || cp /tmp/atlassian-ipv4-final.txt atlassian/ipv4.txt

# Save IPv6
[ -f "downloader.sh" ] && cp /tmp/atlassian-ipv6-final.txt ipv6.txt || cp /tmp/atlassian-ipv6-final.txt atlassian/ipv6.txt

# Clean up temporary files
rm -f /tmp/atlassian.json /tmp/atlassian-ipv4.txt /tmp/atlassian-ipv6.txt /tmp/atlassian-ipv4-final.txt /tmp/atlassian-ipv6-final.txt

echo "Atlassian IP ranges downloaded successfully!" >&2
