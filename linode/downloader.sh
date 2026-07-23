#!/usr/bin/env bash
#
# Linode / Akamai — published geofeed (CSV with '#' comment lines; first column
# is the CIDR).
# https://www.linode.com/community/questions/19247/list-of-linodes-ip-ranges
# Source: https://geoip.linode.com/
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# One CSV carrying both families; drop comment lines, take the first column.
# write_ipv4/write_ipv6 each keep only their own family, so the same stream
# feeds both.
body="$(fetch https://geoip.linode.com/ | grep -v '^#' | cut -d, -f1)"
printf '%s\n' "$body" | write_ipv4 "$DIR"
printf '%s\n' "$body" | write_ipv6 "$DIR"

log "linode: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
