#!/usr/bin/env bash
#
# Devolutions — resolve the published service domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    devolutions.net
    api.devolutions.com
    api.devolutions.net
    account.devolutions.com
    login.devolutions.com
    cloud.devolutions.net
    hub.devolutions.com
    cdn.devolutions.net
    store.devolutions.net
    portal.devolutions.com
    redirection.devolutions.com
    telemetry2.devolutions.net
    send.devolutions.com
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "devolutions: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
