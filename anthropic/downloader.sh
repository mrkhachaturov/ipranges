#!/usr/bin/env bash
#
# Anthropic / Claude — documented static ranges plus resolved service domains.
# Static IPs from Anthropic docs: inbound 160.79.104.0/23 + 2607:6bc0::/48,
# outbound (MCP tool calls) 160.79.104.0/21.
#
# Domain list from rekryt/iplist config/ai/claude.ai.json. Note that most
# Anthropic-owned hosts — claude.ai, claude.com and their subdomains, the
# anthropic.com zone, claudeusercontent.com, claudepages.dev, clau.de —
# currently answer with a single address inside the static 160.79.104.0/21,
# so they add no new space today. They are listed anyway so the list keeps
# working if Anthropic splits any of them onto separate infrastructure.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

STATIC_V4=(
    160.79.104.0/23
    160.79.104.0/21
)
STATIC_V6=(
    2607:6bc0::/48
)

DOMAINS=(
    # --- anthropic.com ---
    a-api.anthropic.com
    a-cdn.anthropic.com
    accounts.anthropic.com
    anthropic.com
    api.anthropic.com
    api.console.anthropic.com
    assets-proxy.anthropic.com
    assets.anthropic.com
    auth.anthropic.com
    cdn.anthropic.com
    console.anthropic.com
    events.anthropic.com
    files.anthropic.com
    mcp-proxy.anthropic.com
    mcp.anthropic.com
    metrics.anthropic.com
    models.anthropic.com
    oauth.anthropic.com
    s-cdn.anthropic.com
    sentry.anthropic.com
    static.anthropic.com
    statsig.anthropic.com
    status.anthropic.com
    support.anthropic.com
    telemetry.anthropic.com
    workbench.anthropic.com
    www.anthropic.com

    # --- claude.ai ---
    a-cdn.claude.ai
    a.preview.claude.ai
    api.claude.ai
    artifacts.claude.ai
    assets.claude.ai
    chat.claude.ai
    claude.ai
    console.claude.ai
    downloads.claude.ai
    downloads.preview.claude.ai
    pivot.claude.ai
    preview.claude.ai
    pro.claude.ai
    staging.claude.ai
    team.claude.ai
    workbench.claude.ai
    www.claude.ai

    # --- claude.com (the newer primary zone, incl. hosted MCP connectors) ---
    academy.claude.com
    claude.com
    code.claude.com
    console.claude.com
    docs.claude.com
    downloads.claude.com
    downloads.preview.claude.com
    gcal.mcp.claude.com
    gmail.mcp.claude.com
    hcls.mcp.claude.com
    links.email.claude.com
    microsoft365.mcp.claude.com
    platform.claude.com
    preview.claude.com
    privacy.claude.com
    pubmed.mcp.claude.com
    slack-channel.mcp.claude.com
    staging.claude.com
    status.claude.com
    support.claude.com
    url6377.updates.claude.com
    website.claude.com
    websitemain.claude.com
    www.claude.com

    # --- other Anthropic-owned zones ---
    clau.de
    claude.app
    claude.new
    claude.site
    claudemcpclient.com
    claudemcpcontent.com
    claudepages.dev
    claudestudio.com
    claudeusercontent.com
    media.claudeusercontent.com
    www.claudeusercontent.com
    modelcontextprotocol.com
    modelcontextprotocol.io
    modelcontextprotocol.net
    modelcontextprotocol.org

    # --- third-party SaaS the Claude web app talks to ---
    # NOT Anthropic infrastructure: Intercom (support widget) and Datadog
    # (browser telemetry). Included because the upstream list has them and the
    # web app breaks visibly without the widget, but they resolve to shared
    # Intercom/Datadog/AWS space — i.e. routing these sends unrelated traffic
    # from those providers through the same path. Delete this block to drop
    # them; nothing else depends on it.
    api-iam.intercom.io
    downloads.intercomcdn.com
    http-intake.logs.us5.datadoghq.com
    js.intercomcdn.com
    messenger-apps.intercom.io
    nexus-websocket-a.intercom.io
    static.intercomassets.com
    widget.intercom.io
    www.intercom.io
)

{
    printf '%s\n' "${STATIC_V4[@]}"
    resolve_a "${DOMAINS[@]}"
} | write_ipv4 "$DIR"

{
    printf '%s\n' "${STATIC_V6[@]}"
    resolve_aaaa "${DOMAINS[@]}"
} | write_ipv6 "$DIR"

log "anthropic: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
