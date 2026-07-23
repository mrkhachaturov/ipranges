#!/usr/bin/env bash
#
# Microsoft / Azure — public service-tag IP ranges.
# https://azure.microsoft.com/en-us/updates/service-tag-discovery-api-in-preview/
# https://docs.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide
# From: https://github.com/jensihnow/AzurePublicIPAddressRanges/blob/main/.github/workflows/main.yml
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"


# get from public ranges
# NOTE: the download page does not expose a stable JSON URL — it is scraped out
# of the HTML each run. That two-step discovery is preserved verbatim; only the
# final accumulated CIDR streams are routed through write_ipv4 / write_ipv6.
download_and_parse_json() {
    URL="$(curl -s "https://www.microsoft.com/en-us/download/details.aspx?id=${1}" | grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | grep ServiceTags_ | head -1 | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//')"
    curl --connect-timeout 60 --retry 3 --retry-delay 15 -s "${URL}" > /tmp/microsoft.json
    jq '.values[] | [.properties] | .[].addressPrefixes[] | select(. != null)' -r /tmp/microsoft.json > /tmp/microsoft-all.txt

    # save ipv4
    grep -v ':' /tmp/microsoft-all.txt >> /tmp/microsoft-ipv4.txt

    # save ipv6
    grep ':' /tmp/microsoft-all.txt >> /tmp/microsoft-ipv6.txt
}

download_and_parse_csv() {
    URL="$(curl -s "https://www.microsoft.com/en-us/download/details.aspx?id=${1}" | grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | grep msft-public-ips | head -1 | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//')"
    curl --connect-timeout 60 --retry 3 --retry-delay 15 -s "${URL}" > /tmp/microsoft.csv
    awk -F ',' '{print $1}' /tmp/microsoft.csv | grep -E '[:.]+' > /tmp/microsoft-all.txt

    # save ipv4
    grep -v ':' /tmp/microsoft-all.txt >> /tmp/microsoft-ipv4.txt

    # save ipv6
    grep ':' /tmp/microsoft-all.txt >> /tmp/microsoft-ipv6.txt
}

# Public cloud
download_and_parse_json "56519"
# US Gov
download_and_parse_json "57063"
# Germany
download_and_parse_json "57064"
# China
download_and_parse_json "57062"
# Public IPs
download_and_parse_csv "53602"


# Route the accumulated CIDR streams through the shared writer.
write_ipv4 "$DIR" < /tmp/microsoft-ipv4.txt
write_ipv6 "$DIR" < /tmp/microsoft-ipv6.txt

log "microsoft: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
