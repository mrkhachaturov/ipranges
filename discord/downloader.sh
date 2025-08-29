#!/bin/bash

# Discord IP Ranges Downloader
# Downloads Discord main domains and IPs from discord-voice-ips repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://raw.githubusercontent.com/GhostRooter0953/discord-voice-ips/master"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Downloading Discord IP ranges...${NC}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download main Discord domains and IPs
echo -e "${YELLOW}Downloading main Discord domains...${NC}"
curl -s -o main_domains.txt "$REPO_URL/main_domains/discord-main-ip-list" || {
    echo -e "${RED}Failed to download main domains${NC}"
    exit 1
}

# Download voice domains
echo -e "${YELLOW}Downloading voice domains...${NC}"
curl -s -o voice_domains.txt "$REPO_URL/voice_domains/discord-voice-ip-list" || {
    echo -e "${YELLOW}Warning: voice domains not available${NC}"
    touch voice_domains.txt
}

# Try to get some regional data
echo -e "${YELLOW}Attempting to download regional data...${NC}"
REGIONS=("russia" "bucharest" "finland" "frankfurt" "madrid" "milan" "rotterdam" "stockholm" "warsaw")

for region in "${REGIONS[@]}"; do
    echo -e "${YELLOW}  Trying $region...${NC}"
    # Try different possible file names
    for filename in "ipv4.txt" "ipv4_merged.txt" "ipv4"; do
        if curl -s -o "${region}_${filename}" "$REPO_URL/regions/$region/$filename" 2>/dev/null; then
            if [ -s "${region}_${filename}" ]; then
                echo -e "${GREEN}    Downloaded $region/$filename${NC}"
                break
            fi
        fi
        rm -f "${region}_${filename}" 2>/dev/null
    done
done

# Combine all IPs with strict validation and ensure proper CIDR notation
echo -e "${YELLOW}Combining and validating IP addresses...${NC}"
cat *.txt 2>/dev/null | \
    # Remove any non-IP content and ensure proper CIDR format
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    # Remove any lines with extra text or malformed content
    grep -v '[^0-9./]' | \
    # Add /32 to IPs without CIDR notation (single IPs)
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    # Sort and remove duplicates
    sort -u > discord_all.txt

# Count IPs
TOTAL_IPS=$(wc -l < discord_all.txt)
echo -e "${GREEN}Total Discord IPs found: $TOTAL_IPS${NC}"

# Copy files to project directory
cp discord_all.txt "$SCRIPT_DIR/ipv4.txt"
cp main_domains.txt "$SCRIPT_DIR/ipv4_main.txt"

# Clean up
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Discord IP ranges downloaded successfully!${NC}"
echo -e "${GREEN}Files created:${NC}"
echo -e "  - ipv4.txt (all Discord IPs)"
echo -e "  - ipv4_main.txt (main Discord domains only)"

# Generate merged file using the project's merge utility
if [ -f "../utils/merge.py" ]; then
    echo -e "${YELLOW}Generating merged CIDR file...${NC}"
    # Check if netaddr is available
    if python3 -c "import netaddr" 2>/dev/null; then
        python3 ../utils/merge.py --source ipv4.txt > ipv4_merged.txt
        echo -e "${GREEN}Merged file created: ipv4_merged.txt${NC}"
    else
        echo -e "${YELLOW}Warning: netaddr module not found. Install with: pip install netaddr${NC}"
        echo -e "${YELLOW}Creating empty merged file...${NC}"
        touch ipv4_merged.txt
    fi
fi
