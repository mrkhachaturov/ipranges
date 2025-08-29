#!/bin/bash

# Discord IP Ranges Downloader
# Downloads Discord main domains and IPs from discord-voice-ips repository

set -euo pipefail
set -x

REPO_URL="https://raw.githubusercontent.com/GhostRooter0953/discord-voice-ips/master"

# get from public ranges
curl -s "$REPO_URL/main_domains/discord-main-ip-list" > /tmp/discord-main.txt

# get voice domains
curl -s "$REPO_URL/voice_domains/discord-voice-ip-list" > /tmp/discord-voice.txt || echo 'failed'

# get regional data
REGIONS=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")

for region in "${REGIONS[@]}"; do
    curl -s "$REPO_URL/regions/$region/ipv4.txt" > "/tmp/discord-${region}.txt" || echo 'failed'
done

# Combine all IPs and ensure proper CIDR notation
cat /tmp/discord-*.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/discord-all.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/discord-all.txt ipv4.txt || cp /tmp/discord-all.txt discord/ipv4.txt
