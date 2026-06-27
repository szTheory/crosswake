# Follow-up: Remove `release-as` After First `crosswake_rulestead` Release PR Merges

**Type:** Mandatory one-shot follow-up (D-04, Pitfall 6)
**Trigger:** First `crosswake_rulestead-v0.1.0` Release PR is merged + the `crosswake_rulestead-v0.1.0` tag exists on `main`

---

## Background

`release-please-config.json` carries a `"release-as": "0.1.0"` one-shot override on the
`packages/crosswake_rulestead` component entry (added in Phase 131, Plan 01). This is the
only way to force release-please to cut exactly `0.1.0` when the manifest baseline is also
`"0.1.0"` — without it, release-please sees no version bump and never opens a Release PR.

**The one-shot key MUST be removed (or set to `""`) immediately after the first Release PR
merges.** If it is left in place, every subsequent run of release-please will target `0.1.0`
again — it will not open a PR for `0.1.1`, `0.1.2`, or any later version. The companion's
independent versioning will be silently stuck.

This is Pitfall 6 from the Phase 131 research (`§Common Pitfalls`). It applies to every
companion registered with `release-as` — including rindle in Phase 132.

---

## Trigger Condition

Run this follow-up when **both** of the following are true:

1. The `crosswake_rulestead-v0.1.0` Release PR has been merged to `main`.
2. The tag `crosswake_rulestead-v0.1.0` exists on the `main` branch (created by release-please automatically on PR merge).

You can verify:

```bash
git tag | grep crosswake_rulestead
# Expected output: crosswake_rulestead-v0.1.0
```

---

## Exact Edit

Open `release-please-config.json` and remove the `"release-as": "0.1.0"` line from the
`packages/crosswake_rulestead` entry:

**Before (current — pre-first-cut):**
```json
"packages/crosswake_rulestead": {
  "component": "crosswake_rulestead",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_rulestead/mix.exs"],
  ...
}
```

**After (post-first-cut — this follow-up):**
```json
"packages/crosswake_rulestead": {
  "component": "crosswake_rulestead",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "extra-files": ["packages/crosswake_rulestead/mix.exs"],
  ...
}
```

Alternatively, set the value to `""` to disable it (release-please treats `""` as absent):
```json
  "release-as": "",
```

Either approach resolves the pin. Deletion is cleaner.

---

## One-line Verification (after removal)

```bash
python3 -c "
import json
e = json.load(open('release-please-config.json'))['packages']['packages/crosswake_rulestead']
assert 'release-as' not in e or e.get('release-as') == '', 'release-as still set'
print('release-as removed OK — next companion cut will be 0.1.1')
"
```

Or a simpler grep form — confirm the key is absent (exits non-zero = key still present):
```bash
grep -L 'release-as' release-please-config.json
# Expected: prints 'release-please-config.json' (meaning the file does NOT contain the key)
```

Note: `grep -L` prints the filename when it does NOT match — so output = removed, no output = still present.

---

## Commit Message

```
chore: remove one-shot release-as 0.1.0 from crosswake_rulestead config (D-04)

release-as is a first-cut bootstrap — removing it allows release-please to
open 0.1.1 and later Release PRs for the companion (Pitfall 6 avoidance).
```

---

## Rindle Reuse (Phase 132)

The same one-shot pattern applies to `crosswake_rindle` when Phase 132 ships.
See `script/extract_companion.md` Step 12f ("Remove `release-as` after the first
Release PR merges") for the generalized recipe parameterized for any future companion.

After the `crosswake_rindle-v0.1.0` Release PR merges, perform the identical removal
on the `packages/crosswake_rindle` entry in `release-please-config.json`.

---

## Cross-Reference

- `script/extract_companion.md` § Step 12f — generalized removal recipe for any companion
- Phase 131 RESEARCH.md §"D-04: First-Release Bootstrap" — rationale
- Phase 131 RESEARCH.md §"Common Pitfalls" Pitfall 6 — the stuck-at-0.1.0 failure mode
- Phase 131 Plan 01 — where `"release-as": "0.1.0"` was added
