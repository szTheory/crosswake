# Phase 197: Public docs truth - Context

**Gathered:** 2026-10-29
**Status:** Ready for planning

<domain>
## Phase Boundary

A first adopter following the public docs (README "Integrating", `guides/install.md`) from a normal
host with no repository clone gets commands that exist, versions that are real and capability
claims backed by evidence. Requirements DOCS-01, DOCS-02, DOCS-03; success criteria 1-4 in the
workstream ROADMAP. Also carries the Phase 195 review items WR-04, WR-05, WR-06 and IN-03 for
`script/verify_published_cleanroom.sh`.

Not in scope: fixing every internal-code leak hit (counted only this cycle), generating the
Android parity ledger (Phase 198), any release or publish (Phase 199).

</domain>

<decisions>
## Implementation Decisions

All four areas were researched by parallel advisor agents, cross-checked, and locked by the user as
one coherent set ("Lock all").

### Clean-room docs run (DOCS-01, SC1)
- **D-01:** Documented steps are executed from the docs themselves, never from a hand-mirrored copy.
  Every fenced block in the README "Integrating" section and in `guides/install.md` is preceded by
  an invisible HTML-comment marker of one of four kinds:
  `<!-- cleanroom:run id=<id> -->` (shell block run verbatim with `set -e` in the host dir),
  `<!-- cleanroom:apply id=<id> file=<host path> -->` (fragment injected into a host file, with a
  fixed substitution table such as `my_app`→`clean_room_host`, `MyAppWeb`→`CleanRoomHostWeb`),
  `<!-- cleanroom:clone id=<id> -->` (never executed; repo-only), `<!-- cleanroom:show -->`
  (illustrative only). No new dependency (no rundoc/mdsh/byexample).
- **D-02:** New `docs` leg in `script/verify_published_cleanroom.sh`; `DEFAULT_LEGS` becomes
  `hex,maven,ios,docs`. The leg generates a throwaway host with a pinned `phx_new` (reuse the
  pattern in `script/verify_companion_cleanroom.sh`, assets enabled because esbuild flags need
  them), then runs the marked steps in doc order: deps.get → `mix crosswake.install` → bridge hook +
  esbuild flags → `attach/1` → `:ios_host` → compile → `mix crosswake.doctor`. `gen.shell ios` and
  `swift build` are out of this leg (the `ios` leg already builds the mirror). Output follows the
  existing contract: `cleanroom: leg docs PASS <version> executed=<n> not_applicable=<m> ...`,
  `cleanroom: FAIL docs step <id> exit <code>`, `cleanroom: FAIL docs <fetch|parse|tool_unavailable> ...`.
- **D-03:** Docs source. Default: README.md and guides/install.md are extracted from the Hex
  tarball of the version under test, so docs and code are the same artifact (used in Phase 199
  against 0.2.12). For Phase 197, an input selector (not a verdict override, so no SELFTEST)
  `CLEANROOM_DOCS_REF=<40-hex commit>` fetches the two files at a pushed public commit with no
  clone; the commit is printed in the output. The Phase 197 run is a real `result PASS` against
  published 0.2.11. Verified during discussion: the 0.2.11 release commit `7273e6cf` already ships
  `mix crosswake.gen.bridge_hook`, `Crosswake.Bridge.attach/1` and the esbuild wiring in
  install.md, so SC1 is not deferred to Phase 199.
- **D-04:** A step that needs an unreleased version carries `since=X.Y.Z` and reports
  `NOT_APPLICABLE`; the leg FAILs if any of the bridge-hook, esbuild, `attach/1` or `:ios_host`
  steps is NOT_APPLICABLE, and FAILs when `executed` is below a pinned floor. Prefer keeping
  unreleased behavior out of these two files (CHANGELOG `[Unreleased]` instead).
  **Amended 2026-10-29 (plan-check B-1, user decision):** 0.2.11 (`7273e6cf`) does not read
  `config :crosswake, :ios_host`; it landed in Phase 179 after the release. The `:ios_host` step
  carries `since=0.2.12`, reports `NOT_APPLICABLE` against 0.2.11 and is recorded in the Phase 197
  evidence as a named deferral, never counted as executed or passed. It is the only required
  step exempt from the NOT_APPLICABLE FAIL rule, and only while the version under test is below
  0.2.12. The bridge-hook, esbuild and `attach/1` steps must still execute. Phase 199 (0.2.12)
  must execute the `:ios_host` step with no exemption. The D-05 marker test still requires the
  `:ios_host` token in both files.
- **D-05:** Network-free marker test (ExUnit, in the normal suite) fails when a fence in scope has
  no marker, a `run` block mentions `script/`, `bash script` or `examples/`, a `clone` block lacks
  its label, or the combined run/apply blocks lack the required tokens (bridge hook,
  `--external:/crosswake/*`, `--format=esm`, `Crosswake.Bridge.attach()`, `:ios_host`).
- **D-06:** Clone labeling (consumer microcopy): one italic line under each `clone` block —
  *"Needs a clone of the Crosswake repository; skip this if you installed from Hex."* — plus one
  summary line near the top of each file: steps marked "Needs a clone" are for contributors; every
  other step works from Hex alone. Today's `verify_phase5_example_hosts.sh` and
  `verify_generated_*_shell.sh` blocks become `clone`. `:ios_host` wiring is added to both files
  (today it is only in `guides/native_shell.md`).
- **D-07:** Negative controls: (a) offline, in tests — a `mix` stub on PATH that exits 1 for an
  unknown task plus a doc copy where `mix crosswake.doctor` becomes a nonexistent task must yield
  exit 1 and `FAIL docs step doctor`; (b) the same mutation run once for real against 0.2.11,
  output retained; (c) stripping one marker turns the marker test red.
- **D-08:** Carried review fixes land in the same script change: WR-04 curl
  `--max-time`/`--retry`/`--proto '=https' --proto-redir '=https'`; WR-05 report resolve/parse
  failure separately from `not_published`; WR-06 parse POM groupId, artifactId and version; IN-03
  complete `need_tools` (`head`, `tr`, `tar` and any other tool the legs call).
- **D-09:** The clean-room run is local, once in Phase 197 with output retained in phase evidence,
  and again post-publish in Phase 199. It is never a PR job.

### Version truth (DOCS-02, SC2)
- **D-10:** Delete the "Current Version" column from `guides/companion_compatibility.md`; replace it
  with a "Latest on Hex" link to `hex.pm/packages/<pkg>` per row. Keep the drift-tested
  "Requires `crosswake`" range column. Delete the prose about `unpublished`/rindle and rulestead
  state. Rationale: release-please bumps `.release-please-manifest.json` inside the bot release PR
  without touching the guide, so any guide-equals-manifest test would turn the release PR red and
  hand edits to the bot branch are forbidden; a generated cell cannot be kept current without that
  conflict. — **Reversibility:** reversible — a column can be re-added later with a release-please
  updater.
- **D-11:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` drops
  `@published_versions` (it pins the false "rindle unpublished" value) and instead asserts no
  version literal appears in the matrix, with a negative control (inject `0.1.0` into a row → red)
  and a non-vacuity floor on rows compared. Existing floor/phantom-row/runbook assertions stay.
- **D-12:** "Checked against the registry" is satisfied by one `mix crosswake.release.status
  --live` run recorded in phase evidence (hex.pm today: crosswake 0.2.11, rulestead 0.1.1, rindle
  0.1.0, sigra 0.1.3, chimeway 0.1.2, threadline 0.1.0 — the guide is stale on rulestead, chimeway
  and rindle). The live check stays advisory/post-publish; never in PR CI.
- **D-13:** CHANGELOG: delete every "current published family"/"current published Hex release"
  claim, the "No new support claims have been cut after 0.2.1" bullet, and the stale
  planning-milestones paragraph that calls MILESTONE-ARC canonical. Add one version-free sentence
  pointing to GitHub Releases (and hex.pm) for 0.2.2–0.2.11; do not backfill sections
  (release-please owns them). `[Unreleased]` names no release versions (schema/protocol contract
  versions are fine). Add a test asserting `[Unreleased]` contains no
  `current published|published Hex (family|release)` wording, with a negative control.
- **D-14:** `guides/telemetry.md` lists `[:crosswake, :offline, :replay]`; `guides/see_it_run.md`
  states the twin receipt attests `a53fbef`, not main.

### Report-mode docs checks (DOCS-03, SC3)
- **D-15:** One command, `script/docs-report` (bash launcher + `.exs`, same shape as
  `script/bearings-report`), prints `docs.warnings total=<n> extras=<n>`, `docs.links broken=<n>
  checked=<n> files=<n>`, `docs.leaks hits=<n> allowlisted=<n> stale_allowlist=<n> files=<n>` and
  `docs-report: REPORT-ONLY (not a required check)`. Exit 0 = ran, exit 2 = UNVERIFIED; never exit 1.
  Not added to CI (zero CI minutes). Not part of bearings-report.
- **D-16:** Warnings: count `warning:` lines from `mix docs`; `extras=` are those whose location
  line names an extras file. No `--warnings-as-errors`. Missing `doc/index.html` or a non-zero exit
  is UNVERIFIED, never `total=0`.
- **D-17:** Links: files from `mix.exs` `extras:` only; relative `.md` links and `#anchors`
  (GitHub slug rules; ExDoc slug differences noted in the record); external URLs and fenced code
  out of scope; links into non-shipped paths (`lib/`, `.planning/`) count as broken. Plain regex,
  no new dep.
- **D-18:** Leaks: same file scope; case-sensitive patterns `Phase [0-9]+`, `TODO-[0-9]+`,
  `D-[0-9]{2}`, `SEED-[0-9]+`, milestone labels `v1x/v2x(.N)` excluding real semver; allowlist in
  its own file (`script/docs_leak_allowlist.json`, not `ci_docs_allowlist.json`) keyed by file plus
  normalized text with a reason, starting empty.
- **D-19:** Count only this cycle; leak hits are not fixed except on lines this phase rewrites
  anyway (generated guides need generator changes — later). Ordering is mandatory: record the
  baseline on main BEFORE any doc edit in this phase, then re-record after; both in
  `197-DOCS-REPORT.md` with main SHA and ex_doc version. Discussion-time measurement (ex_doc
  0.40.3): 197 warnings (2 in extras), Phase N 43, TODO- 6, D-NN 7, vNN 10, SEED- 1.
- **D-20:** Negative controls via ExUnit fixture dirs: known warning/link/leak fixtures produce
  exact counts; allowlisting turns hits to 0 and mutating the entry turns them back; empty input,
  scan floor below extras count, or unreadable file → UNVERIFIED.

### Android UAT (DOCS-03, SC4)
- **D-21:** Delete the "Last verified against … `x-release-please-version`" line and remove the
  `guides/android_uat.md` entry from `release-please-config.json` extra-files. Replace with a
  version-free status: no emulator or physical-device verification of Android has been recorded;
  the only Android evidence is JVM hermetic proof and shared bridge-contract vectors; the checklist
  is a template for future device evidence.
- **D-22:** Phantom = listed in the doc but absent from `Crosswake.SupportMatrix.canonical()`
  capability families. Remove `account_management`, `diagnostic_export`, `companion_snapshot`,
  `location_capture` (19 → 15). Retitle to "Capability families (registry mirror)" and state that
  listing does not mean Android implements or has verified a family. Boundary text matches ADR
  amendment A1 (no emulator, device or feature-breadth claim).
- **D-23:** Strengthen `test/crosswake/proof/phase68_android_uat_test.exs` into a two-way
  set-equality test parsing only backticked bullets under the families heading, with a non-empty
  guard and a phantom-plus-missing negative control. Update the stamp-dependent assertions in
  `test/crosswake/guides/native_evidence_drift_test.exs` (keep the overclaim negative control).
  Generation from contract vectors is deferred to Phase 198.
- **D-24:** "Android frozen" grep over README, support matrix and native shell guide already
  returns 0 hits (Phase 194); record it as evidence only.

### Gate stance
- **D-25:** The marker test, the CHANGELOG wording test, the phase132 change and the Android
  set-equality test run in the normal merge-blocking suite: each guards text rewritten in the same
  PR and lands with 0 findings by construction. The three docs-report counters, whose findings
  are unknown, stay report-only for one cycle.

### Claude's Discretion
- Exact marker id names, substitution table entries, the pinned `phx_new` version and the
  `executed` floor value.
- Plan/PR split and wave order, provided D-19's baseline-first ordering holds.
- Test file names and module layout for the new tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governance and posture
- `AGENTS.md` — working rules, approval gate, privacy, how changes land
- `.planning/BEARINGS.md` — tripwires (negative controls, no pinned false values, piped exit codes, measure before merge-blocking)
- `.planning/ADR-FIRST-B2C-ADOPTER.md` §A1 — Android posture (JVM-hermetic claims only)
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §Phase 197 — goal, SC1-4, ordering rules
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — DOCS-01, DOCS-02, DOCS-03
- `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-REVIEW-DISPOSITION.md` — WR-04/05/06, IN-03

### Docs under change
- `README.md` §"Integrating Crosswake"
- `guides/install.md`
- `guides/companion_compatibility.md`
- `CHANGELOG.md`
- `guides/telemetry.md`, `guides/see_it_run.md`, `guides/android_uat.md`
- `guides/native_shell.md` — existing `:ios_host` wiring text to reuse

### Scripts, config and tests
- `script/verify_published_cleanroom.sh` — REL-06 clean-room command and output contract
- `script/verify_companion_cleanroom.sh` — pinned `phx_new` host-generation pattern
- `script/bearings-report`, `script/bearings_report.exs` — shape for `script/docs-report`
- `release-please-config.json`, `.release-please-manifest.json`
- `mix.exs` — docs `extras:` list (scan scope)
- `lib/crosswake/release_status.ex` — `mix crosswake.release.status --live`
- `lib/crosswake/support_matrix/support_matrix.ex` — capability family registry
- `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`
- `test/crosswake/proof/phase68_android_uat_test.exs`
- `test/crosswake/guides/native_evidence_drift_test.exs`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `verify_published_cleanroom.sh`: legs, selftest-override gate, `cleanroom:` output contract, exit codes 0/1/2.
- `verify_companion_cleanroom.sh`: `mix archive.install hex phx_new <pinned>` + `mix phx.new --no-ecto ...` throwaway host.
- `bearings-report`: launcher + `.exs`, UNVERIFIED-on-read-failure, negative-control tests.
- `Crosswake.ReleaseStatus`: Hex release probe for the live registry check.

### Established Patterns
- Merge-blocking proof is deterministic and network-free; networked checks are advisory/post-publish.
- Generated guides (`capability_map.md`, `support_matrix.md`) are owned by `mix crosswake.docs.sync`; fix via generator, not by hand.
- release-please owns CHANGELOG release sections and the `x-release-please-version` extra-files.

### Integration Points
- `release-please-config.json` root package `extra-files` (remove `guides/android_uat.md`).
- Phase 199 reuses the `docs` leg in tarball mode against 0.2.12.
- Phase 198 replaces the Android hand list with the generated parity ledger.

</code_context>

<specifics>
## Specific Ideas

- The owner prefers "another copy-paste is better than another dep": no rundoc/mdsh/lychee/markdown-link-check; plain regex and existing tooling.
- Never pin a false literal: rindle is live at 0.1.0 on Hex although the guide and test say "unpublished".

</specifics>

<deferred>
## Deferred Ideas

- Fixing internal-code leak hits in public docs, including generator changes for `capability_map.md` and `support_matrix.md` — after the one-cycle baseline; promotion decision uses the recorded counts.
- Scanning `@moduledoc` text in `lib/` for leaks — later cycle.
- A `docs-ios` clean-room leg (`gen.shell ios` + `doctor --native-checks`, macOS) — only if the docs' run blocks come to include it.
- Generated Android capability ledger from contract vectors — Phase 198.
- Scheduled advisory `release.status --live` job — consider with the Phase 199 post-publish check.

</deferred>

---

*Phase: 197-public-docs-truth*
*Context gathered: 2026-10-29*
