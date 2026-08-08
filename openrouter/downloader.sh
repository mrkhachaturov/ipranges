#!/usr/bin/env bash
#
# OpenRouter — resolve the site, status and Clerk-backed auth domains.
# The API has no dedicated host: it is served from openrouter.ai/api/v1.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    openrouter.ai
    www.openrouter.ai
    status.openrouter.ai
    clerk.openrouter.ai
    accounts.openrouter.ai
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "openrouter: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
