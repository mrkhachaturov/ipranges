#!/usr/bin/env bash
#
# ClickUp — resolve the published domain allowlist plus a set of static IPs.
# (dig +short A already follows CNAME chains to the final A records, so no
# separate CNAME step is needed.)
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

CLICKUP_DOMAINS=(
    "clickup.com"
    "clickup.ada.support"
    "clickup-au.com"
    "app.clickup.com"
    "amazonses.com"
    "app-cdn.clickup.com"
    "attachments.clickup.com"
    "doc.clickup.com"
    "sharing-doc.clickup.com"
    "share-docs.clickup.com"
    "clickup-attachments.com"
    "p.clickup-attachments.com"
    "wildcard-probe.p.clickup-attachments.com"
    "attachments3.clickup.com"
    "ws.clickup.com"
    "help.clickup.com"
    "feedback.clickup.com"
    "outlook.clickup.com"
    "msteams.clickup.com"
    "forms.clickup.com"
    "share.clickup.com"
    "codox.io"
    "proxy.clickup.codox.io"
    "intercom.io"
    "exchangeratesapi.io"
    "sdk.split.io"
    "auth.split.io"
    "streaming.split.io"
    "datadoghq.com"
    "search.clickup-prod.com"
    "search.clickup-eu.com"
    "search.clickup-sg.com"
    "link.clickup.com"
    "unpkg.com"
    "chat.onmaven.app"
    "chameleon.io"
    "daily.co"
)

# Specific IP addresses from the ClickUp allowlist (bare -> /32 by write_ipv4).
CLICKUP_IPS=(
    "35.163.183.252"
    "100.21.76.215"
    "52.33.15.82"
    "35.164.205.162"
    "44.229.175.52"
    "54.203.226.152"
    "54.240.69.229"
    "54.240.77.244"
    "54.240.120.83"
    "54.240.120.84"
    "54.240.120.89"
    "23.251.229.206"
)

{
    printf '%s\n' "${CLICKUP_IPS[@]}"
    resolve_a "${CLICKUP_DOMAINS[@]}"
} | write_ipv4 "$DIR"

resolve_aaaa "${CLICKUP_DOMAINS[@]}" | write_ipv6 "$DIR"

log "clickup: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
