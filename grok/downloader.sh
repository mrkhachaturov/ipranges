#!/usr/bin/env bash
#
# Grok / xAI — resolve the published service domains.
#
# xAI publishes no official prefix list, so resolution is the only source.
# Domain list seeded from rekryt/iplist config/ai/grok.com.json, which tracks
# the regional API endpoints (us-east-1, us-west-1, eu-west-1, asia-south1)
# that a plain grok.com lookup never surfaces.
#
# Note: x.com / twimg.com belong to twitter/, not here — despite the shared
# owner, they resolve to different infrastructure.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    grok.com
    www.grok.com
    assets.grok.com
    livekit.grok.com
    asia-south1-livekit.grok.com
    ssff.grok.com
    typeahead.grok.com
    transcription.grok-v2.x.ai
    x.ai
    www.x.ai
    api.x.ai
    eu-west-1.api.x.ai
    us-east-1.api.x.ai
    us-east-4-raw.api.x.ai
    us-south-1-pltr.api.x.ai
    us-west-1.api.x.ai
    us-west-1-raw.api.x.ai
    assets.x.ai
    console.x.ai
    data.x.ai
    deferred-chat.x.ai
    docs.x.ai
    grok.x.ai
    imgen.x.ai
    jf.x.ai
    login.x.ai
    status.x.ai
    trust.x.ai
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "grok: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
