#!/usr/bin/env bash
#
# Wispr Flow — resolve the Wispr Flow / Wispr Aria / FlowVoice domains and the
# third-party service dependencies (Supabase, S3, Baseten) used by the app.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Wispr Flow domains to resolve
WISPRFLOW_DOMAINS=(
    # Primary Wispr Flow
    "wisprflow.ai"
    "api.wisprflow.ai"
    "api-east.wisprflow.ai"
    "cloud.wisprflow.ai"
    "cdn.wisprflow.com"
    "dl.wisprflow.com"
    "docs.wisprflow.ai"

    # Wispr Aria
    "aria-web.wispr.ai"
    "staging.aria-web.wispr.ai"

    # FlowVoice
    "flowvoice.ai"
    "cloud.flowvoice.ai"

    # Third-party service dependencies
    "dodjkfqhwrzqjwkfnthl.supabase.co"
    "wispr-flow-cdn.s3.us-west-2.amazonaws.com"
    "chain-o232k03l.api.baseten.co"
)

resolve_a    8.8.8.8 "${WISPRFLOW_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${WISPRFLOW_DOMAINS[@]}" | write_ipv6 "$DIR"

log "wisprflow: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
