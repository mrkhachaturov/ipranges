#!/usr/bin/env bash
#
# Games — resolve gaming service domains, plus common subdomains of a couple
# of wildcard domains, to their A/AAAA addresses.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Gaming domains to resolve
DOMAINS=(
    "game.brawlstarsgame.com"
    "ingest.sentry.io"
    "game-assets.clashofclans.com"
    "gamea.clashofclans.com"
    "clashofclans.inbox.supercell.com"
    "supercell.com"
    "game.clashroyaleapp.com"
    "brawlstars.com"
    "wbgames.com"
)

# Wildcard domains (will try common subdomains)
WILDCARD_DOMAINS=(
    "wbagora.com"
    "wbinsights.com"
)

# Common subdomains to try for wildcard domains
SUBDOMAINS=("www" "api" "cdn" "assets" "static" "game" "app" "auth" "login")

# Expand wildcard domains into the concrete names to resolve: the root domain
# plus each subdomain prefix — same set the old per-name loop resolved.
ALL_DOMAINS=("${DOMAINS[@]}")
for domain in "${WILDCARD_DOMAINS[@]}"; do
    ALL_DOMAINS+=("$domain")
    for subdomain in "${SUBDOMAINS[@]}"; do
        ALL_DOMAINS+=("$subdomain.$domain")
    done
done

resolve_a    8.8.8.8 "${ALL_DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa 8.8.8.8 "${ALL_DOMAINS[@]}" | write_ipv6 "$DIR"

log "games: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
