---
id: SEED-004
status: planted
planted: 2026-07-04
planted_during: "Phase 141 core-first publish — all four family packages went live on Hex, but every companion clean-room proof failed on a chain of harness bugs"
trigger_when: "Surface during a release/CI-infrastructure hardening pass, before the next companion Hex release, or whenever the advisory clean-room-proof-* / release-failure-alert noise needs to go quiet. NOT blocking — these proofs are non-required (post-publish, advisory)."
scope: Small
---

# SEED-004: Fix the companion clean-room proof harness (script/verify_companion_cleanroom.sh)

## Why This Matters

`script/verify_companion_cleanroom.sh` runs the post-publish `clean-room-proof-<pkg>` jobs in
`release-please.yml`: from a throwaway Phoenix host it resolves the just-published companion
against published core, compiles, smoke-tests, registers the companion, and runs
`mix crosswake.doctor`. It is the **resolvability safety net** proving a real adopter can pull the
package from Hex. The jobs are **non-required** (advisory; they run after publish and fire
`release-failure-alert`/PROOF-03c on failure but do not block merges).

During Phase 141 the script revealed a **chain** of harness bugs — each fix uncovered the next, and
**no companion clean-room proof went green the entire phase** (sigra, chimeway, threadline all
failed at successively later steps):

1. **App-name (fixed #64):** throwaway dir named `clean-room-<pkg>` → `mix new` app name rejected
   (hyphens invalid in Elixir atoms). Fixed: underscores.
2. **mkdir leaf (fixed #67):** `mkdir -p "$CLEAN_ROOM_DIR"` pre-created the leaf dir → `mix new`
   prompted "directory already exists? [Yn]" → EOF-abort under `bash -e`. Fixed: mkdir only the parent.
3. **Doctor router not available (OPEN):** threadline Step 7 `mix crosswake.doctor --router
   CleanRoomHost.Router` → `** (Mix) router module CleanRoomHost.Router is not available`, *despite*
   Step 4 compiling `lib/clean_room_host/router.ex` and Step 5's inline ExUnit smoke test passing
   ("4 tests, 0 failures"). Something between Step 5 and Step 7 (likely the Step 6 `config/runtime.exs`
   companion registration changing the boot, or the doctor task not force-compiling/loading the host
   app's own modules) leaves the router unloaded at doctor time.

Resolvability itself is effectively proven for threadline (Steps 1–6 passed: resolved 0.1.0 + core
0.2.0, compiled, smoke-tested, registered). Bug #3 is a harness/doctor-invocation wiring issue, not a
real defect in the published package.

## What To Do

1. Reproduce locally: run `script/verify_companion_cleanroom.sh crosswake_threadline 0.1.0` (with a
   published core 0.2.0) and inspect why `CleanRoomHost.Router` is unloaded at the doctor step.
   Likely fixes: `mix compile` (or `mix loadpaths`/`Code.ensure_compiled`) immediately before the
   doctor call after the Step 6 runtime.exs edit; or have the doctor task force-load the host app.
2. Re-verify chimeway and sigra proofs go green with the fix (their proofs never ran past the earlier
   bugs on live code — chimeway's was never re-run after #67; sigra's original failed on app-name).
3. Consider making these proofs **required** once green, so the resolvability net actually gates —
   OR keep advisory but ensure `release-failure-alert` distinguishes "harness bug" from "package
   unresolvable" so a green-publish + red-harness doesn't read as a real failure.
4. Fix the cosmetic `{:"crosswake_threadline", "~> 0.1"}` quoted-atom warning the script emits into
   the throwaway host mix.exs (drop the quotes).

## Scope Estimate

**Small** — a shell-script/harness fix plus a re-verify of all three companion proofs. No product code.
Relates to [[project_crosswake_141_publish]] and the 0-recurring-intervention goal.
