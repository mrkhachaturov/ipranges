#!/bin/bash

# OpenAI IP Ranges Downloader
# Downloads OpenAI IPs from JSON endpoints and resolves additional AI domains

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

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
    "releases.openai.com"
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

# Normalize + validate via the shared lib (drops any non-CIDR / dig error text).
write_ipv4 "$DIR" < /tmp/openai-ipv4.txt
write_ipv6 "$DIR" < /tmp/openai-ipv6.txt

log "openai: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
