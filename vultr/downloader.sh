#!/usr/bin/env bash
#
# Vultr / Constant — published geofeed (both families in one file).
# https://docs.vultr.com/vultr-ip-space
# Source: https://geofeed.constant.com/?text
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# One geofeed carrying both families. write_ipv4/write_ipv6 each keep only their
# own family, so the same stream feeds both.
body="$(fetch 'https://geofeed.constant.com/?text')"
printf '%s\n' "$body" | write_ipv4 "$DIR"
printf '%s\n' "$body" | write_ipv6 "$DIR"

log "vultr: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
