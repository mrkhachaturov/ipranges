#!/usr/bin/env bash
#
# Kino.pub — resolve the public domains across several resolvers to catch the
# full set of CDN round-robin addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(kino.pub www.kino.pub api.kino.pub)
RESOLVERS=(8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9 77.88.8.8)

# Shared CDN edge addresses that are not Kino.pub-specific — excluded on the
# bare form, before write_ipv4 appends /32.
EXCLUDE_V4='^(172\.66\.40\.229|172\.66\.43\.27)$'

for resolver in "${RESOLVERS[@]}"; do
    resolve_a "$resolver" "${DOMAINS[@]}"
done | grep -Ev "$EXCLUDE_V4" | write_ipv4 "$DIR"

for resolver in "${RESOLVERS[@]}"; do
    resolve_aaaa "$resolver" "${DOMAINS[@]}"
done | write_ipv6 "$DIR"

log "kino-pub: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
