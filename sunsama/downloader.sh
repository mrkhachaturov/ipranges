#!/usr/bin/env bash
#
# Sunsama — resolve the Sunsama service domains to their A/AAAA addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Sunsama domains to resolve
SUNSAMA_DOMAINS=(
    "sunsama.com"
    "www.sunsama.com"
    "app.sunsama.com"
    "api.sunsama.com"
    "beta.sunsama.com"
    "help.sunsama.com"
    "sunsama.net"
    "www.sunsama.net"
    "app.sunsama.net"
    "api.sunsama.net"
)

resolve_a "${SUNSAMA_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${SUNSAMA_DOMAINS[@]}" | write_ipv6 "$DIR"

log "sunsama: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
