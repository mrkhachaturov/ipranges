#!/usr/bin/env bash
#
# Brevi Labs (Obsidian Copilot) — resolve the published service domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    brevilabs.com
    www.brevilabs.com
    api.brevilabs.com
    models.brevilabs.com
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "brevilabs: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
