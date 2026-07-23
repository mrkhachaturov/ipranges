#!/usr/bin/env bash
#
# Telegram — published CIDR list (both families in one file).
# Source: https://core.telegram.org/resources/cidr.txt
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# One file carrying both families. write_ipv4/write_ipv6 each keep only their
# own family, so the same stream feeds both.
body="$(fetch https://core.telegram.org/resources/cidr.txt)"
printf '%s\n' "$body" | write_ipv4 "$DIR"
printf '%s\n' "$body" | write_ipv6 "$DIR"

log "telegram: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
