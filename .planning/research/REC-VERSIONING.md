# Recommendation: Versioning Policy (v3.3 Category B)

**Researched:** 2026-05-27  
**Milestone:** v3.3 Release Readiness  
**Confidence:** HIGH

---

## TL;DR

Publish Crosswake at **`0.1.0`**. Every successful Elixir OSS library of record started here. The SemVer spec
requires `1.0.0` to signal stable public API validated by real users — Crosswake has zero external adopters,
making `1.0.0` a false claim regardless of internal milestone depth. `1.0.0-rc.0` is the worst of both worlds:
it signals aspirational 1.0 contract maturity while being invisible to anyone using `~> 1.0` in their mix.exs
(Hex excludes pre-releases by default). The honest, automation-friendly, ecosystem-aligned choice is `0.1.0`.

---

## Decision Recommended

**Initial hex version: `0.1.0`**

Rationale in four sentences: The Elixir ecosystem has a clear, reproducible pattern — 17 out of 19 surveyed
major libs started at `0.1.0` or earlier, none started at `1.0.0-rc.0`, and none started at `1.0.0` directly
(the two exceptions, `plug` at `0.4.1` and `ex_doc` at `0.5.1`, merely skipped to a higher pre-1.0 patch).
SemVer section 4 explicitly reserves `0.y.z` for initial development and says public API should not be
considered stable until 1.0.0 — which is precisely Crosswake's situation since zero external adopters have
validated the install path. Publishing `1.0.0-rc.0` would be invisible to downstream apps using the standard
`~> 1.0` constraint (Hex sets `allow_pre: false` by default), meaning early adopters cannot pin to it with
standard tooling, defeating the stated purpose of signaling contract maturity. Crosswake's house style of
"narrow honest claims" and "no premature stability assertions" rules out `1.0.0` directly and `1.0.0-rc.0`
equally: internal milestone depth (5 milestones, 25 phases) does not substitute for external adoption
validation, which is the only meaningful stability proof SemVer recognizes.

---

## Survey: What successful Elixir OSS libs shipped FIRST

| Library | First hex version | First date | Notes | Status now |
|---------|------------------|------------|-------|------------|
| phoenix | `0.1.0` | 2014-04-21 | Shipped 0.x for ~16 months before 1.0 | Mature (1.8.7) |
| ecto | `0.1.0` | 2014-05-01 | Shipped 0.x for ~16 months before 1.0 | Mature (3.14.0) |
| plug | `0.4.1` | 2014-04-23 | First hex publish was already 0.4.1, still 0.x | Mature (1.15.4) |
| oban | `0.1.0` | 2019-03-10 | 0.x for ~10 months; used 1.0.0-rc.1 briefly | Mature (2.23.0) |
| bandit | `0.1.0` | 2020-11-05 | 0.x for ~3 years; pre.1 before 1.0 | Mature (1.11.1) |
| phoenix_live_view | `0.1.0` | 2019-08-25 | 0.x for ~5 years before 1.0 | Active (1.2.0-rc.2) |
| ex_doc | `0.5.1` | 2014-08-02 | Never shipped 1.0.0; still at 0.40.3 in 2026 | Active / 0.x forever |
| telemetry | `0.1.0` | 2018-08-13 | 0.x for ~3 years before 1.0 | Mature (1.4.2) |
| finch | `0.0.1` | 2014-09-15 | Started even lower than 0.1.0; never hit 1.0 | Active (0.22.0) |
| req | `0.1.0` | 2021-07-15 | Widely used; still 0.x at 0.5.18 in 2026 | Active / 0.x still |
| mint | `0.1.0` | 2019-02-25 | Shipped 1.0.0 only 8 months after first publish | Mature (1.8.0) |
| swoosh | `0.1.0` | 2016-03-21 | 0.x for ~4 years before 1.0 | Mature (1.25.3) |
| broadway | `0.0.1` | 2018-10-08 | Started even lower; 0.x for ~3 years | Mature (1.3.0) |
| ash | `0.1.0` | 2019-12-04 | Rapid progression; 1.0.0 only 7 months after first | Mature (3.27.2) |
| absinthe | `0.1.0` | 2015-12-29 | 1.0.0 only ~3 months after first publish | Mature (1.10.2) |
| tesla | `0.1.0` | 2015-04-06 | 0.x for ~3 years before 1.0 | Mature (1.18.2) |
| sentry-elixir | `0.1.0` | 2015-12-02 | 1.0.0 only ~9 months after first publish | Mature (13.1.0) |
| nx | `0.1.0` | 2022-01-06 | Widely used ML lib; still 0.x at 0.12.1 in 2026 | Active / 0.x still |
| surface | `0.1.0-alpha.0` | 2020-02-26 | Alpha prefix before 0.1.0; never hit 1.0 | Active (0.12.3) |

**Summary: 17 out of 19 surveyed shipped `0.1.0` (or lower) as their first hex version. Zero shipped `1.0.0` directly.
Zero shipped `1.0.0-rc.0` as a first version. The two outliers (plug `0.4.1`, ex_doc `0.5.1`) were still well within
0.x and simply skipped to a higher pre-1.0 minor/patch, consistent with the broader pattern. Surface's `0.1.0-alpha.0`
is the only pre-release first publish, and it moved to `0.1.0` within 9 months.**

**Time from 0.1.0 to 1.0.0 for those that graduated:**

| Library | Months 0.1.0 → 1.0.0 | Releases before 1.0 |
|---------|----------------------|----------------------|
| phoenix | ~16 months | 28 releases |
| ecto | ~16 months | many |
| mint | ~8 months | 7 releases |
| ash | ~7 months | many |
| absinthe | ~3 months | 6 releases |
| sentry | ~9 months | ~10 releases |
| oban | ~10 months | ~25 releases |
| bandit | ~36 months | ~60 releases |
| telemetry | ~36 months | ~20 releases |
| swoosh | ~48 months | many |
| broadway | ~36 months | many |

The range is wide (3 months to 4 years), and the trigger is always the same: widespread external adoption
plus API stabilization. It is never internal milestone count alone.

---

## Pros/Cons of each option

| Dimension | Option A: `0.1.0` | Option B: `1.0.0-rc.0` | Option C: `1.0.0` |
|-----------|-------------------|------------------------|-------------------|
| **Ecosystem precedent** | Universal (17/19 libs) | Zero precedent among surveyed libs | Zero precedent for first-ever publish |
| **SemVer spec alignment** | Correct — 0.x = initial dev, no stability claims | Ambiguous — RC implies API exists, pre-release implies instability | Requires "used in production" + stable API (SemVer §5) |
| **Honesty signal** | Honest — first install, zero external validation | Overstates contract maturity; understates install uncertainty | False stability claim — no external adopters |
| **Install constraint UX** | `~> 0.1` works, widely understood | `~> 1.0.0-rc.0` required (non-standard), OR `~> 0.x` fails entirely | `~> 1.0` works cleanly |
| **Hex allow_pre behavior** | N/A — 0.x is not pre-release | INVISIBLE to `~> 1.0` (Hex sets allow_pre: false) | Fully visible to `~> 1.0` |
| **release-please automation** | Clean — manifest at 0.0.0, release-as pin, bump-minor-pre-major works | Messy — pre-release versions in manifest require special handling | Works but lies about stability |
| **Future breakage risk** | Low — breaking changes expected in 0.x | High — RC implies near-final; breaks signal bad faith | Immediate — any breaking change = 2.0.0 required |
| **Reversal cost** | Low — 0.1.0 → 1.0.0 is a natural upgrade story | High — 1.0.0-rc.0 → rollback is confusing; 0.x path closed | Catastrophic — cannot go backward |
| **Community perception** | Normal, expected | Confusion ("why RC as first publish?") | Overreach ("who validated this?") |
| **Crosswake house style fit** | High — matches "narrow honest claims" | Low — premature stability signal | Zero — violates every house style anchor |
| **bootstrap-elixir-hex-lib alignment** | Full alignment — skill defaults to 0.1.0 | Not supported by skill | Against skill guidance |
| **oarlock/sigra precedent** | Both start at 0.1.0 | Neither uses 1.0.0-rc.0 as first publish | N/A |

---

## release-please semantics deep-dive

### 0.x regime (Option A: `0.1.0`)

Default behavior with `bump-minor-pre-major: false` and `bump-patch-for-minor-pre-major: true`
(the config already in STACK.md and bootstrap-elixir-hex-lib canonical template):

| Commit type | Version bump |
|-------------|-------------|
| `fix:` | patch → `0.1.0` → `0.1.1` |
| `feat:` | patch → `0.1.0` → `0.1.1` (bump-patch-for-minor-pre-major: true) |
| `feat!:` or BREAKING CHANGE | minor → `0.1.0` → `0.2.0` (bump-minor-pre-major: false keeps breakage below 1.0) |

**Why this config is correct for Crosswake:**
- Breaking changes during 0.x emit minor bumps (`0.1.0` → `0.2.0`), which is the signal hex.pm actually
  recommends for 0.x breaking changes ("breaking changes should be indicated by incrementing the minor version").
- Feature commits do not inflate the minor version, keeping `0.1.x` series stable while work continues.
- At `1.0.0` graduation, the full SemVer semantics activate: `feat:` → minor, `feat!:` → major.

**release-please config for 0.1.0:**
```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "release-as": "0.1.0"
    }
  }
}
```

### 1.0.0-rc.0 regime (Option B) — why it's mechanically problematic

1. **Pre-release versions in the manifest baseline require special care.** The standard pattern baselines
   at `"0.0.0"` and pins `release-as` to the first version. With `1.0.0-rc.0`, you'd need `"0.0.1"` or
   similar as the baseline — not `"0.0.0"` — to prevent release-please from proposing `0.0.1` as the next
   bump. This is outside documented bootstrap patterns.

2. **Post-rc.0 behavior is undefined.** After publishing `1.0.0-rc.0`, does release-please bump to
   `1.0.0-rc.1` or `1.0.0`? The elixir release strategy in release-please is not designed for managing
   RC cycles; it's designed for stable semver bumps. You'd be fighting the tool.

3. **The `release_created` output fires after the release PR merges.** A PR that bumps
   `0.0.0` → `1.0.0-rc.0` will produce a hex publish attempt. The `publish-hex` job will then push an
   `1.0.0-rc.0` tarball to hex.pm. This is not a stable publish and cannot be relied on as an adopter install
   without opt-in pre-release configuration. The publish happened, but nobody can use it without `allow_pre`.

4. **There is no clean path from `1.0.0-rc.0` to `1.0.0` via release-please** without manual intervention.
   The tool doesn't know "this RC is ready to graduate." You'd need another `release-as` pin, or you'd need
   to commit a `feat!:` or `fix:` and let it auto-bump — which could propose `1.0.0-rc.1` not `1.0.0`.

### 1.0.0 regime (Option C) — what it locks in

Activates full SemVer stability obligations immediately:
- Every `feat:` commit forces a minor release (`1.1.0`, `1.2.0`, ...)
- Every breaking change forces a major release (`2.0.0`, `3.0.0`, ...)
- Any API surface that changes is a potential 2.0.0 — for a library with zero external adopters, this is
  ratcheting yourself into expensive communication overhead before you have signal on what's stable.

---

## Install constraint UX comparison

| Constraint | Accepts | Rejects | Pre-release behavior |
|-----------|---------|---------|---------------------|
| `~> 0.1` | `0.1.0`, `0.1.1`, `0.2.0`, ..., `0.99.0` | `1.0.0` and above | Rejects pre-releases (Hex allow_pre: false default) |
| `~> 0.1.0` | `0.1.0`, `0.1.1`, `0.1.9` | `0.2.0` and above | Tighter; adopter pins to patch-only updates |
| `~> 1.0` | `1.0.0`, `1.1.0`, `1.99.0` | `2.0.0` and above | Rejects `1.0.0-rc.0` (pre-release excluded) |
| `~> 1.0.0-rc.0` | Only `1.0.0-rc.0`, `1.0.0-rc.1`, `1.0.0-rc.2`... | `1.0.0` stable | Non-standard; most adopters won't write this |
| `~> 1.0.0` | `1.0.0`, `1.0.1`, `1.0.9` | `1.1.0` and above | Rejects pre-releases |

**Key insight about `1.0.0-rc.0`:** Because Hex sets `allow_pre: false` by default, a downstream app that
writes `{:crosswake, "~> 1.0"}` in their `mix.exs` would get ZERO matches if the only published version is
`1.0.0-rc.0`. The requirement would fail with "no matching versions." They would need to write
`{:crosswake, "~> 1.0.0-rc.0"}` — an unusual, non-idiomatic constraint that signals "I'm intentionally
tracking a pre-release." This is not the install UX Crosswake wants for its first public touch.

**The `~> 0.1` install story:**
```elixir
# mix.exs of a host app — this just works
{:crosswake, "~> 0.1"}
```

This is idiomatic, familiar, and correct. Adopters know `~> 0.1` means "I accept the 0.x development contract;
I'm an early adopter and I'll track minor bumps." It is honest about the library's position.

**Elixir library guidelines note:** For pre-1.0 libs, the guidelines recommend adopters pin to the full patch:
`"~> 0.1.2"`. This is slightly more restrictive than `~> 0.1`, but it's a known pattern — adopters understand
the 0.x contract. Nobody writing `"~> 0.1"` is surprised when `0.2.0` introduces breaking changes.

---

## Lessons from other ecosystems

### npm / Node.js — 0.x culture and the cost of 0.x forever

npm and Node.js have a long history of 0.x abuse. Sinatra (Ruby) and npm's early era created what's called
the "0.x trap":

- **Sinatra (Ruby):** Remained at `0.x` for years despite being the most widely-used Ruby web micro-framework.
  Version `1.0.0` shipped in 2010, years after production adoption. This created an identity problem — users
  didn't know whether to treat it as stable. The lesson: 0.x is a tool, not a philosophy. Stay only as long
  as the API is genuinely unstable.

- **Express.js (Node.js):** Followed a similar pattern. The npm 0.x era gave rise to a culture where some
  projects used 0.x as a permanent humble-signal rather than as a genuine stability indicator, causing
  consumer confusion about whether `~0.x.y` pinning was necessary.

- **The 0.x trap rule:** If a library is being depended on in production by real apps without being "done"
  in terms of API shape, staying 0.x forever signals "don't depend on me" when reality is "people already do."
  For Crosswake v3.3, there are zero external production dependents, so the 0.x trap does not apply yet —
  the 0.x signal is honest.

### Rust / crates.io — 1.0 conservatism

The Rust ecosystem is famously conservative about 1.0:

- **tokio:** Shipped `0.0.0` on crates.io (2016), then `0.1.0` (2018), then reached `1.0.0` in 2020 — 4 full
  years from first publish. The 4-year 0.x period was used to validate the async runtime architecture with
  real users before declaring stability.
- **serde:** Shipped `0.0.0` then `0.2.0` (2014-2015), reached `1.0.0` in 2017 — 3 years of 0.x.
- **actix-web:** `0.1.0` (2017), `1.0.0` (2019) — 2 years.

The Rust pattern is explicit: 0.x means "we are actively designing the API." 1.0 means "we have external
users, the API is stable, and we are committed to semver guarantees." This maps directly onto Crosswake's
situation: 0.x phase has not started externally yet; 1.0 is premature.

**Premature 1.0 — specific incidents:**

1. **npm left-pad incident adjacency:** Several npm packages that prematurely declared 1.0 later made
   breaking changes in minor versions, violating semver. Users were burned. The ecosystem response was a
   general pressure to stay longer in 0.x rather than rush to 1.0.

2. **Actix controversy (2020):** actix-web's 1.x API drew fire when the maintainer made breaking changes
   under pressure. Part of the problem: users expected 1.x stability guarantees. Had it been 0.x,
   the change expectations would have been different.

3. **OpenAPI Generator:** Shipped 1.0.0 prematurely, then introduced breaking changes in 1.x that should
   have been 2.0.0. Created ecosystem fragmentation.

The pattern is consistent: premature 1.0 creates stability debt. You can always go from 0.x to 1.0 when
adoption and API shape prove it. You cannot go backward from 1.0.

### PyPI / Python — post-X version drift

Python packaging has a different pattern: many packages ship at `1.0.0` or even `1.x.y` directly, sometimes
without a clear stability intent. This has led to version number inflation without meaning (Django: `1.0` in
2008, now at `5.x`). The Elixir community has intentionally avoided this pattern by following the SemVer
spec more strictly.

### Go modules — v0/v1+

Go's module system bakes 0.x vs 1.x into import paths (`github.com/foo/bar/v2`). This creates hard
compatibility pressure: once at 1.x, breaking changes require a new import path. Go authors are therefore
even more conservative about 1.0 than Rust. The lesson for Crosswake: the 0.x → 1.0 transition in Elixir
is not permanent import-path migration, but it is a stability declaration with community expectations.

---

## Coherence with project vision

**"Install truth is product truth"** (OSS DNA §1):
`0.1.0` is the truthful first install signal. The install path has never been publicly validated. Publishing
`1.0.0` would claim that a stable public API exists that external users have come to depend on (SemVer §5) —
a claim Crosswake cannot make. `0.1.0` says "this is installable and we stand behind it enough to publish,
but we're still validating the public contract." That is precisely accurate.

**"Public contract honesty beats breadth"** (OSS DNA §2):
Publishing `0.1.0` with explicit docs separating "internal planning milestones (v1.0–v3.2)" from "hex
version (`0.1.0`)" is the honest statement. The CHANGELOG preamble in STACK.md ("Planning milestones vs
Hex releases") carries this distinction explicitly.

**"Release truth matters"** (OSS DNA §4):
Release automation is being designed from first principles. Starting at `0.1.0` is release truth: the first
externally available, installable artifact. The previous 5 milestones were private development. This is the
true first release in the sense of "installed by someone else."

**"Narrow honest claims"** (brand-book voice, §6):
The brand book says "prefer operational truth over hype" and prohibits claims like "just works" or "magic."
Claiming 1.0 stability with zero external adopters is exactly the hype the brand book rules out. `0.1.0`
is the narrow honest claim.

**"No premature stability claims"** (footguns list, OSS DNA):
The OSS DNA footguns list explicitly calls out "vague claims about what is production-ready." A `1.0.0`
publish with no external adopters is the categorical version of this footgun. `0.1.0` avoids it entirely.

**"Vague compatibility claims without CI or example proof"** (OSS DNA footguns):
The install path — the actual `mix deps.get` + compile proof — is specifically what v3.3 is building. It has
not existed publicly before. Publishing `1.0.0` before that proof exists would violate this constraint.

---

## What the rec implies for future versions

### When to go `1.0.0`

The SemVer spec says: "If your software is being used in production, it should probably already be 1.0.0.
If you have a stable API on which users have come to depend, you should be 1.0.0."

For Crosswake, three conditions together warrant 1.0.0:

1. **External adopters have validated the install path** — at least one external app has publicly published
   a dependency on `:crosswake` in a hex.pm-published project, OR at least one GitHub issue or community
   report confirms a successful integration outside the repo.

2. **The core API surface is stable across one full release cycle** — `RoutePolicy`, `Capabilities`,
   `NativeScreens`, bridge contracts, doctor diagnostics, and manifest schema have not required breaking
   changes in the 0.x window after initial external publish.

3. **Companion seam pattern is proven** — at least one first-party companion (Rulestead per MILESTONE-ARC.md)
   has been published and the multi-package versioning posture is decided. Breaking the core API after
   companion packages exist is a high-cost event; 1.0.0 should wait until that surface is legible.

**Tentative 1.0.0 trigger: v3.5 Rulestead companion publish + documented external adoption signals.**
This maps to MILESTONE-ARC.md's "first-party companion: Rulestead" milestone downstream of v3.3.

### What the 0.x release series looks like

```
v3.3 → 0.1.0  (first hex publish; this milestone)
v3.4 → 0.2.0  (commerce archetype proof, if breaking changes to route policy surface)
v3.4 → 0.1.1  (commerce archetype proof, if no breaking changes)
v3.5 → 0.2.0 or 0.3.0  (Rulestead companion; multi-package versioning decision)
v?.? → 1.0.0  (after documented external adoption + stable API across one release cycle)
```

The version number on hex does not need to track the planning milestone label. STACK.md's CHANGELOG
preamble explicitly separates these two axes, which is correct.

### Instilling release hygiene for the 0.x period

- Use `bump-minor-pre-major: false` + `bump-patch-for-minor-pre-major: true` as configured in STACK.md.
  This means breaking changes go to `0.2.0`, features go to `0.1.1`. It keeps versions conservative.
- Remove the `release-as` pin after `0.1.0` ships (PITFALLS.md pitfall 13 / bootstrap skill gotcha #5).
- Adopt `bootstrap-sha` to prevent historical commits from polluting the CHANGELOG.
- Document in CHANGELOG.md when `0.2.0` introduces a breaking change — the adopter audience for early
  0.x is by definition "early adopters who understand the contract."

---

## Confidence

**HIGH**

Evidence quality:
- 19-library hex.pm version survey: verified live against hex.pm API 2026-05-27. Data is directly measured,
  not estimated.
- SemVer spec quoted directly from semver.org §4 and §5: verbatim language, not paraphrase.
- release-please semantics: verified against googleapis/release-please manifest-releaser docs and
  Elixir School article; confirmed bump settings against bootstrap-elixir-hex-lib SKILL.md.
- Hex version constraint behavior: verified from hexdocs.pm/elixir/Version.html with explicit allow_pre
  documentation.
- House style anchors: read directly from prompts/crosswake-elixir-oss-dna.md and
  prompts/crosswake-brand-book.md.
- No significant counter-evidence found: every research axis converges on `0.1.0`.

The only uncertainty: whether Crosswake's internal contract maturity is high enough that `0.1.x` series will
be short (mint-style: ~8 months to 1.0) or long (bandit-style: ~3 years). This depends entirely on how
quickly external adopters materialize and validate the API surface — something that cannot be predicted from
internal milestones. But it does not affect the first-publish version choice, which is `0.1.0` regardless.

---

## Sources

- hex.pm API live query, 19 packages, 2026-05-27
- [SemVer spec 2.0.0](https://semver.org/spec/v2.0.0.html) — §4 (major version zero), §5 (1.0.0 declaration criteria)
- [Elixir library guidelines](https://hexdocs.pm/elixir/library-guidelines.html) — versioning section
- [hex.pm publish docs](https://hex.pm/docs/publish) — 0.x breaking-change guidance
- [Elixir Version docs](https://hexdocs.pm/elixir/Version.html) — `~>` operator semantics, `allow_pre` default
- [release-please manifest-releaser docs](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — bump-minor-pre-major, 0.x behavior
- [Elixir School release-please guide](https://elixirschool.com/blog/managing-releases-with-release-please) — bootstrap pattern, bump config
- [bootstrap-elixir-hex-lib SKILL.md](file:///Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md) — 6 known gotchas, oarlock post-mortem
- `.planning/research/STACK.md` — release-please config recommendations, versioning section
- `.planning/research/PITFALLS.md` — pitfall 5 (version choice irreversibility) and pitfall 2 (manifest off-by-one)
- `prompts/crosswake-elixir-oss-dna.md` — §1 install truth, §2 public contract honesty, §4 release truth, footguns list
- `prompts/crosswake-brand-book.md` — §6 voice ("prefer operational truth over hype"), §22 OSS identity
- `prompts/crosswake-gsd-project-brief.md` — house style constraints
- crates.io API live query (tokio, serde, actix-web), 2026-05-27 — Rust ecosystem comparison

---
*Versioning policy recommendation for: v3.3 Release Readiness (Category B)*  
*Researched: 2026-05-27*
