# Phase 131: Publish Pipeline & Clean-Room Lane (rulestead) - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Take the `packages/crosswake_rulestead/` poncho package that Phase 130 stood up as a
`path:`-dep dress rehearsal and make it **live on Hex as an independently-versioned
package** — wired into `release-please` as a separate (non-lockstep) release component,
published only after a `hex.publish --dry-run` gate, and proven by a clean-room install
lane that resolves the published artifact OUTSIDE the monorepo. This is the **irreversible
publish** Phase 130 rehearsed; module name `Crosswake.Companions.Rulestead` stays preserved.

Requirements: **EXTRACT-05, EXTRACT-06, PROOF-01, PROOF-02.**

**Locked by ROADMAP §"Phase 131" success criteria (do NOT relitigate the WHAT):**
- SC#1 — `crosswake_rulestead` is a separate `elixir` release component, explicitly NOT in
  the core `linked-versions` lockstep group; its own `.release-please-manifest.json` entry.
- SC#2 — a per-companion publish job runs `deps.get → compile --warnings-as-errors → test →
  hex.publish --dry-run → hex.publish` in sequence, keyed on its release-please output.
- SC#3 — `script/verify_companion_cleanroom.sh` creates a throwaway mix project outside the
  monorepo, installs published `crosswake` + `crosswake_rulestead`, compiles
  `--warnings-as-errors`, registers the companion, runs its tests + a `mix crosswake.doctor`
  smoke check — all green, with Hex-propagation polling before install.
- SC#4 — no `hex.publish` for rulestead until BOTH the `--dry-run` gate and the clean-room
  lane are green; `crosswake_rulestead` is live and resolvable on Hex at end of phase.

**Out of scope (defer):** rindle extraction + publish via the identical recipe (Phase 132,
EXTRACT-07/SEAM-05); cross-package compat matrix + `guides/companion_compatibility.md`
(Phase 132, COMPAT-02/03); sigra/chimeway extraction (later milestone, EXTRACT-FUT);
`Crosswake.Telemetry` public API (Phase 133); a future adopter-facing clean-room for
companions beyond resolvability (this phase proves resolvability + happy-path doctor only).

### Independence is the through-line
The companion is its OWN versioning universe: it stays at `0.1.0` while core
(`hex`/`ios-core`/`android-core`) is at `0.1.2` lockstep. Every decision below structurally
enforces that a companion fix patches the companion WITHOUT touching core, and vice versa
(EXTRACT-05). The whole pipeline is built parameterized so rindle (Phase 132) reuses it by
substitution, not reinvention.
</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched by four parallel subagents (release-please wiring,
publish-job gating, clean-room test+doctor semantics, clean-room placement), each grounded in
the live repo, the project DNA (`prompts/`, `brandbook/BRAND-SPEC.md`), and ecosystem idiom
(Elixir/Hex multi-package release, Changesets/cargo-release/release-plz lessons). The four
decision sets are mutually coherent: ① produces the tag + outputs ② gates on; ② sets the env
that makes ③'s published dep honest; ④ consumes ②'s publish and resolves the artifact ③ made
honest. **User locked all four as-is (2026-06-25).**

### ① release-please wiring — independent component with its OWN Release PR
- **D-01: Add `packages/crosswake_rulestead` as a standalone `packages` entry — `component:
  "crosswake_rulestead"`, `release-type: "elixir"`, `separate-pull-requests: true` — and do
  NOT add it to the `linked-versions` plugin's `components` array.** `separate-pull-requests`
  is load-bearing: it gives the companion its own Release PR with independent cadence and
  forces the publish job onto a per-component gate. Component name is `crosswake_rulestead`
  (NOT bare `rulestead`) to match the Hex package name and avoid conflation with the external
  `rulestead` ENGINE. Resulting tag: `crosswake_rulestead-v0.1.0`.
- **D-02: `extra-files: ["packages/crosswake_rulestead/mix.exs"]` is MANDATORY.** The `elixir`
  release-type scans root `mix.exs` by default and would otherwise bump CORE's `@version`. The
  `# x-release-please-version` marker D-22 placed on the companion `@version "0.1.0"` is the
  correct annotation for the elixir releaser to find.
- **D-03: Add `"packages/crosswake_rulestead": "0.1.0"` to `.release-please-manifest.json`.**
  Manifest baseline is the reliable bootstrap idiom in manifest mode — NOT a second
  `bootstrap-sha`. Path-based commit attribution is then automatic: a commit under
  `packages/crosswake_rulestead/**` bumps only the companion; a root commit bumps only core
  (`"."`). Exactly EXTRACT-05.
- **D-04 (PLANNER INVESTIGATION — do not skip): resolve the first-release bootstrap.** A
  manifest baseline of `0.1.0` makes the NEXT fix cut `0.1.1`, not publish `0.1.0` itself. To
  publish exactly `0.1.0`, add a one-shot `"release-as": "0.1.0"` to the companion's config
  for the first cut, then remove it. Decide 0.1.0-exact (`release-as`) vs. accept-first-cut-
  is-0.1.1 at plan time. SC#4 requires "live and resolvable," not a specific number — but
  D-22 set `@version 0.1.0`, so 0.1.0-exact is the coherent default.
- **D-05: The recipe generalizes for rindle (Phase 132) by substitution** — one new `packages`
  entry + one manifest key + one publish job, `crosswake_rindle` swapped for
  `crosswake_rulestead`. No other config changes. Fold this into `script/extract_companion.md`
  Step 4 ("register the component") so SEAM-05 becomes mechanical.

### ② Publish job — in-band, gated on the PER-COMPONENT output
- **D-06: Add a `publish-hex-rulestead` job to the EXISTING `.github/workflows/release-please.yml`**
  (not a separate workflow). One release-please run, shared outputs, single pipeline graph;
  cleaner than a second `workflow_run`-triggered file at N=2–4 companions. (Revisit a dedicated
  workflow only at 5+ companions.)
- **D-07: Gate on the per-component output `rulestead_release_created`, NEVER the aggregate
  `releases_created`.** The aggregate fires when ANY package releases (the documented
  release-please-action v4 footgun the existing workflow comments already warn about) — gating
  the companion on it would publish on every core-only release. This is the single most
  important correctness point in this area.
- **D-08: Alias the slash-path outputs in the `release-please` job's `outputs:` block**, because
  GitHub Actions `if:` cannot index a slash-containing key directly:
  `rulestead_release_created: ${{ steps.release.outputs['packages/crosswake_rulestead--release_created'] }}`
  (and `rulestead_tag_name`, `rulestead_version` likewise). The downstream job then uses
  `needs.release-please.outputs.rulestead_release_created == 'true'` (dot-notation safe).
- **D-09: Job shape mirrors `hex-publish.yml` / the core `publish-hex` job**, scoped to the
  package: checkout ref = `rulestead_tag_name`; `working-directory: packages/crosswake_rulestead`;
  steps `deps.get → compile --warnings-as-errors → mix test → hex.publish --dry-run →
  hex.publish` (SC#2 sequence verbatim); reuse `HEX_API_KEY`; version-grep guard against the
  COMPANION `mix.exs` (`grep -n "@version \"$VERSION\"" packages/crosswake_rulestead/mix.exs`);
  then poll `https://hex.pm/api/packages/crosswake_rulestead/releases/$VERSION` for propagation.
- **D-10: Test step = the engine-ABSENT hermetic lane** — plain `mix test` in the package dir
  (mirrors `phase130-proof.yml`'s `companion-engine-absent-proof`; `test_helper.exs` already
  excludes `:engine_present`). Do NOT add `--exclude requires_example_host` (core-only tag).

### ③ The `path:` → Hex dep pivot — ENV-CONDITIONAL, not a permanent rewrite
- **D-11: Keep the `path:` dep for local/in-tree CI; emit the Hex dep only when publishing,
  via a small named resolver in the companion `mix.exs`.** A PERMANENT `{:crosswake, "~> 0.1"}`
  would break Phase 130's investment: the merge-blocking `companion-engine-absent-proof` lane
  runs `deps.get`/`compile`/`test` in the package, and a permanent Hex dep makes it test
  PUBLISHED core instead of LOCAL core — destroying the local-integration fidelity D-19 was
  built for and creating a chicken-and-egg for any coordinated core+companion PR.
  ```elixir
  defp crosswake_dep do
    # Local dev + in-tree CI test against LOCAL core (high fidelity).
    # The publish job sets CROSSWAKE_RELEASE=1 → the PUBLISHED package records an
    # honest Hex requirement (hex.publish silently DROPS path deps otherwise).
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end
  ```
- **D-12: hex.publish does NOT error on a path dep — it SILENTLY drops it** as a non-Hex dep,
  shipping a package that compiles but crashes at runtime because `:crosswake` is absent from
  the adopter's tree. `--dry-run` alone won't catch this. **Belt: after `mix hex.build --unpack`
  assert (plain grep) that `crosswake` actually appears in the built package's dependency
  metadata.** This activates Step 2 of `script/verify_companion_package.sh` (currently gated off
  while the path dep is present) — the dress-rehearsal verify becomes fully live in 131.
- **D-13: The publish job (②) sets `CROSSWAKE_RELEASE=1` in its env**; everywhere else keeps the
  path dep. The committed `mix.lock` reflects the path dep (default); CI re-locks ephemerally
  against Hex at publish. Same resolver + env var carry into rindle (Phase 132).
- **D-14 (PLANNER INVESTIGATION): the `hex.build --unpack` dep-presence assertion wording** —
  confirm where built-package requirements surface in the unpacked tarball metadata and grep for
  `crosswake` there; lead any failure with `[crosswake]` per brand voice.

### ④ Clean-room — POST-publish resolvability proof; HAPPY-PATH-GREEN doctor
- **D-15: PROOF-02 reconciles via the established native-lane split.** PRE-publish gate = the
  merge-blocking in-monorepo companion lanes (`phase130-proof.yml`) + the `hex.publish --dry-run`
  step inside the publish job. POST-publish proof = a NEW `clean-room-proof-rulestead` job
  (`needs: [release-please, publish-hex-rulestead]`) that resolves the freshly-published package
  from Hex. This mirrors `clean-room-proof-ios`/`-android` (which `needs: publish-*` and prove
  post-publish resolvability). Bad-publish recovery verb is `mix hex.retire crosswake_rulestead
  $VERSION`.
- **D-16: Logic lives in a thin, parameterized `script/verify_companion_cleanroom.sh`** (matches
  `verify_companion_package.sh`: `$1` PACKAGE default `crosswake_rulestead`, `$2` VERSION,
  `[crosswake]`-prefixed failures, `set -euo pipefail`). CI YAML stays thin (checkout, setup-beam,
  install hex+rebar, then `bash script/verify_companion_cleanroom.sh crosswake_rulestead $VERSION`).
  Locally reproducible — "proof lanes are part of the product." Reused verbatim for rindle.
- **D-17: Script body.** (1) Poll `hex.pm/api/packages/crosswake_rulestead/releases/$VERSION` for
  propagation (core already live; poll the companion specifically), retry-loop matching the core
  verify step (`MAX_ATTEMPTS≈36 / DELAY≈10`). (2) `mix new` a throwaway app in `$RUNNER_TEMP`
  OUTSIDE the monorepo — **as a minimal Phoenix host** (it needs `phoenix` + a tiny
  `use Crosswake.Router` module, because `mix crosswake.doctor` requires `--router`); this
  mirrors a real adopter exactly. (3) Deps `{:crosswake, "~> 0.1"}` + `{:crosswake_rulestead,
  "~> 0.1"}` + the engine → `deps.get` → `compile --warnings-as-errors`. (4) Register the
  companion in config; run an **inline smoke test** (the tarball ships no `test/`) asserting the
  PUBLIC seam: `validate_dependency/0 == :ok`, `companion_id/0 == :rulestead`, `enabled?/1` — and
  do NOT use `MockFlagSource` (excluded from the tarball; use only public callbacks). (5)
  `mix crosswake.doctor --router …` → assert exit 0.
- **D-18: "runs its tests" = an INLINE smoke test authored in the throwaway project**, because
  the package's `files:` allowlist excludes `test/` (D-24) — the Hex tarball ships no ExUnit
  files. The smoke test exercises the published artifact through the registered seam; it does NOT
  attempt to run the companion's in-repo tests (they aren't shipped).
- **D-19: "all green" doctor = install the REAL `rulestead` engine (happy path), NOT assert the
  fail-closed finding.** `mix crosswake.doctor` exits non-zero on the `:error`
  `companion.dependency_missing` finding, so an engine-ABSENT clean-room would RED the lane —
  and SC#3's "all green" means exit 0. The fail-closed path stays proven merge-blocking in CORE
  (phase42/43 + the COMPAT-01 contract test, D-20 from Phase 130), so the clean-room owns the
  adopter happy path without redundancy. Honest: the gate is proven where it lives; the clean-
  room proves the published artifact resolves and works.
- **D-20 (PLANNER INVESTIGATION — do not skip): the engine identity + version-cap mismatch.**
  Research found a `rulestead` package on Hex at `1.0.0`, which does NOT satisfy the companion's
  `{:rulestead, "~> 0.1", optional: true}` cap (`~> 0.1` = `>= 0.1.0 and < 1.0.0`). Pin the
  clean-room engine to a `0.1.x` line (e.g. `{:rulestead, "~> 0.1.6"}`, the documented adopter
  shape) OR widen the companion's optional constraint. Also confirm the engine package's module
  is actually `Rulestead` (so `Code.ensure_loaded?(Rulestead)` flips true). **Fallback:** if the
  engine cannot be cleanly resolved/installed, prove BOTH states instead of happy-path-only
  (engine-absent → assert the fail-closed finding emits; engine-present → doctor exit 0).

### Claude's Discretion
- Exact CI job/step names, env var name beyond `CROSSWAKE_RELEASE` (keep that one — it's
  referenced across ② and ③), propagation poll constants, and the precise
  `verify_companion_cleanroom.sh` parameter signature (at minimum: package, version; likely also
  engine package/module for rindle reuse).
- Whether the inline clean-room smoke test is a single-file ExUnit module run via `mix test`, a
  `mix run` assertion script, or a tiny generated `test/` — pick the least-surprising at plan time.
- Microcopy for new failure messages (lead `[crosswake]`, "name what happened, what to do next").
- The exact minimal Phoenix host shape (router-only vs. a fuller stub) the doctor smoke needs.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 131" — goal + 4 success criteria (SC#1–4 pin the WHAT verbatim);
  §"Phase 132" for what is deferred (rindle, compat matrix).
- `.planning/REQUIREMENTS.md` §EXTRACT (EXTRACT-05, EXTRACT-06), §PROOF (PROOF-01, PROOF-02).
- `.planning/STATE.md` §"v16.0 Roadmap Decisions" — independent versioning, core never compile-
  deps a companion, fail-closed doctor, establish-pattern-first, no-publish dress rehearsal (130)
  → irreversible publish (131).
- `.planning/phases/130-extraction-mechanics-footgun-guards/130-CONTEXT.md` — the dress-rehearsal
  decisions this phase promotes: D-19 (poncho `path:` dep, core is a RUNTIME dep, NO `runtime:
  false`), D-22 (companion `@version 0.1.0` + marker, do NOT join linked-versions — now wired in
  131), D-24 (`files:` allowlist excludes `test/`; the documented `path:`→Hex lock pivot for 131;
  `hex.build --unpack` / `hex.publish --dry-run` fidelity), D-25 (`extract_companion.md` recipe),
  D-20 (test split: SC#1 adapter behavior in companion lane, COMPAT-01 fail-closed in CORE lane),
  D-31 (config-indirection flag_source), D-33 (engine-absent vs engine-present lanes).

### CI / release pipeline to change
- `release-please-config.json` — add the `packages/crosswake_rulestead` component (D-01/02);
  the `linked-versions` plugin `components` array it must NOT join.
- `.release-please-manifest.json` — add the `"0.1.0"` baseline (D-03).
- `.github/workflows/release-please.yml` — THE pipeline to extend (D-06): the `release-please`
  job `outputs:` block to alias slash-path outputs (D-08); the `releases_created` aggregate
  footgun documented in its comments (D-07); `publish-hex` (core) job to mirror; the post-publish
  `clean-room-proof-ios`/`-android` jobs to mirror for the companion clean-room (D-15).
- `.github/workflows/hex-publish.yml` — the manual-recovery job whose step shape (setup-beam,
  local.hex, deps.get, compile --warnings-as-errors, test, dry-run, publish) the companion job
  mirrors (D-09).
- `.github/workflows/phase130-proof.yml` — the merge-blocking in-monorepo companion lanes that
  are the PRE-publish gate (D-15); `companion-engine-absent-proof` is the test-lane template.

### Companion package + scripts
- `packages/crosswake_rulestead/mix.exs` — the `{:crosswake, path: "../.."}` dep to make
  env-conditional (D-11); the `# x-release-please-version` marker (D-02); the `files:` allowlist
  that excludes `test/` (D-18); `{:rulestead, "~> 0.1", optional: true}` engine constraint (D-20).
- `packages/crosswake_rulestead/mix.lock` — committed against the path dep (D-13).
- `script/verify_companion_package.sh` — Step 2 (hex.build/dry-run) is GATED off while a path dep
  is present; 131 activates it (D-12); house style for the new `verify_companion_cleanroom.sh`.
- `script/extract_companion.md` §"Phase 131 lock pivot" + §"Checklist Summary" — the recipe to
  update so rindle (132) inherits the wiring + clean-room (D-05/13/16).
- Other `script/verify_*.sh` (e.g. `verify_hex_tarball.sh`, `verify_generated_ios_shell.sh`) —
  the parameterized, `[crosswake]`-prefixed, `set -euo pipefail` house style.

### Core source the clean-room exercises (read-only here)
- `lib/crosswake/companions/rulestead.ex` — `validate_dependency/0` (~99-108) + the runtime
  `Code.ensure_loaded?(Rulestead)` probe; `companion_id/0`, `enabled?/1`, `report_state/0` — the
  public callbacks the inline smoke test asserts (D-17/18).
- `lib/crosswake/doctor/doctor.ex` — the `companion.dependency_missing` `:error` finding
  (~564-618) and the exit semantics (`Mix.raise` / non-zero on any `:error` finding) that make
  D-19 necessary; the install-manifest load path (advisory, not `:error`, when absent).
- `lib/mix/tasks/` `crosswake.doctor` task — the `--router` requirement that forces the clean-room
  throwaway app to be a minimal Phoenix host (D-17).

### Project DNA / brand voice
- `prompts/crosswake-elixir-oss-dna.md` — "proof lanes are part of the product", "no opaque shell
  soup" (rejects the ephemeral-CI-rewrite pivot → D-11), lean-core, independent-versioning /
  sibling-package guidance, "no decision you cannot inspect" (the env-conditional resolver is a
  named, inspectable function).
- `prompts/crosswake-integrations-and-companions.md` — adapter↔engine relationship, "not a
  fail-open optional-dependency model" (the fail-closed posture D-19 keeps proven in core).
- `brandbook/BRAND-SPEC.md` (supersedes `prompts/crosswake-brand-book.md` — prefer the brandbook) —
  §6 error-message rule ("name what happened, what to do next", `[crosswake]` prefix) for new CI
  + script failure microcopy.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release-please.yml` `publish-hex` (core) job + `hex-publish.yml` — the exact
  setup-beam / local.hex / deps.get / compile --warnings-as-errors / test / dry-run / publish /
  verify-on-Hex step sequence to mirror for the companion (D-09).
- `clean-room-proof-ios` / `clean-room-proof-android` jobs — the post-publish "install published
  artifact, generate outside monorepo, build with propagation-polling retry" idiom (D-15/17).
- `script/verify_companion_package.sh` — parameterized-by-`$PACKAGE`, `[crosswake]`-prefixed
  dress-rehearsal verify whose Step 2 activates once the dep pivots (D-12); the template for
  `verify_companion_cleanroom.sh` (D-16).
- `phase130-proof.yml` `companion-engine-absent-proof` — the merge-blocking package test lane
  (`mix test` in the package dir) that is the PRE-publish gate and the test-step template (D-10/15).

### Established Patterns
- release-please manifest mode: per-component publish gates on the path-prefixed
  `<path>--release_created` output, NOT the plural aggregate (D-07); component config outside the
  `linked-versions` group = independent versioning (D-01).
- Env-conditional `mix.exs` deps (`if System.get_env(...) do {hex} else {path} end`) — the idiomatic
  Elixir answer to "path locally, Hex when published" (D-11); keeps a named, inspectable seam.
- Thin CI YAML + logic in a reusable `script/verify_*.sh` (testable, locally runnable, rindle-
  parameterized) — the repo's house style (D-16).
- Optional engine dep = runtime `Code.ensure_loaded?` probe + `@compile {:no_warn_undefined}` +
  `optional: true` (Phase 130) — the clean-room flips the probe true by installing the real engine
  (D-19).

### Integration Points
- The `release-please` job `outputs:` block — slash-path outputs MUST be aliased there before any
  downstream `if:` can read them (D-08).
- `hex.publish` published-requirements ← companion `mix.exs` `deps` evaluated WITH `CROSSWAKE_RELEASE=1`
  → records `{:crosswake, "~> 0.1"}` honestly (D-11/13).
- The companion's `{:rulestead, "~> 0.1", optional: true}` cap ↔ the engine version actually on Hex —
  the resolution seam the clean-room must satisfy (D-20).
- `mix crosswake.doctor` ↔ `--router` ↔ a Phoenix host in the throwaway app (D-17).

### Footguns surfaced by research (carry into planning)
- **Gating the companion on `releases_created` (aggregate) publishes on every core release** — gate
  on the per-component output (D-07).
- **hex.publish SILENTLY drops a path dep** (compiles, crashes at runtime for adopters); `--dry-run`
  won't error — add a `hex.build --unpack` dep-presence grep (D-12).
- **A permanent Hex pivot makes the in-tree companion lane test PUBLISHED core, not local** — breaks
  Phase 130's local-fidelity proof + coordinated-PR flow; use the env-conditional dep (D-11).
- **`mix crosswake.doctor` exits non-zero on the fail-closed `:error` finding** — engine-absent
  clean-room reds the lane; install the engine for the green happy path (D-19).
- **The Hex tarball ships NO `test/`** — "runs its tests" must be an inline smoke test; `MockFlagSource`
  is unavailable (D-18).
- **`mix crosswake.doctor` requires `--router`** — the throwaway app must be a minimal Phoenix host,
  not a bare `mix new` (D-17).
- **`rulestead` on Hex at 1.0.0 ∉ `~> 0.1`** — pin the clean-room engine to `0.1.x` or widen the cap
  (D-20).
- **First-release bootstrap**: manifest baseline `0.1.0` cuts `0.1.1` next, not `0.1.0` — use a
  one-shot `release-as: 0.1.0` to publish exactly 0.1.0 (D-04).
</code_context>

<specifics>
## Specific Ideas

- Component name `crosswake_rulestead` (matches Hex package; disambiguates from the external
  `rulestead` engine) → tag `crosswake_rulestead-v0.1.0`; output aliases `rulestead_release_created`
  / `rulestead_tag_name` / `rulestead_version`.
- Env-conditional resolver named `crosswake_dep/0` in the companion `mix.exs`, gated on
  `CROSSWAKE_RELEASE=1` (set only in the publish job).
- Adopter clean-room target shape (the published happy path): `{:crosswake, "~> 0.1"}` +
  `{:crosswake_rulestead, "~> 0.1"}` + `{:rulestead, "~> 0.1.6"}`, then `config :crosswake,
  :companions, [Crosswake.Companions.Rulestead]` + enable, then `mix crosswake.doctor --router`.
- Ecosystem exemplars consulted: release-please manifest-mode multi-component repos (per-path
  outputs); Changesets / cargo-release / release-plz (per-package gated publish, local-path-vs-
  published-dep handling); npm `npm pack`+install / cargo install-from-crates / PyPI post-publish
  import smoke (post-publish resolvability canaries, propagation-race lessons); Swoosh/Broadway
  (companion adapters list the published Hex dep, optional-dep idiom).
</specifics>

<deferred>
## Deferred Ideas

- **rindle extraction + publish via the identical recipe** (env-conditional resolver, per-component
  release-please entry, parameterized clean-room script) + cross-package compat matrix — Phase 132
  (EXTRACT-07, SEAM-05, COMPAT-02/03).
- **A dedicated companion-publish workflow file** (vs. in-band in release-please.yml) — revisit only
  if companion count reaches ~5+ (D-06).
- **Widening the companion's `{:rulestead, "~> 0.1"}` optional cap to admit engine 1.x** — a real
  decision if adopters need the 1.0 engine line; out of scope unless D-20 investigation forces it.
- **An adopter-facing clean-room that proves richer companion behavior** (beyond resolvability +
  happy-path doctor) — later hardening; this phase proves the published artifact resolves and the
  happy path is green.
- **`Crosswake.Telemetry` public API** — Phase 133 (TELEM-01/02/03).

None of the above are scope creep into 131 — all map to existing later phases/milestones.
</deferred>

---

*Phase: 131-Publish Pipeline & Clean-Room Lane (rulestead)*
*Context gathered: 2026-06-25*
