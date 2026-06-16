# IP Ranges

> Continuously-updated public IP ranges for major cloud providers, services, and apps — one txt file per provider, ready to drop into firewalls, allowlists, or geo blocks.

[![Update](https://github.com/mrkhachaturov/ipranges/actions/workflows/update.yml/badge.svg)](https://github.com/mrkhachaturov/ipranges/actions/workflows/update.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/mrkhachaturov/ipranges/main)](https://github.com/mrkhachaturov/ipranges/commits/main)

<!-- BEGIN AUTO:summary -->
**36 providers** · **116,076 IPv4 entries** · **269,098 IPv6 entries** · refreshed every 4 hours via GitHub Actions
<!-- END AUTO:summary -->

All addresses come from public sources (vendor-published JSON/TXT or DNS resolution of vendor domains). The lists are committed back to `main` after each refresh, so consumers can pin to either `main` (rolling) or a specific commit (frozen).

## Quick start

Each provider directory contains four files:

| File | Contents |
|---|---|
| `ipv4.txt` | IPv4 CIDRs, one per line |
| `ipv4_merged.txt` | Same list reduced to the smallest equivalent set of CIDRs |
| `ipv6.txt` | IPv6 CIDRs, one per line |
| `ipv6_merged.txt` | Same list reduced |

Fetch them straight from `raw.githubusercontent.com`:

```bash
curl -fsSL https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv4_merged.txt
```

### Use in `ipset` + `iptables`

```bash
ipset create cloudflare hash:net family inet
curl -fsSL https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv4_merged.txt \
  | xargs -I{} ipset add cloudflare {}
iptables -I INPUT -m set --match-set cloudflare src -j ACCEPT
```

### Use in nginx

```nginx
geo $is_googlebot {
    default 0;
    include /etc/nginx/googlebot-ipv4.conf;  # generated from googlebot/ipv4_merged.txt as "<cidr> 1;"
}
```

### Use in a Python allowlist

```python
import ipaddress, urllib.request
url = "https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/openai/ipv4_merged.txt"
nets = [ipaddress.ip_network(line.strip()) for line in urllib.request.urlopen(url) if line.strip()]
def is_openai(ip: str) -> bool:
    addr = ipaddress.ip_address(ip)
    return any(addr in n for n in nets)
```

## Providers

<!-- BEGIN AUTO:providers -->
| Provider | IPv4 | IPv4 (merged) | IPv6 | IPv6 (merged) | Notes |
|---|---|---|---|---|---|
| Akamai | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/akamai/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/akamai/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/akamai/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/akamai/ipv6_merged.txt) |  |
| Amazon (AWS) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/amazon/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/amazon/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/amazon/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/amazon/ipv6_merged.txt) |  |
| Anthropic (Claude) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/anthropic/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/anthropic/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/anthropic/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/anthropic/ipv6_merged.txt) |  |
| Apple (Private Relay) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/apple-proxy/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/apple-proxy/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/apple-proxy/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/apple-proxy/ipv6_merged.txt) |  |
| Atlassian | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/atlassian/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/atlassian/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/atlassian/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/atlassian/ipv6_merged.txt) |  |
| Bing (Bingbot) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/bing/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/bing/ipv4_merged.txt) | — | — |  |
| ClickUp | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/clickup/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/clickup/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/clickup/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/clickup/ipv6_merged.txt) |  |
| Cloudflare | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflare/ipv6_merged.txt) |  |
| Cloudflare Tunnel (Argo) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflared/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflared/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflared/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudflared/ipv6_merged.txt) |  |
| Amazon CloudFront | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudfront/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudfront/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudfront/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/cloudfront/ipv6_merged.txt) |  |
| DeepL | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/deepl/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/deepl/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/deepl/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/deepl/ipv6_merged.txt) |  |
| Devolutions | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/devolutions/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/devolutions/ipv4_merged.txt) | — | — |  |
| DigitalOcean | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/digitalocean/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/digitalocean/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/digitalocean/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/digitalocean/ipv6_merged.txt) |  |
| Discord | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/discord/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/discord/ipv4_merged.txt) | — | — |  |
| Facebook (Meta) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/facebook/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/facebook/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/facebook/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/facebook/ipv6_merged.txt) |  |
| Games | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/games/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/games/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/games/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/games/ipv6_merged.txt) |  |
| GitHub | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/github/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/github/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/github/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/github/ipv6_merged.txt) |  |
| Google (Cloud & GoogleBot) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/google/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/google/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/google/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/google/ipv6_merged.txt) |  |
| Google (GoogleBot) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/googlebot/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/googlebot/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/googlebot/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/googlebot/ipv6_merged.txt) | To allow GoogleBot, block all Google IPs first, then allow these. |
| Groq | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/groq/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/groq/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/groq/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/groq/ipv6_merged.txt) |  |
| Kino.pub | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/kino-pub/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/kino-pub/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/kino-pub/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/kino-pub/ipv6_merged.txt) |  |
| Linode | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/linode/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/linode/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/linode/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/linode/ipv6_merged.txt) |  |
| Microsoft | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/microsoft/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/microsoft/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/microsoft/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/microsoft/ipv6_merged.txt) |  |
| Notion | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/notion/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/notion/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/notion/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/notion/ipv6_merged.txt) |  |
| OpenAI (GPTBot) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/openai/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/openai/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/openai/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/openai/ipv6_merged.txt) |  |
| OpenTofu | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/opentofu/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/opentofu/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/opentofu/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/opentofu/ipv6_merged.txt) |  |
| Oracle (Cloud) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/oracle/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/oracle/ipv4_merged.txt) | — | — |  |
| ProtonVPN (exit nodes) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/protonvpn/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/protonvpn/ipv4_merged.txt) | — | — |  |
| Roblox | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/roblox/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/roblox/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/roblox/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/roblox/ipv6_merged.txt) |  |
| Spotify | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/spotify/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/spotify/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/spotify/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/spotify/ipv6_merged.txt) |  |
| Sunsama | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/sunsama/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/sunsama/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/sunsama/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/sunsama/ipv6_merged.txt) |  |
| Tana | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/tana/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/tana/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/tana/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/tana/ipv6_merged.txt) |  |
| Telegram | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/telegram/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/telegram/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/telegram/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/telegram/ipv6_merged.txt) |  |
| Twitter / X | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/twitter/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/twitter/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/twitter/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/twitter/ipv6_merged.txt) |  |
| Vultr | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/vultr/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/vultr/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/vultr/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/vultr/ipv6_merged.txt) |  |
| Wispr Flow | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/wisprflow/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/wisprflow/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/wisprflow/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/wisprflow/ipv6_merged.txt) |  |
| **All-in-one** (every provider combined) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/all/ipv4.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/all/ipv4_merged.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/all/ipv6.txt) | [txt](https://raw.githubusercontent.com/mrkhachaturov/ipranges/main/all/ipv6_merged.txt) | Aggregate of every provider above |
<!-- END AUTO:providers -->

> The provider table above is generated from [utils/providers.json](utils/providers.json) by [utils/render_readme.py](utils/render_readme.py). Don't edit between the `<!-- BEGIN AUTO:* -->` markers by hand — the GitHub Action will overwrite changes on the next run.

## How updates work

A GitHub Action runs every 4 hours (`cron: '8 */4 * * *'`) and on `workflow_dispatch`:

1. Executes every `*/downloader.sh` discovered under the repo
2. Concatenates all per-provider lists into [`all/ipv4.txt`](all/ipv4.txt) and [`all/ipv6.txt`](all/ipv6.txt)
3. Runs [`utils/merge.py`](utils/merge.py) to produce `*_merged.txt` for each list
4. Runs [`utils/render_readme.py`](utils/render_readme.py) to refresh the table and counts above
5. Commits any changes back to `main`

If you want fresher data than the cron, trigger the **Update** workflow manually from the Actions tab.

## Adding a new provider

The full contract lives in [CLAUDE.md](CLAUDE.md). The short version:

1. Create `<provider>/downloader.sh`. Use [devolutions/downloader.sh](devolutions/downloader.sh) (DNS-resolution pattern) or [google/downloader.sh](google/downloader.sh) (vendor-JSON pattern) as templates. Both invocation modes — repo root and inside the provider directory — must work.
2. Run it once locally to seed `<provider>/ipv4.txt` and `<provider>/ipv6.txt`.
3. Add an entry to [utils/providers.json](utils/providers.json) (kept in alphabetical order). The README updates itself on the next workflow run.

## Local development

```bash
# system deps
sudo apt install -y whois parallel gawk dnsutils jq python3-pip

# python deps
pip install -r utils/requirements.txt

# run a single provider
cd cloudflare && bash downloader.sh

# regenerate the merged file for one list
python utils/merge.py --source=cloudflare/ipv4.txt | sort -V > cloudflare/ipv4_merged.txt

# refresh README from current data
python utils/render_readme.py

# CI guard — fail if README would change
python utils/render_readme.py --check
```

## License

[MIT](LICENSE) — © 2026 Ruben Khachaturov. The IP data itself comes from public sources and is not subject to copyright on its own.

## Source

<https://github.com/mrkhachaturov/ipranges>
