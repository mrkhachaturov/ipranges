#!/bin/bash

# Spotify IP Ranges Downloader
# Resolves Spotify domain names to IP addresses

set -euo pipefail
set -x

# Spotify domains to resolve
SPOTIFY_DOMAINS=(
    "pscdn.co"
    "scdn.co"
    "spoti.fi"
    "spotify-everywhere.com"
    "spotify.com"
    "spotify.design"
    "spotifycdn.com"
    "spotifycdn.net"
    "spotifycharts.com"
    "spotifycodes.com"
    "spotifyforbrands.com"
    "spotifyjobs.com"
    "audio-ak-spotify-com.akamaized.net"
    "audio4-ak-spotify-com.akamaized.net"
    "cdn-spotify-experiments.conductrics.com"
    "heads-ak-spotify-com.akamaized.net"
    "heads4-ak-spotify-com.akamaized.net"
    "spotify.com.edgesuite.net"
    "spotify.map.fastly.net"
    "spotify.map.fastlylb.net"
)

# get IPs from Spotify domains
for domain in "${SPOTIFY_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/spotify-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/spotify-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/spotify-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | \
    sed 's/$/\/32/' | \
    sort -V | uniq > /tmp/spotify-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/spotify-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/spotify-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/spotify-ipv4-final.txt ipv4.txt || cp /tmp/spotify-ipv4-final.txt spotify/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/spotify-ipv6-final.txt ipv6.txt || cp /tmp/spotify-ipv6-final.txt spotify/ipv6.txt
