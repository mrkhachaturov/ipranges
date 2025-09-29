#!/bin/bash

# Notion IP Ranges Downloader
# Resolves Notion domain names to IP addresses and includes specific IP ranges

set -euo pipefail
set -x

# Notion domains to resolve
NOTION_DOMAINS=(
    "notion.com"
    "notion.site"
    "notion.so"
    "api.notion.com"
    "img.notionusercontent.com"
    "notionusercontent.com"
	"www.notion.so"
	"exp.notion.so"
	"http-inputs-notion.splunkcloud.com"
	"identity.notion.so"
	"msgstore.www.notion.so"
	"o324374.ingest.us.sentry.io"
    
)

# Specific IP addresses from Notion allowlist
NOTION_IPS=(
    "18.158.108.139"
    "3.66.39.119"
    "52.58.241.199"
    "18.185.27.82"
    "18.158.230.148"
    "63.176.43.161"
    "18.198.182.154"
    "3.77.47.230"
    "63.176.24.113"
)

# Clear temporary files
rm -f /tmp/notion-ipv4.txt /tmp/notion-ipv6.txt

# Add specific IP addresses (ensure proper CIDR notation)
for ip in "${NOTION_IPS[@]}"; do
    echo "$ip/32" >> /tmp/notion-ipv4.txt
done

# Resolve domains to IP addresses
for domain in "${NOTION_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/notion-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/notion-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/notion-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/notion-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/notion-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/notion-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/notion-ipv4-final.txt ipv4.txt || cp /tmp/notion-ipv4-final.txt notion/ipv4.txt

# save ipv6 (if any)
if [ -s /tmp/notion-ipv6-final.txt ]; then
    [ -f "downloader.sh" ] && cp /tmp/notion-ipv6-final.txt ipv6.txt || cp /tmp/notion-ipv6-final.txt notion/ipv6.txt
else
    # Create empty IPv6 file if no IPv6 addresses found
    [ -f "downloader.sh" ] && touch ipv6.txt || touch notion/ipv6.txt
fi
