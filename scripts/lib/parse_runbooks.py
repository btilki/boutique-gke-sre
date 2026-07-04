#!/usr/bin/env python3
"""Parse observability/monitoring/runbooks.yaml without external dependencies."""
from __future__ import annotations

import argparse
import pathlib
import sys
from typing import Any


def _parse_scalar(value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    if value[0] in "\"'" and value[-1] == value[0]:
        return value[1:-1]
    return value


def load_registry(path: pathlib.Path) -> dict[str, Any]:
    """Minimal YAML parser for the fixed runbooks registry schema."""
    root: dict[str, Any] = {}
    stack: list[tuple[dict[str, Any], int]] = [(root, -1)]
    current_policy: str | None = None
    in_policies = False

    for raw in path.read_text().splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        line = raw.strip()
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()

        while len(stack) > 1 and indent <= stack[-1][1]:
            stack.pop()

        if key == "policies" and value == "":
            in_policies = True
            root["policies"] = {}
            stack.append((root["policies"], indent))
            continue

        if in_policies and indent == 2 and value == "":
            current_policy = key
            root["policies"][current_policy] = {}
            continue

        parent, _ = stack[-1]

        if in_policies and current_policy and indent >= 4:
            policy_entry = root["policies"][current_policy]
            if value == "":
                policy_entry[key] = {}
                stack.append((policy_entry[key], indent))
            elif value in ("true", "false"):
                policy_entry[key] = value == "true"
            else:
                policy_entry[key] = _parse_scalar(value)
            continue

        if value == "":
            parent[key] = {}
            stack.append((parent[key], indent))
        elif value in ("true", "false"):
            parent[key] = value == "true"
        else:
            parent[key] = _parse_scalar(value)

    if "github" not in root or "policies" not in root:
        raise ValueError(f"Invalid registry schema in {path}")
    return root


def github_runbook_url(registry: dict[str, Any], policy: str) -> str:
    gh = registry["github"]
    entry = registry["policies"][policy]
    return (
        f"https://github.com/{gh['org']}/{gh['repo']}/blob/{gh['branch']}/"
        f"{gh['runbooks_path']}/{entry['runbook']}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Runbook registry helpers")
    parser.add_argument("registry", type=pathlib.Path)
    sub = parser.add_subparsers(dest="cmd", required=True)

    url_p = sub.add_parser("url")
    url_p.add_argument("policy")

    sub.add_parser("list")
    sub.add_parser("pagerduty")

    desc_p = sub.add_parser("description")
    desc_p.add_argument("policy")

    short_p = sub.add_parser("short")
    short_p.add_argument("policy")

    args = parser.parse_args()
    registry = load_registry(args.registry)

    if args.cmd == "url":
        print(github_runbook_url(registry, args.policy))
    elif args.cmd == "list":
        for name in registry["policies"]:
            print(name)
    elif args.cmd == "pagerduty":
        for name, entry in registry["policies"].items():
            if entry.get("pagerduty"):
                print(name)
    elif args.cmd == "description":
        print(registry["policies"][args.policy]["description"])
    elif args.cmd == "short":
        rb = registry["policies"][args.policy]["runbook"]
        print(rb.removesuffix(".md"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
