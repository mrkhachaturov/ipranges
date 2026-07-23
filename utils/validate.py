#!/usr/bin/env python3
"""Validate every published CIDR list.

Guards against the class of bug where a downloader leaks non-CIDR text into a
committed ``ipv4.txt`` / ``ipv6.txt`` (and their ``_merged`` siblings):

  - base64 / PGP blocks       (GitHub /meta commit_signing_keys)
  - bare IPs without a prefix  (ProtonVPN EntryIP)
  - dig error strings          (";; communications error to 1.1.1.1#53: timed out")

Every non-empty line must be a valid CIDR *with an explicit prefix*, and its
address family must match the file it lives in. Anything else fails the run.

Scope: ``<dir>/ipv4.txt``, ``<dir>/ipv6.txt`` and their ``_merged`` siblings,
one level below the repo root. The legacy top-level files are intentionally
skipped (see CLAUDE.md — not used by any tooling).

Usage:
    python utils/validate.py            # validate the whole repo
    python utils/validate.py google     # validate one or more providers (+ all/)
"""

import argparse
import ipaddress
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

FAMILY = {"ipv4": 4, "ipv6": 6}


def expected_version(path: Path) -> int:
    """4 or 6, inferred from the filename prefix (ipv4.txt / ipv6_merged.txt)."""
    for prefix, version in FAMILY.items():
        if path.name.startswith(prefix):
            return version
    raise ValueError(f"cannot infer address family from {path.name!r}")


def validate_file(path: Path) -> list[str]:
    want = expected_version(path)
    errors: list[str] = []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.rstrip("\n")
        if line == "":
            errors.append(f"{path}:{lineno}: blank line")
            continue
        if line != line.strip():
            errors.append(f"{path}:{lineno}: leading/trailing whitespace: {line!r}")
            continue
        if "/" not in line:
            errors.append(f"{path}:{lineno}: not a CIDR (missing /prefix): {line!r}")
            continue
        try:
            net = ipaddress.ip_network(line, strict=False)
        except ValueError as exc:
            errors.append(f"{path}:{lineno}: invalid CIDR: {line!r} ({exc})")
            continue
        if net.version != want:
            errors.append(
                f"{path}:{lineno}: IPv{net.version} address in an IPv{want} file: {line!r}"
            )
    return errors


PATTERNS = ("ipv4.txt", "ipv6.txt", "ipv4_merged.txt", "ipv6_merged.txt")


def target_files(providers: list[str]) -> list[Path]:
    """CIDR list files to check: every <dir>/ipv{4,6}{,_merged}.txt one level deep.

    With no providers given, globs the whole repo (excludes root-level legacy
    files). With providers given, restricts to those directories.
    """
    dirs = providers or ["*"]
    files: set[Path] = set()
    for d in dirs:
        for pat in PATTERNS:
            files.update(REPO.glob(f"{d}/{pat}"))
    return sorted(files)


def explicit_files(paths: list[str]) -> list[Path]:
    """Validate exactly the given paths — but only real CIDR lists.

    Used by the pre-commit hook, which passes staged files. Anything that
    isn't one of the tracked ipv{4,6}{,_merged}.txt names is ignored so the
    hook can hand us its whole staged set without pre-filtering by name.
    """
    return sorted(
        {Path(p) for p in paths if Path(p).name in PATTERNS and Path(p).is_file()}
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "providers",
        nargs="*",
        help="provider directories to check (default: all). 'all' is included automatically.",
    )
    parser.add_argument(
        "--files",
        nargs="*",
        default=None,
        help="validate these exact file paths instead of scanning dirs (pre-commit hook mode).",
    )
    args = parser.parse_args()

    if args.files is not None:
        files = explicit_files(args.files)
        if not files:
            # Nothing CIDR-related staged — a clean pass, not an error.
            print("validate: no CIDR list files to check")
            return 0
    else:
        files = target_files(args.providers)
        if not files:
            print("validate: no CIDR list files found", file=sys.stderr)
            return 1

    all_errors: list[str] = []
    for path in files:
        all_errors.extend(validate_file(path))

    if all_errors:
        for err in all_errors:
            print(err.replace(str(REPO) + "/", ""))
        print(
            f"\nvalidate: FAILED — {len(all_errors)} bad line(s) across "
            f"{len({e.split(':')[0] for e in all_errors})} file(s)",
            file=sys.stderr,
        )
        return 1

    print(f"validate: OK — {len(files)} files clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
