#!/usr/bin/env bash
#
# Facebook / Meta — announced ASN route prefixes.
#
# https://www.workplace.com/resources/tech/it-configuration/domain-whitelisting
# https://www.irr.net/docs/list.html
# https://bgp.he.net/search?search%5Bsearch%5D=facebook&commit=Search
# https://github.com/SecOps-Institute/FacebookIPLists/blob/master/facebook_asn_list.lst
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

ASNS=(AS32934 AS54115 AS63293 AS149642)

# Query the IRRs once — asn_routes emits both route (v4) and route6 (v6)
# prefixes; each write_* keeps only its own family.
routes="$(for asn in "${ASNS[@]}"; do asn_routes "$asn"; done)"

printf '%s\n' "$routes" | write_ipv4 "$DIR"
printf '%s\n' "$routes" | write_ipv6 "$DIR"

log "facebook: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
