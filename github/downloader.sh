#!/bin/bash

# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-githubs-ip-addresses

set -euo pipefail
set -x


# get from public ranges
curl -s https://api.github.com/meta > /tmp/github.json


# Extract every string leaf in the payload and keep only valid CIDRs.
# Allowlist (grep the CIDR shape), NOT a denylist of known-bad keys: the
# /meta schema keeps growing non-CIDR fields (ssh_keys, ssh_key_fingerprints,
# domains, commit_signing_keys with embedded PGP blocks) and any new one would
# otherwise leak raw strings into the IP lists.
jq -r '.. | strings' /tmp/github.json \
    | grep -E '^[0-9a-fA-F:.]+/[0-9]+$' > /tmp/github-all.txt


# save ipv4
grep -v ':' /tmp/github-all.txt > /tmp/github-ipv4.txt

# save ipv6
grep ':' /tmp/github-all.txt > /tmp/github-ipv6.txt


# sort & uniq
sort -V /tmp/github-ipv4.txt | uniq > github/ipv4.txt
sort -V /tmp/github-ipv6.txt | uniq > github/ipv6.txt
