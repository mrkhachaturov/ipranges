#!/usr/bin/env bash
#
# Coder — resolve the published domains (coder.com, registry.coder.com, etc.).
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    coder.com
    www.coder.com
    registry.coder.com
    docs.coder.com
    dev.coder.com
)

resolve_a    8.8.8.8 "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "coder: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
