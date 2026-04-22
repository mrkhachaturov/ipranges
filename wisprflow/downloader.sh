#!/bin/bash

# Wispr Flow IP Ranges Downloader
# Resolves Wispr Flow / Wispr Aria / FlowVoice domains and third-party
# service dependencies (Supabase, S3, Baseten) used by the app.

set -euo pipefail
set -x

# Wispr Flow domains to resolve
WISPRFLOW_DOMAINS=(
    # Primary Wispr Flow
    "wisprflow.ai"
    "api.wisprflow.ai"
    "api-east.wisprflow.ai"
    "cloud.wisprflow.ai"
    "cdn.wisprflow.com"
    "dl.wisprflow.com"
    "docs.wisprflow.ai"

    # Wispr Aria
    "aria-web.wispr.ai"
    "staging.aria-web.wispr.ai"

    # FlowVoice
    "flowvoice.ai"
    "cloud.flowvoice.ai"

    # Third-party service dependencies
    "dodjkfqhwrzqjwkfnthl.supabase.co"
    "wispr-flow-cdn.s3.us-west-2.amazonaws.com"
    "chain-o232k03l.api.baseten.co"
)

# Clean up temp files
rm -f /tmp/wisprflow-ipv4.txt /tmp/wisprflow-ipv6.txt

# Resolve Wispr Flow domains
for domain in "${WISPRFLOW_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/wisprflow-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/wisprflow-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/wisprflow-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/wisprflow-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/wisprflow-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/wisprflow-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/wisprflow-ipv4-final.txt ipv4.txt || cp /tmp/wisprflow-ipv4-final.txt wisprflow/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/wisprflow-ipv6-final.txt ipv6.txt || cp /tmp/wisprflow-ipv6-final.txt wisprflow/ipv6.txt

echo "Done!"
