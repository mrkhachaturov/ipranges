#!/usr/bin/env bash
#
# PaddlePaddle — resolve the hosts used by PaddlePaddle / PaddleOCR model +
# wheel downloads and by AI Studio.
#
# These names are served by Baidu GeoDNS: the answer depends on where the
# query comes from. A single resolver returns only one of several regional
# addresses, so every domain is queried against a spread of public resolvers
# (US / EU / RU / CN) to collect the full set. Do not "simplify" this back to
# one resolver — it silently loses half the addresses.
#
# Much of this space is China Telecom / China Unicom IDC rather than Baidu's
# own ASNs, which is why this provider exists alongside `baidu`.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

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
# in the list because it returns the in-China view when it does answer.
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "77.88.8.8" "9.9.9.9" "114.114.114.114")

# Baidu's CDN leaks RFC1918 answers (e.g. baidubce.com -> 10.58.144.74), so
# private and loopback space is dropped explicitly on the bare form, before
# write_ipv4 appends /32.
EXCLUDE_V4='^(10\.|127\.|169\.254\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)'

for dns in "${DNS_SERVERS[@]}"; do
    resolve_a "$dns" "${PADDLE_DOMAINS[@]}"
done | grep -vE "$EXCLUDE_V4" | write_ipv4 "$DIR"

for dns in "${DNS_SERVERS[@]}"; do
    resolve_aaaa "$dns" "${PADDLE_DOMAINS[@]}"
done | write_ipv6 "$DIR"

log "paddle: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
