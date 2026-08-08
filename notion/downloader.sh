#!/usr/bin/env bash
#
# Notion — resolve the published domain allowlist plus a set of static IPs.
# (dig +short A already follows CNAME chains to the final A records, so no
# separate CNAME step is needed.)
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

NOTION_DOMAINS=(
    "notion.com"
    "notion.site"
    "notion.so"
    "api.notion.com"
    "img.notionusercontent.com"
    "notionusercontent.com"
    "www.notion.so"
    "exp.notion.so"
    "http-inputs-notion.splunkcloud.com"
    "identity.notion.so"
    "msgstore.www.notion.so"
    "o324374.ingest.us.sentry.io"
    "file.notion.so"
    "s3-us-west-2.amazonaws.com"
    "s3.amazonaws.com"
)

# Specific IP addresses from the Notion allowlist (bare -> /32 by write_ipv4).
NOTION_IPS=(
    "18.158.108.139"
    "3.66.39.119"
    "52.58.241.199"
    "18.185.27.82"
    "18.158.230.148"
    "63.176.43.161"
    "18.198.182.154"
    "3.77.47.230"
    "63.176.24.113"
)

{
    printf '%s\n' "${NOTION_IPS[@]}"
    resolve_a "${NOTION_DOMAINS[@]}"
} | write_ipv4 "$DIR"

resolve_aaaa "${NOTION_DOMAINS[@]}" | write_ipv6 "$DIR"

log "notion: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
