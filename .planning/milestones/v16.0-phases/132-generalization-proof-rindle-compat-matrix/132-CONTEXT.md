# Phase 132: Generalization Proof (rindle) + Compat Matrix - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Run the **identical, already-locked extraction recipe** (`script/extract_companion.md`,
proven on rulestead in Phases 130–131) on the `rindle` companion: move
`Crosswake.Companions.Rindle` **and its owned domain modules** (`Rindle.Contracts` with
`UploadGrant`/`CaptureEvidence`/`MediaObject`, and `Rindle.Reconciliation` with
`Attempt`/`IdempotencyKey`/`EvidenceResult`) into a standalone `packages/crosswake_rindle/`
Hex project (module names **preserved** = non-breaking), publish it independently versioned on
Hex via the same release-please/clean-room pipeline, and add **no rindle-specific branch to
core**. Then ship the cross-package **compatibility matrix** (`guides/companion_compatibility.md`,
COMPAT-02) and a **merge-blocking drift test** (COMPAT-03) that keeps the matrix honest against
each companion's declared `{:crosswake, "~> …"}` requirement.

Requirements: **EXTRACT-07, SEAM-05, COMPAT-02, COMPAT-03.**

### What is ALREADY LOCKED by the 130/131 recipe (do NOT relitigate — reuse by substitution)
- Env-conditional `crosswake_dep/0` resolver (`CROSSWAKE_RELEASE=1` → `{:crosswake, "~> 0.1"}`,
  else `path: "../.."`); poncho `path:` dep, core is a **runtime** dep, **no `runtime: false`** (130-D-19).
- release-please **separate component** (NOT in `linked-versions` lockstep), `extra-files` +
  manifest baseline + one-shot `release-as`, per-component-output-gated publish job (131-D-01..09).
- Parameterized `script/verify_companion_cleanroom.sh` (already takes `$1 PACKAGE $2 VERSION
  $3 ENGINE_PACKAGE $4 ENGINE_MODULE`) + `verify_companion_package.sh` Step-2 dep-presence grep.
- `CompanionGuard` frozen MapSet (130-D-13/14): add `Crosswake.Companions.Rindle` now; never a
  blanket `Companions.*` ban (Sigra/Chimeway stay legal until a later milestone).
- Test-split principle (130-D-20): adapter/domain-behavior proofs → companion lane; the
  COMPAT-01 fail-closed contract → **stays in core** exercising only the `@behaviour`+registry seam.
- `@compile {:no_warn_undefined, Rindle}` + runtime `Code.ensure_loaded?(Rindle)` probe (130-D-28/29).

**Out of scope (defer):** sigra/chimeway/threadline extraction (later milestone, EXTRACT-FUT);
`Crosswake.Telemetry` public API (Phase 133); shell lifecycle + native UAT (Phase 134); widening
the rindle engine cap to admit the `0.3.x` line (see D-19 — a deliberate future decision, not this phase).
</domain>

<decisions>
## Implementation Decisions

Four gray areas were researched by four parallel subagents (each grounded in the live code, the
130/131 locked recipe, the project DNA `prompts/` + `brandbook/BRAND-SPEC.md`, and ecosystem
idiom). Every load-bearing code fact below was re-verified against the repo. **User delegated all
four decisions to a single coherent recommendation set (2026-06-26) — "one-shot it so I don't have
to think."** The four sets are mutually coherent: ① defines what moves and where its tests land; ②
designs the matrix doc; ③ designs the test that keeps ②'s doc honest against ①'s packaged mix.exs;
④ proves the published artifact resolves.

### ① rindle's owned contracts + the (broader-than-expected) test coupling [EXTRACT-07, SEAM-05]
- **D-01: `Rindle.Contracts` and `Rindle.Reconciliation` are companion-PRIVATE domain types — they
  move WITH rindle into `packages/crosswake_rindle/`, module names preserved; NONE are promoted to
  the Phase-129 frozen public companion-contract surface.** Principled test (ecosystem-unanimous —
  Swoosh/Oban/Ash/Membrane/Broadway): **core owns the behaviour/envelope types it must pattern-match
  to talk to *any* companion** (the frozen 5: `Companion`, `Companion.State`, `Compatibility.Finding`,
  `Compatibility.Target`, `Manifest.Types.RouteEntry`); **the companion owns its own domain model.**
  Verified: zero core `lib/` module references these types (the `support_matrix.ex`/`renderer.ex`
  "Rindle" hits are prose **string literals**, not aliases — not EXTRACT-03 nodes). Keeping the public
  surface exactly 5 is the honest signal (lean-core; "public contract honesty beats breadth").
- **D-02: SEAM-05 is structurally clean — core needs NO rindle-specific branch.** The CompanionGuard
  MapSet gains `Crosswake.Companions.Rindle` (and the guard naturally covers the `.Contracts`/
  `.Reconciliation` children since they share the namespace prefix); no core `lib/` refactor of
  aliases is required (unlike the eventual sigra/chimeway work). This is the whole point of the phase:
  prove the recipe generalizes with zero core special-casing.
- **D-03: The test coupling is the biggest mechanical reality of this phase — SIX core-lane test
  files alias rindle internals and will fail to compile once the modules move.** (rulestead moved
  only 2.) They split by the D-20 rule — **domain/adapter-behavior proofs → companion lane; seam/
  fail-closed contracts → stay in core exercising ONLY `@behaviour`+registry (no internal alias).**
  Per-file disposition (PLANNER to confirm each, but the default classification is):
  - `phase72_media_evidence_workflow_proof_test.exs` — pure rindle media/evidence DOMAIN proof →
    **move wholesale to companion lane** (with its CI `phase72-proof.yml` redirected/folded into the
    rindle companion lane). Its hermeticity self-scan and authority-mutation guards are atomic and
    portable.
  - `phase45_rindle_mock_media_test.exs`, `phase45_rindle_companion_test.exs`,
    `phase45_rindle_advisory_test.exs` — adapter/domain behavior → **companion lane** (mirrors
    rulestead's phase42/phase43 split).
  - `phase47_companion_arc_test.exs` — **PLANNER INVESTIGATION (do not skip):** likely a
    CROSS-companion arc test referencing rulestead AND rindle. If it asserts the generic
    `@behaviour`/registry seam, **rewrite it to the seam and keep in core**; if it asserts rindle
    domain internals, move it. Decide per assertion at plan time.
  - `test/crosswake/guides/companions_test.exs` (core-owned guides test) — uses
    `Code.ensure_loaded!(Crosswake.Companions.Rindle)` + `function_exported?/3` at lines 122/131/150/
    228. **Rewrite to exercise rindle through the seam (registry + behaviour callbacks), NOT a direct
    module alias** — otherwise EXTRACT-03 fires. This is migration work BEYOND the recipe's Step 2.
- **D-04: Unit tests `contracts_test.exs` + `reconciliation_test.exs` move verbatim to the companion
  lane** (verified: zero `test/support` deps). Companion `test/support` needs: a `StudySessionLive`
  stub copied (D-23 idiom — `phase45_rindle_companion_test` mounts a `live` route), a fake top-level
  `Rindle` engine stub under an engine-present path (D-33), and — if phase72/phase45_mock_media move —
  the four `examples/phoenix_host` media helpers (`reconciliation_keys`, `reconciliation_inbox`,
  `mock_capture`, `media_projection`) **copied** into the companion's `test/support/example_host/`
  (standalone-installable; the hermeticity self-scan matches on basename, so the copy is safe).

### ② Compatibility matrix doc — `guides/companion_compatibility.md` [COMPAT-02]
- **D-05: One markdown table, one row per companion, 6 columns** (minimal-but-sufficient for the
  adopter JTBD "what core version + which engine do I need to add `crosswake_<x>`?"):
  `Hex Package | Companion ID | Current Version | Requires \`crosswake\` | Engine Dependency | hexdocs`.
  Concrete locked shape (fill rindle on extraction):
  ```markdown
  | Hex Package | Companion ID | Current Version | Requires `crosswake` | Engine Dependency | hexdocs |
  |---|---|---|---|---|---|
  | `crosswake_rulestead` | `:rulestead` | `0.1.0` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rulestead](https://hexdocs.pm/crosswake_rulestead) |
  | `crosswake_rindle`    | `:rindle`    | `0.1.0` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}`    | [hexdocs.pm/crosswake_rindle](https://hexdocs.pm/crosswake_rindle) |
  ```
- **D-06: `Requires crosswake` is the VERBATIM `~> 0.1` requirement string (not a resolved range).**
  It is the exact literal the drift test (③) extracts from the companion's `mix.exs` — any
  transformation manufactures a drift seam. `Companion ID` is the only adopter touch-point name that
  is NOT the package name (it goes in `config :crosswake, :companions`), so it earns a column.
- **D-07: Columns deliberately OMITTED:** status/maturity (nothing experimental at N=2; don't add a
  column you can't keep accurate), inline config snippet (belongs in prose, not a cell), "what it
  does" (lives in `guides/companions.md`). Grows by ADDING ROWS, never columns — scales to 5+ clean.
- **D-08: Prose sections around the table** (short, brand-voice, no over-promise): (1) opening
  orientation (link to `guides/companions.md` for setup, don't re-explain companions); (2)
  **Independent Versioning** (companion 0.1.0 + core 0.1.2 coexist; declares a minimum, NOT a
  ceiling — concrete example); (3) **Reading the Requirement Syntax** (`~> 0.1` = `>= 0.1.0 and <
  1.0.0`, once); (4) **Engine Dependencies** (the `optional: true` engine is NOT pulled transitively;
  honestly name the friction — the live `rindle`/`rulestead` engines have releases OUTSIDE `~> 0.1`,
  see D-19); (5) **Verifying Companion Health** (`mix crosswake.doctor` CTA — closes the "added the
  package but forgot to register/add-engine" support loop, emits `companion.dependency_missing`).
- **D-09: Do NOT over-promise / banned-word discipline:** not "Crosswake's companion ecosystem"
  (→ "first-party companion packages"); not "fully compatible" (state the declared minimum, doctor
  is the live check); no "just"; caveat that `Current Version` points to hexdocs for the live number.
  Match the existing `guides/support_matrix.md` table house-style; note `guides/compatibility.md`
  already exists and is DISTINCT (forward-looking compatibility-contract prose) — link, don't merge.

### ③ Compat-matrix drift test — `guides/companion_compatibility.md` ⇄ packages/*/mix.exs [COMPAT-03]
- **D-10: CORE owns the test, in the hermetic PR-gating proof lane** (e.g.
  `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`): one file, untagged, `async: true`,
  NOT `:requires_example_host`. The matrix DOC lives in core `guides/`; both companion `mix.exs`
  files are in-tree at `packages/*/mix.exs` and read **read-only** (no compile coupling) — the same
  access class as the phase129/phase130 `Path.wildcard` source assertions. NOT per-companion (a
  companion can't bidirectionally check the doc or its sibling) and NOT both (two-source-of-truth
  smell the DNA rejects).
- **D-11: Extract the published requirement by AST-parsing `crosswake_dep/0`** via
  `Code.string_to_quoted/2` + `Macro.prewalk/3` (the repo idiom, 130-D-12) — find the `defp
  crosswake_dep` node, take the `do:` branch of its `if`, read the `{:crosswake, "~> X.Y"}` string
  literal. **This is mandatory because the env-conditional resolver means a naive `deps/0` read or a
  bare `grep crosswake` returns the PATH dep (or BOTH strings) when `CROSSWAKE_RELEASE` is unset.**
  Rejected: evaluating `deps/0` with `System.put_env` (non-hermetic, not async-safe, pollutes
  `Mix.Project`); a separate `@min_version` attribute (invents a second drift seam — the mix.exs IS
  the canonical source per the requirement text). Verified target (rulestead/mix.exs:64-67):
  `defp crosswake_dep do if System.get_env("CROSSWAKE_RELEASE") == "1", do: {:crosswake, "~> 0.1"}, else: {:crosswake, path: "../.."} end`.
- **D-12: Parse the doc by finding the row keyed on the Hex package name (col 1) and capturing the
  `~>`-prefixed core-requirement cell** (regex, no markdown-parser dep). The doc owes the test a
  pinned column contract: pin it with an HTML comment above the table
  (`<!-- compat-03 contract: col1=Hex Package, requirement cell = "Requires crosswake"; do not reorder without updating phase132_compat_matrix_drift_test.exs -->`)
  so the test keys on the package name + the requirement token, not a fragile absolute column index.
- **D-13: Exact-string match; BIDIRECTIONAL; non-vacuity-guarded.** Fail on: (a) version mismatch
  (doc ≠ mix.exs literal), (b) a `packages/crosswake_*/mix.exs` missing from the doc, (c) a doc row
  with no matching package (phantom). Assert the doc EXISTS first (distinct "create the doc" failure,
  mirroring the phase129 `companion_contract.md` exists check). Assert `Path.wildcard("packages/*/mix.exs")`
  returns ≥2 (rulestead+rindle) to prevent the empty-glob silent pass (130-D-13 footgun). Reuse
  `ProofAssertions.stable_id_message/7`; failures lead `[crosswake]`, name what happened + the one
  fix (stable ids `proof.compat_03.matrix_drift.<pkg>.{missing_from_doc,version_mismatch}` /
  `…phantom_doc_row`). Reject substring match (false-passes on `~> 0.1.0` containing `~> 0.1`) and
  semver-equivalence (hides real drift; adds complexity).

### ④ rindle clean-room engine handling [EXTRACT-07, PROOF reuse]
- **D-14: HEX INVESTIGATION RESULT (verified via hex.pm):** `rindle` exists on Hex (same author,
  `szTheory`), versions `0.1.4 … 0.1.10`, then `0.3.0` (latest). Top-level module is `Rindle`
  (probe flips true). **`0.3.0 ∉ "~> 0.1"`** (`~> 0.1` = `>= 0.1.0 and < 0.2.0`) — the SAME mismatch
  class as rulestead's `1.0.0 ∉ ~> 0.1` (131-D-20). A compliant `0.1.x` resolution **does exist:
  `0.1.10`.**
- **D-15: Clean-room proves the HAPPY PATH (engine present → `mix crosswake.doctor --router` exit 0),
  NOT both-states** (131-D-19): the fail-closed `:error` path stays proven merge-blocking in CORE
  (the moved phase45 lane + the COMPAT-01 contract test in core), so the clean-room owns only the
  adopter happy path — no redundancy. Pin the clean-room engine to `{:rindle, "~> 0.1"}` (resolves
  `0.1.10`); the script already emits this via its `ENGINE_PACKAGE` param.
- **D-16: Companion engine cap stays `{:rindle, "~> 0.1", optional: true}`** in
  `packages/crosswake_rindle/mix.exs` — unchanged from the recipe template; widening to `~> 0.3` is a
  deliberate FUTURE decision (the `0.3.x` API isn't validated against the `Rindle` probe), explicitly
  out of scope here.
- **D-17: Inline smoke test (tarball ships no `test/`) asserts the public `@behaviour` seam** —
  `companion_id/0 == :rindle`, `validate_dependency/0 == :ok` (engine present), `enabled?/1`,
  `report_state/0` — **PLUS one rindle-specific resolvability canary:**
  `Crosswake.Companions.Rindle.Contracts.media_state_vocabulary()` returns a non-empty list (rindle's
  `Contracts` module DOES ship in the tarball, unlike rulestead which had no sub-module; the canary
  confirms it wasn't orphaned). One canary, not a full Contracts suite.
- **D-18: `verify_companion_cleanroom.sh` needs NO new param** (already `crosswake_rindle <ver> rindle
  Rindle`). The clean-room CI job `clean-room-proof-rindle` is a copy-substitute of
  `clean-room-proof-rulestead` (swap args + `needs:`/`if:` output refs). The Contracts canary is the
  one rindle delta in the script's generated smoke-test body (a small `if [ "$PACKAGE" = crosswake_rindle ]`
  append — keep the proof colocated in the script).
- **D-19 (carry the engine-version honesty into the matrix doc ②/D-08):** both live engines
  (`rulestead 1.0.0`, `rindle 0.3.0`) have a latest release outside the companion's `~> 0.1` cap.
  The matrix's "Engine Dependencies" prose must name this so an adopter pins the `0.1.x` line and
  isn't surprised — this is the "honest failure modes / name the friction" brand stance.

### Claude's Discretion
- Exact ExUnit module/file names, stable-id slug strings, and the precise drift-test helper API.
- Whether `phase72`/`phase45` CI gets a new `phase132-proof.yml` (none exists yet) or folds into the
  `phase130-proof.yml` companion-lane pattern — pick the cleaner at plan time (recommend one
  workflow file per companion lane, mirroring phase130).
- Exact brand-voice microcopy within the drafted failure strings + the matrix prose (calm/explicit/
  honest, `[crosswake]`, "name what happened, what to do next").
- Whether the engine-present stub rides a tag + conditional `elixirc_paths` or a separate alias
  (inherit whatever rulestead's package settled on).
- Whether the four media helpers are copied vs. relative-pathed for the moved phase72 (recommend copy).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 132" — goal + 4 success criteria (SC#1 standalone+live+clean-room,
  SC#2 no rindle branch in core + checklist test for BOTH companions, SC#3 the matrix doc, SC#4 the
  drift test); §"Phase 133"/"Phase 134" for what is deferred.
- `.planning/REQUIREMENTS.md` §EXTRACT-07, §SEAM-05, §COMPAT-02, §COMPAT-03; the naming-convention
  reminder (package `crosswake_<name>` ≠ module `Crosswake.Companions.<Name>`); Out-of-Scope table.
- `.planning/STATE.md` §"v16.0 Roadmap Decisions" (:65-72) — esp the Phase-132 line (identical recipe
  incl. owned `Contracts.MediaObject`+`Reconciliation`, no rindle branches, ships
  `companion_compatibility.md` + drift test, `phase132-proof.yml` + reused clean-room).

### The locked recipe + prior-phase decisions this phase REUSES BY SUBSTITUTION
- `script/extract_companion.md` — THE parameterized checklist; Step 4 (release-please register),
  Step 12 (publish + clean-room), the `path:`→Hex lock pivot. Follow it; substitute `rindle`.
- `.planning/phases/130-extraction-mechanics-footgun-guards/130-CONTEXT.md` — D-13/14 (CompanionGuard
  frozen MapSet; no blanket ban), D-19 (poncho path dep, no `runtime: false`), D-20 (test split),
  D-12 (AST source-assertion idiom), D-25 (recipe), D-28/29 (optional engine + `no_warn_undefined`),
  D-33 (engine-present vs -absent lanes).
- `.planning/phases/131-publish-pipeline-clean-room-lane-rulestead/131-CONTEXT.md` — D-01..09
  (release-please component + gated publish), D-11/12/13 (env-conditional `crosswake_dep/0` + hex.build
  dep-presence grep — the ③ drift-test parsing source), D-15..20 (clean-room: happy-path doctor, inline
  smoke, engine version-cap mismatch + fallback — the ④ template).
- `.planning/phases/129-stable-companion-contract-surface/129-CONTEXT.md` — the FROZEN 5-module public
  surface (the D-01 "what stays in core" boundary) + the Finding↔Denial ownership rule.

### Core source to MOVE + the tests that couple to it
- `lib/crosswake/companions/rindle.ex` — adapter (probes `Code.ensure_loaded?(Rindle)` at :27/:41;
  public callbacks `companion_id/0`=`:rindle`, `validate_dependency/0`, `enabled?/1`, `report_state/0`).
- `lib/crosswake/companions/rindle/contracts.ex` — `Contracts` + nested `UploadGrant`/`CaptureEvidence`/
  `MediaObject`; public API incl. `media_state_vocabulary/0` (the ④ canary), `new_media_object/1`.
- `lib/crosswake/companions/rindle/reconciliation.ex` — `Reconciliation` + nested `Attempt`/
  `IdempotencyKey`/`EvidenceResult`.
- SIX coupling tests (D-03/04): `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs`,
  `phase45_rindle_mock_media_test.exs`, `phase45_rindle_companion_test.exs`,
  `phase45_rindle_advisory_test.exs`, `phase47_companion_arc_test.exs` (cross-companion — investigate),
  `test/crosswake/guides/companions_test.exs` (:122/131/150/228 — rewrite to seam, stays in core);
  unit `test/crosswake/companions/rindle/{contracts_test,reconciliation_test}.exs` (move verbatim).
- `.github/workflows/phase72-proof.yml` — exists; needs disposition when phase72 moves.
- `test/support/router_fixtures.ex` (`StudySessionLive` stub, D-23 copy) + `examples/phoenix_host/lib/
  crosswake_example/media/*` (the 4 helpers to copy if phase72/phase45_mock_media move).

### CI / pipeline + scripts to extend (parameterized — substitute rindle)
- `.github/workflows/release-please.yml` — `clean-room-proof-rulestead` job to mirror as
  `clean-room-proof-rindle` (D-18); the `release-please` outputs alias block + per-component gate.
- `release-please-config.json` + `.release-please-manifest.json` — add the `packages/crosswake_rindle`
  component + manifest baseline (NOT `linked-versions`).
- `script/verify_companion_cleanroom.sh` — already `$3 ENGINE_PACKAGE`/`$4 ENGINE_MODULE`
  parameterized (defaults rulestead/Rulestead); the smoke-body Contracts-canary append (D-17).
- `script/verify_companion_package.sh` — **:53/:54 hardcode `companions/rulestead.ex` and :81 the
  `Rulestead` no_warn note — MUST parameterize for rindle** (derive the path from `$PACKAGE`).
- `packages/crosswake_rulestead/` — the WHOLE package is the copy-template for `packages/crosswake_rindle/`
  (mix.exs `crosswake_dep/0` + `# x-release-please-version` marker + `files:` allowlist excluding `test/`).

### Doc house-style + project DNA / brand voice
- `guides/support_matrix.md` (the existing markdown-table house style for the ② matrix); `guides/
  compatibility.md` (DISTINCT existing compat-contract prose — link, don't merge); `guides/companions.md`
  (the `companion.dependency_missing` fail-closed doc + setup the matrix links to); `guides/companion_contract.md`
  (the frozen surface the extraction must not widen).
- `prompts/crosswake-elixir-oss-dna.md` — lean-core, "keep host-owned concerns in host code", "proof
  lanes are part of the product", "no opaque shell soup", independent-versioning, "no decision you
  cannot inspect".
- `prompts/crosswake-integrations-and-companions.md` — adapter↔engine relationship, "not a fail-open
  optional-dependency model".
- `brandbook/BRAND-SPEC.md` (**supersedes** `prompts/crosswake-brand-book.md` — prefer the brandbook) —
  §6 error-message rule, §4 `[crosswake]` prefix + domain nouns, §20 "no decision you cannot inspect",
  §22 "name the specific value", banned-word ("just") discipline.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The ENTIRE `packages/crosswake_rulestead/` tree — the copy-template for rindle (mix.exs shape,
  env-conditional `crosswake_dep/0` at :64-67, `# x-release-please-version` marker, `files:` allowlist).
- `Crosswake.TestSupport.ProofAssertions.stable_id_message/7` — merge-blocking failure-message helper
  for the ③ drift test.
- `Code.string_to_quoted/2` + `Macro.prewalk/3` over `Path.wildcard` — the repo's idiomatic
  source/AST assertion mechanism (phase65/phase129/phase130); the exact tool for ③/D-11.
- `script/verify_companion_cleanroom.sh` (already engine-parameterized) + `verify_companion_package.sh`
  (Step-2 dep-presence grep) — reuse verbatim except the rulestead hardcode at lines 53/54/81.
- `clean-room-proof-rulestead` + the release-please component/publish wiring — copy-substitute.

### Established Patterns
- Companion = poncho `path:` dep (runtime, no `runtime: false`) + env-conditional Hex pivot; optional
  engine via runtime `Code.ensure_loaded?` probe + `@compile {:no_warn_undefined, Engine}`.
- Core owns the behaviour/envelope types; the companion owns its domain model (Swoosh/Oban/Ash/
  Membrane/Broadway are unanimous) — the D-01 public-surface test.
- Drift/fitness tests: code is canonical, a test asserts the human doc didn't drift (Keathley/Oban/Ash
  idiom); one untagged `async: true` suite, teaching `[crosswake]` failure messages (ArchUnit gold std).
- Test split: domain/adapter proof → companion lane; seam/fail-closed contract → stays in core
  exercising only `@behaviour`+registry (never an alias to the moved source — that re-couples + trips
  EXTRACT-03).

### Integration Points
- `CompanionGuard` frozen MapSet — gains `Crosswake.Companions.Rindle` (covers `.Contracts`/
  `.Reconciliation` via prefix); the guard turning red is the signal a core alias survived the move.
- The drift test reads `packages/*/mix.exs` (`crosswake_dep/0` AST) ⇄ `guides/companion_compatibility.md`
  (package-name-keyed row) — the doc's pinned column contract is the seam.
- The clean-room flips `Code.ensure_loaded?(Rindle)` true by installing the real `rindle` `0.1.10`
  engine → doctor exit 0.
- `mix crosswake.doctor` ↔ `--router` ↔ the throwaway app being a minimal Phoenix host (131-D-17).

### Footguns surfaced by research (carry into planning)
- **The test coupling is 3× rulestead's (six files, incl. a cross-companion arc + a core guides test
  that must be seam-rewritten, NOT moved).** Underestimating this is the phase's main risk.
- **A bare `grep crosswake` / naive `deps/0` read mis-extracts the requirement** — the env-conditional
  resolver returns the path dep; AST-parse the `do:` branch (D-11).
- **`verify_companion_package.sh` hardcodes `rulestead.ex`/`Rulestead`** (:53/54/81) — parameterize or
  rindle's package-verify reds.
- **Latest `rindle` (0.3.0) ∉ `~> 0.1`** — pin the clean-room engine to the `0.1.x` line (0.1.10), keep
  the cap `~> 0.1` (D-14/15/16); name the friction in the matrix prose (D-19).
- **Promoting any rindle domain type to the public surface** widens the frozen 5 and breaks SEAM (D-01).
- **Moving the core guides test (or aliasing moved source in the core fail-closed test)** re-couples +
  trips EXTRACT-03 — rewrite to the seam instead.
- **Empty-glob silent pass** if the drift test runs before rindle's mix.exs exists — non-vacuity assert ≥2.
</code_context>

<specifics>
## Specific Ideas

- Locked matrix table shape + the 5 prose sections (D-05/08), and the concrete drift-test stable ids +
  three failure cases (D-13). Use as the starting drafts; finalize wording in brand voice.
- Adopter target shape the matrix documents (the rindle happy path): `{:crosswake, "~> 0.1"}` +
  `{:crosswake_rindle, "~> 0.1"}` + `{:rindle, "~> 0.1"}` (resolves 0.1.10), then
  `config :crosswake, :companions, [Crosswake.Companions.Rindle]` + enable, then `mix crosswake.doctor`.
- Ecosystem exemplars consulted: Swoosh/Oban/Ash/Membrane/Broadway (plugin owns its domain types; core
  owns the behaviour envelope); Ecto+ecto_sql / Phoenix+phoenix_live_view / Nerves / tokio-tower MSRV
  (good human compat tables — package-name key, document the tested floor); Rails-gem-prose /
  `@types/*` peerDeps / pre-18 React-react-dom lockstep / npm `"*"` (cargo-cult/undocumented-coupling
  anti-patterns COMPAT-02/03 prevent); ArchUnit/import-linter (fitness-function teaching messages).

</specifics>

<deferred>
## Deferred Ideas

- **Widening the rindle engine cap to admit the `0.3.x` line** — real future decision once the 0.3 API
  is validated against the `Rindle` probe; out of scope here (keep `~> 0.1`).
- **sigra/chimeway/threadline extraction** (refactor the legitimate core aliases behind the seam, add
  to the guard MapSet) — later milestone (EXTRACT-FUT).
- **`Crosswake.Telemetry` public API** — Phase 133. **Shell lifecycle + native UAT** — Phase 134.
- **An adopter-facing clean-room proving richer companion behavior** (beyond resolvability + happy-path
  doctor) — later hardening.
- **Generating the matrix doc FROM code** (vs. the chosen code-canonical + drift-test-asserts-parity) —
  only if the family grows large enough that hand-maintaining rows becomes a burden.

None of the above are scope creep into 132 — all map to existing later phases/milestones.
</deferred>

---

*Phase: 132-Generalization Proof (rindle) + Compat Matrix*
*Context gathered: 2026-06-26*
