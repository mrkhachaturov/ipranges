# API and CLI Documentation

This repository provides a set of shell scripts to fetch and normalize public IP ranges for major services, and a Python utility to merge CIDR ranges. Outputs are simple newline-delimited CIDR lists in per-vendor directories and combined "all" lists.

## Conventions
- Each vendor directory contains: `ipv4.txt`, `ipv6.txt` (optional), and merged variants `ipv4_merged.txt`, `ipv6_merged.txt`.
- Downloader scripts are runnable either from within the vendor directory or from repo root; most will write into the vendor directory accordingly.
- CIDR format is enforced. Raw A/AAAA lookups are normalized to `/32` or `/128` as needed.

## Requirements
- Bash, curl, jq, dig (bind-utils), awk, grep, sort, uniq, whois
- Python 3 with `netaddr` for merging
  - Install: `pip3 install -r utils/requirements.txt`

## Utilities

### utils/merge.py
Merges IP addresses and CIDRs into the smallest set of non-overlapping CIDRs.

Usage:
```bash
python3 utils/merge.py --source <path/to/input.txt>
```
- Input: file with one CIDR or IP per line. Plain IPs are allowed (treated as /32 or /128 by callers before merging).
- Output: merged CIDRs to stdout.

Example:
```bash
python3 utils/merge.py --source google/ipv4.txt > google/ipv4_merged.txt
```

## Downloader scripts by provider
All scripts are invoked as bash executables. Many support being run from either the vendor directory or from repo root. After running, check the corresponding `ipv4.txt`/`ipv6.txt` and optionally run the merge utility as shown.

Notes:
- Some providers only expose IPv4.
- Some scripts resolve domains and therefore results may vary over time.

### amazon/downloader.sh (AWS)
Fetches from AWS `ip-ranges.json` and writes `amazon/ipv4.txt` and `amazon/ipv6.txt`.

Run:
```bash
bash amazon/downloader.sh
```
Then merge:
```bash
python3 utils/merge.py --source amazon/ipv4.txt > amazon/ipv4_merged.txt
python3 utils/merge.py --source amazon/ipv6.txt > amazon/ipv6_merged.txt
```

### microsoft/downloader.sh
Discovers Service Tags JSON and Public IP CSV, writes `microsoft/ipv4.txt` and `microsoft/ipv6.txt`.

Run:
```bash
bash microsoft/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source microsoft/ipv4.txt > microsoft/ipv4_merged.txt
python3 utils/merge.py --source microsoft/ipv6.txt > microsoft/ipv6_merged.txt
```

### oracle/downloader.sh
Downloads Oracle public IP ranges JSON and writes `oracle/ipv4.txt`. IPv6 not provided.

Run:
```bash
bash oracle/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source oracle/ipv4.txt > oracle/ipv4_merged.txt
```

### digitalocean/downloader.sh
Fetches DO ranges CSV and splits into v4/v6.

Run:
```bash
bash digitalocean/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source digitalocean/ipv4.txt > digitalocean/ipv4_merged.txt
python3 utils/merge.py --source digitalocean/ipv6.txt > digitalocean/ipv6_merged.txt
```

### github/downloader.sh
Uses GitHub `api.github.com/meta`, writes `github/ipv4.txt` and `github/ipv6.txt`.

Run:
```bash
bash github/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source github/ipv4.txt > github/ipv4_merged.txt
python3 utils/merge.py --source github/ipv6.txt > github/ipv6_merged.txt
```

### facebook/downloader.sh (Meta)
Queries multiple whois IRR servers by ASN; writes `facebook/ipv4.txt` and `facebook/ipv6.txt`.

Run:
```bash
bash facebook/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source facebook/ipv4.txt > facebook/ipv4_merged.txt
python3 utils/merge.py --source facebook/ipv6.txt > facebook/ipv6_merged.txt
```

### twitter/downloader.sh
Gets ASN routes and resolves Twitter domains; writes `twitter/ipv4.txt` and `twitter/ipv6.txt`.

Run:
```bash
bash twitter/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source twitter/ipv4.txt > twitter/ipv4_merged.txt
python3 utils/merge.py --source twitter/ipv6.txt > twitter/ipv6_merged.txt
```

### linode/downloader.sh
Fetches from Linode GeoIP CSV; writes `linode/ipv4.txt` and `linode/ipv6.txt`.

Run:
```bash
bash linode/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source linode/ipv4.txt > linode/ipv4_merged.txt
python3 utils/merge.py --source linode/ipv6.txt > linode/ipv6_merged.txt
```

### telegram/downloader.sh
Downloads official Telegram CIDR list; writes `telegram/ipv4.txt` and `telegram/ipv6.txt`.

Run:
```bash
bash telegram/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source telegram/ipv4.txt > telegram/ipv4_merged.txt
python3 utils/merge.py --source telegram/ipv6.txt > telegram/ipv6_merged.txt
```

### openai/downloader.sh
Parses OpenAI JSON allowlists and resolves related domains. Writes `openai/ipv4.txt` and `openai/ipv6.txt` (IPv6 may be empty).

Run:
```bash
bash openai/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source openai/ipv4.txt > openai/ipv4_merged.txt
[ -s openai/ipv6.txt ] && python3 utils/merge.py --source openai/ipv6.txt > openai/ipv6_merged.txt
```

### cloudflare/downloader.sh
Fetches Cloudflare published ranges; writes `cloudflare/ipv4.txt` and `cloudflare/ipv6.txt`.

Run:
```bash
bash cloudflare/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source cloudflare/ipv4.txt > cloudflare/ipv4_merged.txt
python3 utils/merge.py --source cloudflare/ipv6.txt > cloudflare/ipv6_merged.txt
```

### cloudflared/downloader.sh (Argo Tunnel)
Queries `*.v2.argotunnel.com` regions and writes `cloudflared/ipv4.txt` and `cloudflared/ipv6.txt`.

Run:
```bash
bash cloudflared/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source cloudflared/ipv4.txt > cloudflared/ipv4_merged.txt
python3 utils/merge.py --source cloudflared/ipv6.txt > cloudflared/ipv6_merged.txt
```

### cloudfront/downloader.sh
Filters AWS `ip-ranges.json` for CloudFront; writes `cloudfront/ipv4.txt` and `cloudfront/ipv6.txt` and merges automatically when run.

Run:
```bash
bash cloudfront/downloader.sh
```

### google/downloader.sh
Aggregates from multiple official sources and netblocks; writes `google/ipv4.txt` and `google/ipv6.txt`.

Run:
```bash
bash google/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source google/ipv4.txt > google/ipv4_merged.txt
python3 utils/merge.py --source google/ipv6.txt > google/ipv6_merged.txt
```

### googlebot/downloader.sh
Downloads Googlebot-specific ranges; writes `googlebot/ipv4.txt` and `googlebot/ipv6.txt`.

Run:
```bash
bash googlebot/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source googlebot/ipv4.txt > googlebot/ipv4_merged.txt
python3 utils/merge.py --source googlebot/ipv6.txt > googlebot/ipv6_merged.txt
```

### bing/downloader.sh
Downloads Bingbot ranges; writes `bing/ipv4.txt`.

Run:
```bash
bash bing/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source bing/ipv4.txt > bing/ipv4_merged.txt
```

### apple-proxy/downloader.sh (iCloud Private Relay)
Downloads Apple Private Relay egress ranges; writes `apple-proxy/ipv4.txt` and `apple-proxy/ipv6.txt`.

Run:
```bash
bash apple-proxy/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source apple-proxy/ipv4.txt > apple-proxy/ipv4_merged.txt
python3 utils/merge.py --source apple-proxy/ipv6.txt > apple-proxy/ipv6_merged.txt
```

### protonvpn/downloader.sh
Downloads ProtonVPN exit IPs; writes `protonvpn/ipv4.txt`.

Run:
```bash
bash protonvpn/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source protonvpn/ipv4.txt > protonvpn/ipv4_merged.txt
```

### discord/downloader.sh
Combines main/voice/region IPs; writes `discord/ipv4.txt`.

Run:
```bash
bash discord/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source discord/ipv4.txt > discord/ipv4_merged.txt
```

### games/downloader.sh
Resolves curated gaming domains; writes `games/ipv4.txt` and `games/ipv6.txt`.

Run:
```bash
bash games/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source games/ipv4.txt > games/ipv4_merged.txt
python3 utils/merge.py --source games/ipv6.txt > games/ipv6_merged.txt
```

### spotify/downloader.sh
Resolves Spotify domains; writes `spotify/ipv4.txt` and `spotify/ipv6.txt`.

Run:
```bash
bash spotify/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source spotify/ipv4.txt > spotify/ipv4_merged.txt
python3 utils/merge.py --source spotify/ipv6.txt > spotify/ipv6_merged.txt
```

### notion/downloader.sh
Resolves Notion domains and includes a fixed allowlist; writes `notion/ipv4.txt` and `notion/ipv6.txt` (may be empty).

Run:
```bash
bash notion/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source notion/ipv4.txt > notion/ipv4_merged.txt
[ -s notion/ipv6.txt ] && python3 utils/merge.py --source notion/ipv6.txt > notion/ipv6_merged.txt
```

### groq/downloader.sh
Resolves Groq API/console domains; writes `groq/ipv4.txt` and `groq/ipv6.txt`.

Run:
```bash
bash groq/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source groq/ipv4.txt > groq/ipv4_merged.txt
python3 utils/merge.py --source groq/ipv6.txt > groq/ipv6_merged.txt
```

### atlassian/downloader.sh
Fetches from Atlassian IP ranges endpoint; writes `atlassian/ipv4.txt` and `atlassian/ipv6.txt`.

Run:
```bash
bash atlassian/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source atlassian/ipv4.txt > atlassian/ipv4_merged.txt
python3 utils/merge.py --source atlassian/ipv6.txt > atlassian/ipv6_merged.txt
```

### vultr/downloader.sh
Fetches Vultr geofeed; writes `vultr/ipv4.txt` and `vultr/ipv6.txt`.

Run:
```bash
bash vultr/downloader.sh
```
Merge:
```bash
python3 utils/merge.py --source vultr/ipv4.txt > vultr/ipv4_merged.txt
python3 utils/merge.py --source vultr/ipv6.txt > vultr/ipv6_merged.txt
```

### googlebot/downloader.sh vs google/downloader.sh
- To allow Googlebot while blocking general Google: block all `google/*`, then allow `googlebot/*`.

## All-in-one lists
Combined lists are kept under `all/` and updated externally. To generate locally, concatenate and merge across providers, e.g.:

```bash
cat */ipv4.txt | sort -V | uniq > /tmp/all-ipv4.txt
python3 utils/merge.py --source /tmp/all-ipv4.txt > all/ipv4_merged.txt
```

## Troubleshooting
- Ensure `jq`, `dig`, `whois` are installed. On macOS (Homebrew):
  - `brew install jq bind whois`
- If a provider changes format, check their comments/URLs at top of `downloader.sh`.
- For flaky networks, consider adding retries (some scripts already do).
