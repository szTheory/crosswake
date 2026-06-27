#!/usr/bin/env python3
"""Strip the one-shot ``release-as`` (+ adjacent ``_TODO_release_as``) bootstrap pin from a
release-please-config.json package block, identified by its component name.

PROOF-03(b): run automatically by the release-please cleanup-PR job after a companion's first
release tag is cut, so the stale pin can never freeze the component's version (recipe Step 12f /
Pitfall 6). Idempotent — a no-op if the keys are already gone. Surgical line removal (not a jq
reserialize) keeps the PR diff to exactly the removed line(s), and the result is JSON-validated.

Usage: strip_release_as.py <component> [config_path]
"""
import json
import re
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print("[crosswake] FAIL: usage: strip_release_as.py <component> [config]", file=sys.stderr)
        return 2
    component = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 else "release-please-config.json"

    with open(path) as f:
        text = f.read()
    data = json.loads(text)

    # Locate the package block (its JSON key) for this component.
    pkg_key = None
    for key, val in data.get("packages", {}).items():
        if isinstance(val, dict) and val.get("component") == component:
            pkg_key = key
            break
    if pkg_key is None:
        print(f"[crosswake] FAIL: no package block with component '{component}' in {path}", file=sys.stderr)
        return 1

    block = data["packages"][pkg_key]
    if "release-as" not in block and "_TODO_release_as" not in block:
        print(f"[crosswake] OK: '{component}' already has no release-as/_TODO_release_as — no change.")
        return 0

    lines = text.splitlines(keepends=True)
    # Find the opening line of this package block:  `    "<pkg_key>": {`
    opener_re = re.compile(r'^(\s*)"' + re.escape(pkg_key) + r'"\s*:\s*\{')
    start = None
    indent = None
    for i, line in enumerate(lines):
        m = opener_re.match(line)
        if m:
            start = i
            indent = len(m.group(1))
            break
    if start is None:
        print(f"[crosswake] FAIL: could not locate text for package '{pkg_key}'", file=sys.stderr)
        return 1
    # The block closer is the next line at the same indent that starts with '}'.
    end = None
    for j in range(start + 1, len(lines)):
        stripped = lines[j].lstrip()
        cur_indent = len(lines[j]) - len(stripped)
        if cur_indent == indent and stripped.startswith("}"):
            end = j
            break
    if end is None:
        print(f"[crosswake] FAIL: could not find end of package block '{pkg_key}'", file=sys.stderr)
        return 1

    out = []
    removed = 0
    for k, line in enumerate(lines):
        if start < k < end:
            s = line.lstrip()
            if s.startswith('"release-as"') or s.startswith('"_TODO_release_as"'):
                removed += 1
                continue
        out.append(line)
    new_text = "".join(out)

    # Validate: still valid JSON, and the keys are gone for this component.
    new_data = json.loads(new_text)
    nb = next(v for v in new_data["packages"].values() if v.get("component") == component)
    if "release-as" in nb or "_TODO_release_as" in nb:
        print(f"[crosswake] FAIL: keys still present after edit for '{component}'", file=sys.stderr)
        return 1

    with open(path, "w") as f:
        f.write(new_text)
    print(f"[crosswake] OK: stripped {removed} line(s) (release-as/_TODO_release_as) from '{component}' block in {path}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
