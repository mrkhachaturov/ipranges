#!/usr/bin/env bash
#
# Apple iCloud Private Relay — egress IP ranges (CSV, first column is the CIDR).
# https://developer.apple.com/icloud/prepare-your-network-for-icloud-private-relay/
# Source: https://mask-api.icloud.com/egress-ip-ranges.csv
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# One CSV carrying both families; first column is the CIDR. write_ipv4/write_ipv6
# each keep only their own family, so the same stream feeds both.
body="$(fetch https://mask-api.icloud.com/egress-ip-ranges.csv | cut -d',' -f1)"
printf '%s\n' "$body" | write_ipv4 "$DIR"
printf '%s\n' "$body" | write_ipv6 "$DIR"

log "apple-proxy: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
