#!/usr/bin/env bash
#
# Bing (bingbot) — published IP ranges.
# Source: https://www.bing.com/toolbox/bingbot.json
# https://www.bing.com/webmasters/help/verify-bingbot-2195837f
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Since 2 Nov 2022 some prefixes contain a hidden character (​):
# https://i.imgur.com/I4LiPYr.png — strip all unprintable characters first.
fetch https://www.bing.com/toolbox/bingbot.json \
    | tr -cd "[:print:]\n" \
    | jq -r '.prefixes[] | [.ipv4Prefix][] | select(. != null)' \
    | write_ipv4 "$DIR"

# IPv6 not provided.

log "bing: $(count "$DIR/ipv4.txt") IPv4 CIDRs"
