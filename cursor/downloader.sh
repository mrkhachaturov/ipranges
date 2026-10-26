#!/usr/bin/env bash
#
# Cursor — resolve the cursor.sh backend hosts and the cursorvm.com cloud-VM
# regions (AWS, rotating). us{1..20} covers regions Cursor has not opened yet.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    api2.cursor.sh
    api2geo.cursor.sh
    api2direct.cursor.sh
    prod.authentication.cursor.sh
    metrics.cursor.sh
    repo42.cursor.sh
    api3.cursor.sh
    authenticator.cursor.sh
    us{1..20}.cursorvm.com
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "cursor: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
