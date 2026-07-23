#!/usr/bin/env bash
#
# DigitalOcean — published geofeed (CSV, first column is the CIDR).
# https://docs.digitalocean.com/products/platform/
# From: https://github.com/nccgroup/cloud_ip_ranges
# Source: https://www.digitalocean.com/geo/google.csv
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# One CSV carrying both families; first column is the CIDR. write_ipv4/write_ipv6
# each keep only their own family, so the same stream feeds both.
body="$(fetch https://www.digitalocean.com/geo/google.csv | cut -d, -f1)"
printf '%s\n' "$body" | write_ipv4 "$DIR"
printf '%s\n' "$body" | write_ipv6 "$DIR"

log "digitalocean: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
