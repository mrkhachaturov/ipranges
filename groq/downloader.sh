#!/usr/bin/env bash
#
# Groq — resolve the API and console domains to their A/AAAA addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Groq domains to resolve
GROQ_DOMAINS=(
    "groq.com"
    "api.groq.com"
    "console.groq.com"
)

resolve_a "${GROQ_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${GROQ_DOMAINS[@]}" | write_ipv6 "$DIR"

log "groq: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
