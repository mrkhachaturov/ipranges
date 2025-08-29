#!/bin/bash

# Games IP Ranges Downloader
# Resolves gaming domain names to IP addresses

set -euo pipefail
set -x

# Gaming domains to resolve
DOMAINS=(
    "game.brawlstarsgame.com"
    "ingest.sentry.io"
    "game-assets.clashofclans.com"
    "gamea.clashofclans.com"
    "clashofclans.inbox.supercell.com"
    "supercell.com"
    "game.clashroyaleapp.com"
    "brawlstars.com"
    "wbgames.com"
)

# Wildcard domains (will try common subdomains)
WILDCARD_DOMAINS=(
    "wbagora.com"
    "wbinsights.com"
)

# Common subdomains to try for wildcard domains
SUBDOMAINS=("www" "api" "cdn" "assets" "static" "game" "app" "auth" "login")

# get IPs from direct domains
for domain in "${DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/games-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/games-ipv6.txt || echo 'failed'
done

# get IPs from wildcard domains (try subdomains)
for domain in "${WILDCARD_DOMAINS[@]}"; do
    echo "Resolving wildcard domain $domain..." >&2
    # Try root domain
    dig +short A "$domain" @8.8.8.8 >> /tmp/games-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/games-ipv6.txt || echo 'failed'
    
    # Try common subdomains
    for subdomain in "${SUBDOMAINS[@]}"; do
        echo "Trying $subdomain.$domain..." >&2
        dig +short A "$subdomain.$domain" @8.8.8.8 >> /tmp/games-ipv4.txt || echo 'failed'
        dig +short AAAA "$subdomain.$domain" @8.8.8.8 >> /tmp/games-ipv6.txt || echo 'failed'
    done
done

# Process IPv4 addresses
cat /tmp/games-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | \
    sed 's/$/\/32/' | \
    sort -V | uniq > /tmp/games-ipv4-final.txt

# Process IPv6 addresses
cat /tmp/games-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/games-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/games-ipv4-final.txt ipv4.txt || cp /tmp/games-ipv4-final.txt games/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/games-ipv6-final.txt ipv6.txt || cp /tmp/games-ipv6-final.txt games/ipv6.txt
