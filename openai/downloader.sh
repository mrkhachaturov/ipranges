#!/bin/bash

# OpenAI IP Ranges Downloader
# Downloads OpenAI IPs from JSON endpoints and resolves additional AI domains

set -euo pipefail
set -x

# AI domains to resolve (additional to JSON endpoints)
AI_DOMAINS=(
    "ab.chatgpt.com"
    "api.openai.com"
    "arena.openai.com"
    "auth.openai.com"
    "auth0.openai.com"
    "beta.api.openai.com"
    "beta.openai.com"
    "blog.openai.com"
    "cdn.oaistatic.com"
    "cdn.openai.com"
    "community.openai.com"
    "contest.openai.com"
    "debate-game.openai.com"
    "discuss.openai.com"
    "files.oaiusercontent.com"
    "gpt3-openai.com"
    "gym.openai.com"
    "help.openai.com"
    "ios.chat.openai.com"
    "jukebox.openai.com"
    "labs.openai.com"
    "microscope.openai.com"
    "oaistatic.com"
    "openai.com"
    "openai.fund"
    "openai.org"
    "platform.api.openai.com"
    "platform.openai.com"
    "spinningup.openai"
    "chat.openai.com"
    "chatgpt.com"
	"i0.wp.com"
)

# Function to download and parse JSON from OpenAI endpoints
download_and_parse_json() {
    curl --connect-timeout 60 --retry 3 --retry-delay 15 -s "${1}" \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
    -H 'accept-language: en' \
    -H 'cache-control: no-cache' \
    -H 'pragma: no-cache' \
    -H 'priority: u=0, i' \
    -H 'sec-ch-ua: "Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'sec-fetch-dest: document' \
    -H 'sec-fetch-mode: navigate' \
    -H 'sec-fetch-site: none' \
    -H 'sec-fetch-user: ?1' \
    -H 'upgrade-insecure-requests: 1' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36' \
    > /tmp/openai.json

    jq '.prefixes[] | [.ipv4Prefix][] | select(. != null)' -r /tmp/openai.json > /tmp/openai.txt

    # save ipv4
    grep -v ':' /tmp/openai.txt >> /tmp/openai-ipv4.txt

    # ipv6 not provided

    sleep 10
}

# Download from JSON endpoints
download_and_parse_json "https://openai.com/chatgpt-user.json"
download_and_parse_json "https://openai.com/searchbot.json"
download_and_parse_json "https://openai.com/gptbot.json"

# Resolve additional AI domains
for domain in "${AI_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/openai-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/openai-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
cat /tmp/openai-ipv4.txt 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/openai-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
cat /tmp/openai-ipv6.txt 2>/dev/null | \
    grep ':' | \
    sed 's/$/\/128/' | \
    sort -V | uniq > /tmp/openai-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/openai-ipv4-final.txt ipv4.txt || cp /tmp/openai-ipv4-final.txt openai/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/openai-ipv6-final.txt ipv6.txt || cp /tmp/openai-ipv6-final.txt openai/ipv6.txt
