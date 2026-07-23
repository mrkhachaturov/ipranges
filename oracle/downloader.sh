#!/usr/bin/env bash
#
# Oracle Cloud Infrastructure — public IP ranges (IPv4 only; no IPv6 published).
# https://docs.oracle.com/en-us/iaas/Content/General/Concepts/addressranges.htm
# From: https://github.com/nccgroup/cloud_ip_ranges
# Source: https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# ipv6 not provided
fetch https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json \
    | jq '.regions[] | [.cidrs][] | .[].cidr | select(. != null)' -r \
    | write_ipv4 "$DIR"

log "oracle: $(count "$DIR/ipv4.txt") IPv4 CIDRs"
