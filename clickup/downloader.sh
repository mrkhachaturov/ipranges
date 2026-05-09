#!/bin/bash

# ClickUp IP Ranges Downloader
# Resolves ClickUp domains to IP addresses and includes specific IP addresses

set -euo pipefail
set -x

# ClickUp domains to resolve
CLICKUP_DOMAINS=(
    "clickup.com"
    "clickup.ada.support"
    "clickup-au.com"
    "app.clickup.com"
    "amazonses.com"
    "app-cdn.clickup.com"
    "attachments.clickup.com"
    "doc.clickup.com"
    "sharing-doc.clickup.com"
    "share-docs.clickup.com"
    "clickup-attachments.com"
    "p.clickup-attachments.com"
    "wildcard-probe.p.clickup-attachments.com"
    "attachments3.clickup.com"
    "ws.clickup.com"
    "help.clickup.com"
    "feedback.clickup.com"
    "outlook.clickup.com"
    "msteams.clickup.com"
    "forms.clickup.com"
    "share.clickup.com"
    "codox.io"
    "proxy.clickup.codox.io"
    "intercom.io"
    "exchangeratesapi.io"
    "sdk.split.io"
    "auth.split.io"
    "streaming.split.io"
    "datadoghq.com"
    "search.clickup-prod.com"
    "search.clickup-eu.com"
    "search.clickup-sg.com"
    "link.clickup.com"
    "unpkg.com"
    "chat.onmaven.app"
    "chameleon.io"
    "daily.co"
)

# Specific IP addresses from ClickUp allowlist
CLICKUP_IPS=(
    "35.163.183.252"
    "100.21.76.215"
    "52.33.15.82"
    "35.164.205.162"
    "44.229.175.52"
    "54.203.226.152"
    "54.240.69.229"
    "54.240.77.244"
    "54.240.120.83"
    "54.240.120.84"
    "54.240.120.89"
    "23.251.229.206"
)

# Clear temporary files
rm -f /tmp/clickup-ipv4.txt /tmp/clickup-ipv6.txt

# Add specific IP addresses (ensure proper CIDR notation)
for ip in "${CLICKUP_IPS[@]}"; do
    echo "$ip/32" >> /tmp/clickup-ipv4.txt
done

# Resolve domains to IP addresses (including CNAME records)
for domain in "${CLICKUP_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    
    # Get A records
    dig +short A "$domain" @8.8.8.8 >> /tmp/clickup-ipv4.txt || echo 'failed'
    
    # Get CNAME records and resolve them too
    cname=$(dig +short CNAME "$domain" @8.8.8.8 | head -1)
    if [ -n "$cname" ] && [ "$cname" != "failed" ]; then
        echo "Resolving CNAME $cname for $domain..." >&2
        dig +short A "$cname" @8.8.8.8 >> /tmp/clickup-ipv4.txt || echo 'failed'
    fi
    
    # Get AAAA records
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/clickup-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/clickup-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/clickup-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/clickup-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/clickup-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/clickup-ipv4-final.txt ipv4.txt || cp /tmp/clickup-ipv4-final.txt clickup/ipv4.txt

# save ipv6 (if any)
if [ -s /tmp/clickup-ipv6-final.txt ]; then
    [ -f "downloader.sh" ] && cp /tmp/clickup-ipv6-final.txt ipv6.txt || cp /tmp/clickup-ipv6-final.txt clickup/ipv6.txt
else
    [ -f "downloader.sh" ] && touch ipv6.txt || touch clickup/ipv6.txt
fi
