---
phase: 60-example-host-registry-and-phoenix-wiring
verified: 2026-06-02T00:00:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 60: Example Host Registry And Phoenix Wiring — Verification Report

**Phase Goal:** Provide a copyable Phoenix-owned registry path for binding, rotating, revoking, pruning, and invalidating notification tokens.
**Verified:** 2026-06-02
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | D-01/D-02/D-03/D-04/D-05/D-06: example host persists backend-owned token lifecycle rows with token_ref and token_fingerprint only, rejects raw APNs/FCM token material | VERIFIED | `token_binding.ex` schema has no raw-token fields; migration grep confirms no `:token`, `:raw_token`, `:device_token`, `:apns_token`, `:fcm_token` columns; `MetadataSanitizer.sanitize/1` drops both atom- and string-keyed forbidden keys; proof test passes |
| 2 | D-07/D-14: closed Chimeway vocabularies are enforced through Ecto.Enum-backed changesets plus named unique constraints before rows persist | VERIFIED | `TokenBinding` and `TokenBindingEvent` both use `Ecto.Enum` for all vocabulary fields; `changeset/2` declares four named `unique_constraint/3` calls matching migration index names exactly |
| 3 | D-08/D-09/D-10/D-11/D-12/D-13: active token identity and authority scopes are protected by explicit lookup, idempotency, and partial unique indexes, including a separate subject_installation index | VERIFIED | Migration defines `:chimeway_token_bindings_active_token_identity_index`, `:chimeway_token_bindings_active_subject_session_scope_index`, and `:chimeway_token_bindings_active_subject_installation_scope_index` as separate named partial unique indexes; SQLite boot harness confirms all three exist at runtime |
| 4 | D-26/D-27/D-28/D-29: append-only audit rows exist as first-class lifecycle evidence with allowlisted fields and forbidden metadata, written in the same transaction as binding changes | VERIFIED | `TokenBindingEvent` schema is allowlist-only; audit migration has no `on_delete: :delete_all` or `references()`; `MetadataSanitizer.sanitize/1` is called in `TokenBindingEvent.changeset/2`; all `Registry` lifecycle paths insert audit events inside the same `Ecto.Multi` transaction |
| 5 | D-15/D-16: lifecycle writes use Ecto.Multi to change the mutable binding row and append audit rows atomically | VERIFIED | `registry.ex` uses named `Ecto.Multi` steps (`:existing_same_token`, `:displaced_bindings`, `:supersede_displaced`, `:binding`, `:audit_events`) throughout all lifecycle paths |
| 6 | D-17/D-19: same-token refresh preserves binding history, rotation supersedes displaced active rows and inserts a new active binding | VERIFIED | `bind_or_rotate/3` implementation confirmed: refresh branch updates only `last_seen_at`/`notification_status`/`app_identity_posture`/`metadata` and writes `:observed` event; rotation branch uses `state: :superseded, reason: :token_rotated` for displaced rows before inserting new; WR-04 fix confirmed (`reason = if is_rotation, do: :token_rotated, else: :initial_bind`) |
| 7 | D-20/D-21/D-22/D-23/D-24: logout revocation, session revocation with session_version protection, permission loss, provider invalidation, and staleness pruning change lifecycle state without deleting binding or audit truth | VERIFIED | All five lifecycle functions present in `registry.ex`; WR-03 fix confirmed (`session_ref` required in `revoke_for_logout/2`); session_version guard present in `revoke_for_session_revocation/2`; `prune_stale/1` uses `state: :stale` without deleting; proof suite exercises all five paths |
| 8 | D-30/D-31/D-32: Chimeway telemetry only emits after successful commits, uses sanitized transaction return shapes, and never emits success events from rolled-back lifecycle flows | VERIFIED | `Telemetry.execute/3` calls appear exclusively inside `{:ok, changes}` pattern-match branches after `Repo.transaction/1`; telemetry rollback safety proof test passes (mailbox confirmed empty after forced constraint failure) |
| 9 | CR-01 fail-closed fix: feedback with neither token_fingerprint nor token_ref returns `{:error, :feedback_missing_token_selector}` and leaves all active bindings intact | VERIFIED | `feedback_target_query/1` helper exists at line 860; `_ -> {:error, :feedback_missing_token_selector}` branch at line 884; `do_feedback_invalidate/5` wraps entire pipeline in `with {:ok, query} <- feedback_target_query(fb)`; regression test passes (18/18) |
| 10 | Phase 60 proof covers schema safety, lifecycle transitions, audit retention, telemetry rollback safety, and raw-token absence end to end | VERIFIED | 18 tests, 0 failures confirmed by live test run; tests cover: schema source assertions, SQLite boot harness, bind/refresh/rotate lifecycle, revoke/feedback/prune/telemetry rollback, CR-01 regression, WR-01 regression, WR-05 regression |
| 11 | D-33/D-35: worker integration remains optional host-owned guidance; no Oban/Quantum/Broadway/GenStage dependency or compiled scheduler code introduced | VERIFIED | `examples/phoenix_host/mix.exs` has no `{:oban,`, `{:quantum,`, `{:broadway,`, or `{:gen_stage,`; no compiled chimeway file uses `use Oban.Worker`, `use Quantum`, `use Broadway`, `Process.send_after`, or `:timer.send_interval`; README contains "Optional Chimeway background jobs" section with correct scope and API names |

**Score:** 11/11 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex` | Allowlisted metadata persistence | VERIFIED | Exists; `forbidden_keys/0` and `sanitize/1` handle atom and string keys without `String.to_atom/1` |
| `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex` | Mutable binding projection schema | VERIFIED | Exists; `schema "chimeway_token_bindings"` with Ecto.Enum for 8 vocabulary fields; WR-05 fix (`validate_required([:session_ref, :session_version])` for `:subject_session`) confirmed at line 134 |
| `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex` | Append-only audit schema | VERIFIED | Exists; `schema "chimeway_token_binding_events"` with 13 Ecto.Enum fields; `actor_kind` locked to `[:backend, :provider, :maintenance]`; `proof_class` locked to `[:hermetic, :advisory, :not_applicable]` |
| `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` | Synchronous host-owned lifecycle API | VERIFIED | Exists; exports all 6 public functions (`bind_or_rotate/3`, `revoke_for_logout/2`, `revoke_for_session_revocation/2`, `revoke_for_permission_loss/2`, `apply_provider_feedback/2`, `prune_stale/1`); CR-01/WR-01/WR-02/WR-03/WR-04 fixes all confirmed in source |
| `examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs` | Mutable binding table with partial unique indexes | VERIFIED | Exists; no raw-token columns; three named partial unique indexes confirmed |
| `examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs` | Append-only audit table | VERIFIED | Exists; no `on_delete: :delete_all`; no `references()`; unique `:chimeway_token_binding_events_event_ref_index` confirmed |
| `test/crosswake/proof/phase60_chimeway_registry_test.exs` | Merge-blocking TOKN-03 proof lane | VERIFIED | Exists; 18 tests covering all lifecycle paths plus three regression tests (CR-01, WR-01, WR-05); 18/18 pass |
| `examples/phoenix_host/README.md` | Optional worker guidance section | VERIFIED | Contains "Optional Chimeway background jobs" section naming `prune_stale/1` and `apply_provider_feedback/2`; forbidden phrases absent; Broadway explicitly scoped out |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `TokenBinding.changeset/2` | `MetadataSanitizer.sanitize/1` | `sanitize_metadata/1` private function | WIRED | `sanitize_metadata/1` calls `MetadataSanitizer.sanitize(metadata)` on `:metadata` change |
| `TokenBindingEvent.changeset/2` | `MetadataSanitizer.sanitize/1` | `sanitize_metadata/1` private function | WIRED | Same pattern in `token_binding_event.ex` |
| `Registry.bind_or_rotate/3` | `TokenBinding` + `TokenBindingEvent` changesets | `Ecto.Multi` steps | WIRED | `:binding` step calls `TokenBinding.changeset/2`; `:audit_events` step calls `TokenBindingEvent.changeset/2` |
| `Registry.apply_provider_feedback/2` | `feedback_target_query/1` fail-closed guard | `with {:ok, query} <- feedback_target_query(fb)` | WIRED | CR-01 fix present; unbounded fan-out path is gone |
| `do_feedback_invalidate/5` | `{:error, :no_active_bindings}` on zero match | `:invalidate` Multi step returns error | WIRED | WR-01 fix present at line 898 |
| Migration index names | `unique_constraint` names in schemas | Exact string match | WIRED | All four constraint names verified identical in migration and `token_binding.ex` |
| Phase 60 proof | SQLite boot harness | `System.cmd("mix", ["run", ...])` | WIRED | Boot harness runs all migrations and asserts table + index existence |
| Telemetry emission | Post-commit only | `{:ok, changes}` branch after `Repo.transaction/1` | WIRED | All five lifecycle paths emit telemetry only inside `{:ok, _}` match; rollback test confirms no leakage |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `registry.ex bind_or_rotate/3` | `binding` returned in result | `Ecto.Multi` `:binding` step via `repo.insert`/`repo.get!` | Yes — DB insert/query | FLOWING |
| `registry.ex revoke_for_logout/2` | `bindings` list | `:bindings` re-query with `order_by: b.binding_ref` | Yes — DB query after `update_all` | FLOWING |
| `registry.ex apply_provider_feedback/2` | query in `feedback_target_query/1` | `from(b in TokenBinding, where: ...)` scoped by token_fingerprint or token_ref + provider/platform/environment | Yes — scoped DB query, fails closed if no selector | FLOWING |
| `registry.ex prune_stale/1` | `bindings` list | `:bindings` re-query after `mark_stale` `update_all` | Yes — DB query | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full proof suite | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | 18 tests, 0 failures (4.3s) | PASS |
| CR-01 regression test | included in proof suite | `phase60-cr01-regression-proof: ok` | PASS |
| WR-01 regression test | included in proof suite | `phase60-wr01-regression-proof: ok` | PASS |
| WR-05 regression test | included in proof suite | `phase60-wr05-regression-proof: ok` | PASS |

---

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `test/crosswake/proof/phase60_chimeway_registry_test.exs` | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | Exit 0, 18 tests, 0 failures | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| TOKN-03 | Plans 60-01, 60-02, 60-03 | Token rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning revoke or supersede bindings without deleting safe audit truth | SATISFIED | All five lifecycle transitions implemented atomically in `registry.ex`; append-only audit rows survive all transitions; proof confirms history is never deleted; 18/18 proof tests pass |

---

### Review Fix Verification (commit cd5a7cd)

All six findings from the code review are confirmed fixed in the actual source code. Each was independently verified against the file content:

| Finding | Fix Present | Evidence Location |
|---------|------------|-------------------|
| CR-01: unbounded provider feedback fan-out | CONFIRMED | `feedback_target_query/1` at line 860; `{:error, :feedback_missing_token_selector}` at line 884; `with {:ok, query} <-` guard at line 889 |
| WR-01: fabricated success on zero-match invalidation | CONFIRMED | `{:error, :no_active_bindings}` inside `:invalidate` Multi step at line 898; `{:error, :invalidate, :no_active_bindings, _changes} ->` at line 1032 |
| WR-02: unordered telemetry zipping | CONFIRMED | `order_by: b.binding_ref` on `:bindings` re-query in all 4 bulk flows; `Enum.sort_by(pre_bindings, & &1.binding_ref)` in all event-building helpers; `events_by_ref = Map.new(events, ...)` lookup in all 5 telemetry loops |
| WR-03: silent session-scope widening in `revoke_for_logout` | CONFIRMED | `case ctx[:session_ref]` at line 488; `{:error, {:session_ref, :required}}` at line 493 |
| WR-04: rotated binding persists `:initial_bind` reason | CONFIRMED | `is_rotation = not Enum.empty?(displaced)` at line 287; `reason = if is_rotation, do: :token_rotated, else: :initial_bind` at line 288; `build_binding_attrs(ctx, ev, installation_ref, now, reason)` at line 291; rotation audit event uses `reason: :token_rotated` at line 379 |
| WR-05: subject_session binding accepts nil session_version | CONFIRMED | `validate_required([:session_ref, :session_version])` at `token_binding.ex` line 134 |

---

### Anti-Patterns Found

No blockers found. The four Info-level findings from the code review (IN-01 dead rotation-reason code, IN-02 `now_dt` alias, IN-03 unused `request_ref` index, IN-04 unused `app_identity_ref` field) are present in the source but are all Info-only scope — none affect behavior, correctness, or the phase goal. No `TBD`, `FIXME`, or `XXX` debt markers found in any phase-60 file.

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `registry.ex:248, 339` | `now_dt = now` alias (IN-02, carried over per review) | Info | No behavioral impact; cosmetic only |
| `token_binding_event.ex` / audit migration | `request_ref` field/column/index declared but never written (IN-03) | Info | Dead surface area; no behavioral impact in Phase 60 |
| `token_binding.ex` / registry | `app_identity_ref` field declared but never written by registry (IN-04) | Info | Dead surface area; no behavioral impact in Phase 60 |

---

### Human Verification Required

None. All lifecycle behaviors are mechanically verifiable through the hermetic SQLite proof suite and source-level assertions. No visual, real-time, or external-service behavior is involved.

---

### Gaps Summary

No gaps. All 11 must-haves are VERIFIED. The phase goal — a copyable Phoenix-owned registry path for binding, rotating, revoking, pruning, and invalidating notification tokens — is fully achieved in the codebase. The critical security fix (CR-01 fail-closed unbounded fan-out) and all five warnings from the code review are confirmed present in commit cd5a7cd. The proof suite runs cleanly with 18 tests and 0 failures.

---

_Verified: 2026-06-02_
_Verifier: Claude (gsd-verifier)_
