#!/bin/bash

# PaddlePaddle IP Ranges Downloader
# Resolves the hosts used by PaddlePaddle / PaddleOCR model + wheel downloads
# and by AI Studio.
#
# These names are served by Baidu GeoDNS: the answer depends on where the
# query comes from. A single resolver returns only one of several regional
# addresses, so every domain is queried against a spread of public resolvers
# (US / EU / RU / CN) to collect the full set. Do not "simplify" this back to
# one `dig @8.8.8.8` — it silently loses half the addresses.
#
# Much of this space is China Telecom / China Unicom IDC rather than Baidu's
# own ASNs, which is why this provider exists alongside `baidu`.

set -euo pipefail
set -x

# PaddlePaddle / AI Studio / BOS bucket hosts to resolve
PADDLE_DOMAINS=(
    "paddlepaddle.org.cn"
    "www.paddlepaddle.org.cn"
    "aistudio.baidu.com"
    "paddle-model-ecology.bj.bcebos.com"
    "paddle-inference-lib.bj.bcebos.com"
    "paddle-wheel.bj.bcebos.com"
    "paddleocr.bj.bcebos.com"
    "paddledet.bj.bcebos.com"
    "paddleseg.bj.bcebos.com"
    "paddle-imagenet-models-name.bj.bcebos.com"
    "bj.bcebos.com"
    "gz.bcebos.com"
    "su.bcebos.com"
)

# Spread of resolvers — Baidu GeoDNS answers differ per vantage point.
# 114.114.114.114 (CN) is frequently unreachable from outside China; it stays
# in the list because it returns the in-China view when it does answer, but
# every query below is capped by DIG_OPTS so an unreachable resolver costs
# 2s instead of the 15s default (5s timeout x 3 tries).
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "77.88.8.8" "9.9.9.9" "114.114.114.114")

# Hard caps so one dead resolver cannot stall the whole run.
DIG_OPTS=(+time=2 +tries=1)

# Clean up temp files
rm -f /tmp/paddle-ipv4.txt /tmp/paddle-ipv6.txt
rm -f /tmp/paddle-ipv4-final.txt /tmp/paddle-ipv6-final.txt
touch /tmp/paddle-ipv4.txt /tmp/paddle-ipv6.txt

# Resolve every domain against every resolver
for domain in "${PADDLE_DOMAINS[@]}"; do
    echo "Resolving $domain..." >&2
    for dns in "${DNS_SERVERS[@]}"; do
        dig "${DIG_OPTS[@]}" +short A "$domain" @"$dns" >> /tmp/paddle-ipv4.txt || echo 'failed'
        dig "${DIG_OPTS[@]}" +short AAAA "$domain" @"$dns" >> /tmp/paddle-ipv6.txt || echo 'failed'
    done
done

# Process IPv4 addresses (ensure proper CIDR notation).
# Baidu's CDN leaks RFC1918 answers (e.g. baidubce.com -> 10.58.144.74), so
# private and loopback space is dropped explicitly.
{ grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /tmp/paddle-ipv4.txt || true; } | \
    grep -vE '^(10\.|127\.|169\.254\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)' | \
    sed 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$/\1\/32/' | \
    sort -V | uniq > /tmp/paddle-ipv4-final.txt

# Process IPv6 addresses (ensure proper CIDR notation)
{ grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /tmp/paddle-ipv6.txt || true; } | \
    sed 's/^\([^/]*\)$/\1\/128/' | \
    sort -V | uniq > /tmp/paddle-ipv6-final.txt

# save ipv4
[ -f "downloader.sh" ] && cp /tmp/paddle-ipv4-final.txt ipv4.txt || cp /tmp/paddle-ipv4-final.txt paddle/ipv4.txt

# save ipv6
[ -f "downloader.sh" ] && cp /tmp/paddle-ipv6-final.txt ipv6.txt || cp /tmp/paddle-ipv6-final.txt paddle/ipv6.txt

echo "Done!"
