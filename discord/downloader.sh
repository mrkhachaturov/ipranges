#!/usr/bin/env bash
#
# Discord — main + voice IP lists and per-region lists from the
# GhostRooter0953/discord-voice-ips repository. IPv4 only.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

REPO_URL="https://raw.githubusercontent.com/GhostRooter0953/discord-voice-ips/master"
REGIONS=(russia bucharest finland frankfurt madrid milan rotterdam stockholm warsaw)

# Combine every source; a single unreachable file is tolerated (|| true) and
# write_ipv4 validates + de-dupes. If ALL sources fail the result is empty and
# write_ipv4 keeps the existing list rather than wiping it.
{
    fetch "$REPO_URL/main_domains/discord-main-ip-list"  || true
    fetch "$REPO_URL/voice_domains/discord-voice-ip-list" || true
    for region in "${REGIONS[@]}"; do
        fetch "$REPO_URL/regions/$region/ipv4.txt" || true
    done
} | write_ipv4 "$DIR"

log "discord: $(count "$DIR/ipv4.txt") IPv4"
