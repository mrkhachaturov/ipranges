#!/bin/bash

# Twitter IP Ranges Downloader
# Downloads Twitter IPs from ASN routes and resolves additional Twitter domains

set -euo pipefail
set -x

# Twitter domains to resolve (additional to ASN routes)
TWITTER_DOMAINS=(
    "t.co"
    "twimg.com"
    "twitter.com"
    "x.com"
    "ads-twitter.com"
    "pscp.tv"
    "twtrdns.net"
    "twttr.net"
    "twttr.com"
    "abs.twimg.com"
)

# Function to get routes from Autonomous System
get_routes() {
    whois -h riswhois.ripe.net -- "-i origin $1" | grep '^route' | awk '{ print $2; }'
    whois -h whois.radb.net -- "-i origin $1" | grep '^route' | awk '{ print $2; }'
    whois -h rr.ntt.net -- "-i origin $1" | grep '^route' | awk '{ print $2; }'
    whois -h whois.rogerstelecom.net -- "-i origin $1" | grep '^route' | awk '{ print $2; }'
    whois -h whois.bgp.net.br -- "-i origin $1" | grep '^route' | awk '{ print $2; }'
}

# Get routes from ASNs
get_routes 'AS13414' > /tmp/twitter.txt || echo 'failed'
get_routes 'AS35995' >> /tmp/twitter.txt || echo 'failed'
get_routes 'AS54888' >> /tmp/twitter.txt || echo 'failed'
get_routes 'AS63179' >> /tmp/twitter.txt || echo 'failed'

# Resolve additional Twitter domains
for domain in "${TWITTER_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/twitter-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/twitter-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/twitter-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/twitter-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/twitter-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/twitter-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/twitter-ipv4-final.txt ipv4.txt || cp /tmp/twitter-ipv4-final.txt twitter/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/twitter-ipv6-final.txt ipv6.txt || cp /tmp/twitter-ipv6-final.txt twitter/ipv6.txt
