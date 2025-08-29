#!/bin/bash

# Discord IP Ranges Downloader
# Downloads Discord main domains and IPs from discord-voice-ips repository

set -euo pipefail
set -x

REPO_URL="https://raw.githubusercontent.com/GhostRooter0953/discord-voice-ips/master"

# Determine output directory based on current location
if [ -f "downloader.sh" ]; then
    # Running from discord directory
    OUTPUT_DIR="."
else
    # Running from project root (GitHub Actions)
    OUTPUT_DIR="discord"
fi

# get from public ranges
curl -s "$REPO_URL/main_domains/discord-main-ip-list" > /tmp/discord-main.txt

# get voice domains
curl -s "$REPO_URL/voice_domains/discord-voice-ip-list" > /tmp/discord-voice.txt || echo 'failed'

# get regional data
REGIONS=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")

for region in "${REGIONS[@]}"; do
    # Try different possible file names
    for filename in "ipv4.txt" "ipv4_merged.txt" "ipv4"; do
        if curl -s "$REPO_URL/regions/$region/$filename" > "/tmp/discord-${region}.txt" 2>/dev/null; then
            if [ -s "/tmp/discord-${region}.txt" ]; then
                break
            fi
        fi
        rm -f "/tmp/discord-${region}.txt" 2>/dev/null
    done
done

# Combine all IPs and ensure proper CIDR notation
cat /tmp/discord-*.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/discord-all.txt

# save ipv4
cp /tmp/discord-all.txt "$OUTPUT_DIR/ipv4.txt"
