#!/usr/bin/env bash
#
# Amazon (AWS) — public IP ranges.
# Source: https://ip-ranges.amazonaws.com/ip-ranges.json
# https://docs.aws.amazon.com/general/latest/gr/aws-ip-ranges.html
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

json="$(fetch https://ip-ranges.amazonaws.com/ip-ranges.json)"
jq -r '.prefixes[] | [.ip_prefix][] | select(. != null)' <<<"$json" | write_ipv4 "$DIR"
jq -r '.ipv6_prefixes[] | [.ipv6_prefix][] | select(. != null)' <<<"$json" | write_ipv6 "$DIR"

log "amazon: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
