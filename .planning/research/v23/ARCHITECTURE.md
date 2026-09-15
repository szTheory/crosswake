# Architecture: v23.0 Release Pipeline Repair & Proof-Lane Truth

**Domain:** integration design for the Crosswake release-authority graph
**Researched:** 2026-09-15
**Scope:** how D1-D6 (TODO-009/SEED-017, TODO-011/SEED-004, TODO-012) integrate with the
existing Phase 168 release-candidate architecture without weakening it.

## Recommended Architecture (unchanged shape, generalized parameters)

The existing shape is correct and stays:

```
approved-release-guard (per-release identity: head/tree/base/receipt)
        │  outputs: linked_release, approved_head, approved_tree, merge_oid, candidate_receipt
        ▼
release-please (cuts tags/versions; per-component outputs)
        │
        ├─▶ publish-hex / publish-ios-core / publish-android-core   (irreversible, root-linked)
        │        │
        │        ▼
        │   clean-room-proof-ios / -android  (adopter-shaped resolvability)
        │        │
        │        ▼
        └─▶ exact-public-proof  (byte-exact post-publish truth)
                 │
                 ▼
        linked-release-rollup (Workflow.rollup!/1 — fail-closed)

publish-hex-<companion>  (independent, per-component gate)
        │
        ▼
clean-room-proof-<companion>  (independent adopter-shaped proof, advisory today)
```

Today this graph is parameterized by exactly one constant, `"0.2.1"`, injected in five places
across two axes that must be split: **which version is gated** (must generalize) and **which
merge is authorized to publish** (must stay exact). D1-D6 below change what flows through the
existing edges; they do not add new top-level stages.

### Component Boundaries (new vs modified)

| Component | New/Modified | Responsibility | Communicates With |
|---|---|---|---|
| `approved-release-guard` job | Modified (D1) | Produces per-release identity — now version-parametric | `release-please` (its outputs consumed downstream), `publish-*`, `exact-public-proof` |
| `Crosswake.ReleaseCandidate.Workflow` | Modified (D1) | `@coordinates`/`@dependencies` become functions of version, not module attributes | `evaluate_cli!/0`, rollup consumers |
| `script/guarded_hex_publish.sh` | Modified (D1) | Already takes version as an argument — becomes the identity carrier's consumer, unchanged in shape | `publish-hex*` jobs |
| `verify_companion_cleanroom.sh` (matrix mode) | Modified (D2) | Per-package `candidate_ref`/version resolution instead of one shared ref | `Crosswake.ReleaseCandidate.Cleanroom`, Hex registry |
| `Crosswake.ReleaseCandidate.Cleanroom` | Modified (D2) | `validate_approved_artifacts!/1` accepts per-package refs | clean-room script, `exact-public-proof` |
| `exact-public-proof` job | Modified (D3) | `needs:` restructured to converge both publish paths | `publish-*`, a new **recovery-completion signal** |
| new: recovery-completion marker | New (D3) | Records that a release published via exact-ref recovery, keyed by version+approved_head | `guarded_hex_publish.sh` (recovery path), `exact-public-proof` gate |
| `verify_companion_cleanroom.sh` Step 4/host | Modified (D4) | Realistic host: real route + `mix crosswake.install` | `mix crosswake.doctor`, clean-room proof |
| `script/check_release_workflow_integrity.exs` | Modified (D5) | Retire `release.version_weld.gates_match_declared_version`; add `release.publish_gate.no_bare_version_literal` structural check | CI, `Crosswake.ReleaseStatus` |
| `Crosswake.ReleaseStatus.scanner_ids_result/2` | Modified (D6) | Propagate failing check's own message instead of collapsing to "missing IDs" | any `mix crosswake.release.status` consumer, CI summaries |

---

## D1 — Split version from authority (TODO-009 / SEED-017)

**Staff architect lens.** The bug is a coupling defect: one literal (`"0.2.1"`) is asked to
prove two unrelated properties — "this is the version being released" and "this is the
approved transaction." Fix by naming two things instead of one and threading both through
job outputs, which is already the graph's idiom (`approved-release-guard.outputs.*`).

**Where the per-release identity comes from.** It already exists and is already exact:
`approved-release-guard` outputs `approved_head`, `approved_tree`, `merge_oid`,
`candidate_receipt` (`release-please.yml:36-45`). This *is* the per-release identity. The bug
is that four downstream `if:` conditions additionally AND it with a version literal
(`release-please.yml:223`, `525`, `571`, `728`) instead of trusting `linked_release == 'true'`
alone plus the receipt's own bound identity.

**The design:** delete the `needs.release-please.outputs.version == '0.2.1'` clause from all
four `if:` conditions. Do not simply delete it and stop (TODO-009 explicitly warns against
this) — replace the *version-exactness* property it accidentally provided with a property that
belongs where exactness is actually enforced: inside `approved-release-guard`'s receipt
validation, and inside `Workflow.rollup!/1`'s per-release coordinate construction.

1. **`approved-release-guard`** already binds `approved_head`/`approved_tree`/`base` from the
   receipt (`release-please.yml:114-116`). Add one more binding: the receipt's
   `identity.bound.version` (a field the candidate-receipt producer — the "iOS mirror
   authority" trusted workflow — must now stamp in, since D1 needs *a version* bound into the
   exact same receipt that already binds head/tree/base). Emit it as a new job output,
   `approved_version`. This makes the version part of the *exact receipt*, not a workflow
   literal — the receipt was generated for one specific version's candidate run, so this is a
   faithful generalization, not a new trust boundary.
2. **Publish jobs gate on:** `linked_release == 'true'` AND
   `needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version`.
   This is the crucial invariant: the version is no longer a constant, but it must still equal
   *the version the approval was for*. A release-please run proposing `0.2.3` while the
   approved receipt was captured for `0.2.2` fails closed exactly like today's weld failed
   closed on `0.2.2 != 0.2.1` — except now the comparison is receipt-to-manifest, not
   literal-to-manifest, so it is correct for every version, not just one.
3. **`Crosswake.ReleaseCandidate.Workflow`** (`workflow.ex:7-11`): `@coordinates` becomes a
   function `coordinates(version)` returning the three coordinate strings interpolated with the
   real version, not a module attribute frozen at `0.2.1`. `rollup!/1`'s input map gains a
   required `:version` key (`exact_semver!/1` validator, following the existing `exact_hex!/2`
   pattern) alongside `approved_ref`/`candidate_receipt`. `@dependencies`/`@children` stay
   structural (they describe the *shape* of the graph, not a version) and are unchanged.
4. **On a re-run:** the receipt artifact is named
   `phase168-candidate-receipt-${approved_head}` — already keyed by head, not version, so
   re-running the same approved merge is already idempotent. Adding `approved_version` to the
   receipt does not change re-run semantics: the same head always re-derives the same version
   binding. A *second, different* release (new head, new version) produces a new receipt
   artifact under its own head-keyed name — no collision with the prior release's proof
   artifacts, which is already true today (`exact-public-proof-0.2.1`,
   `linked-release-status-0.2.1` artifact names are also version-suffixed and must become
   `-${version}` interpolated, not dropped — see conflict note below).

**Security/supply-chain lens.** The threat this must not reopen: an attacker (or a confused
release-please run) proposing version `X` while an *unrelated* approved receipt for version `Y`
is still the most recent valid artifact. The `approved_version == release-please.version` check
above is exactly the mitigation — it is the same "exact equality, not a floor" doctrine Phase
168 already uses for head/tree, just extended one field.

**SRE lens — re-run/partial publication.** `rollup!/1` remains fail-closed regardless (D1
doesn't touch that function's `skipped != success` logic). The blast radius of getting D1 wrong
is a *specific* version-confusion publish; the specific mitigation (binding version into the
already-exact receipt) keeps blast radius at "this release doesn't tag," never "the wrong
release publishes."

**Elixor/OTP idiom.** Keep the identity-binding logic in `Workflow` (pure functions, testable
without CI) rather than spreading version-equality checks across YAML `if:` strings — YAML
should express *which inputs feed which comparisons*, Elixir should express *what the
comparison means*. This mirrors how `rollup!/1` already centralizes the fail-closed semantics
instead of letting each job compute its own partial/complete label.

**Comparable systems.** This is the cargo-dist / goreleaser pattern of a "release plan" object
computed once and referenced by SHA/ID everywhere downstream, and it is exactly sigstore's
transparency-log idiom: the log entry (here, the candidate receipt) binds subject identity
(head/tree) AND the artifact's claimed version together, so verifying "this artifact matches
its log entry" is a single equality check rather than trusting either fact in isolation.

---

## D2 — Per-package approved refs (TODO-012)

**Staff architect lens.** TODO-012's own analysis is correct and its recommendation (2) is the
right one: replace the single `candidate_ref` with one approved ref per manifest entry. This
directly matches D-15/D-16 (companions version independently) and the runbook's explicit
statement that companions are "evidence, not members of the linked approval."

**Manifest schema change.** Today `verify_companion_cleanroom.sh:207`:
```
candidate_ref=$(jq -er 'map(.candidate_ref) | unique | if length == 1 then .[0] else error(...) end' "$MATRIX_APPROVED_MANIFEST")
```
requires one ref shared across all six `{package, version, candidate_ref, ...}` entries. Change
the manifest schema so **each entry carries its own `candidate_ref`** (it may already structurally
have a `candidate_ref` field per entry — the bug is the `unique | length == 1` collapse, not a
missing field). The fix is almost entirely a *deletion*: drop the `unique`/`length == 1`
collapse and instead assert `candidate_ref != null` per-entry via `jq -er '.[] | .candidate_ref'`
inside `matrix_fetch_public_family`'s per-package loop (`verify_companion_cleanroom.sh:209-244`),
threading the resolved per-package `candidate_ref` alongside `version` into
`Crosswake.ReleaseCandidate.Artifact.inspect_cli!/1`'s existing per-package argument list
(it already takes `package version tarball unpacked_root outer_checksum outer_kind` per entry at
line 243 — add `candidate_ref` as a seventh positional field here, or better, pass it through
the artifact-args tuple so `Artifact` records provenance per package rather than the script
computing a single shared ref up front).

**Migration path.** The manifest producer is `approved-release-guard` (for core) plus whatever
currently stamps `candidate_ref` for companions — today it is a single value copied onto all six
rows. Change the producer to stamp **the exact head each package's own release-please tag was
cut from** (available from `needs.release-please.outputs.<pkg>_tag_name` → resolvable to a SHA
via `git rev-list -n1 <tag>`), not the core's `approved_head`. This is a strictly additive
manifest-schema change (new distinct values in an already-present column), so no consumer needs
a version-flag; there is no "old manifest shape" to keep reading because this proof has never
gone green with the old shape (TODO-012's own finding — it literally cannot produce a passing
manifest today).

**`cleanroom.ex:244-305` (`validate_public_artifacts!/3`) change.** This function does not
reference `candidate_ref` at all today — it only compares `metadata_digest`/`payload_digest`
against `approved` (built by `validate_approved_artifacts!/1`, `cleanroom.ex:218-242`). The
actual coupling to "one candidate" lives in `validate_approved_artifacts!/1`'s implicit
assumption (enforced by the *shell script*, not this function) that one ref produced the whole
manifest, plus the harder assertion at `cleanroom.ex:236`:
```elixir
Map.fetch!(by_package, "crosswake").version == "0.2.1"
```
This is a second, Elixir-side version weld and must be removed as part of D1/D2 together — it
hardcodes exactly the same defect TODO-009 targets in YAML, just one layer down. Replace it with
"core's version is *some* version consistent with the same receipt's `approved_version`,"
threaded in as a parameter to `evaluate_public!/1`/`evaluate!/1`, not a module constant.

**Byte-exact digest equality is preserved exactly.** D2 only changes *which historical build*
each package is compared against (its own release commit instead of a shared one); the
comparison itself (`digest_mismatch` at `cleanroom.ex:298-300`) is untouched. This is the load-
bearing invariant the quality gate calls out, and D2 is designed specifically to make that
invariant *satisfiable* rather than to loosen it — TODO-012 shows today it is unsatisfiable by
construction, which is worse than loose.

**Consistency with D-15/D-16.** Independent companion versioning was *already* the release-please
config's reality (each companion is its own release-please component, publishing off its own
tag). D2 makes the *proof* match a design that has existed since Phase 137-139; it does not
introduce independence, it stops asserting a false linkage.

**Release engineer / security lens.** Threat model: could per-package refs let an attacker
smuggle an unapproved package build past the proof by picking a favorable-but-wrong ref for one
package? No — the digest check still compares against **Hex's own served tarball** (fetched
live in `matrix_fetch_public_family`), so the ref only determines what "approved" means for the
purpose of *this run's evidence trail*, not what bytes are accepted. This is analogous to npm's
provenance attestations: each package version carries its own build-provenance statement; a
family of packages is not required to share one.

**Comparable systems.** Maven Central staging repositories and npm provenance both attest
per-artifact, not per-release-train; Nix/Bazel content addressing keys purely by content hash
and treats "which commit built this" as metadata, not as part of the trust boundary — the same
shape D2 adopts here (trust = digest match; ref = audit trail).

---

## D3 — Recovery-path convergence (TODO-009 second gap)

**Staff architect lens.** The defect is a `needs:` graph that makes proof reachability
contingent on *how* publication happened, when the proof's entire purpose is to be indifferent
to how publication happened — it is supposed to ask "is what's on the registry byte-identical to
what was approved," which is equally answerable (and equally necessary) whether `publish-hex`
ran normally or a human ran `guarded_hex_publish.sh` by hand during a recovery.

**Design: converge on a version-keyed "publication happened" signal, not a job-success signal.**
Introduce a **recovery-completion record** — a small JSON artifact, `publication-record-<pkg>-
<version>.json`, written by *both* paths:

1. **Normal path:** `publish-hex`/`publish-ios-core`/`publish-android-core` write it as their
   final step (in `guarded_hex_publish.sh` and the two native publish scripts), containing
   `{package, version, coordinate, approved_head, published_at, mode: "workflow"}`.
2. **Recovery path:** the *same* `guarded_hex_publish.sh` (and native equivalents) already run
   during manual recovery — they are scripts, not workflow-only logic (`release-please.yml:257`
   invokes the identical script the recovery runbook invokes by hand). Recovery differs only in
   *who* triggers it (an operator via `workflow_dispatch` or a documented manual runbook step),
   not in *what* runs. Make the recovery entrypoint a `workflow_dispatch`-triggered job
   (`recovery-hex-publish`, mirroring `android-publish-fire-drill`'s dispatch-only pattern
   already in this file) that calls the *identical* `guarded_hex_publish.sh` with the *identical*
   receipt-derived identity arguments, and writes the identical record artifact.

**`exact-public-proof`'s `needs:` becomes:**
```
needs: [approved-release-guard, release-please]
if: needs.approved-release-guard.outputs.linked_release == 'true'
    && <version-parity check from D1>
```
— i.e., it stops depending on `publish-hex`/`publish-ios-core`/`publish-android-core` job
*success* and instead depends only on the **release-please tag having been cut** plus the
approval being linked. Internally, its first step becomes "assert a publication record exists
for this exact `{package, version, approved_head}` triple" (checking for the artifact from
either the normal or recovery path) **before** attempting the Hex/SwiftPM/Maven re-fetch that
`verify_companion_cleanroom.sh --source-mode exact-public` already performs. If no record
exists yet (publication hasn't happened by either path), the proof job fails closed with a named
diagnostic ("no publication record for 0.2.2 — publish has not run through either path") rather
than silently skipping via `needs:`.

**This does not make the proof skippable** — the quality gate's explicit requirement. Today it
is *conditionally reachable* (skippable via `needs:` non-satisfaction, which is silent);
converging on an explicit precondition check makes non-readiness a **loud failure** instead of a
graph-topology skip, which is strictly stronger, matching the "silence is never success"
doctrine `Workflow.rollup!/1` already enforces for the rest of the graph.

**SRE lens — blast radius of the one-way door.** The recovery path is precisely the case where
something already went wrong once; converging the proof onto it is the highest-value fix in this
milestone, because TODO-011's evidence shows every real release so far has hit at least one
irregularity, and 0.2.1 itself shipped by recovery. A proof lane that only exercises the happy
path is optimized for the case that has never actually occurred.

**Comparable systems.** This is the same lesson Oban's and Ecto's release tooling encode
structurally: publish scripts are idempotent, callable both from CI and by a human, and proof/
verification steps are keyed on *registry state*, never on *which job ran*. Goreleaser's
`--skip-publish`/manual-continuation model is the same shape — the "did this happen" check reads
the actual release artifact, not the CI job graph.

---

## D4 — Realistic clean-room host (TODO-011 / SEED-004)

**Staff architect lens.** The harness's own comment ("Open Question 1... no routes required for
doctor smoke") is the bug's origin — an assumption recorded and never revisited. `doctor`'s
`manifest_contract` check is correct to fail: a routeless router genuinely cannot produce a
`:routes` section, and no adopter ships that. Fix the harness's fidelity to match `doctor`'s
actual (correct) contract, per TODO-011's own recommended option (1).

**What the host declares, in order:**

1. **A real Crosswake-owned route**, not a plain `PageController` stub. Concretely, add one
   `get "/", PageController, :home, metadata: [crosswake: [...]]` (or the smallest route-policy
   declaration `Crosswake.RoutePolicy` accepts) to the generated router *before* compiling —
   i.e., Step 4's router-writing stage gains one real policy-annotated route rather than zero
   routes. (Interestingly, the option-based `--source-mode` matrix path already added exactly
   this at lines 388-412 of the current script for the *matrix* profiles — `matrix_write_host`
   patches `get "/", PageController, :home, metadata: %{crosswake: [...]}}`. The legacy
   positional-argument path used for real per-companion release jobs — Steps 1-9 — is the one
   that still has the routeless stub at line 1140-1145. **D4 is therefore "backport the matrix
   path's already-working router fix to the legacy per-companion path,"** not a new design.)
2. **Run `mix crosswake.install` before `doctor`.** `doctor.ex:234-277`'s
   `load_install_manifest/1` already treats a missing install as *advisory*, but TODO-011 notes
   the harness never runs it at all — meaning the harness is silent on a check `doctor` itself
   considers worth flagging. Add a Step 6.5 (`mix crosswake.install`, or whatever the install
   task's actual invocation is) between "register companion config" (Step 6) and "run doctor"
   (Step 7), so the sequence a real adopter performs (generate → declare routes → install →
   doctor) is exactly what the harness performs.
3. **What each step proves**, restated for the corrected order: Step 4 (router with one real
   route) proves the manifest compiles with a non-empty `:routes` section; the new install step
   proves the install task itself does not crash against a freshly-resolved companion + core
   pair; Step 7 (`doctor`) then proves the *actual* adopter-facing contract (`manifest_contract`,
   install-state advisory, companion registration, dependency validation) against a host shaped
   like a real one, not a minimal compile fixture.

**Threadline/sigra failures are separate causes — do not conflate the fix.** TODO-011's own
table names distinct root causes: threadline's July 2026 failure was a "module-shipment variant"
(not diagnosed there), sigra's August 2026 failure was `test/smoke_test.exs:21` (a smoke-test
assertion issue, unrelated to the router). Neither is fixed by D4's router/install change. Build
order must therefore treat D4 as "fix the router/install harness bug for all profiles" and then
**re-run each of the three previously-failing companions independently**, expecting rindle to go
green immediately (its root cause is exactly what D4 fixes) and treating a still-red threadline
or sigra run as a **new, separately-diagnosed finding**, not evidence D4 is wrong.

**API/consumer design lens.** The consumer of this fix is the maintainer debugging a red
`clean-room-proof-*` job at 2am after a release. Today they get `manifest_contract
(manifest_invalid)` with no indication that the *harness* (not the package) is at fault. Keep
the harness's own diagnostic honest: if a genuinely different failure recurs post-D4, the
harness output must make it obvious this is a *new* class, e.g. by tagging its steps
(`step=router`, `step=install`, `step=doctor`) in the log stream the way the matrix path already
does (`echo "[crosswake] source_mode=... step=..."`) — the legacy path currently only logs `Step
N:` prose without a machine-greppable `step=` field; bring it to parity.

---

## D5 — Tripwire retirement

**What replaces it.** TODO-009 already names the successor precisely: **"no publish job is
gated on a bare version literal."** Implement this as a new structural scanner check,
`release.publish_gate.no_bare_version_literal`, added to
`script/check_release_workflow_integrity.exs` alongside (and eventually *instead of*)
`release.version_weld.gates_match_declared_version`.

**What invariant it asserts.** For each job in `@version_gated_jobs` (already enumerated in the
scanner: `publish-hex publish-ios-core publish-android-core exact-public-proof`), parse the
job's `if:` string and assert it contains **no bare semver-shaped literal** (regex
`\d+\.\d+\.\d+` appearing outside a `needs.*.outputs.*` reference) — i.e., the check inspects
*syntax*, not *semantics*. This is strictly cheaper and more durable than the weld check it
replaces: `gates_match_declared_version` compares the manifest's declared version against the
job literals (semantic — requires reading a second file, the manifest, and matching values); the
successor only needs to grep the workflow file's own `if:` clauses for a literal-looking token
that is not a variable reference. It cannot regress into a version-specific weld because it
never encodes a version at all.

**Retirement, not weakening — how they land together.** The scope order matters: D1's fix
(deleting the four `== '0.2.1'` clauses and replacing them with the `approved_version` equality
from D1) is what makes `gates_match_declared_version` structurally moot — once no job's `if:`
contains a version literal, `welded == []` unconditionally, and the check becomes permanently
vacuous. TODO-009 explicitly says do not let it go quietly green forever; retire it *in the same
change* that removes the literals, and land `no_bare_version_literal` first or atomically so
there is no window where neither check is active.

**How we know the successor is not itself vacuous.** Three concrete non-vacuity proofs, mirroring
the pattern `phase168_release_version_weld_test.exs` already established for its predecessor:

1. **A fixture test that plants a bare literal** in a synthetic `if:` clause and asserts the
   check FAILs — proving the regex actually fires (this is the same "coverage test fails loudly
   if a fifth version-gated job appears" property TODO-009 already requires of the old check;
   carry it forward unchanged, since `@version_gated_jobs` is the enumeration the new check must
   also walk).
2. **Run it against the pre-D1 workflow file** (kept as a fixture, not live) and assert it FAILs
   there too — proving it would have caught the original defect, which is the actual bar for "is
   this check worth having."
3. **Assert the check inspects `if:` clauses specifically**, not job names or comments — a
   regression where someone adds `# TODO: remove after 0.2.3` as a comment must not trip it
   (comments are irrelevant), while a real `if: ... == '0.2.3'` must.

---

## D6 — Diagnostic propagation

**Root cause (from tracing the code, not just re-reading the TODO).**
`workflow_integrity_evidence/1` (`release_status.ex:894-914`) runs
`check_release_workflow_integrity.exs` **once** and parses every `[crosswake] OK|FAIL: <id> -
<detail>` line it printed into one `checks` map, shared across *all* of `release_status.ex`'s
downstream `scanner_check/6` calls (each of which asks about a different subset of `required_ids`
— e.g. `@workflow_path_gate_ids` for the path-gate check, a single-element list for the
version-weld check). `scanner_ids_result/2`'s `%{status: :failed, checks: checks}` branch
(`release_status.ex:806-820`) already *does* distinguish "id absent from `checks`" (→ "missing
scanner IDs") from "id present with `status: :error`" (→ "failing scanner IDs") — this part is
not broken. The actual defect TODO-009 observed is that **when the underlying Elixir script
exits non-zero part-way through** (an exception, not a clean assertion failure), it can stop
printing `[crosswake] OK/FAIL:` lines before reaching later checks — so those later checks'
required ids are legitimately absent from `checks`, and `scanner_ids_result/2` correctly reports
them as "missing" — but this is *misleading to a human*, because "missing" reads as "this check
doesn't exist," when the truth is "the scanner died before running it, because an earlier check
in the same process failed/raised."

**The fix.** Two changes, both in `release_status.ex`:

1. **`workflow_integrity_evidence/1` must retain the raw scanner output** (or at least the last
   N lines / the first non-`[crosswake]`-prefixed line, which is where an uncaught exception's
   message and stacktrace would appear) inside the `:failed` result, e.g.
   `%{status: :failed, checks: checks, message: ..., raw_tail: <last lines of output>}`. This
   costs nothing structurally — `System.cmd/3` already captures the full output.
2. **`scanner_ids_result/2`'s `:failed` branch, when `missing != []`, must report *why* — surface
   the last FAIL id that *did* print (if any) plus a note that the scan may have terminated
   early**, e.g.: `"missing scanner IDs: release.outputs.paths_released, ... (scanner run
   terminated after release.version_weld.gates_match_declared_version failed — see raw_tail)"`.
   Concretely: track the *last* `{id, %{status: :error}}` entry parsed before the point where
   `missing` ids would have appeared syntactically in the script's `checks = [...]` list (the
   scanner's check list is static and ordered — `check_release_workflow_integrity.exs`'s
   `checks = [...]` literal — so `release_status.ex` can statically know a given required id's
   position and note "N checks after the last observed failure never ran").

**The general rule this establishes.** *A scanner that reports "check X is missing" must be able
to say whether X was never defined, never reached, or reached-and-passed-but-unparsed — "missing"
and "not yet run because something upstream crashed" are different facts and must never share one
message.* This is the same discipline as the "absence scored as success" defect class already in
this project's memory (a check passing because it measured nothing) — D6 is the sibling defect:
*a check failing with the wrong explanation because a different check's crash silenced it.*
Any future `scanner_check`/`scanner_ids_result`-shaped code in this codebase should carry this
rule forward: propagate the *actual failing check's own message* whenever it is available, and
say so explicitly when it is not.

---

## Build Order

1. **D5's structural check must exist before D1's YAML edit lands** (or in the same PR, gated
   together) — otherwise there is a window where the version literal is removed but nothing
   would catch its return. Since D5's successor check is cheap (pure syntax scan, no fixture
   dependency on D1's identity plumbing), it can be written and merged first, in a state where it
   currently passes vacuously against `main`'s pre-D1 workflow (the four jobs *do* have version
   literals today, so the new check should initially **FAIL** against `main` — which is fine and
   expected; it becomes the acceptance criterion for D1, not a pre-check).
2. **D1 (split version from authority)** is the structural prerequisite for everything else:
   D3's convergence, D2's per-package refs, and the retirement half of D5 all assume the graph
   already accepts arbitrary versions. Land D1 first among the functional changes.
3. **D2 (per-package approved refs)** can proceed in parallel with D1 once D1's
   `approved_version` binding exists on the receipt, because D2 mainly touches the companion-
   proof manifest/script/`cleanroom.ex`, a mostly-separate code path from the four `if:` gates
   D1 touches — but D2 depends on D1 having removed `cleanroom.ex:236`'s
   `Map.fetch!(by_package, "crosswake").version == "0.2.1"` weld, since that line is the same
   defect class one layer down. Sequence: D1's YAML+Workflow changes land, then D1's Elixir
   companion (removing the `cleanroom.ex` weld) lands together with D2's schema change, since
   both touch the same module and the same test fixtures.
4. **D3 (recovery convergence)** depends on D1 (the version-parity `if:` clause it reuses) and
   is otherwise independent of D2/D4 — it can land any time after D1.
5. **D4 (realistic clean-room host)** is independent of D1/D2/D3 — it only touches the harness's
   Step 4-7 sequence and can land at any point, including *before* D1, since TODO-011's proof
   lane is advisory (`needs: publish-hex-*`, non-blocking) today and stays advisory until D3
   converges it onto the required path. Land D4 early opportunistically to get real signal on
   whether the threadline/sigra failures are still present, since diagnosing those is calendar-
   bound (each only reproduces against a live Hex release) and should not wait on D1-D3.
6. **D6 (diagnostic propagation)** is fully independent of D1-D4 structurally, but land it
   **before or alongside D1's PR**, because D1's own generalization is exactly the kind of
   multi-step CI change likely to trip `check_release_workflow_integrity.exs` in an unexpected
   way during development — a maintainer iterating on D1 is the direct beneficiary of D6's fix,
   and having it land first makes D1's own development loop faster and its failures legible.

**Suggested phase grouping for the roadmapper:**
- Phase A: D6 (diagnostic propagation) + D5 successor check (both are CI-tooling-only, no
  release-graph behavior change, fast to verify, immediately useful for every later phase's dev
  loop).
- Phase B: D1 (version/authority split) + the `cleanroom.ex` weld removal + D5 retirement of the
  old tripwire (these are one coherent change to the identity model, best reviewed together to
  see the "old constant → new parametric field" migration in one diff).
- Phase C: D2 (per-package approved refs), immediately following B since it needs `approved_
  version`/the removed core-version weld to be gone first.
- Phase D: D3 (recovery convergence), following B (needs the version-parity gate) — can run in
  parallel with C since it touches a disjoint set of files (`needs:` graph + publish scripts vs.
  `cleanroom.ex`/manifest schema).
- Phase E (can start anytime, ideally in parallel with A): D4 (realistic clean-room host) +
  re-diagnosis of the threadline/sigra-specific failures found along the way.

---

## Conflicts Between Decisions (surfaced, not smoothed over)

1. **D1 vs D2 — where does "the approved version" live?** D1 puts a single `approved_version`
   on the *core* receipt (one release, one version, matching the linked-release identity model).
   D2 needs *per-package* versions/refs for the five independent companions, which by design are
   **not** part of the linked-release identity at all (per the runbook: "not members of the
   linked approval"). These are not actually in tension once stated precisely — D1's
   `approved_version` binds only the linked-core release; D2's per-package refs are a wholly
   separate manifest concern for the exact-public proof's companion rows — but a careless
   implementation could try to reuse one "approved_version" concept for both and re-introduce a
   single-ref assumption through the back door. The roadmap phase for D2 must explicitly state
   that companion approved-refs are **keyed per package**, never inherited from D1's core
   `approved_version`.

2. **D1 vs D3 — artifact naming.** Today's artifact names bake in the version literal
   (`exact-public-proof-0.2.1`, `linked-release-status-0.2.1` at `release-please.yml:761`,
   `829`). D1 generalizing the version means these names must become
   `exact-public-proof-${version}` / `linked-release-status-${version}` — a mechanical but
   easy-to-miss change, since GitHub Actions artifact names are static strings evaluated at
   workflow-parse time from expressions, which *is* supported (`${{ needs.release-please.outputs
   .version }}` interpolates fine in `with: name:`), but every consumer that currently hardcodes
   `-0.2.1` when downloading these artifacts (if any exist outside this workflow, e.g. dashboards
   or the runbook's manual steps) must be found and generalized in the same change, or D1 will
   silently break artifact discovery for the very proof D3 is trying to make load-bearing.

3. **D3 vs "the proof stays non-skippable."** Converging recovery and normal paths onto one
   precondition (a publication record) is *itself* a new gate that could, if built loosely,
   become a second `needs:`-shaped escape hatch (e.g., if the record-check step is allowed to
   pass on a missing record with a warning instead of failing). The design in D3 above is
   explicit that a missing record must be a **hard failure** of `exact-public-proof`, not a skip
   — this is called out because it is the single easiest way to reintroduce exactly the defect
   D3 is fixing, one layer deeper.

4. **D4 vs D2 — do not conflate.** TODO-011 (D4) is about the **clean-room proof host being too
   minimal**; TODO-012 (D2) is about the **exact-public proof's manifest requiring one shared
   ref**. Both touch `verify_companion_cleanroom.sh`, but D4 only touches the per-profile host-
   generation steps (4-9, the legacy positional-argument path), while D2 only touches the
   `--source-mode` matrix path's `matrix_fetch_public_family`/manifest-parsing logic (lines
   ~198-278). They are almost disjoint regions of the same file; a plan that tries to fix both in
   one diff risks a merge that silently reintroduces one profile's routeless stub while fixing
   the manifest schema, or vice versa. Keep them as separate plans even though they share a file.

5. **D5's successor check vs D1's rollout window.** If D5's `no_bare_version_literal` check is
   merge-blocking *before* D1 lands, it will correctly and immediately fail against `main` (which
   still has four bare-literal gates) — meaning D1 cannot land incrementally; the check and the
   fix must merge together (or the check must be temporarily non-blocking/advisory for exactly
   the one PR that lands D1). Do not let this land as two separate PRs with a green-CI window in
   between, or `main` will be red for the interim, which is a worse operator experience than the
   interim tripwire it replaces.

## Sources

- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md` (HIGH — primary finding, current repo)
- `.planning/todos/TODO-011-companion-cleanroom-lane-has-never-been-green.md` (HIGH)
- `.planning/todos/TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md` (HIGH)
- `.planning/seeds/SEED-017-release-graph-version-generalization.md` (HIGH)
- `.planning/seeds/SEED-004-cleanroom-proof-harness.md` (HIGH)
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` (HIGH)
- `.github/workflows/release-please.yml` (HIGH — read directly, lines 1-1064; jobs
  `approved-release-guard`, `release-please`, `publish-hex*`, `publish-ios-core`,
  `publish-android-core`, `clean-room-proof-*`, `exact-public-proof`, `linked-release-rollup`)
- `lib/crosswake/release_candidate/workflow.ex` (HIGH — read in full)
- `lib/crosswake/release_candidate/cleanroom.ex` (HIGH — read in full)
- `script/verify_companion_cleanroom.sh` (HIGH — read in full, both `--source-mode` matrix path
  and legacy positional-argument path)
- `lib/crosswake/release_status.ex` (HIGH — `scanner_ids_result/2`, `workflow_integrity_evidence/1`,
  `parse_workflow_integrity_output/1` read directly, lines ~760-970)
- `script/check_release_workflow_integrity.exs` (HIGH — header/check-list read directly)
- `docs/COMPANION-PUBLISH-RUNBOOK.md` (HIGH — operator contract, confirms companions are outside
  the linked approval)
- Comparable-systems reasoning (cargo-dist, goreleaser, Maven Central staging, npm provenance,
  sigstore transparency log, Nix/Bazel content addressing, Oban/Ecto/Phoenix/Nerves release
  idiom) — MEDIUM confidence, drawn from general knowledge of these projects' publicly documented
  release architectures rather than a fresh fetch in this session; recommend a follow-up
  `WebSearch` pass per named tool if the roadmapper wants citations for a written ADR.
