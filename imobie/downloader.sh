#!/usr/bin/env bash
#
# iMobie / FocuSee — account, license, downloads and AI voice/model hosts.
# Spread across imobie.com and imobie-resource.com; several are fronted by
# Cloudflare / CloudFront / Incapsula, so the resolved IPs are shared CDN edges.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    # account / login / verification
    account.imobie.com
    my.imobie.com
    # FocuSee product backend, store, license/upgrade
    focusee.imobie.com
    # launch config + downloads
    dl.imobie.com
    download.imobie.com
    # AI features: voice/transcription + whisper model downloads
    focusee-voice.imobie.com
    focusee.imobie-resource.com
    # general site / store
    imobie.com
    www.imobie.com
    store.imobie.com
    imobie-resource.com
    www.imobie-resource.com
)

resolve_a    8.8.8.8 "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "imobie: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
