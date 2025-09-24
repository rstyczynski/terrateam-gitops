#!/usr/bin/env python3
import yaml
import sys

USAGE = "Usage: galaxy_firewall.py <input_file>"

# --- Parse args (single required positional: input file) ---
if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
    print(USAGE, file=sys.stderr)
    sys.exit(1)

infile = sys.argv[1]

with open(infile, "r") as f:
    data = yaml.safe_load(f) or {}

# Keep originals for reporting
orig_collections = list(data.get("collections", []) or [])
orig_roles = list(data.get("roles", []) or [])

# Keep only entries where type is "dir" or "git"
filtered_collections = []
removed_collections = []
for c in orig_collections:
    if isinstance(c, dict) and c.get("type") in ("dir", "git"):
        filtered_collections.append(c)
    else:
        removed_collections.append(c)

# Keep only roles with src starting with "git+" or "https://" or type "dir"
filtered_roles = []
removed_roles = []
for r in orig_roles:
    if isinstance(r, dict):
        src = r.get("src", "")
        if src.startswith("git+") or src.startswith("https://") or r.get("type") == "dir":
            filtered_roles.append(r)
        else:
            removed_roles.append(r)
    else:
        removed_roles.append(r)

changed = bool(removed_collections or removed_roles)

# Write sanitized YAML to STDOUT (only top-level keys roles and/or collections)
sanitized_data = {}
if filtered_collections:
    sanitized_data["collections"] = filtered_collections
if filtered_roles:
    sanitized_data["roles"] = filtered_roles

yaml.dump(sanitized_data, sys.stdout, sort_keys=False, explicit_start=True)

# Write blocked entries as commented YAML lines
def dump_commented_blocked(prefix, items):
    for item in items:
        dumped = yaml.dump(item, sort_keys=False).rstrip()
        for line in dumped.splitlines():
            print(f"# BLOCKED by galaxy_firewall: {line}")

if removed_collections:
    dump_commented_blocked("collections", removed_collections)
if removed_roles:
    dump_commented_blocked("roles", removed_roles)

# --- Reporting to STDERR so CI can detect eliminations without relying on YAML reformatting ---
# Always print a concise summary line first (easy to grep)
if changed:
    print(
        f"galaxy_firewall: removed {len(removed_collections)} collections and {len(removed_roles)} roles",
        file=sys.stderr,
    )
    exit(1)
else:
    print("galaxy_firewall: no eliminations", file=sys.stderr)
    exit(0)
