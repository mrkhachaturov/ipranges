#!/usr/bin/env bash
#
# Fastly — the CDN's published edge prefixes.
#   https://www.fastly.com/documentation/reference/api/utils/public-ip-list/
#
# The API answers "Restricted Country or Region" from some locations (e.g.
# Russia); run locally with HTTPS_PROXY set if needed. CI is unaffected.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

json="$(fetch https://api.fastly.com/public-ip-list)"

jq -r '.addresses[]'      <<<"$json" | write_ipv4 "$DIR"
jq -r '.ipv6_addresses[]' <<<"$json" | write_ipv6 "$DIR"

log "fastly: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
