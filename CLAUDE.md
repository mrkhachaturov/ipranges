# CLAUDE.md

Guidance for Claude Code working in this repo.

## Repository purpose

A list of public IP ranges per service provider (Google, AWS, Microsoft, Cloudflare, OpenAI, etc.), refreshed every 4 hours by a GitHub Action and committed back to `main`. Consumers reference the raw `.txt` files via `raw.githubusercontent.com` URLs (see [README.md](README.md)). Licensed under [MIT](LICENSE).

## Architecture

Each provider lives in its own top-level directory (e.g. [google/](google/), [openai/](openai/), [devolutions/](devolutions/)) with exactly four files:

- `downloader.sh` — fetches and normalizes the raw addresses
- `ipv4.txt` / `ipv6.txt` — parsed CIDR list, one per line
- `ipv4_merged.txt` / `ipv6_merged.txt` — same list reduced to the smallest set of CIDRs (auto-generated, not produced by `downloader.sh`)

Plumbing that ties it together:

- [utils/lib.sh](utils/lib.sh) — **shared bash primitives that every downloader sources.** This is the heart of the repo; read it before touching any `downloader.sh`. See the contract below.
- [utils/merge.py](utils/merge.py) — thin wrapper around `netaddr.cidr_merge`. The workflow runs it for every `ipv4.txt` / `ipv6.txt` to produce `_merged.txt` siblings.
- [utils/validate.py](utils/validate.py) — CI guard. Every non-empty line in a published list must be a valid CIDR *with an explicit prefix*, matching its file's address family. Catches the recurring class of bug where a downloader leaks PGP blocks, bare IPs or `dig` error strings into a committed file. Run it after changing any downloader.
- [utils/providers.json](utils/providers.json) — single source of truth for provider directories and their display names. New providers MUST be added here.
- [utils/render_readme.py](utils/render_readme.py) — generates the provider table and counts in [README.md](README.md) between `<!-- BEGIN AUTO:* -->` / `<!-- END AUTO:* -->` markers. Idempotent — safe to re-run. Never edit between those markers by hand.
- [ruff.toml](ruff.toml) — lint config for the Python utils. CI runs `ruff check .` and fails on findings.
- [all/](all/) — aggregate of every provider's IPs. Built with `find -mindepth 2 -name ipv4.txt -not -path './all/*'`, so it covers provider lists only — the `mindepth`/`-not` guards keep the root legacy files and `all/`'s own previous output from feeding back in.
- [.github/workflows/update.yml](.github/workflows/update.yml) — runs every `downloader.sh` on `cron: '8 */4 * * *'` and `workflow_dispatch`, then builds `all/`, merges, runs `ruff check`, `validate.py` and `render_readme.py`, then commits.

The top-level `ipv4.txt`, `ipv4_merged.txt`, `ipv6.txt`, `ipv6_merged.txt` are legacy/example files — not used by any tooling. Don't confuse them with the per-provider files.

### The `downloader.sh` contract

A downloader sources [utils/lib.sh](utils/lib.sh) and pipes raw address lines into `write_ipv4` / `write_ipv6`. It never hand-rolls grep/sed normalization, and never writes `ipv4.txt` directly. The skeleton:

```bash
#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/lib.sh
source "$DIR/../utils/lib.sh"

resolve_a example.com | write_ipv4 "$DIR"
resolve_aaaa example.com | write_ipv6 "$DIR"

log "example: $(count "$DIR/ipv4.txt") IPv4, $(count "$DIR/ipv6.txt") IPv6"
```

`DIR` is the absolute provider directory, so the script behaves identically whether invoked from the repo root (the GitHub Action) or from inside the provider dir. **This replaced an older `[ -f "downloader.sh" ] && ... || ...` dual-mode guess — do not reintroduce that idiom.**

What lib.sh gives you:

| helper | purpose |
|---|---|
| `resolve_a [resolver] <domain...>` | A records. With no resolver argument, queries the **whole `RESOLVERS` pool** and unions the answers. |
| `resolve_aaaa [resolver] <domain...>` | Same for AAAA. |
| `fetch <url> [curl args...]` | HTTP GET that fails on error status and retries. Replaces bare `curl -s`, which silently wrote HTML error pages into the pipeline. |
| `asn_routes <ASN>` | `route`/`route6` prefixes announced by an ASN, from public IRR mirrors. Emits both families. |
| `write_ipv4 <dir>` / `write_ipv6 <dir>` | Filter stdin to well-formed CIDRs of the right family, upgrade bare addresses to `/32` / `/128`, sort, de-dupe, write atomically. |
| `log` / `count` | Progress to stderr; non-empty line count. |

Two behaviours worth knowing before you debug something:

- **Resolve across the full pool by default.** `RESOLVERS=(8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9 77.88.8.8)`. Hosts behind GeoDNS — anything on Cloudflare, Akamai or Fastly — return different addresses to different resolvers, so a single-resolver query yields a permanently incomplete list. Naming one resolver explicitly restricts the query to it and will under-report such hosts; only do that deliberately. A downloader may override `RESOLVERS` (see [paddle/downloader.sh](paddle/downloader.sh), which adds a China-local resolver).
- **`write_*` refuses to overwrite a non-empty list with an empty result**, so a transient DNS or fetch failure can't wipe good data. It logs a WARN and keeps the existing file.

Other conventions:

- `set -euo pipefail` at the top. **No `set -x`** — lib.sh enables xtrace only under `DEBUG=1`.
- `log` writes to stderr so it never pollutes the address stream on stdout.

Sources break down roughly as: **21 of 44** providers resolve a hardcoded domain list via `resolve_a`/`resolve_aaaa` (Devolutions, Anthropic, Tana, Sunsama, Twitter, most newer ones); **19** parse a vendor-published JSON/TXT feed via `fetch` + `jq` (Google, AWS, Cloudflare, Telegram, Oracle); **2** use `asn_routes`. Several combine mechanisms — Anthropic pairs documented static ranges with resolution, OpenAI pairs a feed with resolution.

[akamai/downloader.sh](akamai/downloader.sh) and [github/downloader.sh](github/downloader.sh) predate lib.sh and still hand-roll their own logic. `github` in particular hardcodes `github/ipv4.txt`, so it only works when invoked from the repo root. Migrate them if you touch them; don't copy them as templates.

## Common commands

System deps once (matches what CI installs):

```bash
sudo apt install -y whois gawk dnsutils jq
pip install -r utils/requirements.txt   # netaddr + ruff
```

Run a single provider's downloader. Both invocations are equivalent — lib.sh resolves paths from `BASH_SOURCE`, not the working directory:

```bash
bash google/downloader.sh          # from repo root (matches the GitHub Action)
cd google && bash downloader.sh    # from inside the provider dir
DEBUG=1 bash google/downloader.sh  # with full xtrace
```

Validate the lists after changing a downloader (this is what catches leaked non-CIDR text):

```bash
python utils/validate.py           # whole repo
python utils/validate.py google    # one or more providers
ruff check .                       # lint the Python utils
```

Regenerate `_merged.txt` for one provider:

```bash
python utils/merge.py --source=google/ipv4.txt | sort -V > google/ipv4_merged.txt
python utils/merge.py --source=google/ipv6.txt | sort -V > google/ipv6_merged.txt
```

Refresh the auto-generated parts of the README:

```bash
python utils/render_readme.py          # rewrites in place
python utils/render_readme.py --check  # CI guard — exits non-zero if it would change anything
```

Reproduce the full workflow locally:

```bash
find . -name downloader.sh | sort -h | awk '{print "Executing "$1"...";system("bash "$1)}'

find . -mindepth 2 -name ipv4.txt -not -path './all/*' -exec cat {} + | sort -V | uniq > all/ipv4.txt
find . -mindepth 2 -name ipv6.txt -not -path './all/*' -exec cat {} + | sort -V | uniq > all/ipv6.txt

for fam in ipv4 ipv6; do
  find . -mindepth 2 -name "$fam.txt" | sort -h | while read -r f; do
    python utils/merge.py --source="$f" | sort -V > "${f%.txt}_merged.txt"
  done
done

ruff check .
python utils/validate.py
python utils/render_readme.py
```

Trigger the production update on demand: GitHub Actions → "Update" workflow → Run workflow.

## Adding a new provider

1. Create `<provider>/downloader.sh` following the contract above. Templates: [devolutions/downloader.sh](devolutions/downloader.sh) for pure domain resolution, [anthropic/downloader.sh](anthropic/downloader.sh) for static ranges + resolution, [google/downloader.sh](google/downloader.sh) for a vendor feed. Do **not** copy `akamai/` or `github/` — they predate lib.sh.
2. Run it once locally to seed `ipv4.txt` / `ipv6.txt`, then `python utils/validate.py <provider>` to confirm nothing but CIDRs landed. The `_merged.txt` files don't need to be created by hand — the workflow generates them — but committing initial versions keeps the repo state consistent.
3. Add an entry to [utils/providers.json](utils/providers.json) (kept in alphabetical order by `dir`). Optional `note` field shows up in the README's Notes column.
4. Run `python utils/render_readme.py` to refresh the README table.
5. The `all/` aggregate and the cron schedule pick up the new provider automatically — no workflow edits needed.
