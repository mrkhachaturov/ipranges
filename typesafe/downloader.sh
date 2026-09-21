#!/usr/bin/env bash
#
# TypeSafe AI — resolve the published service domains.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    typesafe.ai
    www.typesafe.ai
    docs.typesafe.ai
    console.typesafe.ai
    api.typesafe.ai
    evals.typesafe.ai
    login.typesafe.ai
    status.typesafe.ai
    # trust.typesafe.ai is a Vanta-hosted trust center (CNAME to vantatrust.com)
    # and daggerverse.docs.typesafe.ai is GitHub Pages — third-party pages with
    # no TypeSafe traffic, so they are deliberately left out.
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "typesafe: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
