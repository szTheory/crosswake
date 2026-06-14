---
phase: 109-drift-prevention-gate
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - brandbook/tools/check-consumer-drift.mjs
  - brandbook/tools/check-consumer-drift.test.mjs
  - brandbook/tools/contrast.mjs
  - .github/workflows/brandbook-verify.yml
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

This phase adds a deterministic consumer drift gate (`check-consumer-drift.mjs`),
a node:test contract suite, a main-module guard on the pre-existing `contrast.mjs`,
and CI wiring in `brandbook-verify.yml`.

The mechanism is sound and the green baseline + contract tests pass (verified:
`node check-consumer-drift.mjs` exits 0; all 14 drift tests and the contrast tests
pass). The main-module guard is correct and `PALETTE` is properly exported.

However, this is a *drift gate* — its entire value is in its detection coverage, and
the adversarial finding here is that several realistic drift forms slip through the
detectors silently. Because the gate is a REQUIRED merge check, every false-negative
is a hole that lets brand drift land while presenting a green check. None are
exploitable security issues, but several would defeat the gate's stated purpose, so
they are classified WARNING. The matching strategy (`String.includes`) and the
quote/value-context assumptions baked into the regexes are the core weaknesses.

No Critical issues found. No source files were modified.

## Warnings

### WR-01: Hex literals inside double-quoted attribute values are not detected

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** The hex lookbehind `(?<=[:,(\s])` only fires when `#` is preceded by `:`,
`,`, `(`, or whitespace. A `"` is not in that class, so hex inside a quoted attribute
value is missed. Verified:

- `<rect fill="#2B756A" />` -> 0 violations
- `<stop stop-color="#9A4D35" />` -> would also be missed

This is a live drift form for these exact files: three of the five manifest entries
are HEEX/template files, and the deferred-offender comment at lines 28-33 explicitly
notes hardcoded hex appearing in template/JS string contexts (`offline_study.js`
`innerHTML` hex). A normalizer regression that reintroduces `fill="#..."` or inline
`style="...:#..."` at an attribute boundary passes the gate green.
**Fix:** Add `"` and `'` to the lookbehind class so quoted-attribute hex is caught:
```js
const hexRe = /(?<=[:,("'\s])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/g;
```
(Note: reorder the alternation longest-first — see WR-03.)

### WR-02: `class="..."` regex misses multi-line and dynamic `class={...}` attributes

**File:** `brandbook/tools/check-consumer-drift.mjs:142`
**Issue:** `findRetiredTailwindInClassAttrs` matches only `/class="([^"]*)"/g`. Two
common HEEX forms evade it:

1. **Dynamic bindings** — `class={"flex " <> @x}` -> 0 violations (verified). HEEX/
   Phoenix templates routinely use `class={...}` interpolation; a retired utility
   reintroduced there is invisible to the gate.
2. **Single-quoted attrs** — `class='flex'` -> 0 violations (verified).

Multi-line `class="..."` *does* work (the `[^"]*` spans newlines), so that case is
fine. The dynamic-binding gap is the material one: the manifest's HEEX files are
Phoenix templates where `class={...}` is idiomatic, so a future edit can drift past
the gate.
**Fix:** Also scan `class={...}` and single-quoted forms, e.g. add a second pass:
```js
const classRe = /class=(?:"([^"]*)"|'([^']*)'|\{([^}]*)\})/g;
// then test (m[1] ?? m[2] ?? m[3]) against the blocklist
```
At minimum, add a contract test pinning the `class={...}` case so the gap is explicit.

### WR-03: Hex alternation order can drop a malformed long hex run

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** The alternation is `{6}|{8}|{3}` (6 before 8). For a 7-hex-digit run like
`color: #2B756A1;`, the 6-branch matches `2B756A` but the trailing `\b` fails because
`1` (a word char) follows; the 8-branch needs 8 chars; the 3-branch fails the same
`\b` way. Net result: `#2B756A1` -> **0 violations** (verified). A typo'd or
concatenated hex that still clearly encodes a color intent slips through.
**Fix:** Order alternatives longest-first so the engine prefers the 8-digit match
and the `\b` anchoring behaves predictably; also consider that any 7+ run is itself
suspicious:
```js
const hexRe = /(?<=[:,("'\s])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/g;
```
This won't fully catch the 7-digit case (still no clean length), but combined with
WR-04 it removes the ambiguity. Worth a test fixture either way.

### WR-04: 4-digit `#RGBA` shorthand hex is not detected

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** Comment at line 76 claims "Valid CSS hex lengths: 3, 6, or 8 digits only."
That is incorrect — CSS Color 4 defines **4-digit `#RGBA`** shorthand (and it is
widely supported in browsers). `color: #abcd;` -> 0 violations (verified). A
reintroduced color using 4-digit shorthand bypasses the hex rule entirely.
**Fix:** Add the 4-digit length to the alternation and update the comment:
```js
const hexRe = /(?<=[:,("'\s])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})\b/g;
```
(4-digit won't have a 6-digit PALETTE name, so the existing length===6 name lookup
already handles it correctly by emitting the bare literal.)

### WR-05: Blocklist uses substring `includes`, producing false positives and brittle matches

**File:** `brandbook/tools/check-consumer-drift.mjs:149`
**Issue:** `classes.includes(retired)` is an unanchored substring test. `flex` (the
shortest, most generic blocklist entry) matches any class containing the substring:

- `<div class="reflex underflexed">` -> flagged `flex` (verified false positive)
- `inline-flex`, `flex-col` -> flagged, even if those are not the retired bare `flex`

Conversely the bare prefixes (`bg-cw-`) match mid-token garbage like
`my-bg-cw-thing` (verified). The result is both false positives (legitimate utility
class names containing `flex`) and imprecise matching that future maintainers can't
reason about. Because `flex` is a real, common Tailwind family root, this is the
most likely entry to misfire on real templates.
**Fix:** Tokenize the class string on whitespace and match per-class with anchoring —
exact match for bare utilities (`flex`, `bg-white`, `min-h-screen`, `max-w-md`) and
prefix match for the trailing-dash families (`bg-cw-`, `text-cw-`, etc.):
```js
const classList = classes.split(/\s+/).filter(Boolean);
for (const cls of classList) {
  for (const retired of RETIRED_TAILWIND) {
    const hit = retired.endsWith('-') ? cls.startsWith(retired) : cls === retired;
    if (hit) violations.push({ line: lineNum, text: cls, rule: 'retired-tailwind-class-forbidden' });
  }
}
```
This also fixes the duplicate-report behavior where one class string can emit
multiple violations for the same root.

### WR-06: CI step ordering wastes the merge-gate's fail-fast value

**File:** `.github/workflows/brandbook-verify.yml:80-94`
**Issue:** The drift gate (a cheap, dependency-free Node script, ~tens of ms) is placed
*after* the WCAG step but *before* the expensive Playwright install + structural e2e
(lines 84-94: `npm ci` in `brandbook/e2e` plus `npx playwright install --with-deps
chromium`). The drift gate itself is fine where it is, but the e2e Chromium install
is the long pole. That ordering is acceptable. The real scoping concern: the gate runs
with `working-directory: brandbook/tools` and invokes the script by relative name; the
script resolves `ROOT` via `../..` from its own file URL, so manifest paths still
resolve from repo root regardless of `working-directory`. That is correct — but it is
load-bearing and undocumented in the workflow. If anyone "tidies" the step to
`run: node brandbook/tools/check-consumer-drift.mjs` without `working-directory`, the
`npm ci`-installed deps still resolve (script has none) so it keeps working; but if the
script later gains a tools-local dependency, the path assumption silently matters.
**Fix:** Leave behavior as-is but add a one-line comment on the step noting that
`ROOT` is derived from the script's own location (so `working-directory` does not
affect which files are scanned), preventing a future regression. Optionally move the
drift gate above the WCAG/contrast `node --test` steps so the cheapest deterministic
gate fails first.

## Info

### IN-01: `on.paths` and the MANIFEST can drift apart silently

**File:** `.github/workflows/brandbook-verify.yml:20-33` / `check-consumer-drift.mjs:35-41`
**Issue:** The workflow trigger paths (app.css, `priv/static/crosswake/**`,
`priv/templates/crosswake/offline_ui/**`, the offline_html controller) are maintained
by hand in two places — `on.pull_request.paths`, `on.push.paths`, and the MANIFEST
array. A new normalized consumer added to MANIFEST but not to both `paths` blocks
won't trigger the workflow when only that file changes. There is no test pinning the
correspondence.
**Fix:** Add a comment cross-referencing the MANIFEST, or a small test asserting each
MANIFEST path is covered by a workflow trigger glob.

### IN-02: `checkCssSemanticCoverage` accepts any `var(--cw-` including primitives

**File:** `brandbook/tools/check-consumer-drift.mjs:129`
**Issue:** Coverage passes if any `var(--cw-` exists. A CSS file containing *only*
`var(--cw-primitive-*)` references would satisfy coverage (rule 3) while
simultaneously failing the primitive rule (rule 2) — so the net gate still fails,
which is fine. But the coverage check's intent ("semantic token coverage") is not
what it measures ("any cw var"). Minor semantic mismatch; behavior is safe due to
rule 2.
**Fix:** Optionally tighten to `var(--cw-(?!primitive-)` for coverage, or document
that rule 2 backstops it.

### IN-03: Per-line regex re-compiled inside the loop

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** `hexRe` is declared inside the `for` loop, recompiling the regex every
line. Not a performance concern at this file size (out of scope for v1 anyway) and
not a correctness bug since it's not shared `lastIndex` state — but it reads as
accidental. `findPrimitiveRefs` correctly hoists its regex (line 106); the
inconsistency suggests the placement was unintentional.
**Fix:** Hoist `hexRe` above the loop for consistency with `findPrimitiveRefs`.

### IN-04: `file-read-error` violations bypass the structured test path

**File:** `brandbook/tools/check-consumer-drift.mjs:209`
**Issue:** A missing manifest file is reported only in the IS_MAIN runner block, not
via an exported function, so the contract suite cannot unit-test the read-error path.
The `all manifest files exist on disk` test (test file line 34) covers the happy
case but the failure branch is untested.
**Fix:** Optional — extract the per-entry run into an exported `runEntry(entry)` that
returns violations (including read errors) so the error path is testable.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
