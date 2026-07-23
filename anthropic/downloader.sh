#!/usr/bin/env bash
#
# Anthropic / Claude — documented static ranges plus resolved service domains.
# Static IPs from Anthropic docs: inbound 160.79.104.0/23 + 2607:6bc0::/48,
# outbound (MCP tool calls) 160.79.104.0/21.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

STATIC_V4=(
    160.79.104.0/23
    160.79.104.0/21
)
STATIC_V6=(
    2607:6bc0::/48
)

DOMAINS=(
    claude.ai
    api.anthropic.com
    console.anthropic.com
    www.anthropic.com
    anthropic.com
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

log "anthropic: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
