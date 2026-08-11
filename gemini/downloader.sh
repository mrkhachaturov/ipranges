#!/usr/bin/env bash
#
# Google Gemini / AI Studio / Vertex AI — resolved service hosts.
#
# WHY THIS EXISTS SEPARATELY FROM google/
#
# google/ carries Google's complete published prefix set (goog.txt, cloud.json,
# SPF netblocks) — every address here is already inside it. This provider is for
# ATTRIBUTION, not coverage: it lets you route Gemini somewhere other than the
# rest of Google. Because these are /32s inside google/'s /24s, a more-specific
# route wins, so announcing both works the way you want with no extra filtering.
#
# WHAT IS AND IS NOT SEPARABLE
#
# Google Frontend assigns a distinct last octet per hostname, so the web hosts
# really do separate — gemini.google.com answers .2 where www.google.com
# answers .119 and mail.google.com answers .17/.18/.19 in the same /24.
#
# The API does NOT separate. generativelanguage.googleapis.com, every regional
# *-aiplatform.googleapis.com, and plain www.googleapis.com all answer with the
# identical eight addresses 172.217.112.4 - 172.217.119.4. Routing the Gemini
# API therefore routes all of www.googleapis.com with it. Same story for
# aiplatform.googleapis.com, which shares the generic ".95" API frontend with
# oauth2.googleapis.com. That is inherent to Google's anycast frontend, not
# something a different domain list can fix.
#
# EXPECT CHURN
#
# These are GeoDNS-rotated /32s. The list will differ between runs.
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

DOMAINS=(
    # --- Gemini web app ---
    gemini.google.com

    # --- AI Studio (makersuite backends from rekryt/iplist) ---
    aistudio.google.com
    alkalimakersuite-pa.clients6.google.com
    webchannel-alkalimakersuite-pa.clients6.google.com

    # --- Gemini API ---
    generativelanguage.googleapis.com

    # --- Vertex AI, incl. the regional model endpoints ---
    aiplatform.googleapis.com
    us-central1-aiplatform.googleapis.com
    us-east1-aiplatform.googleapis.com
    us-east4-aiplatform.googleapis.com
    us-west1-aiplatform.googleapis.com
    us-west4-aiplatform.googleapis.com
    europe-west1-aiplatform.googleapis.com
    europe-west2-aiplatform.googleapis.com
    europe-west3-aiplatform.googleapis.com
    europe-west4-aiplatform.googleapis.com
    europe-west9-aiplatform.googleapis.com
    asia-northeast1-aiplatform.googleapis.com
    asia-northeast3-aiplatform.googleapis.com
    asia-southeast1-aiplatform.googleapis.com
    asia-south1-aiplatform.googleapis.com
    australia-southeast1-aiplatform.googleapis.com
    me-west1-aiplatform.googleapis.com
    southamerica-east1-aiplatform.googleapis.com

    # --- adjacent Google AI properties ---
    notebooklm.google
    notebooklm.google.com
    labs.google
    deepmind.google
    stitch.withgoogle.com
    app-companion-430619.appspot.com
)

resolve_a "${DOMAINS[@]}" | write_ipv4 "$DIR"
resolve_aaaa "${DOMAINS[@]}" | write_ipv6 "$DIR"

log "gemini: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
