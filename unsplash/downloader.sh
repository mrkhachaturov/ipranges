#!/usr/bin/env bash
#
# Unsplash — resolve the site, API and image CDN hosts. Everything sits on
# Fastly: the site/API on the shared Fastly edge, images on imgix (also
# Fastly). GeoDNS-split per resolver, so the full RESOLVERS pool matters.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    unsplash.com
    www.unsplash.com
    api.unsplash.com
    views.unsplash.com
    instant.unsplash.com
    help.unsplash.com
    images.unsplash.com
    plus.unsplash.com
    unsplash.imgix.net
    unsplash-plus.imgix.net
    unsplash-assets.imgix.net
    unsplash-premium-photos-production.imgix.net
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "unsplash: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
