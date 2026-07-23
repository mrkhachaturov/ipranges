#!/usr/bin/env bash
#
# OpenTofu — resolve the main site, registry, install script, search, API and
# apt/rpm package repository domains to their A/AAAA addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# OpenTofu domains to resolve
OPENTOFU_DOMAINS=(
    # Main site
    "opentofu.org"
    "www.opentofu.org"

    # Registry (provider/module index)
    "registry.opentofu.org"
    "search.opentofu.org"

    # Install script / binary distribution
    "get.opentofu.org"

    # API
    "api.opentofu.org"

    # apt/rpm package repository
    "packages.opentofu.org"
)

resolve_a    8.8.8.8 "${OPENTOFU_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${OPENTOFU_DOMAINS[@]}" | write_ipv6 "$DIR"

log "opentofu: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
