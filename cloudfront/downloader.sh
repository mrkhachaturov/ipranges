#!/usr/bin/env bash
#
# CloudFront — AWS CloudFront IP ranges, filtered from the AWS IP ranges JSON.
# Source: https://ip-ranges.amazonaws.com/ip-ranges.json
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

json="$(fetch https://ip-ranges.amazonaws.com/ip-ranges.json)"
jq -r '.prefixes[] | select(.service == "CLOUDFRONT") | .ip_prefix' <<<"$json" | write_ipv4 "$DIR"
jq -r '.ipv6_prefixes[]? | select(.service == "CLOUDFRONT") | .ipv6_prefix' <<<"$json" | write_ipv6 "$DIR"

log "cloudfront: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
