# Phase 153: iOS Mirror Unblock - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Release infrastructure only. Two deliverables:

1. **MIRROR-01** — Backfill the missing `v0.2.0` tag onto the `szTheory/crosswake-shell-core-ios` SwiftPM mirror so iOS adopters can resolve the current shell core (mirror is stuck at `v0.1.2` while Hex + Maven core are live at `0.2.0`).
2. **MIRROR-02** — Make a native shell-core release reach Hex, Maven, and the iOS mirror in one run, and make a mirror-push failure surface as a hard, named CI failure that actually reaches a human.

**No product code.** No bridge/control surface, no `Bridge.push/3`, no route policy. This phase lands and merges independently of the Pack 1 feature phases (154-157) so it is never gated behind product review.

**Hard prerequisite for Phase 156** — native bridge dispatch is a closed `switch` compiled into the shipped shell-core binaries, so the native menu control requires a new native release. That release cannot reach iOS adopters until the mirror is unstuck.

</domain>

<decisions>
## Implementation Decisions

### Root Cause (established during discussion — supersedes SEED-003 and v20 research)

- **D-01: The 403 was NOT a token scope problem. It is an `actions/checkout` credential-hijack bug.** `publish-ios-core` (and `ios-mirror-backfill.yml`) run `actions/checkout` with the default `persist-credentials: true`, which writes `http.https://github.com/.extraheader = AUTHORIZATION: basic <GITHUB_TOKEN>` into `.git/config`. That config key has no username component, so it matches **every** `https://github.com/*` remote in the working copy — including the `mirror` remote added at `release-please.yml:425` — and an explicit `Authorization:` header beats the `x-access-token:${MIRROR_TOKEN}@` userinfo in the URL. The push therefore authenticates as `github-actions[bot]`, which has zero rights on the separate mirror repo.

  **Proof by elimination (no live re-test needed):** (a) the job guards `if [ -z "${MIRROR_TOKEN:-}" ]` with a distinct exit-1 message and did not take that branch, so the secret **was** set and non-empty on 2026-07-03 — `gh secret list` confirms it was created 2026-06-17; (b) the 403 nonetheless named **`github-actions[bot]`**, not `szTheory` (the PAT owner). A PAT that was actually used would produce a denial naming its owner. Therefore the token in the URL was never used. Verified: `grep -rn persist-credentials .github/workflows/` returns **no matches** anywhere in the repo.

  **Three consequences that drive this whole phase:**
  1. **Rotating `MIRROR_PUSH_TOKEN` alone would 403 again and burn another release.** SEED-003's "What To Do" step 1, the v20 `RELEASE-STRATEGY.md` §3 recommendation, and the MIRROR requirement framing all encode the *wrong* theory. Downstream agents must not "just rotate the PAT."
  2. **The existing preflights cannot catch it** — the mirror repo is **public**, so `git ls-remote mirror HEAD` succeeds anonymously regardless of the token. The read probe is not a permission gate.
  3. **The backfill path is broken by the same bug.** `ios-mirror-backfill.yml` has the same unguarded checkout, so `--apply` would push through the same hijacked transport. **Transport MUST be fixed before the backfill is attempted**, or the backfill fails and looks like a token problem all over again.

- **D-02: "Make it louder" is a non-fix, and downstream agents must not treat it as one.** `publish-ios-core` **already** hard-fails (`set -euo pipefail` + explicit `exit 1` + named messages). The release run on 2026-07-03 **was already red** and went unnoticed for ~3 months. Adding `exit 1` to `native-release-rollup` therefore changes *nothing on its own*. Redness was never the variable; **where red lands** is. A post-merge Actions run has no persistence and no inbox. Every escalation decision below follows from this.

### Credential Strategy

- **D-03: Use an SSH deploy key with write access on `szTheory/crosswake-shell-core-ios`.** New secret `MIRROR_DEPLOY_KEY`. **Retire `MIRROR_PUSH_TOKEN`.**

  Chosen over a fine-grained PAT and a GitHub App because it is the only option that is *both*:
  - **structurally immune to D-01** (different transport — an SSH remote cannot be hijacked by an `http.*` extraheader), and
  - **zero-rotation** — deploy keys do not expire. A fine-grained PAT caps at 366 days and would expire **silently, mid-release**, which is a guaranteed future repeat of this exact incident and a recurring-intervention tax that violates the project's stated zero-recurring-intervention goal.

  Blast radius shrinks from "every repo szTheory owns" (classic PAT) or "one repo, coupled to the maintainer's account" (fine-grained PAT) to **one regenerable artifact repo** — the mirror is a pure `splitsh-lite` function of the monorepo and can be rebuilt at any time.

  GitHub App rejected as over-built for one maintainer pushing to one repo (register app + install + 2 secrets, and it is still HTTPS so it would *also* need the `persist-credentials: false` fix). It remains the right upgrade **later** if a bot identity is ever needed for more than this push.

- **D-04: Disable checkout credential persistence in BOTH `release-please.yml` (`publish-ios-core`) and `ios-mirror-backfill.yml`** — set `persist-credentials: false` on the checkout step. Belt-and-braces even with SSH — it removes the hijack vector at the source rather than only routing around it.

- **D-05: Maintainer handoff is four CLI commands, no browser, one time, never again.** The exact ritual (agent generates, human executes):
  ```
  ssh-keygen -t ed25519 -C "crosswake-ios-mirror" -f ./crosswake_ios_mirror -N ""
  gh repo deploy-key add ./crosswake_ios_mirror.pub -R szTheory/crosswake-shell-core-ios \
    --title "crosswake monorepo split (write)" --allow-write
  gh secret set MIRROR_DEPLOY_KEY -R szTheory/crosswake < ./crosswake_ios_mirror
  rm -P ./crosswake_ios_mirror ./crosswake_ios_mirror.pub
  ```
  (If `gh` lacks scope: `gh auth refresh -h github.com -s admin:public_key` first.) Note this is *better* DX than the PAT path, which has **no** prefillable creation URL for fine-grained tokens — only the deprecated classic-PAT URL supports `?scopes=`.

### Backfill Execution (MIRROR-01)

- **D-06: Run the backfill in CI via `gh workflow run ios-mirror-backfill.yml`, NOT locally.** Decisive rationale: the failure being repaired is literally *"CI did not push the tag."* A laptop push would repair the symptom while leaving the **CI credential still unexercised** until the next real release — reproducing the original bug's precondition. Running it in CI converts the backfill into the missing proof that the CI push path works.

- **D-07: Teach the script's verify-only branch to run `git push --dry-run --porcelain` BEFORE `--apply` exists.** Today `verify_or_apply_mirror()` returns in verify-only mode *before* reaching the dry-run, so `apply=false` proves **read** scope only — and read succeeds anonymously on a public repo (D-01.2), making verify-only nearly worthless as a permission check. Adding the dry-run probe to the verify branch (~5 lines) turns the already-dispatchable `apply=false` run into **the iOS fire-drill the repo lacks** — with zero new jobs and zero new recurring surface. (The repo has an `android-publish-fire-drill` but no iOS equivalent, on the surface that actually broke.)

- **D-08: ⚠️ SECOND ARMED FUSE — mirror `main` is OFF-LINEAGE, and this would break the next release even after the credential fix.**

  **Evidence (verified 2026-07-12):** the 0.1.2 iOS mirror was completed **out-of-band via `git subtree split`**, not by splitsh-lite — the splitsh v2.0.0 404 killed the job *before* the push step, so the maintainer finished it by hand. Consequences, confirmed by probe:
  - Mirror `main` == `HEAD` == `refs/tags/v0.1.2` == `6417ae6543219f1c35be120766827503eaa8ceea`, and **that object does not exist in this repo** (`git cat-file -t 6417ae65` → *could not get object info*).
  - `git subtree split --prefix=packages/crosswake-shell-core-ios ios-core-v0.1.2` run today yields `94fd9c01…` — different again. The mirror's history is **not reproducible from this repo by any tool we have**.

  **Therefore mirror `main` sits on a lineage splitsh-lite did not produce**, and:
  1. The release job's **non-forced** `git push mirror "$SPLIT_SHA:refs/heads/main"` (`release-please.yml:449`) would be a **non-fast-forward reject**. Under `set -euo pipefail`, with the `--dry-run` spanning *both* refspecs, the job dies **before the tag push** — and reports `MIRROR_PUSH_TOKEN cannot push …`, **misdiagnosing a lineage problem as a credential problem for the second time.** Fixing the credential alone does **not** unbreak the next release.
  2. `verify_ios_mirror_backfill.sh`'s `--update-main` ancestry guard (`git merge-base --is-ancestor "$current_main" "$SPLIT_SHA"`, line ~238) runs **in the monorepo**, where `6417ae65` is an unknown object → the command errors → the script **fail-closes** with `mirror main has commits not reachable from expected split SHA`. That message is *directionally right but diagnostically wrong* (it conflates "unknown object" with "mirror-only commits would be lost"). **`update_main=true` will NOT simply work.**

  **MIRROR-01 (the tag) is UNAFFECTED** — `SPLIT_SHA:refs/tags/v0.2.0` creates a brand-new ref with no fast-forward constraint. And the existing `v0.1.2` tag stays resolvable for SwiftPM forever even after `main` is re-baselined, because a tag pins its object regardless of branch reachability. So the tag backfill can proceed on its own.

  **Decision: perform a deliberate, one-time RE-BASELINE of mirror `main` onto the splitsh-lite lineage**, rather than trying to satisfy an ancestry proof that is unsatisfiable by construction. This is safe precisely because the mirror is a **pure derived, read-only artifact**: nothing depends on its commit SHAs, only on its **tags** (SwiftPM resolves tags, never branches), and both `v0.1.2` and `v0.2.0` tags are preserved through the operation. Requirements on the re-baseline:
  - It is an explicit, separately-approved step — **not** silently smuggled inside `--apply`.
  - The **`v0.1.2` tag is never touched** (it becomes an orphaned-but-resolvable commit; verify it still resolves afterwards).
  - Push with `--force-with-lease` against the known lease `6417ae65`, so a concurrent third-party change aborts it.
  - Fix the ancestry guard's message to distinguish *unknown object* from *would-lose-commits* (Claude's discretion whether to add an explicit `--rebaseline` flag that requires the operator to pass the expected current SHA).

  **Also fix the release job so this cannot recur:** push `main` with `--force-with-lease` (not bare, non-forced) as part of the atomic push in **D-13**, so a future lineage divergence can never again swallow the tag.

  Re-baselining also fixes the *shopfront* — GitHub renders `main`'s README, so an adopter's first impression of the package is currently 0.1.2 content for a package that is really 0.2.0.

- **D-09: Verify-first choreography with an explicit go/no-go gate.** Dispatch `apply=false` first; the run MUST print all five OK lines (three-way release-ref agreement; manifest lockstep; live Hex+Maven 200s; computed split SHA — **record it by hand**; mirror tag absent). **No-go on any `FAIL:`, or on `points at <X>, expected <Y>`** (tag exists at a different SHA — a published tag is NEVER moved). Only then dispatch `apply=true update_main=true`. Post-check: `git ls-remote` on the mirror must show one SHA equal to the recorded split SHA.

- **D-10: The tag push is a one-way door. Rollback is forward-only.** SwiftPM caches aggressively and the script refuses by design to delete or move a published tag. If the tag lands wrong, the only remedy is `v0.2.1` — never a retag. All safety is **pre-push** (verify run, dry-run, SHA-equality short-circuit). Idempotent and safe to re-run: the tag path short-circuits with "no push needed" when the mirror tag already equals the split SHA, and fail-closes when it differs.

### Release-Job Correctness (MIRROR-02 — "in one run")

- **D-11: Pin the split to the release tag.** `publish-ios-core` currently checks out with **no `ref:`**, so `splitsh-lite` splits from `github.sha`. This is *not* a "main advances" race (checkout pins to the event SHA) — the real path is **release-please's retroactive `autorelease: pending` behavior**: if the release step fails or is cancelled, release-please creates the Release + tags on a **later push**, where `github.sha` is a newer, unrelated commit. `publish-hex` and `publish-android-core` (which uses `ref: tag_name`) would build the correct tree while `publish-ios-core` splits the **newer** tree and publishes it under tag `v0.2.0` — **wrong content under a correct-looking tag**, silently, on the one registry whose tags this project's own policy forbids moving. And this repo has already been on that recovery path.

  Fix: `ref: ${{ needs.release-please.outputs.tag_name }}`, **keeping `fetch-depth: 0`**. ⚠️ **Trap:** copying `publish-android-core`'s checkout block verbatim drops `fetch-depth: 0` and silently hands `splitsh-lite` a shallow clone.

  Corroborating evidence this is the correct discipline: `script/verify_ios_mirror_backfill.sh` **already forbids exactly this** — it rejects `main`/`master`/`HEAD`/`refs/heads/*` and demands an exact `refs/tags/ios-core-v${VERSION}` ref. The backfill script encodes the discipline the release job violates.

- **D-12: Gate the mirror on Hex only — `needs: [release-please, publish-hex]`.** Least-recoverable-registry-last. Recoverability ranking: Hex is revertible for 60 min; Maven Central is permanently immutable once PUBLISHED; the **mirror git tag is immutable by this project's own policy** — so the mirror is the *least* recoverable registry and currently races the *most* recoverable one. Gating cannot create a new bad state; it can only convert the **irreversible** one (mirror tag live for a version with no Hex package) into the **reversible** one (Hex failed, nothing published, re-run).

  ⚠️ **Do NOT add `needs: publish-android-core`.** `script/check_release_workflow_integrity.exs`'s `native_proof_decoupled` check **deliberately requires the iOS lane to not depend on Android** — coupling them would fight an encoded decision and let an Android flake block a recoverable mirror push. Gate on `publish-hex` **only**. This is safe precisely *because* the linked-versions group is asserted to be exactly `{hex, ios-core, android-core}`, so `publish-hex` cannot silently skip.

- **D-13: Make the mirror push atomic, and force-with-lease on `main`.** Today the `--dry-run` probes both refspecs in one command, but the **real push is two separate commands** (`main`, then the tag) — so a tag-push failure leaves mirror `main` advanced with **no `v0.2.0` tag**: a partial state on the exact surface MIRROR-02 exists to eliminate. Fix: one `git push --atomic mirror --force-with-lease "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v$VERSION"`. Apply the same treatment to the script's `--update-main` path.

  ⚠️ **`--force-with-lease` on `main` is REQUIRED, not optional** — per **D-08**, a bare non-forced `main` push is exactly what would non-fast-forward-reject and swallow the tag. Atomicity alone does not fix that: an atomic push that *rejects* pushes neither ref, which turns a partial state into a total release failure still misreported as a token error. The tag must be pushed even when `main` diverges. **Planner: verify `--atomic` and `--force-with-lease` compose as expected here; if they do not, push the TAG FIRST and `main` second, never the reverse.**

  Also fix the **misleading failure message**: a non-fast-forward `main` push currently reports as `MIRROR_PUSH_TOKEN cannot push …`, misattributing a lineage problem to a credential problem. This single message has now caused **two** misdiagnoses (D-01 and D-08). Name it correctly, and make it distinguish *auth failure* from *non-fast-forward* from *unknown object*.

- **D-14: `permissions: contents: read` on `publish-ios-core` is CORRECT — do not change it.** It scopes `GITHUB_TOKEN` only; the push authenticates via the deploy key. Raising it would be strictly worse. Recorded so it is not "fixed" by a well-meaning downstream agent.

### Escalation — where red actually lands (MIRROR-02 — "hard, named failure")

Per **D-02**, each mechanism below is chosen for *reach*, not for redness.

- **D-15: Extend `release-failure-alert` to the native jobs. This is the persistence surface, and it already exists.** Its `needs:` currently lists **only the ten companion jobs** — a companion failure opens a tracking issue; a mirror-push failure opens **nothing**. The surface that actually broke is the only one with no alerting (PROOF-03c was built for companions and never extended to native). Add the four native jobs + the rollup to `release-failure-alert.needs` and echo their results. This lands red in the **issues list and the maintainer's inbox** — the only surface with persistence — and reuses existing machinery instead of adding a new workflow.

- **D-16: New merge-blocking parity gate — `merge-blocking-ios-mirror-parity`.** New `script/check_ios_mirror_parity.sh` + new workflow. One `git ls-remote --tags` against the public mirror (no credential needed), set-compared against local `ios-core-v*` tags, 3 retries for network flake. Red lands on the **merge button** — unignorable, fail-closed, cannot be scrolled past. It also catches drift from causes a release-time guard structurally cannot see (manual force-push, tag deletion, a half-finished backfill).

  **Invariant (the whole design in one sentence):** *for every `refs/tags/ios-core-vX` in this repo, `refs/tags/vX` must exist on `szTheory/crosswake-shell-core-ios`.*

  ⚠️ **DEADLOCK TRAP — key on released tags, NEVER on `.release-please-manifest.json`.** The manifest bumps to X *before* the tag and publish exist, so keying on it would make the release PR block itself, permanently.

  Hermetic on ubuntu (one network call, sub-second), so it does **not** violate the v15 COLL-01 iOS-advisory precedent — that precedent is about Xcode/macOS runner instability, not about iOS-shaped concerns. Exact in-repo precedent: `merge-blocking-release-as-staleness` is likewise a state-vs-config tripwire. Auto-discovered by `script/list_merge_blocking_checks.py` (substring match on `merge-blocking`), then registered via `DRY_RUN=0 script/register_required_checks.sh` once green on main.

- **D-17: `native-release-rollup` exits 1 when `native_core != complete`.** Necessary — it currently computes `native_core=partial`, renders it to the step summary + JSON artifact, and **exits 0**, so MIRROR-02's "hard named failure" is literally unbuilt and a partial release still *claims* success. But per **D-02** this is explicitly **not trusted to reach a human**; it exists to stop the release lying, not to alarm. Write the artifact **before** exiting, and give the upload step `if: always()` or the diagnostic you just failed on is lost. (`always()` on the *job* governs running, not exit code, so the existing `native_rollup_summary` invariant still passes.)

- **D-18: `mix crosswake.release.status --live` must fail hard on a missing mirror tag** — it returns `:error`, not `:warning`. Today it reports `:warning` and `exit_code/1` returns 1 only for `:error` — so the project's own release-truth command **exits 0** while every iOS adopter's `.package(from: "0.2.0")` cannot resolve. That is a support-truth lie in the project's own voice and violates the OSS DNA's fail-closed / no-silent-fallback rule.

  ⚠️ **Split `:missing` from `:unavailable`** — `live_registry_checks/2` currently lumps them (`reject(&(&1.live.status == :ok))`). `:missing` (registry answered, tag absent) is a **definite negative** → `:error` under `release.live_registry_presence`. `:unavailable` (probe failed) is an **unknown**, not a negative → `:error` after 3 retries under a **distinct** code `release.live_registry_unverifiable`. Both exit 1 (fail-closed on unknowns), but the message must never misreport *which* failure occurred.

- **D-19: Named-failure microcopy must match existing conventions AND the existing parser.** `release_status.ex:676` parses `^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$` — emitting that exact shape makes new scripts machine-consumable by the status task **for free**. Every failure names the adopter impact and gives **one** command to fix. Target shape:
  ```
  [crosswake] FAIL: release.ios_mirror_parity - SwiftPM mirror is missing refs/tags/v0.2.0.
  [crosswake]   released here:  refs/tags/ios-core-v0.2.0
  [crosswake]   mirror state:   szTheory/crosswake-shell-core-ios has no refs/tags/v0.2.0
  [crosswake]   adopter impact: .package(url: "…/crosswake-shell-core-ios", from: "0.2.0")
  [crosswake]                   CANNOT RESOLVE. Every iOS adopter of 0.2.0 is broken right now.
  [crosswake] What to do next:
  [crosswake]   gh workflow run ios-mirror-backfill.yml -f version=0.2.0 \
  [crosswake]     -f release_ref=refs/tags/ios-core-v0.2.0 -f apply=true
  [crosswake] This gate stays RED and merges stay BLOCKED until the mirror tag exists.
  ```

- **D-20: Every fix gets a matching invariant in `script/check_release_workflow_integrity.exs`.** This is the repo's established pattern — every release invariant has a checker function — and it is what stops the fix from regressing. D-11 in particular needs a new `release.ios.checkout_ref_pinned` check asserting **both** `ref: tag_name` **and** `fetch-depth: 0`. Extend `test/crosswake/proof/phase142_release_integrity_test.exs` with decoys, per house style.

### Sequencing (load-bearing — the two halves are NOT independent)

- **D-21: Strict order. There are TWO independent armed fuses (D-01 credential, D-08 lineage) and fixing only one still leaves the next release broken.** Per D-01.3 the backfill workflow shares the hijacked checkout, so attempting `--apply` before the transport fix would fail and re-present as a token problem. Per D-08, fixing the credential without re-baselining `main` leaves a non-fast-forward reject that *also* reports as a token problem.

  1. **Transport fix** (deploy key + `persist-credentials: false`) in `release-please.yml`, `ios-mirror-backfill.yml`, and the script. — *defuses D-01*
  2. **Human mints the deploy key** (D-05). One time, four commands.
  3. **Backfill `apply=false`** → now carries the dry-run push probe (D-07) → **proves write scope**. This is the fire drill, and it is the first time the CI push credential has ever been exercised.
  4. **Backfill `apply=true`** → pushes `refs/tags/v0.2.0`. **MIRROR-01 done.** (Tag push is unconstrained by the lineage problem.)
  5. **Re-baseline mirror `main`** onto the splitsh-lite lineage, `--force-with-lease` against `6417ae65`, preserving the `v0.1.2` tag and verifying it still resolves. — *defuses D-08*
  6. **Durable guards** (D-11 … D-20). **MIRROR-02 done.**

  Steps 4 and 5 are **separately approved** — 4 is a one-way door (a public tag), 5 is reversible (leased force-push). Do not bundle them behind a single `--apply`.

  Step 6 is independent of 1-5 and may land in either order: the backfill script already splits from `refs/tags/ios-core-v0.2.0` and already does the right thing, so D-11 only changes *future* releases. **But D-13's `--force-with-lease` fix must land before the next real release, or D-08's fuse re-arms.**

  **Definition of done for the phase:** a `git ls-remote` on the mirror shows `refs/tags/v0.2.0` present and equal to the splitsh-lite split SHA; `v0.1.2` still resolves; `mix crosswake.release.status --live` exits 0; and the parity gate is green and registered as a required check.

### Claude's Discretion

- Exact file/function decomposition of `script/check_ios_mirror_parity.sh` and whether the `--deep` (splitsh SHA-identity) mode is included in v1 of the script.
- Whether the SSH agent is wired via `webfactory/ssh-agent` (pinned) or an inline `GIT_SSH_COMMAND` — planner picks based on the repo's existing action-pinning discipline.
- Number of plans and their split. The transport+backfill half and the guards half are natural plan boundaries.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — MIRROR-01, MIRROR-02 (the two requirements this phase owns); also documents why MIRROR blocks MENU.
- `.planning/ROADMAP.md` — v20.0 phase list; Phase 153 as prerequisite for 156.
- `.planning/STATE.md` — v20.0 roadmap decisions (locked 2026-07-12).

### Research (read §3 and §5 of RELEASE-STRATEGY, but see D-01 — its root-cause diagnosis is WRONG)
- `.planning/research/v20/RELEASE-STRATEGY.md` §3 "SEED-003 — iOS mirror push token", §5 "Release choreography" — correct on *land it first* and on *the tag push is one-way*; **its "fine-grained PAT" root-cause diagnosis is superseded by D-01.**
- `.planning/seeds/SEED-003-ios-mirror-push-token.md` — the original incident record. **Its "What To Do" step 1 (rotate the PAT) is superseded by D-01.** Treat as history, not instruction.

### The machinery being changed
- `.github/workflows/release-please.yml` — `publish-ios-core` (386-450), `publish-android-core` (452-479), `clean-room-proof-ios` (481-531), `native-release-rollup` (593-701), `release-failure-alert`, `android-publish-fire-drill` (703+).
- `.github/workflows/ios-mirror-backfill.yml` — the `workflow_dispatch` recovery lane (inputs: version / release_ref / apply / update_main).
- `script/verify_ios_mirror_backfill.sh` — 252 lines; `validate_inputs` → `verify_release_refs` → `verify_manifest_versions` → `verify_live_registries` → `compute_split_sha` → `verify_or_apply_mirror`.
- `script/check_release_workflow_integrity.exs` — the release invariant checker; `native_proof_decoupled` (⚠️ D-12), `mirror_token_preflight`, `mirror_token_write_preflight`, `native_status_artifact`.
- `lib/crosswake/release_status.ex` — `maybe_ios_mirror_live/3` (772-787), `live_registry_checks/2` (462-491), `exit_code/1` (626-628), the `[crosswake] OK|FAIL: <id> - <detail>` parser (676).
- `script/list_merge_blocking_checks.py`, `script/register_required_checks.sh` — how a new `merge-blocking-*` lane gets discovered and registered.
- `test/crosswake/proof/phase142_release_integrity_test.exs`, `test/crosswake/proof/phase145_ios_backfill_script_test.exs` — existing structural proofs to extend.
- `.release-please-manifest.json`, `release-please-config.json` — linked-versions group `{hex, ios-core, android-core}`; all three at `0.2.0`.

### Doctrine
- `prompts/crosswake-elixir-oss-dna.md` §3 "Proof lanes are part of the product", §4 "Release truth matters", and the "Footguns To Avoid" list — the source of the fail-closed / no-silent-fallback / proof-carries-the-claim rules that D-15..D-20 implement.
- `guides/compatibility.md` — rebuild-class vocabulary (`docs-only` / `core-only` / `native or companion rebuild required`).

### Prior-art precedent (from research; cite, don't re-derive)
- Kubernetes `publishing-bot` — monorepo→split-repo mirror with **periodic reconciliation + one canonical re-opened issue**. The "red must reach an inbox" pattern behind D-15.
- Symfony / Laravel / Doctrine subtree splits — split is a **pure function of the release tag**, never the branch tip (D-11); mirrors are marked `[READ ONLY]` with Issues disabled.
- `danharrin/monorepo-split-github-action` — avoids D-01 by pushing from a **fresh temp clone**, so the workspace extraheader never leaks in. Confirms the two valid fixes are *change transport* or *don't push from the checked-out workspace*.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`script/verify_ios_mirror_backfill.sh`** — already does the right verification (three-way release-ref agreement, manifest lockstep, live Hex+Maven 200s, fail-closed on tag mismatch, `--force-with-lease` + `merge-base --is-ancestor` on main). Needs only the D-07 dry-run probe and the D-13 atomic push. **Do not rewrite it.**
- **`.github/workflows/ios-mirror-backfill.yml`** — the dispatch lane already exists and defaults to verify-only. With D-07 it *becomes* the iOS fire-drill; no new job needed.
- **`release-failure-alert`** — the issue-opening machinery already exists (D-15 extends `needs:`, does not build a new workflow).
- **`release_status.ex:676` `[crosswake] FAIL: <id> - <detail>` parser** — a new script emitting that shape is machine-consumable by the status task for free (D-19).
- **`merge-blocking-release-as-staleness`** — the exact structural precedent for D-16 (a state-vs-config tripwire as a required check).

### Established Patterns
- **Every release invariant has a checker function** in `check_release_workflow_integrity.exs`, with decoy tests in `phase142_release_integrity_test.exs`. D-20 follows this.
- **Merge-blocking hermetic lanes vs advisory device/toolchain lanes** — the iOS *toolchain* lanes are advisory because of macOS/Xcode runner instability (v15 COLL-01). A `git ls-remote` parity check is hermetic on ubuntu and is therefore correctly merge-blocking (D-16).
- **Fail-closed, never move a published tag** — encoded in both the release job and the backfill script. Preserve it.
- **Named failures with one next command** — `[crosswake] FAIL: … What to do next: …`.

### Integration Points
- `publish-ios-core` ← the deploy key, the tag-pinned checkout, the Hex gate, the atomic push.
- `release-failure-alert.needs` ← the four native jobs + rollup.
- `script/list_merge_blocking_checks.py` ← auto-discovers the new parity lane by name substring.
- `.git/config` extraheader ← the hijack vector; neutralized by `persist-credentials: false` + SSH.

### Live state verified during discussion (2026-07-12)
- Mirror tags: **`v0.1.2` only.** Mirror `main` == `HEAD` == `v0.1.2` == `6417ae6543219f1c35be120766827503eaa8ceea`. Zero mirror-only commits.
- Monorepo: `ios-core-v0.2.0`, `hex-v0.2.0`, `android-core-v0.2.0` all exist locally. Manifest has core/ios/android at `0.2.0`. Hex + Maven live at `0.2.0`.
- `gh secret list`: `MIRROR_PUSH_TOKEN` set 2026-06-17, never rotated since the 2026-07-03 403.
- `grep -rn persist-credentials .github/workflows/` → **no matches.**

</code_context>

<specifics>
## Specific Ideas

- The maintainer handoff must be **four commands, no browser, one time, never again** (D-05). Any credential design requiring an annual re-mint is explicitly rejected as a recurring-intervention tax.
- The parity gate's failure output must state **adopter impact in adopter language** (`.package(url: …, from: "0.2.0")` CANNOT RESOLVE), not internal job names — the reader is the maintainer at 2am, and the message must make the stakes obvious without a click-through.
- Consider marking the mirror repo `[READ ONLY] Subtree split of packages/crosswake-shell-core-ios` with Issues disabled, per Symfony/Laravel convention. **Do NOT archive it** — an archived repo is read-only to pushes too, which would brick the release job.

</specifics>

<deferred>
## Deferred Ideas

- **Credential-expiry preflight lane (weekly cron)** — probing `github-authentication-token-expiration` for all retained PATs. Deferred: the deploy-key choice (D-03) removes the *mirror* from the expiry problem entirely, which is this phase's concern. The remaining tokens are a separate surface. **Worth a seed.**
- **`RELEASE_PLEASE_TOKEN`'s silent fallback** — `release-please.yml:92` does `|| github.token`, which degrades **quietly and wrongly** rather than failing closed, directly violating the OSS DNA's no-silent-fallback rule. Real, but not MIRROR-scoped. **Worth a seed.**
- **GPG signing-key expiry is unmonitored** (`ORG_GRADLE_PROJECT_signingInMemoryKey`) — the true Android analogue of the mirror-token risk: an expired key fails Maven Central validation *after* Hex has already published, breaking lockstep exactly the way the mirror did. **Worth a seed.**
- **SHA-pin `actions/upload-artifact@v4`** — the only unpinned action in `release-please.yml`. Not free (`native_status_artifact` asserts the literal string `actions/upload-artifact@v4`, so pinning requires a lockstep checker edit). Supply-chain hygiene, not MIRROR-02 correctness.
- **Weekly cron reconciliation lane** (k8s publishing-bot pattern) — explicitly rejected for now: GitHub auto-disables scheduled workflows after 60 days of repo inactivity, so a cron **fails OPEN** — a *new* silent-failure surface, which is the exact bug class being fixed. The PR/push-triggered parity gate (D-16) covers every window that matters for an active repo.
- **Standalone `ios-mirror-fire-drill` job** — unnecessary. D-07 makes the existing `apply=false` dispatch serve this purpose with zero new recurring surface.
- **`ios_core_tag_name` output + in-workflow three-way tag agreement assertion** — the backfill script already asserts it and the linked-versions group guarantees it.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 153-iOS Mirror Unblock*
*Context gathered: 2026-07-12*
