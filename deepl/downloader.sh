#!/bin/bash

# DeepL IP Ranges Downloader
# Downloads DeepL IPs from known ranges and resolves domains

set -euo pipefail
set -x

# DeepL domains to resolve
DEEPL_DOMAINS=(
    "deepl.com"
    "www.deepl.com"
    "api.deepl.com"
    "api-free.deepl.com"
    "www2.deepl.com"
)

# Static IPs from DeepL infrastructure (AS60550)
# Source: IP2Location and PeeringDB

# IPv4 ranges
echo "185.37.238.0/24" > /tmp/deepl-ipv4.txt
echo "194.124.204.0/24" >> /tmp/deepl-ipv4.txt
echo "194.124.205.0/24" >> /tmp/deepl-ipv4.txt
echo "194.124.206.0/23" >> /tmp/deepl-ipv4.txt
echo "195.180.152.0/22" >> /tmp/deepl-ipv4.txt

# Known IPv4 addresses
echo "104.18.36.122/32" >> /tmp/deepl-ipv4.txt
echo "172.64.151.134/32" >> /tmp/deepl-ipv4.txt

# IPv6 ranges
echo "2a13:b240::/48" > /tmp/deepl-ipv6.txt
echo "2a13:b240:1::/48" >> /tmp/deepl-ipv6.txt
echo "2a13:b240:2::/47" >> /tmp/deepl-ipv6.txt
echo "2a13:b240:4::/46" >> /tmp/deepl-ipv6.txt
echo "2a13:b240:8::/45" >> /tmp/deepl-ipv6.txt
echo "2a13:b240:10::/44" >> /tmp/deepl-ipv6.txt

# Known IPv6 addresses
echo "2606:4700:440b::6812:247a/128" >> /tmp/deepl-ipv6.txt
echo "2a06:98c1:3108::ac40:9786/128" >> /tmp/deepl-ipv6.txt

# Resolve additional domains
for domain in "${DEEPL_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 | sed 's/$/\/32/' >> /tmp/deepl-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 | sed 's/$/\/128/' >> /tmp/deepl-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses
cat /tmp/deepl-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sort -V | uniq > /tmp/deepl-ipv4-final.txt

# Process IPv6 addresses
cat /tmp/deepl-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sort -V | uniq > /tmp/deepl-ipv6-final.txt

# sort & uniq
sort -V /tmp/deepl-ipv4-final.txt | uniq > deepl/ipv4.txt
sort -V /tmp/deepl-ipv6-final.txt | uniq > deepl/ipv6.txt

