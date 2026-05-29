---
status: complete
phase: 30-hex-page-polish
source: [30-01-SUMMARY.md, 30-02-SUMMARY.md]
started: 2026-05-29T00:41:15Z
updated: 2026-05-29T00:41:15Z
verification: automated
---

## Current Test

[testing complete — verified by automated tests, zero human steps]

## Method

All four Phase 30 checkpoints were converted from manual UAT to automated tests
(no human verification required):

- Hermetic ExUnit test `test/crosswake/hex_page_test.exs` (runs on every `mix test`).
- CI workflow `.github/workflows/hex-page-proof.yml` (runs on every PR + push to main):
  full `mix test`, `mix docs` build smoke, `script/verify_hex_tarball.sh`,
  `mix hex.publish --dry-run`.

The automated approach surfaced two real bugs the manual SUMMARY had missed (see Gaps).

## Tests

### 1. README links resolve on hex.pm
expected: Links to non-package paths use absolute GitHub URLs; in-package guide links stay relative and exist on disk; no absolute filesystem paths.
result: pass
note: Caught TWO real bugs. (a) README.md:45 was still a relative link to examples/phoenix_host/README.md (not shipped → 404 on HexDocs) → fixed to absolute URL. (b) 29 guide cross-links across 6 files were hardcoded absolute local paths (/Users/jon/projects/crosswake/guides/*.md) — broken on HexDocs — surfaced only when CI ran on a different machine → rewritten to basename relative links. Test hardened to flag absolute filesystem paths deterministically. Enforced by hex_page_test "README + guide link hygiene".

### 2. Docs sidebar grouping
expected: groups_for_modules / groups_for_extras define the configured groups and reference real modules/files.
result: pass
note: Caught a real bug first — groups_for_modules listed `Crosswake.Bridge`, which does not exist (only Crosswake.Bridge.* submodules). Replaced with a regex (matching the existing Capabilities-group pattern); test now green. Enforced by hex_page_test "HexDocs sidebar grouping config".

### 3. Hex tarball verification script
expected: script/verify_hex_tarball.sh succeeds — expected files present, banned internal paths excluded.
result: pass
note: Runs green locally and is now wired into CI (was previously never run in CI). Config-layer mirror also enforced by hex_page_test "hex package file allowlist".

### 4. Hex publish dry-run
expected: mix hex.publish --dry-run --yes passes metadata, license, and preflight checks.
result: pass
note: Exit 0 locally; now wired into the hex-page-proof CI workflow.

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

# Both gaps were diagnosed and fixed in this same change; tests now green.

- truth: "README links to non-package paths are absolute GitHub URLs (resolve on HexDocs)"
  status: fixed
  reason: "README.md:45 was still relative to examples/phoenix_host/README.md (not in package :files allowlist), which 404s on HexDocs. Phase 30 SUMMARY claimed all such links were made absolute; this one was missed."
  severity: major
  test: 1
  root_cause: "Missed link during the Phase 30 relative→absolute rewrite."
  artifacts:
    - path: "README.md"
      issue: "line 45 relative link to non-package path"
  missing:
    - "Rewrite to https://github.com/szTheory/crosswake/blob/main/examples/phoenix_host/README.md"

- truth: "docs groups_for_modules references only real modules"
  status: fixed
  reason: "groups_for_modules listed `Crosswake.Bridge`, which is not a module (only Crosswake.Bridge.* exist) — the Bridge sidebar group was dead config."
  severity: minor
  test: 2
  root_cause: "Group authored against a parent module that was never defined."
  artifacts:
    - path: "mix.exs"
      issue: "Bridge: [Crosswake.Bridge] references a non-existent module"
  missing:
    - "Use a regex (~r/Crosswake\\.Bridge(\\.|$)/) matching the real Bridge submodules"

## Notes

While running the full suite, the automated approach also found a pre-existing,
unrelated failure outside Phase 30 scope: `summary_frontmatter_test.exs` globbed
`.planning/milestones/v3.3-phases/` (not created until v3.3 is archived), so it
failed on main and was breaking the phase23-proof merge gate. Repaired to degrade
gracefully (skip when the current-milestone archive does not exist yet; activates
automatically once archived).
