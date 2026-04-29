#!/bin/bash

# OpenTofu IP Ranges Downloader
# Resolves OpenTofu domains: main site, registry, install script,
# search, API, and apt/rpm package repository.

set -euo pipefail
set -x

# OpenTofu domains to resolve
OPENTOFU_DOMAINS=(
    # Main site
    "opentofu.org"
    "www.opentofu.org"

    # Registry (provider/module index)
    "registry.opentofu.org"
    "search.opentofu.org"

    # Install script / binary distribution
    "get.opentofu.org"

    # API
    "api.opentofu.org"

    # apt/rpm package repository
    "packages.opentofu.org"
)

# Clean up temp files
rm -f /tmp/opentofu-ipv4.txt /tmp/opentofu-ipv6.txt

# Resolve OpenTofu domains
for domain in "${OPENTOFU_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    dig +short A "$domain" @8.8.8.8 >> /tmp/opentofu-ipv4.txt || echo 'failed'
    dig +short AAAA "$domain" @8.8.8.8 >> /tmp/opentofu-ipv6.txt || echo 'failed'
done

# Process IPv4 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/opentofu-ipv4.txt || true; } | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/opentofu-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/opentofu-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/opentofu-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/opentofu-ipv4-final.txt ipv4.txt || cp /tmp/opentofu-ipv4-final.txt opentofu/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/opentofu-ipv6-final.txt ipv6.txt || cp /tmp/opentofu-ipv6-final.txt opentofu/ipv6.txt

echo "Done!"
