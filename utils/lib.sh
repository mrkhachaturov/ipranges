#!/usr/bin/env bash
#
# utils/lib.sh — shared primitives for provider downloaders.
#
# The problem this solves: every downloader used to hand-roll its own grep/sed
# to turn raw dig/whois/jq output into a CIDR list. Each copy was a chance to
# get it subtly wrong, and several did — leaking PGP blocks, bare IPs and dig
# error strings into published files. This centralises the dangerous part once.
#
# Usage from a downloader:
#
#     #!/usr/bin/env bash
#     set -euo pipefail
#     DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     source "$DIR/../utils/lib.sh"
#
#     { resolve_a 8.8.8.8 example.com; } | write_ipv4 "$DIR"
#
# DIR resolves to the absolute provider directory whether the script is invoked
# from the repo root (the GitHub Action: `bash provider/downloader.sh`) or from
# inside the provider dir (`bash downloader.sh`). That single line replaces the
# old `[ -f downloader.sh ] && ... || ...` dual-mode guess.
#
# Feed raw address lines — bare or CIDR, in any order, from any source — into
# write_ipv4 / write_ipv6. They keep only well-formed CIDRs of the right family,
# upgrade bare addresses to /32 or /128, de-dupe and sort. Nothing else survives.

# Opt-in command trace: run any downloader with DEBUG=1 for full xtrace.
[ "${DEBUG:-0}" = "1" ] && set -x

# log <msg...>: progress to stderr (never pollutes the address stream on stdout).
log() { printf '%s\n' "$*" >&2; }

# count <file>: number of non-empty lines (for summaries).
count() { grep -c . "$1" 2>/dev/null || printf '0\n'; }

# fetch <url> [extra curl args...]: HTTP GET that fails on error status and
# retries transient faults. Extra args pass through, e.g. -H 'x-api-key: ...'.
# Honours the standard http_proxy / https_proxy env vars automatically (useful
# when a source is geo-blocked — export https_proxy=http://host:port).
# (The old `curl -s` would silently write an HTML error page into the pipeline.)
fetch() { curl -fsSL --retry 3 --retry-delay 2 --max-time 60 "$@"; }

# Per-query dig caps so one unreachable resolver can't stall a run for ~15s.
_DIG_OPTS=(+time=3 +tries=1)

# resolve_a <resolver> <domain...>: print A records, one per line. dig errors
# go to /dev/null and never enter the stream.
resolve_a() {
    local resolver="$1"; shift
    local domain
    for domain in "$@"; do
        dig +short "${_DIG_OPTS[@]}" A "$domain" "@$resolver" 2>/dev/null || true
    done
}

# resolve_aaaa <resolver> <domain...>: print AAAA records, one per line.
resolve_aaaa() {
    local resolver="$1"; shift
    local domain
    for domain in "$@"; do
        dig +short "${_DIG_OPTS[@]}" AAAA "$domain" "@$resolver" 2>/dev/null || true
    done
}

# asn_routes <ASN>: print announced route/route6 prefixes from public IRR mirrors.
# Emits both families; write_ipv4/write_ipv6 each keep only what they want.
asn_routes() {
    local asn="$1" server
    for server in riswhois.ripe.net whois.radb.net rr.ntt.net \
                  whois.rogerstelecom.net whois.bgp.net.br; do
        whois -h "$server" -- "-i origin $asn" 2>/dev/null \
            | awk '/^route6?:/ { print $2 }' || true
    done
}

# --- normalization (the part that used to be copy-pasted and get it wrong) ---

# Keep valid IPv4 lines, upgrade bare addresses to /32, sort and de-dupe.
_finalize_v4() {
    grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$' \
        | sed -E 's#^([0-9]{1,3}(\.[0-9]{1,3}){3})$#\1/32#' \
        | sort -V | uniq
}

# Keep valid IPv6 lines, upgrade bare addresses to /128, sort and de-dupe.
# Requires at least one ':' so bare hex tokens and error text can't slip through.
_finalize_v6() {
    grep -E '^[0-9A-Fa-f:]*:[0-9A-Fa-f:]*(/[0-9]{1,3})?$' \
        | sed -E 's#^([0-9A-Fa-f:]+)$#\1/128#' \
        | sort -V | uniq
}

# _write <outfile> <finalize_fn>: run the filter over stdin into a temp file and
# atomically replace <outfile> — but refuse to overwrite a non-empty list with
# an empty result, so a transient fetch/DNS failure can never wipe good data.
_write() {
    local out="$1" filter="$2" tmp
    tmp="$(mktemp "${out}.XXXXXX")"
    "$filter" > "$tmp" || true          # grep no-match must not abort the run
    if [ ! -s "$tmp" ] && [ -s "$out" ]; then
        log "WARN: ${out} — empty result this run, keeping existing $(count "$out") entries"
        rm -f "$tmp"
        return 0
    fi
    mv -f "$tmp" "$out"
}

# write_ipv4 <provider_dir>: read address lines from stdin -> <dir>/ipv4.txt.
write_ipv4() { _write "$1/ipv4.txt" _finalize_v4; }

# write_ipv6 <provider_dir>: read address lines from stdin -> <dir>/ipv6.txt.
write_ipv6() { _write "$1/ipv6.txt" _finalize_v6; }
