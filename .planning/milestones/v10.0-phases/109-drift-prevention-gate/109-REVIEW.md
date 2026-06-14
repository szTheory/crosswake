---
phase: 109-drift-prevention-gate
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .github/workflows/brandbook-verify.yml
  - brandbook/tools/check-consumer-drift.mjs
  - brandbook/tools/check-consumer-drift.test.mjs
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the consumer-drift prevention gate: a CI workflow job, the Node drift
scanner, and its contract test. The code is clean stylistically and the test
suite is thoughtfully structured (positive fixtures + false-positive guards +
green-baseline integration). However, the core value proposition — "exit
non-zero when any file reintroduces brand-color drift" (file header, lines 6-7)
— has multiple proven holes. This is a *regression gate*, so it must catch
drift in forms the files do not currently contain; several common
reintroduction vectors silently pass.

Two classes of correctness defect dominate:

1. **Hex-detection false negatives** — the value-context lookbehind misses real
   drift vectors (`=#fff` custom-property assignment, attribute syntax like
   `stop-color="#fff"`, `;#fff` value separators). A developer reintroducing a
   hardcoded brand color in any of these positions ships undetected.
2. **Retired-Tailwind substring matching** — `classes.includes(retired)`
   produces both false positives (`inline-flex`, `flex-col`, `reflex` all match
   `flex`) and is brittle against quoting/wrapping that HEEX commonly uses
   (single quotes, newline-wrapped class lists, `class={...}` dynamic bindings
   all evade detection).

Additionally, the contract test file is **not wired into CI** — it never runs
in `brandbook-verify.yml`, so the manifest-completeness pins and false-positive
guards it encodes cannot fail a build. All findings include concrete fixes and
were reproduced against the shipped module.

## Critical Issues

### CR-01: Hex-color gate misses common reintroduction vectors (false negatives)

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** The lookbehind `(?<=[:,(\s])` requires `#` to be immediately preceded
by `:`, `,`, `(`, or whitespace. This was chosen to exclude `#id` selectors, but
it also silently passes legitimate drift. Reproduced against the shipped module:

```
findHexColors("--x=#ffffff")           => []   // CSS custom property assignment
findHexColors('stop-color="#ffffff"')  => []   // SVG/HTML attribute (no colon before #)
findHexColors("a:1;#ffffff")           => []   // semicolon-separated value
```

The gate's stated job (header lines 6-9) is to fail when *any* file reintroduces
a hex literal. A contributor adding `--cw-brand: #2B756A` via `=`, or inline SVG
`fill="#2B756A"` in the offline HEEX templates, drifts past the gate while
reasonably believing it is covered. This is a correctness control with a bypass,
not a style nit.

**Fix:** Drop the fragile lookbehind; match hex broadly and exclude only the
documented `#id`-selector case explicitly:

```js
// Match hex in any position, then skip when the line is a CSS selector rule.
const hexRe = /#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})\b/g;
// For each match, skip if the surrounding text is selector context:
//   /^\s*[.#:a-zA-Z\[][^{}]*\{/.test(line)  // e.g. "#status { ... }"
```

Add fixtures for `=#fff`, `;#fff`, and `attr="#fff"` to lock the behavior.
(4-digit `#RGBA` is also valid CSS and currently uncovered — see WR-02.)

### CR-02: Retired-Tailwind detection produces false positives that fail valid builds

**File:** `brandbook/tools/check-consumer-drift.mjs:148-152`
**Issue:** `classes.includes(retired)` is an unbounded substring test.
Reproduced against the shipped module:

```
findRetiredTailwindInClassAttrs('<div class="inline-flex gap-2">') => ["flex"]
findRetiredTailwindInClassAttrs('<div class="flex-col">')          => ["flex"]
findRetiredTailwindInClassAttrs('<div class="reflex">')            => ["flex"]
```

`inline-flex`, `flex-col`, `flex-1`, `reflex`, etc. are all flagged as the
retired `flex` utility. Because this is a **required merge gate** (workflow lines
7-8, 36, and not `continue-on-error`), a future HEEX edit legitimately using
`inline-flex` or any `flex-*` utility will hard-block the PR with a false
violation. The blocklist mixes exact tokens (`flex`, `bg-white`,
`min-h-screen`, `max-w-md`) with prefixes (`bg-cw-`, `text-cw-`, `border-cw-`,
`border-gray-`, `space-y-`), but the matcher treats all of them as substrings,
so exact entries over-match and prefix entries can also collide.

**Fix:** Tokenize the class attribute on whitespace and match per-class —
`startsWith` for prefix entries (those ending in `-`), strict equality otherwise:

```js
const tokens = classes.split(/\s+/).filter(Boolean);
for (const retired of RETIRED_TAILWIND) {
  const isPrefix = retired.endsWith('-');
  for (const cls of tokens) {
    if (isPrefix ? cls.startsWith(retired) : cls === retired) {
      violations.push({ line: lineNum, text: retired, rule: 'retired-tailwind-class-forbidden' });
    }
  }
}
```

Add negative fixtures for `inline-flex`, `flex-col`, and `reflex`. The existing
blocklist-pin test (test lines 126-144) only proves positives; it does not catch
this over-match.

## Warnings

### WR-01: Class-attribute scan misses single quotes, wrapped lists, and dynamic bindings (false negatives)

**File:** `brandbook/tools/check-consumer-drift.mjs:142`
**Issue:** `classRe = /class="([^"]*)"/g` matches only double-quoted, single-line,
static `class` attributes. HEEX/EEx templates commonly use other forms — all of
which evade detection (reproduced):

```
findRetiredTailwindInClassAttrs("<div class='flex'>")          => []   // single quotes
findRetiredTailwindInClassAttrs("<div\n class=\"foo\n bar\">")  => []   // newline-wrapped
findRetiredTailwindInClassAttrs("<div class={@foo}>")          => []   // HEEX dynamic binding
```

The gate claims to guard HEEX files (rule 4, lines 184-187) but covers only the
narrowest syntax. Single-quoted and multi-line class lists are idiomatic in
`.heex`.

**Fix:** Broaden the attribute regex to accept either quote style:

```js
const classRe = /class=(?:"([^"]*)"|'([^']*)')/g;
// classes = m[1] ?? m[2];
```

For `class={...}` dynamic bindings, decide explicitly whether to scan the
expression text or document the gap in the file header — today it is an
undocumented silent miss.

### WR-02: 4-digit (#RGBA) hex literals are not detected, and the comment is factually wrong

**File:** `brandbook/tools/check-consumer-drift.mjs:76-77`
**Issue:** The alternation is `{6}|{8}|{3}` — 4-digit `#RGBA` (valid CSS Color 4,
widely supported) is omitted: `findHexColors("color: #1a2b;") => []`. The comment
on line 76 ("Valid CSS hex lengths: 3, 6, or 8 digits only") is incorrect —
4-digit hex is valid. A `#fff8` drift passes the gate.

**Fix:** Add the 4-digit alternative and correct the comment:
`[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3}`.

### WR-03: Contract test file is never executed in CI

**File:** `.github/workflows/brandbook-verify.yml:80-82`
**Issue:** The workflow runs `node check-consumer-drift.mjs` (the gate) but has no
step running `node --test check-consumer-drift.test.mjs`. Contrast lines 72-78,
which explicitly invoke `node --test compile-tokens.test.mjs` and
`node --test contrast.test.mjs`. The new contract test — which pins manifest
completeness (exactly 5 entries), the 9-token blocklist, and every
false-positive guard — therefore cannot fail a build. The regex regressions in
CR-01/CR-02/WR-01/WR-02 would slip through because the guards meant to catch them
never run in CI. The test exists but gives zero CI protection.

**Fix:** Add a step after line 82:

```yaml
      - name: Consumer drift gate contract tests
        working-directory: brandbook/tools
        run: node --test check-consumer-drift.test.mjs
```

### WR-04: Green-baseline test swallows diagnostics on failure

**File:** `brandbook/tools/check-consumer-drift.test.mjs:148-154`
**Issue:** The integration test uses `assert.doesNotThrow(() => execSync(..., {
stdio: 'pipe' }))`. On failure it reports only "gate must exit 0" — the captured
stdout/stderr (the actual `::error file=...` violation lines) is discarded, so a
red baseline yields a near-useless message and forces a manual re-run to diagnose.
It also couples the unit test to a `node`-on-PATH subprocess when the functions
are already exported for in-process use.

**Fix:** Capture and surface the subprocess output:

```js
try {
  execSync(`node ${scriptPath}`, { cwd: ROOT, stdio: 'pipe' });
} catch (err) {
  assert.fail(`gate exited non-zero:\n${err.stdout?.toString()}\n${err.stderr?.toString()}`);
}
```

Or assert against `checkFile()` over the real manifest in-process.

### WR-05: Hex alternation order is shorter-first, risking order-dependent matches

**File:** `brandbook/tools/check-consumer-drift.mjs:77`
**Issue:** Alternation lists `{6}` before `{8}`. With the trailing `\b`, a valid
8-digit `#RRGGBBAA` value can be attempted as a 6-digit match first; the engine
recovers here, but ordering shorter-before-longer in a hex matcher is a latent
foot-gun and makes 8-digit coverage implicit rather than asserted. There is no
fixture pinning 8-digit detection.

**Fix:** Order alternatives longest-first (`{8}|{6}|{4}|{3}`) so the full-length
token is preferred, and add an explicit fixture for an 8-digit `#RRGGBBAA` value.

## Info

### IN-01: Deferred-offender exclusions have no enforcement backstop

**File:** `brandbook/tools/check-consumer-drift.mjs:28-34`
**Issue:** The comment defers `offline_study.js` (`#9A4D35` etc.) and
`step_up_challenge_live.ex` (`bg-[#F8FAFC]`) as excluded "deferred offenders."
Both contain exactly the drift this gate exists to prevent, and nothing tracks
that the exclusion is temporary — a future reader has no machine-checkable signal
they must eventually be normalized and added. Consider a known-debt allowlist
with an issue reference so the debt cannot silently become permanent.

### IN-02: `findHexColors` recompiles its regex inside the per-line loop; inconsistent with `findPrimitiveRefs`

**File:** `brandbook/tools/check-consumer-drift.mjs:77` vs `:106`
**Issue:** `findHexColors` declares `const hexRe = /.../g` inside the `for` loop
over lines (re-created each iteration), while `findPrimitiveRefs` hoists its
regex above the loop and relies on `exec` resetting `lastIndex` per line. Both do
the same per-line scan but use different patterns; align them.

**Fix:** Hoist `hexRe` above the loop for parity, or add a one-line comment noting
the in-loop declaration is intentional for `lastIndex` hygiene.

### IN-03: Unknown CLI flags are silently ignored

**File:** `brandbook/tools/check-consumer-drift.mjs:196-197`
**Issue:** Only `--verbose`/`-v` is recognized; any other argument (a typo like
`--verbsoe`, or `--help`) is silently ignored and the scan runs anyway, giving no
feedback.

**Fix:** Reject unknown flags or print a brief usage line.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
