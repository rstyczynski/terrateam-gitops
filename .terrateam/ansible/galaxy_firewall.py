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
        if src.startswith("git+") or src.startswith("https://") or r.get("type") == "dir" or r.get("type") == "file":
            filtered_roles.append(r)
        else:
            removed_roles.append(r)
    else:
        removed_roles.append(r)

changed = bool(removed_collections or removed_roles)


# Emit YAML manually so we can place comments under the right keys
print("---")

# collections
print("collections:")
if filtered_collections:
    dumped = yaml.safe_dump(filtered_collections, sort_keys=False).rstrip()
    # indent each line by two spaces
    print("\n".join("  " + ln for ln in dumped.splitlines()))
else:
    print("  []")
for item in removed_collections:
    dumped = yaml.safe_dump(item, sort_keys=False).rstrip()
    for line in dumped.splitlines():
        print("  # BLOCKED by galaxy_firewall: " + line)

# roles
print("roles:")
if filtered_roles:
    dumped = yaml.safe_dump(filtered_roles, sort_keys=False).rstrip()
    print("\n".join("  " + ln for ln in dumped.splitlines()))
else:
    print("  []")
for item in removed_roles:
    dumped = yaml.safe_dump(item, sort_keys=False).rstrip()
    for line in dumped.splitlines():
        print("  # BLOCKED by galaxy_firewall: " + line)

# --- Reporting to STDERR so CI can detect eliminations without relying on YAML reformatting ---
# Always print a concise summary line first (easy to grep)
if changed:
    print(
        f"galaxy_firewall: removed {len(removed_collections)} collections and {len(removed_roles)} roles",
        file=sys.stderr,
    )
    exit(2)
else:
    print("galaxy_firewall: no eliminations", file=sys.stderr)
    exit(0)
