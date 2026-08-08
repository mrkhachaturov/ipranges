#!/usr/bin/env bash
#
# Exa AI — resolve the published API, app and docs domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    exa.ai
    www.exa.ai
    api.exa.ai
    dashboard.exa.ai
    docs.exa.ai
    demo.exa.ai
    chat.exa.ai
    search.exa.ai
    auth.exa.ai
    research.exa.ai
    websets.exa.ai
    mcp.exa.ai
    status.exa.ai
    exa.sh
    metaphor.systems
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "exa: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
