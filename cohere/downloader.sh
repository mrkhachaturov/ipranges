#!/usr/bin/env bash
#
# Cohere — resolve the published domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    cohere.com
    www.cohere.com
    cohere.ai
    www.cohere.ai
    cohere.io
    api.cohere.com
    api.cohere.ai
    production.api.cohere.com
    production.api.cohere.ai
    staging.api.cohere.com
    staging.api.cohere.ai
    stg.api.cohere.ai
    north.cohere.com
    dashboard.cohere.com
    dashboard.cohere.ai
    docs.cohere.com
    docs.cohere.ai
    coral.cohere.com
    coral.cohere.ai
    chat.cohere.com
    txt.cohere.com
    txt.cohere.ai
    status.cohere.com
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "cohere: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
