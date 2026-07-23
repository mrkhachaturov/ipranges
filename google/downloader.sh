#!/usr/bin/env bash
#
# Google — Cloud + GoogleBot + goog.txt, plus _netblocks/SPF discovery.
#   https://support.google.com/a/answer/60764
#   https://cloud.google.com/compute/docs/faq#find_ip_range
#   https://developers.google.com/search/docs/advanced/crawling/verifying-googlebot
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

# Published prefix lists.
fetch https://www.gstatic.com/ipranges/goog.txt                         > /tmp/goog.txt
fetch https://www.gstatic.com/ipranges/cloud.json                       > /tmp/cloud.json
fetch https://developers.google.com/search/apis/ipranges/googlebot.json > /tmp/googlebot.json

# _netblocks*.google.com TXT records (SPF-style), walked until one comes back empty.
: > /tmp/netblocks.txt
txt="$(dig TXT _netblocks.google.com +short @8.8.8.8)"
idx=2
while [[ -n "${txt}" ]]; do
  echo "${txt}" | tr '[:space:]+' "\n" | grep ':' | cut -d: -f2- >> /tmp/netblocks.txt
  txt="$(dig TXT _netblocks${idx}.google.com +short @8.8.8.8)"
  ((idx++))
done

# Recursively expand SPF include: chains into ip4:/ip6: prefixes.
get_dns_spf() {
   dig @8.8.8.8 +short txt "$1" |
   tr ' ' '\n' |
   while read -r entry; do
      case "$entry" in
             ip4:*) echo "${entry#*:}" ;;
             ip6:*) echo "${entry#*:}" ;;
         include:*) get_dns_spf "${entry#*:}" ;;
      esac
   done
}
get_dns_spf "_cloud-netblocks.googleusercontent.com" >> /tmp/netblocks.txt
get_dns_spf "_spf.google.com" >> /tmp/netblocks.txt

# Combine every source into one stream; write_ipv4 / write_ipv6 each keep only
# their own family and validate, so no manual grep-by-colon splitting.
{
  cat /tmp/goog.txt
  jq -r '.prefixes[] | [.ipv4Prefix, .ipv6Prefix][] | select(. != null)' /tmp/cloud.json
  jq -r '.prefixes[] | [.ipv4Prefix, .ipv6Prefix][] | select(. != null)' /tmp/googlebot.json
  cat /tmp/netblocks.txt
} > /tmp/google-all.txt

write_ipv4 "$DIR" < /tmp/google-all.txt
write_ipv6 "$DIR" < /tmp/google-all.txt

log "google: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
