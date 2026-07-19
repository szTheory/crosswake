---
phase: 153
slug: ios-mirror-unblock
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-13
---

# Phase 153 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) + bash-invoked structural assertions (existing pattern: `script/check_release_workflow_integrity.exs` shelled to from `phase142_release_integrity_test.exs`) |
| **Config file** | `mix.exs` (existing — no new framework config needed) |
| **Quick run command** | `mix test --only phase153_ios_mirror_unblock` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds (quick) / ~90 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --only phase153_ios_mirror_unblock` (fast, hermetic, bare-repo-fixture-based — covers the atomic-push/lease logic, the highest-risk surface)
- **After every plan wave:** Run `mix test` + `elixir script/check_release_workflow_integrity.exs`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD (planner assigns) | 01 | 1 | MIRROR-02 | T-153-01 (credential hijack) | `persist-credentials: false` on every checkout that later adds a cross-repo remote; SSH transport structurally immune to `http.*.extraheader` | structural | `elixir script/check_release_workflow_integrity.exs` | ❌ W0 (new scanner check) | ⬜ pending |
| TBD | 01 | 1 | MIRROR-02 | T-153-02 (secret leakage) | Private key never `cat`/`echo`'d in any step; loaded via `webfactory/ssh-agent` (SHA-pinned) | structural | `elixir script/check_release_workflow_integrity.exs` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | MIRROR-01 | T-153-04 (stale lease) | Atomic + explicit-lease push lands both refs when lineage diverges; fails the WHOLE txn on stale lease (no partial apply) | unit (bare-repo fixtures) | `mix test --only phase153_ios_mirror_unblock` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | MIRROR-01 | T-153-03 (tag move) | Existing tag CANNOT move inside the atomic push — lease scoped to `main` alone leaves the tag refspec genuinely unforced | unit (bare-repo fixtures) | `mix test --only phase153_ios_mirror_unblock` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | MIRROR-01 | — | `apply=false` dry-run push probe proves WRITE scope (not just read — read succeeds anonymously on a public repo) | structural + CI dispatch | `elixir script/check_release_workflow_integrity.exs` asserts probe present in verify branch; real proof = `gh workflow run ios-mirror-backfill.yml -f apply=false` | ❌ W0 | ⬜ pending |
| TBD | 02 | 2 | MIRROR-02 | — | One run publishes Hex, Maven, mirror together — `needs: [release-please, publish-hex]`, NOT `publish-android-core` | structural | `elixir script/check_release_workflow_integrity.exs` | ✅ pattern exists (`workflow_native_proof_decoupled`) — needs new gate condition | ⬜ pending |
| TBD | 02 | 2 | MIRROR-02 | — | `ref: tag_name` AND `fetch-depth: 0` both present on `publish-ios-core` checkout (D-11 — the shallow-clone trap) | structural | `elixir script/check_release_workflow_integrity.exs` (new `release.ios.checkout_ref_pinned`) | ❌ W0 | ⬜ pending |
| TBD | 02 | 2 | MIRROR-02 | — | Failure reaches a human: `release-failure-alert.needs` includes the 4 native jobs + rollup | structural | ExUnit assertion, `phase142_release_integrity_test.exs` style | ❌ W0 | ⬜ pending |
| TBD | 02 | 2 | MIRROR-02 | — | Merge-blocking parity gate: for every local `ios-core-vX`, mirror has `refs/tags/vX` | integration (hermetic — one unauthenticated `git ls-remote`, sub-second) | the new workflow in CI; locally `script/check_ios_mirror_parity.sh` | ❌ W0 (new script + workflow) | ⬜ pending |
| TBD | 02 | 2 | MIRROR-01/02 | — | `:missing` (definite negative → `release.live_registry_presence`) split from `:unavailable` (unknown → `release.live_registry_unverifiable` after 3 retries); BOTH exit 1 | unit (existing `probes` map injection seam) | `mix test test/crosswake/release_status_test.exs` | ❌ W0 for the split; ✅ existing test pattern to extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` — bare-repo fixtures for the three push scenarios: (a) atomic+lease push with off-lineage `main` **succeeds**; (b) atomic+lease push with a **stale lease** fails the whole transaction and the tag is **absent** afterwards; (c) an attempt to **move an existing tag** inside the atomic push is **rejected** and the tag is unchanged
- [ ] `script/check_ios_mirror_parity.sh` — does not exist yet
- [ ] `.github/workflows/merge-blocking-ios-mirror-parity.yml` — does not exist yet (name must contain `merge-blocking` for `script/list_merge_blocking_checks.py` substring auto-discovery)
- [ ] New/updated scanner checks in `script/check_release_workflow_integrity.exs`: SSH transport (`persist-credentials: false` + deploy-key wiring — **replaces** `mirror_token_preflight` / `mirror_token_write_preflight`, which reference a secret being retired), `release.ios.checkout_ref_pinned` (D-11/D-20), updated `ios_backfill_no_default_main_force` substrings for the new explicit-lease form, `release-failure-alert.needs` includes native jobs
- [ ] ExUnit test for `Crosswake.ReleaseStatus.live_registry_checks/2`'s new `:missing`/`:unavailable` split — **planner must first locate the existing test file for this module** (likely `test/crosswake/release_status_test.exs`; not confirmed during research)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Deploy key minted and registered | MIRROR-01/02 | Requires a human with `admin:public_key` scope on the mirror repo. **Live-verified during research: the current `gh auth` session LACKS this scope** — D-05's `gh auth refresh` caveat is confirmed necessary, not hypothetical. One time, never again (deploy keys do not expire — this is the whole point of D-03). | Run the four D-05 commands: `ssh-keygen -t ed25519 …` → `gh repo deploy-key add … --allow-write` → `gh secret set MIRROR_DEPLOY_KEY` → `rm -P` the local key halves. Prefix with `gh auth refresh -h github.com -s admin:public_key`. |
| `apply=false` fire-drill dispatch (D-07/D-09) | MIRROR-01 | Genuinely CI-only. The bug being repaired is literally *"CI did not push the tag"* — a laptop push would leave the CI credential unexercised, reproducing the original bug's precondition. This dispatch IS the missing proof. | `gh workflow run ios-mirror-backfill.yml -f version=0.2.0 -f release_ref=refs/tags/ios-core-v0.2.0 -f apply=false`. Run MUST print all five OK lines. **Record the computed split SHA by hand.** |
| Go/no-go gate before `apply=true` (D-09) | MIRROR-01 | Irreversible go-decision requiring human judgment. | **No-go on any `FAIL:`**, or on `points at <X>, expected <Y>` (a published tag is NEVER moved). |
| `apply=true` tag backfill (D-21 step 4) | MIRROR-01 | **One-way door.** SwiftPM caches aggressively; the script refuses by design to delete or move a published tag. Rollback is forward-only (`v0.2.1`, never a retag). All safety is pre-push. | Only after the `apply=false` run is clean. Post-check: `git ls-remote` on the mirror shows one SHA equal to the recorded split SHA. |
| Mirror `main` re-baseline (D-21 step 5) | MIRROR-01 | Separately approved from step 4 — reversible (leased force-push), but must NOT be smuggled inside `--apply`. | `--force-with-lease` against the known lease `6417ae65`. **`v0.1.2` tag is never touched** — verify it still resolves afterwards. |
| Register the new parity lane as a required check | MIRROR-02 | Requires repo-admin rights; done once the lane is green on `main`. | `DRY_RUN=0 script/register_required_checks.sh` |

*Everything else has automated verification.*

---

## Sampling-Rate Framing — would this have caught BOTH armed fuses?

- **D-01 (credential hijack): YES, hermetically.** A structural scanner assertion that `persist-credentials: false` is present on every checkout in any job that later does a cross-repo `git push` is a pure YAML/text check. It was addable at any point in the last 3 months and would have caught this before the release. This phase adds it (D-04 + D-20).
- **D-08 (lineage divergence): NOT hermetically — and that is the real gap-closer.** Nothing offline could have caught it; it required comparing the mirror's actual remote state (`git ls-remote`) against locally-computable splitsh-lite output. That is exactly what D-16's merge-blocking parity gate now does **on every PR**, not only at release time.
- **What still slips through (intentionally out of scope):** a human manually force-pushing garbage onto the mirror's `main` between releases. `main` has no parity check of its own — only tag existence is checked. This is acceptable because **SwiftPM resolves tags, never branches**, so a corrupted `main` has no symptom an adopter would hit. Tags remain structurally protected (D-10/D-16). Flagged as a deliberate scope boundary, not an oversight.
- **Recurring-intervention audit (project goal: ZERO):** the deploy key does not expire (D-03), the parity gate is PR-triggered rather than cron (a cron would fail OPEN — GitHub auto-disables scheduled workflows after 60 days of inactivity, which is the exact bug class being fixed). No step in this phase creates a recurring manual tax.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
