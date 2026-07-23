#!/usr/bin/env bash
#
# Cloudflare — published public IP ranges (separate v4 and v6 endpoints).
# https://www.cloudflare.com/ips/
# Source: https://www.cloudflare.com/ips-v4/ , https://www.cloudflare.com/ips-v6/
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

fetch https://www.cloudflare.com/ips-v4/ | write_ipv4 "$DIR"
fetch https://www.cloudflare.com/ips-v6/ | write_ipv6 "$DIR"

log "cloudflare: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
