#!/usr/bin/env python3
"""Render the providers table and summary block into README.md.

Reads utils/providers.json plus each provider's ipv4.txt / ipv6.txt counts,
and substitutes content between marker pairs in README.md:

    <!-- BEGIN AUTO:summary --> ... <!-- END AUTO:summary -->
    <!-- BEGIN AUTO:providers --> ... <!-- END AUTO:providers -->

The script is deterministic: same inputs produce the same output, so re-running
on unchanged data does not dirty the working tree.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_BASE = "https://raw.githubusercontent.com/mrkhachaturov/ipranges/main"


def count_lines(path: Path) -> int:
    if not path.is_file():
        return 0
    with path.open("rb") as f:
        return sum(1 for line in f if line.strip())


def link(url: str, label: str) -> str:
    return f"[{label}]({url})"


def render_summary(providers: list[dict], totals: dict[str, int]) -> str:
    return (
        f"**{len(providers)} providers** · "
        f"**{totals['ipv4']:,} IPv4 entries** · "
        f"**{totals['ipv6']:,} IPv6 entries** · "
        f"refreshed every 4 hours via GitHub Actions"
    )


def render_table(providers: list[dict], repo_root: Path) -> str:
    lines = [
        "| Provider | IPv4 | IPv4 (merged) | IPv6 | IPv6 (merged) | Notes |",
        "|---|---|---|---|---|---|",
    ]
    for p in providers:
        d = p["dir"]
        name = p["name"]
        note = p.get("note", "")
        has4 = (repo_root / d / "ipv4.txt").is_file() and count_lines(repo_root / d / "ipv4.txt") > 0
        has6 = (repo_root / d / "ipv6.txt").is_file() and count_lines(repo_root / d / "ipv6.txt") > 0
        c4 = link(f"{REPO_BASE}/{d}/ipv4.txt", "txt") if has4 else "—"
        c4m = link(f"{REPO_BASE}/{d}/ipv4_merged.txt", "txt") if has4 else "—"
        c6 = link(f"{REPO_BASE}/{d}/ipv6.txt", "txt") if has6 else "—"
        c6m = link(f"{REPO_BASE}/{d}/ipv6_merged.txt", "txt") if has6 else "—"
        lines.append(f"| {name} | {c4} | {c4m} | {c6} | {c6m} | {note} |")

    lines.append(
        f"| **All-in-one** (every provider combined) "
        f"| {link(f'{REPO_BASE}/all/ipv4.txt', 'txt')} "
        f"| {link(f'{REPO_BASE}/all/ipv4_merged.txt', 'txt')} "
        f"| {link(f'{REPO_BASE}/all/ipv6.txt', 'txt')} "
        f"| {link(f'{REPO_BASE}/all/ipv6_merged.txt', 'txt')} "
        f"| Aggregate of every provider above |"
    )
    return "\n".join(lines)


def replace_block(text: str, marker: str, body: str) -> str:
    pattern = re.compile(
        rf"(<!-- BEGIN AUTO:{marker} -->)(.*?)(<!-- END AUTO:{marker} -->)",
        flags=re.DOTALL,
    )
    if not pattern.search(text):
        sys.exit(f"error: marker pair AUTO:{marker} not found in README")
    return pattern.sub(rf"\1\n{body}\n\3", text)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", type=Path)
    parser.add_argument("--providers", default=None, type=Path)
    parser.add_argument("--readme", default=None, type=Path)
    parser.add_argument("--check", action="store_true",
                        help="Exit non-zero if README would change (CI guard).")
    args = parser.parse_args()

    repo_root: Path = args.repo_root.resolve()
    providers_path: Path = args.providers or (repo_root / "utils/providers.json")
    readme_path: Path = args.readme or (repo_root / "README.md")

    providers = json.loads(providers_path.read_text(encoding="utf-8"))

    totals = {"ipv4": 0, "ipv6": 0}
    for p in providers:
        totals["ipv4"] += count_lines(repo_root / p["dir"] / "ipv4.txt")
        totals["ipv6"] += count_lines(repo_root / p["dir"] / "ipv6.txt")

    text = readme_path.read_text(encoding="utf-8")
    new_text = replace_block(text, "summary", render_summary(providers, totals))
    new_text = replace_block(new_text, "providers", render_table(providers, repo_root))

    if new_text == text:
        print("README is up to date.")
        return 0

    if args.check:
        sys.exit("README is out of date — run utils/render_readme.py to refresh.")

    readme_path.write_text(new_text, encoding="utf-8")
    print(f"README rewritten: {readme_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
