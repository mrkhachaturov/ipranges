#!/usr/bin/env bash
#
# DeepL — known static ranges (AS60550, from IP2Location + PeeringDB) plus
# resolved service domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

STATIC_V4=(
    185.37.238.0/24
    194.124.204.0/24
    194.124.205.0/24
    194.124.206.0/23
    195.180.152.0/22
    104.18.36.122/32
    172.64.151.134/32
    8.6.112.6/32
    8.47.69.6/32
)
STATIC_V6=(
    2a13:b240::/48
    2a13:b240:1::/48
    2a13:b240:2::/47
    2a13:b240:4::/46
    2a13:b240:8::/45
    2a13:b240:10::/44
    2606:4700:440b::6812:247a/128
    2a06:98c1:3108::ac40:9786/128
)

DOMAINS=(
    deepl.com
    www.deepl.com
    api.deepl.com
    api-free.deepl.com
    www2.deepl.com
)
RESOLVERS=(8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9 77.88.8.8)

{
    printf '%s\n' "${STATIC_V4[@]}"
    for r in "${RESOLVERS[@]}"; do resolve_a "$r" "${DOMAINS[@]}"; done
} | write_ipv4 "$DIR"

{
    printf '%s\n' "${STATIC_V6[@]}"
    for r in "${RESOLVERS[@]}"; do resolve_aaaa "$r" "${DOMAINS[@]}"; done
} | write_ipv6 "$DIR"

log "deepl: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
