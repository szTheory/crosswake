---
id: SEED-007
status: planted
planted: 2026-07-28
planted_during: "Phase 153 iOS mirror unblock (v20.0) — planted after a ~2h serial merge-queue drain made the cost structural rather than anecdotal"
trigger_when: "Surface before any milestone that will land many PRs, whenever a merge queue backs up, when CI cost or macOS minutes are questioned, or when a red gate is discovered to have been invisible."
scope: Medium-Large
---

# SEED-007: Make CI fast, cheap, and honestly gated

## Thesis (read this first)

**Thesis (one sentence):** Crosswake's CI spends ~7 hours of runner time per push to run an
88-second test suite, and the spend buys *less* safety than it looks like — so the work is to cut
the waste (wrong runner class, zero caching, 24 copy-paste workflows) **and** close three real
gate-integrity holes the waste is hiding.

**The reframe that matters:** the cost is **not compute**. It is macOS *queue* time, and most of
the macOS jobs never touch an Apple toolchain. This is not "tests are slow" — the test suite is
healthy and should not be touched.

## You Are Here — Decided / Open / Where to look

**Decided**
- The Elixir suite (1,093 tests, ~43–88 s) is **healthy and out of scope**. Do not shard it;
  `mix test --partitions` would be a net *regression* here (see Breadcrumbs).
- Proof *evidence* granularity is a culture asset and is preserved. What consolidates is
  workflow **files** and required **contexts**, not the per-phase proof jobs, their names, or
  their logs.
- Measure first: `OBS-*` lands before any optimization, so every claim has a before/after.

**Open (decide at milestone activation)**
- **Merge queue or not.** `on: merge_group:` would let cheap lanes run per-push and the full
  proof set run once per merge against the real merge commit. It is the single highest-leverage
  option and also the biggest semantic change to "every proof runs on every change."
- **How far to consolidate required contexts** — 22 → 1 aggregating gate is the industry answer,
  but this repo has real auto-discovery machinery (`list_merge_blocking_checks.py` →
  `register_required_checks.sh`) built around the granular model.
- Public vs private billing posture: public today ⇒ macOS cost shows up as *queueing*, not
  dollars. Both point the same direction; only the framing changes.

**Where to look**
- `.github/workflows/` — 39 files, 24 of them `phase*-proof.yml`
- `script/list_merge_blocking_checks.py` — auto-discovery by `merge-blocking` substring
- `script/register_required_checks.sh` — green-first registration ritual
- `.github/workflows/phase69-proof.yml` — already hand-rolls the change-detection skip pattern
  (`steps.changes.outputs.relevant`); the in-repo template to generalize
- `test/test_helper.exs` — the default exclude list, and the `:requires_example_host` gap
- `docs/MILESTONE-BOUNDARY-HYGIENE.md` — the adjacent maintainer ritual

## Why This Matters

Three reasons, in descending order of severity — note the top one is **correctness, not speed**:

1. **The gate set has integrity holes.** Three required check *names* are each emitted by two
   different workflows. Branch protection matches by string only, so a red run can be masked by a
   green one wearing the same name. Separately, 20 test files are structurally invisible to CI.
2. **The spend is mostly waste.** 14 of 18 macOS PR jobs are pure Elixir with a cargo-cult
   `DEVELOPER_DIR`. macOS bills at 10× and queues 75–250× longer than ubuntu.
3. **It taxes every future milestone.** `strict: true` + 22 required contexts + ~7 h/push means a
   handful of concurrent PRs serializes into hours. Observed directly: draining 6 PRs took ~2 h of
   wall-clock for changes that were individually green in minutes.

## When to Surface

Before v21+ planning, or immediately if: a merge queue backs up again, macOS minutes are
questioned, or another invisible red gate is found. The `GATE-*` category is severable and could
be pulled forward on its own — it is a correctness fix, not an optimization.

## Scope Estimate

**Medium-Large.** `GATE-*` + `CACHE-*` + `RUNNER-*` are mechanical and high-confidence.
`CONSOL-*` (39 → ~4 workflow files) is the large, judgment-heavy piece and interacts with the
required-check machinery. Core-only; no product surface changes.

## Breadcrumbs

Measured 2026-07-28 on `main` (commands included so every number is re-derivable, not trusted).

**Baseline**

| Metric | Value | How |
|---|---|---|
| Workflow files | 39 (24 `phase*-proof.yml`) | `ls .github/workflows/*.yml \| wc -l` |
| Checks per PR | **75** | `gh pr checks <n> \| wc -l` |
| Required contexts | 22 (22/22 registered) | `gh api .../required_status_checks` |
| Runner-seconds/push | **~25,500 (~7 h)** | sum of avg durations, `gh run list --branch main` |
| Full Elixir suite | **1,093 tests, ~43–88 s** | `mix test` |
| Median PR checks, peer Elixir OSS | **9** | 15 repos surveyed; `plug` ships **2** |

**The queue-vs-compute reframe (the key insight).** Per-job `created→started` vs `started→completed`:
`phase43` merge-blocking rulestead proof = **2,230 s queued / 180 s executed** on `macos-15`.
Ubuntu equivalents queue in **4–8 s**. 18 macOS jobs fire simultaneously into a pool serving ~5.
**The "slow" workflows are ~90% waiting.**

**Findings**

- **14 of 18 macOS PR jobs need no Apple toolchain** — pure `mix deps.get` + `compile` + `test`
  (`phase23/34/41/43/45/48/52/58/70/71/73`, plus `phase5` which explicitly sets
  `CROSSWAKE_PHASE5_NATIVE_PROOFS: "0"`, `phase10`, and `phase68` whose Android emulator belongs
  on ubuntu+KVM). Each carries a `DEVELOPER_DIR` env with no consumer. **Estimated ~82% cost cut.**
  Note `phase34-proof.yml:100-107` already contains a comment reasoning that macOS is "pure waste"
  — correctly applied to the weekly advisory lane, never to the every-PR lane 40 lines above.
- **Only 6 of 39 workflows cache anything, and none cache `deps/`.** 28 do a cold
  `deps.get` + full compile every run. Defects found: `phase69-proof.yml:59` uses
  `actions/cache@v3` (service retired Feb 2025 — silently dead); `_build` cached with **no
  OTP/Elixir dimension** (`contract-drift-gate.yml:64,90`, `offline-sync-e2e-gate.yml:108,145`)
  while the toolchain comes from `.tool-versions`, so an OTP bump silently restores incompatible
  BEAM files; the Gradle cache points at project-local `.gradle` instead of `~/.gradle/caches`.
- **Zero reusable workflows or composite actions.** The checkout→setup-beam→deps.get→compile block
  is copy-pasted ~40×; `erlef/setup-beam` appears 62×. Six lanes each run a near-full suite
  differing only in `--exclude` flags.
- **🔴 Duplicate required-check names (gate-integrity hole).** `core hermetic proof
  (merge-blocking)` and `companion engine-absent proof (merge-blocking)` are each emitted by both
  `phase130` and `phase132`; `merge-blocking commerce support proof (hermetic)` by both `phase23`
  and `phase34`. Branch protection matches by **string**, so it cannot distinguish them — a red
  `phase132` can be masked by a green `phase130`. `check_required_checks_registered.sh` checks
  presence, never **uniqueness**, so it will not catch this.
- **🔴 20 test files are invisible to CI.** Every suite-running lane passes
  `--exclude requires_example_host` (8 workflows); **no** lane runs `--only`; and
  `test/test_helper.exs` does not exclude the tag locally. Result: they run *only* on laptops.
  This is how a genuinely red gate (`phase55`/`phase56`, fixed in #89) sat on `main` unnoticed.
- **🔴 Order-dependent global state.** `phase55`/`phase56` **passed in a full suite and failed in
  isolation** — another test leaks `Application.put_env(:crosswake, :companions, …)` without
  restoring. `test/support/example_host.ex` also prepends companion ebin dirs and *replaces*
  (not merges) repo config, silently dropping `pool_size: 5`. Suspected root of the `phase7`
  concurrency flake.
- **Flake inventory (all observed live, 2026-07-28 — not hypothetical).** Three distinct
  order/concurrency-dependent failures, each passing in isolation: `phase7_saas_lane_test.exs`
  (SQLite example-DB), `phase55`/`phase56` (leaked companion registration), and
  `Crosswake.Manifest.ValidatorTest` — *"json rendering is deterministic"*, which is itself
  non-deterministic under full-suite concurrency. Two consecutive `mix test` runs on an
  unchanged tree produced different failure sets. Plus two CI-infrastructure flakes: a
  `MainActivity.kt` temp-dir read (green on re-run) and a 20-minute runner cancellation while
  compiling deps. **`max_cases` is unset**, so the suite runs at `schedulers_online * 2` —
  concurrency high enough to expose latent shared state on a big dev box.
- **`phase135_ci_ops_proof_test.exs:579,599` runs a nested `mix test` from an `async: true`
  module** — recompiling the `_build` the parent VM is executing from. Highest-entropy construct
  in the repo; double-executes two other files.
- **No `timeout-minutes` on 15 workflows.** Worst: `phase79-proof.yml` runs `xcodebuild` on
  `macos-15` with no timeout → a hang holds a scarce macOS runner for the 6 h default while 17
  jobs queue behind it. The observed intermittent 264 s→1,823 s blowout on `phase18` is
  `xcodebuild -downloadPlatform iOS` exceeding a 15-minute **step** timeout.
- **8 gates use `push: branches: ['**']`** and also run on `pull_request` — every gate fires twice.
- **94 SHA pins vs 94 tag pins**, split along the infra/phase-proof line. Same SHA
  (`9c091bb…`) is annotated `# v6` in six files and `# v7.0.0` in `release-please.yml` — at least
  one comment is a lie, defeating the purpose of annotated pins.
- **Sharding is the wrong lever.** 1,093 tests / ~88 s ≈ 12 ms each. Per-shard setup (60–90 s)
  exceeds the execution saved; Ecto measured a **31% regression** (elixir-ecto/ecto#3599) and
  **zero** of 15 surveyed Elixir projects partition. Also structurally unsafe here (nested
  `mix test`, `File.cd!`, shared `examples/phoenix_host/_build`).

**Now-stale claim, corrected:** `required-checks-audit.yml`'s header says "only 2/20 declared
merge-blocking lanes are actually registered." That was Phase 135's finding and is **no longer
true** — it is 22/22 today. Fix the comment during this milestone.

## Notes

### The one universal Elixir-OSS idiom this repo doesn't use

Every surveyed project (phoenix, ecto, plug, nx, oban, postgrex, finch, LiveView, tesla) uses the
**`lint:` matrix-flag**: one matrix entry carries `lint: lint` and format/warnings-as-errors/
credo/dialyzer steps carry `if: ${{ matrix.lint }}`. Lint is *steps inside the newest-version test
job*, not separate checks. Their matrices are "oldest supported + newest, occasionally 1–3 between"
— nobody runs a cross-product, and the wide axis when present is an external dependency (postgrex:
12 Postgres versions), never a phase count.

### The required-check trap (must be understood before any path-filtering)

Two mechanisms, **opposite** behavior:

| Mechanism | Status reported | Blocks a required check? |
|---|---|---|
| Workflow-level `paths:` → workflow never runs | **nothing** → "Expected — Waiting for status" | **YES — PR hangs forever** |
| Job-level `if:` → job evaluates, resolves false | `skipped` | **NO — merge allowed** |

So: **never** add a workflow-level `paths:` filter to any of the 22 required contexts. Use
job-level `if:` + an always-running aggregating gate. Two correctness details that bite:
`if: always()` on the gate is **mandatory** (without it, the gate is *skipped* when a needed job
fails, and a skipped required check counts as **passing** — the gate fails open), and the gate must
test `contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')`, never
`success()`. **Ship a canary proving the gate fails closed.**

### Reconciling cost-cutting with the proof culture

Standard advice ("collapse to one workflow") would delete the audit trail the support-truth
discipline depends on. The reconciliation: **keep proof jobs — names, logs, artifacts — and
collapse workflow *files* and *required contexts*.** Job-level granularity preserves per-phase
evidence in the Checks tab; file-level granularity buys nothing but 39 chances for a `paths:`
filter to hang a PR.

If the culture requires every proof to re-run on every change, path-filtering genuinely weakens the
guarantee — and the honest resolution is the **merge queue**: cheap proofs per push, the full set
once per merge against the real merge commit. Nothing lands unproven; you stop re-proving every WIP
commit. Native lanes have an irreducible floor (simulator boot, codesigning) no caching removes, so
for iOS the answer is **fewer runs**, not faster ones — the opposite of the Elixir lane.

### Requirement-category skeleton (for `/gsd-new-milestone`)

- **OBS-\*** — baseline instrumentation FIRST: per-job queue-vs-exec timing, cache hit rate,
  runner-class cost split, published as a job summary. Measure, then optimize; every later claim
  cites a before/after.
- **GATE-\*** — correctness, severable and pullable forward: de-duplicate the 3 colliding check
  names; extend `check_required_checks_registered.sh` to assert **uniqueness**, not just presence;
  add a CI lane that actually runs `:requires_example_host` (serially, after building the example
  host) and add the tag to the default local exclude so local and CI agree; fix the stale
  `required-checks-audit.yml` header.
- **RUNNER-\*** — move the 14 non-Apple macOS jobs to ubuntu and delete the dead `DEVELOPER_DIR`;
  Android/gradle to ubuntu; add `timeout-minutes` everywhere (start with `phase79`).
- **CACHE-\*** — `deps` + `_build` keyed `os|arch|otp|elixir|MIX_ENV|hash(mix.lock)` with
  `restore-keys` differing by exactly the lock hash; `gradle/actions/setup-gradle`; SPM +
  `irgaly/xcode-cache` (plain `actions/cache` loses the nanosecond mtimes Xcode needs); replace
  `actions/cache@v3`. Mind the **10 GB repo cap with LRU eviction** — consolidation is a
  *prerequisite* for caching to work, since 24 lanes × multi-GB DerivedData thrashes it. Note
  caches are branch-scoped: only `main` writes caches other branches can read.
- **CONSOL-\*** — a `.github/actions/setup-elixir` composite; collapse 39 files → ~4 preserving
  job names; single `pull_request` trigger (drop the double-firing `push: '**'`); conditional
  `cancel-in-progress` (oban's form — unconditional `true` can itself strand required checks).
- **FLAKE-\*** — fix `example_host.ex` (memoize the DB path, *merge* rather than replace repo
  config, gate the ebin prepending); delete the nested `mix test` at `phase135:579,599`; make
  `phase55`/`phase56` `async: false`; move repo-relative `@tmp_dir`s under `System.tmp_dir!()`.
  **No blanket auto-retry** — and never auto-retry a macOS lane.
- **DX-\*** — a single `mix ci` equivalent to the PR gate, documented in CONTRIBUTING, so a
  contributor can reproduce a red check locally.

Rough phase sketch: (1) OBS baseline; (2) GATE correctness; (3) RUNNER + timeouts (biggest,
lowest-risk win); (4) CACHE; (5) CONSOL + required-check topology; (6) FLAKE + DX.
Target: ~25,500 → ~2,000–3,000 runner-seconds/push with the full proof set intact.

### Constraints carried forward

- Never workflow-level-`paths:` a required context.
- Preserve per-phase proof job names and artifacts — evidence is a product feature here.
- No auto-retry as a flake fix; quarantine + fix root cause.
- `release-please.yml` is security-sensitive (REL-05 SHA pinning, two prior armed fuses) — treat
  its concurrency (`cancel-in-progress: false`, `queue: max`) as correct and do not "optimize" it.
