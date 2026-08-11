#!/usr/bin/env bash
#
# OpenAI — published crawler prefixes plus resolved service domains.
#
# Two sources:
#   1. openai.com/{gptbot,searchbot,chatgpt-user}.json — the crawler egress
#      prefixes OpenAI publishes for allowlisting. IPv4 only; the feeds carry
#      no ipv6Prefix entries.
#   2. DNS resolution of the user-facing hosts, which live on Cloudflare and
#      Vercel and are absent from the crawler feeds.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

FEEDS=(
    https://openai.com/gptbot.json
    https://openai.com/searchbot.json
    https://openai.com/chatgpt-user.json
)

# Each hostname behind Cloudflare gets its own address set, so near-duplicates
# are worth querying separately — api./realtime./ws./search./sora./operator.
# all answer differently.
#
# Deliberately NOT listed: the 38 chatgpt-async-webps-prod-<region>-<n> hosts
# that rekryt/iplist enumerates. Every one of them is covered by the
# *.chatgpt.com wildcard and returns exactly chatgpt.com's addresses — 380
# extra queries for zero new IPs.
DOMAINS=(
    # chatgpt.com
    chatgpt.com
    www.chatgpt.com
    ab.chatgpt.com
    api.chatgpt.com
    ogimg.chatgpt.com
    operator.chatgpt.com
    privacy-pass-issuer.api.chatgpt.com
    realtime.chatgpt.com
    search.chatgpt.com
    sora.chatgpt.com
    webrtc.chatgpt.com
    ws.chatgpt.com

    # openai.com
    openai.com
    www.openai.com
    api.openai.com
    auth.openai.com
    auth0.openai.com
    beta.api.openai.com
    beta.openai.com
    cdn.openai.com
    community.openai.com
    developers.openai.com
    gym.openai.com
    help.openai.com
    jukebox.openai.com
    microscope.openai.com
    platform.api.openai.com
    platform.openai.com
    releases.openai.com
    spinningup.openai.com

    # chat.openai.com (legacy, still resolving)
    chat.openai.com
    android.chat.openai.com
    ios.chat.openai.com
    tcr9i.chat.openai.com

    # static/asset hosts
    cdn.oaistatic.com
    oaistatic.com
    files.oaiusercontent.com

    # other OpenAI-owned zones
    gpt3-openai.com
    openai.fund
)

{
    for url in "${FEEDS[@]}"; do
        fetch "$url" | jq -r '.prefixes[]?.ipv4Prefix // empty'
    done
    resolve_a "${DOMAINS[@]}"
} | write_ipv4 "$DIR"

resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "openai: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
