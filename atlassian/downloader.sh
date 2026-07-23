#!/usr/bin/env bash
#
# Atlassian — published IP ranges.
# Source: https://ip-ranges.atlassian.com/
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# The endpoint expects browser-like headers; preserve the original set.
json="$(fetch https://ip-ranges.atlassian.com/ \
    -H 'accept: application/json' \
    -H 'accept-language: en' \
    -H 'cache-control: no-cache' \
    -H 'pragma: no-cache' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36')"

jq -r '.items[] | select(.network | test("^[0-9]")) | .cidr' <<<"$json" | write_ipv4 "$DIR"
jq -r '.items[] | select(.network | test(":")) | .cidr' <<<"$json" | write_ipv6 "$DIR"

log "atlassian: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
