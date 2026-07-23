#!/usr/bin/env bash
#
# GoogleBot — public crawler IP ranges.
# From: https://developers.google.com/search/docs/advanced/crawling/verifying-googlebot
# Source: https://developers.google.com/search/apis/ipranges/googlebot.json
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

json="$(fetch https://developers.google.com/search/apis/ipranges/googlebot.json)"

jq '.prefixes[] | [.ipv4Prefix][] | select(. != null)' -r <<<"$json" | write_ipv4 "$DIR"
jq '.prefixes[] | [.ipv6Prefix][] | select(. != null)' -r <<<"$json" | write_ipv6 "$DIR"

log "googlebot: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
