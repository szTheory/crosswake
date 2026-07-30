---
phase: 154-the-control-contract-seam
verified: 2026-07-29T22:40:00Z
status: passed
score: 5/5 roadmap success criteria verified; 7/7 requirements (CTRL-01..05, PROOF-04, HRDN-01) verified
behavior_unverified: 0
overrides_applied: 0
re_verification: "No — initial verification"
---

# Phase 154: The Control-Contract Seam — Verification Report

**Phase Goal:** A LiveView can invoke a bounded native control through one typed seam and get a
correlated reply; every shell-absent/old-shell/undeclared failure mode collapses into one denial;
the command vocabulary is structurally closed against drift; and the already-shipped haptics
capability proves the seam end-to-end with zero native-side risk.

**Verified:** 2026-07-29
**Status:** passed
**Re-verification:** No — initial verification

## Method

This is goal-backward verification against the actual codebase, not a re-read of SUMMARY.md
claims. All commands below were executed directly in this session, from a clean working tree
(`git status` showed nothing to commit, `tmp/` untracked only). Every reported test count is a
live rerun, not a copy of a prior report.

## Goal Achievement

### Observable Truths (ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A LiveView can call `Crosswake.Bridge.push/3` for a declared capability and receive a correlated typed reply | ✓ VERIFIED | `lib/crosswake/bridge.ex` ships `push/3`, `attach/1`, `on_mount/4`. `test/crosswake/bridge/push_test.exs` exercises the full round trip (correlation id echoed, reply decoded to `%Crosswake.Bridge.Reply{}`, delivered via `{:crosswake_bridge, ref, reply}`); re-ran live — 93 tests, 0 failures including this file. `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex:76` calls `Bridge.push(@haptics_family, ref: @haptics_ref, ...)` in production code. |
| 2 | No-shell, too-old-shell, and undeclared-capability all produce the identical `Crosswake.Shell.Denial` shape, so an adopter writes one `handle_event` branch, not three | ✓ VERIFIED | `lib/crosswake/shell/denial.ex` closed 14-reason vocabulary incl. `:shell_unreachable` (added this phase). All client-detectable failure modes (no transport, unwired hook, reply timeout, transport error, explicit shell refusal) resolve to one `%Crosswake.Shell.Denial{}` — confirmed by `test/crosswake/bridge/push_test.exs` and by the Playwright `route_tour.spec.ts` three-case suite (`shell-absent → deny`, `shell-present → ok`, `hook-unwired → server-side deny`), re-run live: 23/23 Playwright tests passed including these three. CTRL-02 is honestly scoped in `guides/compatibility.md:130` and `guides/bridge.md:239` as "one typed denial **at the adopter boundary**", never "one vocabulary on the wire" — verified by direct grep, not by trusting the SUMMARY. |
| 3 | Invoking a capability never declared in route policy fails loudly and names the missing declaration, instead of silently doing nothing | ✓ VERIFIED | `Crosswake.Bridge.UndeclaredCapabilityError` (named exception, raised unconditionally — no `Mix.env`/`:dev`-only branch found in `lib/crosswake/bridge.ex`). `test/crosswake/bridge/push_test.exs:216` asserts the raise names route, family, declared capabilities, view module, router file/line, and the fix line (D-10). No `available?/2` or `connected?/1` predicate exists anywhere in `lib/crosswake/bridge.ex` (confirmed by grep) — D-09's "no pre-check back door" holds. |
| 4 | A proposed control that is host-registrable, dynamic, or otherwise violates the catalog line fails a merge-blocking structural CI test, and every control's rebuild class is visible in changelog/support matrix/doctor | ✓ VERIFIED | `lib/crosswake/bridge/catalog_guard.ex` (945 lines) implements `assert_catalog_closed!/1` with 11 check predicates; `test/crosswake/proof/phase154_catalog_guard_test.exs` and `test/crosswake/proof/phase154_recipe_followable_test.exs` (both re-run live, green) prove the gate is non-vacuous: a synthetic control fails at each omitted step and the failure message names the artifact. `Capability.@enforce_keys` now includes `:rebuild, :interaction` (confirmed in `lib/crosswake/manifest/types.ex:110`). `Crosswake.Doctor.capability_rebuild_findings/1` exists and is exercised by `test/crosswake/proof/phase154_advisory_actionability_test.exs` (check G, re-run live: passes against the real example host). CHANGELOG.md documents the `manifest_schema_version` 1.0.0→1.1.0 bump under Upgrade Impact. |
| 5 | The AdminPilot haptics call runs through `Bridge.push/3` with the old hand-rolled `<script>` IIFE deleted, proving the seam against an already-native, zero-risk capability | ✓ VERIFIED | `approval_live.ex:76` and `bridge_proof_live.ex` both call `Bridge.push/3`. `examples/phoenix_host/assets/js/app.js` confirmed deleted (does not exist on disk). Evidence panel (`#haptics-evidence`, `#haptics-reply`) renders from `data-cw-envelope={Jason.encode!(...)}`, the real envelope `push/3` built — not a hand-copied summary. `examples/phoenix_host/e2e/evidence_panel.spec.ts` checks A–F re-run live in both `chromium-light` and `chromium-dark` projects: 23/23 passed. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified).

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
|---|---|---|---|
| CTRL-01 | 154-03, 154-04, 154-07, 154-08 | ✓ SATISFIED | `push/3` + correlated `Reply` struct; Android native + server-synthesized denial reply paths proven; iOS native reply return leg built in-repo (`BridgeReplyDelivery`, Swift unit tests, committed contract vectors) but **honestly scoped** in `guides/support_matrix.md:114` as reaching adopters only with the Phase 156 native release — no overclaim found. |
| CTRL-02 | 154-03, 154-05, 154-08 | ✓ SATISFIED | One typed `Shell.Denial` at the adopter boundary, scoped honestly (see truth #2 above and the dedicated scrutiny section below). |
| CTRL-03 | 154-01, 154-03 | ✓ SATISFIED | `UndeclaredCapabilityError`, unconditional raise, named and tested. |
| CTRL-04 | 154-05 | ✓ SATISFIED | `CatalogGuard` merge-blocking, non-vacuous, proven RED-to-GREEN and single-omission RED by `phase154_recipe_followable_test.exs`. D-45's honest limit ("does not stop 40 controls added one at a time") is stated in the guard's own moduledoc and in `guides/bridge.md`'s Guarantee Strength table. |
| CTRL-05 | 154-02, 154-08 | ✓ SATISFIED | `@enforce_keys` widened (structurally impossible part, D-52); `capability_rebuild_findings/1` shipped and tested against the real example host; rebuild column added to `guides/capability_map.md`; CHANGELOG documents the schema bump. |
| PROOF-04 | 154-05, 154-08 | ✓ SATISFIED | Merge-blocking, untagged in `test/crosswake/proof/`, no new workflow file (confirmed: `git log` shows no `.github/workflows/` additions for 154-05/08 beyond the pre-existing `offline-sync-e2e-gate.yml` edit for Playwright project scoping). |
| HRDN-01 | 154-07, 154-08 | ✓ SATISFIED | AdminPilot haptics call migrated; IIFE deleted from both showcase LiveViews; `app.js` deleted. Scope honestly stated in CHANGELOG.md and `guides/web_to_mobile_migration.md` as "bridge dispatch no longer renders a server-built payload into an inline `<script>` element" — **not** "the last inline-script allowance is gone". `examples/phoenix_host/lib/crosswake_example/layouts.ex:25` still carries the Phoenix LiveSocket bootstrap as an inline `<script type="module">`, confirmed by direct read, and this is not contradicted anywhere in the guides or changelog. |

No orphaned requirements found — `.planning/REQUIREMENTS.md`'s traceability table maps exactly CTRL-01..05, PROOF-04, HRDN-01 to Phase 154, and all seven appear in at least one plan's `requirements:` frontmatter field.

## Scrutiny Items (from the verification brief)

1. **CTRL-02 honesty.** Confirmed. `guides/compatibility.md:130` states "Crosswake claims one typed denial **at the adopter boundary**. That is the honest scope..." and names the gap explicitly: eight fixed native out-of-vocabulary strings (enumerated in `CatalogGuard.@out_of_vocabulary_denial_allowlist`, cross-checked against `SEED-008-native-denial-vocabulary.md`) plus five unbounded delegate seams. `guides/bridge.md:239` repeats the same scoping beside the CTRL-05-adjacent guarantee-strength claim. No guide, changelog entry, or requirement text found claiming "one vocabulary on the wire."

2. **Human verification gate mechanized, not deleted.** Confirmed. `examples/phoenix_host/e2e/evidence_panel.spec.ts` (checks A–F) and `test/crosswake/proof/phase154_advisory_actionability_test.exs` (check G) and `test/crosswake/proof/phase154_recipe_followable_test.exs` (check H) were read in full. All are genuinely non-vacuous: enumerated forbidden-vocabulary sweeps with explicit non-vacuity assertions (e.g. `evidence_panel.spec.ts` test A explicitly asserts the idle panel does NOT already contain reply/dispatch rows, to prevent the assertions from passing vacuously on the wrong state), a real WCAG contrast computation with an explicit color-scheme-actually-took-effect check, object-identity tracking across DOM mutations for the live-region proof, and — for check H — an actual RED-to-GREEN execution of the real `CatalogGuard.assert_catalog_closed!/1` raiser against a synthetic fixture tree, with each single-step omission independently proven RED. Proxy limitations are labelled inside the tests' own docblocks (PARTIAL PROXY for C and E, PROXY for F, MECHANICAL-BY-PROXY for G, SYNTHETIC-TREE CAVEAT for H, plus an explicit "KNOWN HOLE" describe block in H asserting step 1 is *not* mechanically caught) — not merely in the SUMMARY. Re-ran all: 23/23 Playwright (including 6×2 evidence-panel checks) and the two ExUnit proof files, all green.

3. **No iOS overclaim.** Confirmed. `guides/support_matrix.md:114` states the iOS native reply return leg "reaches adopters with the **Phase 156** native release" and that "until then an iOS route still receives the server-synthesized denial rather than a native reply." No guide or matrix entry found implying a shipped iOS reply path to adopters today.

4. **HRDN-01 scope.** Confirmed. CHANGELOG.md and `guides/web_to_mobile_migration.md` both scope the claim as "bridge dispatch no longer renders a server-built payload into an inline `<script>` element," and `examples/phoenix_host/lib/crosswake_example/layouts.ex:25-35` was read directly — it still contains the Phoenix `LiveSocket` bootstrap as an inline `<script type="module">`. This is not contradicted by any overclaiming text found in the guides.

5. **`CatalogGuard` not weakened.** Confirmed. `assert_catalog_closed!/1`'s injection options (`root:`, `commands:`, `command_capability_map:`, `catalog_capability_ids:`) all default via `Keyword.get`/`Keyword.get_lazy` to the real shipped values (`File.cwd!()`, `Contract.commands()`, `shipped_command_capability_map/0`, `bounded_bridge_capability_ids/0`), read directly in `lib/crosswake/bridge/catalog_guard.ex:584-630`. The zero-arg gate the real CI/doctor calls is unchanged. `phase154_catalog_guard_test.exs` (unmodified per 154-08's own acceptance criteria) still runs and passes against the real tree.

6. **Legitimately deferred items.** SEED-008 exists and is substantive (both halves of the D-16 gap named, tracked, and cited from the guides). `deferred-items.md` documents the `validator_test.exs` `$TMPDIR` flake as pre-existing and unrelated to Phase 154. The `ecto_sqlite3` log noise item mentioned in the verification brief was not separately named in phase docs but is consistent with ordinary test-runner log chatter observed during the live reruns below (not a functional failure in any lane).

## Live Execution Evidence (rerun in this session, not copied from SUMMARY.md)

| Command | Result | Matches claimed fact? |
|---|---|---|
| `mix test --exclude requires_example_host --exclude advisory_only` (core repo) | 1253 tests, 0 failures (73 excluded), 69.5s | Yes — exact match |
| `mix test --only requires_example_host` (core repo) | 63 tests, 0 failures (1263 excluded), 19.9s | Yes — exact match |
| `mix test` (in `examples/phoenix_host`) | 95 tests, 0 failures | Yes — exact match |
| `node --test test/js/*.mjs` | 22 pass, 0 fail | Yes — exact match |
| `npx playwright test` (in `examples/phoenix_host`) | 23 passed | Yes — exact match |
| `node script/check-e2e-honesty.mjs` | exit 0, "observe real app behavior" | Yes — exact match |
| `mix compile --warnings-as-errors` (core repo) | exit 0 | Yes |
| `mix compile --warnings-as-errors` (phoenix_host, via default cwd) | exit 0 | Yes |
| `mix docs` (core repo) | exit 0 (doc-reference warnings present but non-fatal, no `error` string in output) | Yes |

Also spot-checked: `test/crosswake/proof/phase154_recipe_followable_test.exs`, `test/crosswake/proof/phase154_catalog_guard_test.exs`, and `test/crosswake/bridge/push_test.exs` run together in isolation — 93 tests, 0 failures, and directly read the reconnect/epoch behavior test (`test/crosswake/bridge/push_test.exs:451`, "a reply minted under a previous epoch is dropped as foreign-epoch after a simulated remount") to confirm the D-24 reconnect-semantics claim is exercised by a real passing test, not just present-and-wired code.

### Anti-Patterns Found

None. Swept `lib/crosswake/bridge.ex`, `lib/crosswake/bridge/catalog_guard.ex`, `lib/crosswake/bridge/reply.ex`, `priv/static/crosswake.esm.js`, `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`, `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`, `lib/crosswake/shell/denial.ex`, `lib/mix/tasks/crosswake.gen.bridge_hook.ex` for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER|coming soon|not yet implemented` — zero matches across all files.

### Human Verification Required

None. The phase's own closing checkpoint was mechanized (checks A–H), and this verification independently confirmed those checks are substantive rather than rubber-stamped, by reading their assertions and re-running them live.

### Minor Documentation Nit (not a gap)

`.planning/ROADMAP.md:282` still reads "**Plans**: 7/8 plans executed" for Phase 154, while the phase's own plan checklist immediately below it lists `154-01` through `154-08` all as `[x]`, and `.planning/STATE.md` states "COMPLETE (8/8 plans)". This is a stale count left over from mid-execution and does not reflect any missing work — every plan file (154-01 through 154-08) has a corresponding SUMMARY.md, and this verification directly confirmed the artifacts and tests from all eight. Recommend a one-line ROADMAP.md fix but it does not block phase completion.

## Gaps Summary

None found. All five ROADMAP.md success criteria and all seven requirements (CTRL-01..05, PROOF-04,
HRDN-01) are backed by live, re-executed, passing tests and directly-read source. The scrutiny items
called out in the verification brief — CTRL-02 scope honesty, the mechanized human-verification gate's
non-vacuity, the iOS non-overclaim, the HRDN-01 scope statement, and the CatalogGuard injection seam's
safety — were each independently confirmed against the actual codebase rather than trusted from
SUMMARY.md. The phase goal is achieved.

---

_Verified: 2026-07-29_
_Verifier: Claude (gsd-verifier)_
