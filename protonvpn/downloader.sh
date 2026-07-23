#!/usr/bin/env bash
#
# ProtonVPN — entry IPs of every logical VPN server.
# Source: https://api.protonvpn.ch/vpn/logicals
#         .LogicalServers[].Servers[].EntryIP  (bare IPv4 addresses)
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# The API requires an app-version header; without it it returns 400.
# EntryIP is a bare IPv4 address — write_ipv4 upgrades it to /32 and validates,
# so nulls or any non-address value are dropped rather than published.
fetch https://api.protonvpn.ch/vpn/logicals \
    -H 'x-pm-appversion: Other' -H 'x-pm-apiversion: 3' \
    | jq -r '.LogicalServers[].Servers[].EntryIP // empty' \
    | write_ipv4 "$DIR"

# The endpoint publishes no IPv6, so ipv6.txt is left as-is.

log "protonvpn: $(count "$DIR/ipv4.txt") IPv4 CIDRs"
