#!/usr/bin/env bash
#
# Spotify — resolve the Spotify service and CDN domains to their A/AAAA
# addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Spotify domains to resolve
SPOTIFY_DOMAINS=(
    "pscdn.co"
    "scdn.co"
    "spoti.fi"
    "spotify-everywhere.com"
    "spotify.com"
    "spotify.design"
    "spotifycdn.com"
    "spotifycdn.net"
    "spotifycharts.com"
    "spotifycodes.com"
    "spotifyforbrands.com"
    "spotifyjobs.com"
    "audio-ak-spotify-com.akamaized.net"
    "audio4-ak-spotify-com.akamaized.net"
    "cdn-spotify-experiments.conductrics.com"
    "heads-ak-spotify-com.akamaized.net"
    "heads4-ak-spotify-com.akamaized.net"
    "spotify.com.edgesuite.net"
    "spotify.map.fastly.net"
    "spotify.map.fastlylb.net"
)

resolve_a    8.8.8.8 "${SPOTIFY_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${SPOTIFY_DOMAINS[@]}" | write_ipv6 "$DIR"

log "spotify: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
