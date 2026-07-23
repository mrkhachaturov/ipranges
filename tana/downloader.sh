#!/usr/bin/env bash
#
# Tana — resolve the Tana service domains to their A/AAAA addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Tana domains to resolve
TANA_DOMAINS=(
    "tana.inc"
    "app.tana.inc"
    "be.tana.inc"
    "desktop-update.tana.inc"
    "outliner.tana.inc"
)

resolve_a    8.8.8.8 "${TANA_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${TANA_DOMAINS[@]}" | write_ipv6 "$DIR"

log "tana: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
