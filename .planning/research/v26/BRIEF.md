# v26.0 research brief: Harden Before Trust

Workstream `quality-ratchet-release`. Started 2026-10-15. Phase numbering continues at 184.

## Goal

Before anyone relies on v25's code, remove each path where a v25 check can pass while it checks nothing, or where a guarantee can quietly weaken. Then run the reference twin once more, cleanly, against the hardened commit (run root `twin-05`).

## Selected inputs

1. **v25 retained debt.** Read `.planning/workstreams/quality-ratchet-release/milestones/v25.0-closeout/debt-disposition.md` and the audit `.planning/workstreams/quality-ratchet-release/milestones/v25.0-MILESTONE-AUDIT.md`.
2. **Review dispositions** under `.planning/workstreams/quality-ratchet-release/phases/`:
   - `181-*/181-REVIEW-DISPOSITION.md` (13 open)
   - `182-*/182-REVIEW-DISPOSITION.md` (10 open)
   - `183-*/183-REVIEW-DISPOSITION.md` (8 open). WR-01 (index flags) and WR-02 (filemode) can each weaken a future run without anyone noticing.
3. **SEED-018**, limited to the v25 code only. Covers collection assertions that pass when the collection is empty.
   - Seed file: `.planning/seeds/SEED-018-vacuous-collection-assertions.md`.
   - Existing tooling: `script/collection_assertion_ledger.json`, `script/collection_assertion_remediation.json` and `script/check_absence_is_not_success.exs`.
   - Not a repo-wide cleanup unless the evidence shows that is cheap and safe.
4. **SEED-023:** extend the scope-cardinality guard. Seed file: `.planning/seeds/SEED-023-extend-scope-cardinality-gate.md`.
5. **SEED-014:** proof-lane and doctor fidelity. Seed file: `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`.
   - CW-REQ-B is already closed, by 174-03.
   - CW-REQ-A is deferred until a release pipeline has been proven. Phase 175 ended with REL-10 breached. Decide from the evidence whether that reopen condition is met.
   - Re-check C, D, E and F against the candidate code. Some may already be fixed.

## Where things are

- **Product code** is the candidate `/private/tmp/crosswake-phase180-impl`, at HEAD `50fcd57`, with a clean tree. All v25 code is there and only there.
  - Read it; do not modify it.
  - Do not run the twin, the simulator or xcodebuild.
  - Running read-only commands such as `git`, `grep` and `mix test <file>` there is fine.
- **Planning and research** live in the recovery checkout `<home>/projects/crosswake`. Write only your one assigned output file under `.planning/research/v26/`.
- **Project rules:** read `AGENTS.md`, `.planning/PROJECT.md` and `.planning/ADR-FIRST-B2C-ADOPTER.md`.
- **Prior research:** `.planning/research/v25/` (SUMMARY, PITFALLS, TWIN-*, PROOF-*).
- **Vision and quality DNA:** `prompts/` (`crosswake-elixir-oss-dna.md`, `ARCHITECTURE-CODE-WALKTHROUGH-DNA.md`, `crosswake-brand-book.md`). Use only where relevant. This milestone is mostly not UI. CW-REQ-D (the SwiftUI denial view) is the one exception.

## Hard constraints

- **No git staging, commits, tags, branches or worktrees.** Never push, merge, release or open a PR.
- **Sensitive data.** Never record or infer the real adopter's name, founder, price, geography, customers, taxonomy or revealing links. Use only the codename First B2C Adopter. Never search git history or external sources to reidentify it. Raw answers, media, credentials, account ids, tokens, stable device ids and local usernames must not enter outputs.
- **Dependencies.** "Another copy and paste is better than another dep." Recommend no new dependencies unless one is unavoidable.
- **Out of scope:** Android (frozen), new companions, native-control breadth, generic sync, dashboards and brand polish.
- **Verification.** Use zero-human checks: unit, integration and artifact inspection. Human action only for credentials or irreversible trust steps.
- **Fail-closed.** A check must never pass by observing nothing. Name any path that can degrade silently.
- **Evidence.** Prefer primary sources: git, Elixir/ExUnit, Phoenix and Ecto docs, Apple docs, and the repo itself. State uncertainty plainly.
- **Coherence.** Recommendations must agree with one another and move toward the project thesis: a Phoenix-first route-policy and runtime-contract system for one real app on one physical iPhone.
