---
id: SEED-014
status: dormant
planted: 2026-09-14
planted_during: quality-ratchet-release Phase 168
trigger_when: next milestone touching the proof-lane contracts, mix crosswake.doctor, or the shipped SwiftUI denial views
scope: medium
severity: contains two high-severity items (CW-REQ-A, CW-REQ-B)
---

# SEED-014: Proof-lane and doctor fidelity — six adopter gaps that were worked around

## Why This Matters

These six came from the First B2C Adopter's Phase 6 (2026-09-11) and **were never ferried back into
this repo** — they sat in the adopter's own tree until the 2026-09-14 triage found them. That is the
first thing worth fixing: the ferry path is manual and it dropped a whole batch.

None of the six blocked the adopter's phase. Every one of them cost the phase a host-owned
workaround. That is the shape of a library that is *usable* but not yet *trusted as the seam* —
each workaround is a place the adopter decided to own something Crosswake claims to own.

The common thread: **Crosswake's gates produce evidence the adopter cannot act on.** Exit codes
collapse, structured details get flattened into prose, provenance headers are placeholders, and a
closed vocabulary has no room for the thing actually being proved. All six are fidelity problems in
the evidence surface, not functionality gaps.

## Related finding (2026-09-15)

`TODO-011` records that the post-publish companion clean-room lane has never been green —
threadline (Jul), sigra (Aug), rindle (Sep) all failed, each for a different reason. The rindle
cause is the same shape as the six items below: the proof host is too minimal to satisfy the
contract the proof asserts, so `doctor` produces evidence about the harness rather than about the
package. It belongs to this seed's scope.

## When to Surface

**Trigger:** next milestone touching the proof-lane contracts, `mix crosswake.doctor`, or the shipped
SwiftUI denial views.

Observed against a git pin that is an ancestor of 0.2.1. Claims below were re-verified against this
working tree on 2026-09-14; **see the staleness note on CW-REQ-A.**

## Scope Estimate

**Medium.** B, C, E, F are small, self-contained, and independently landable. A needs a contract
decision. D is a design opinion about shipped UI.

---

## CW-REQ-A — no haptics assertion in `PhysicalIphoneContract` (high)

`Crosswake.ProofLane.PhysicalIphoneContract` is a closed, ordered vocabulary, and `validate_report/1`
rejects any assertion ID outside it. There is no haptics assertion, so a physical-iPhone haptic
actuation proof is **unexpressible without forking the contract**.

**Ask:** add a haptics assertion (suggested `PI-BRIDGE-HAPTIC-IMPACT`, `owner: :device_local`) to
`@assertions` in `lib/crosswake/proof_lane/physical_iphone_contract.ex`, with a `@schema_version`
bump. The vocabulary is versioned and closed on purpose, so this is an intentional breaking
addition, not a silent one.

> **Staleness note — verified 2026-09-14.** The adopter observed a **10-assertion** vocabulary at
> `@schema_version 1`. This tree already carries `@schema_version 2` with **20** assertions
> (recovery, logout/account-switch fences, and their `:backend_authority` counterparts were added).
> The *ask still stands* — there is still no haptics assertion — but the "closed 10-assertion set,
> bump 1→2" framing is outdated. Re-derive the current vocabulary before planning; the bump is
> 2→3.

**Workaround they built:** a separate host-owned three-layer haptics evidence gate that never
touches `PhysicalIphoneContract`. The haptics proof runs entirely outside the Crosswake proof-lane
vocabulary while the offline/persistence criteria the vocabulary *does* cover still go through
`mix crosswake.proof_lane.physical_iphone` in the same tethered session — two gates, two records,
for one device session.

## CW-REQ-B — the runner cannot say "ran, and found a real defect" (high)

`lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` calls `System.halt(2)` on every failure path,
including the validated-report-with-`blocked`-outcome path (line 50) and the no-report paths
(lines 57, 61). A genuinely **refuted** assertion and an **unavailable precondition** are
indistinguishable from the exit code.

**Ask:** exit **1** for a validated report containing at least one `outcome: :blocked`; reserve
exit **2** for `PI-HOST-CONFIG` / `PI-HOST-CALLBACK`-class failures where no report was produced.

**Why it bites:** every host-owned gate in the adopter's phase uses 0/1/2 (pass / refuted /
could-not-run) so a red CI run is interpretable without reading logs. This one non-host-owned gate
collapses that, and a red run requires opening the report to tell "device wasn't there" from
"device was there and something is broken."

## CW-REQ-C — `verify_navigation_shell` hardcodes placeholder provenance (medium)

`lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex:105-114` hardcodes
`crosswake_version: "0.1.0"`, `template_version: "161"`,
`commit_ref: "git-0000000000000000000000000000000000000000"`, `device_class: :unknown`.

Any adopter recording this header in a provenance ledger gets **misattributed provenance** and an
all-zero commit reference that reads as a real hash and can never be correlated back to the verified
code. In an evidence-first repository this is the worst class of placeholder.

**Ask:** populate all four from real values at verification time — installed Hex/git version, actual
generated `template_version`, `git rev-parse HEAD` (or an explicit "unknown, not a git checkout"
sentinel, *not* an all-zero hash), and the real device class.

## CW-REQ-D — `RouteUnavailableView` renders a route ID on a user-facing surface (low)

The shipped view renders a monospaced `Route: <routeID>` debug line, and hardcodes `.largeTitle` /
`systemGroupedBackground`.

A route identifier leaking into user-facing UI fails an accessibility/copy bar — the adopter has a
`testNoRouteIdentifierInAccessibilityTree` UI test guarding exactly this.

**Ask:** drop the debug line from the rendered body (the `routeID` stays available on
`RouteDenialPresentation` for hosts that want to log or show it deliberately), and use platform
defaults for type and background so hosts adopting the shipped view aren't locked into the library's
visual opinions.

**Workaround they built:** a host-owned denial view composed from the public
`RouteDenialPresentation` value, not using `RouteUnavailableView` at all — i.e. they declined the
shipped UI entirely. Relates to SEED-005 (themable web control equivalents).

## CW-REQ-E — `unmanaged_routes` doctor finding drops its own path list (medium)

`Crosswake.Policy.Compiler.build_warnings/3` builds `Warning.unmanaged_routes(paths, source_module)`
and embeds the sorted path list as **formatted text** in `message`. But
`lib/crosswake/doctor/doctor.ex:367` passes no `details` map, so the structured list never reaches
`mix crosswake.doctor --format json`.

The pattern to match is already two clauses earlier in the same function: `policy_compile_failed`
(line 406) *does* pass structured details.

**Ask:** pass `details: %{unmanaged_paths: paths, router: source_module}` to that `check/6` call.
Adopters gating on doctor JSON in CI currently have to regex-parse free text.

**Workaround they built:** computed their own managed/unmanaged route set from the host
`RouteTable`'s `__routes__/0` rather than parsing doctor's finding.

## CW-REQ-F — `phase_4_posture/1`'s offline-coherence check has a filter hole (medium)

`lib/crosswake/doctor/doctor.ex:448` filters `manifest.routes` down to
`route.cache_contract != nil or route.island_contract != nil` **before** the coherence check that
requires `:local_first` to have an `island_contract`.

So a route declared `offline: :local_first` with **no** `island_contract` is filtered out before
`Enum.all?` ever sees it — the exact misconfiguration the check exists to catch never reaches it.

**Ask:** either filter by `route.offline != :unavailable` (examine every route claiming any offline
behavior, contract or not), or make `:local_first` without an `island_contract` a `Policy.Route`
**compile-time** validation error — symmetric with the existing rule that `:cached_read_only`
without a `cache_contract` is already invalid. The compile-time option is stronger and matches the
repo's fail-closed posture.

*Docs item in the same area:* state explicitly that `--router` accepts any module exporting
`__routes__/0`, not only a `Phoenix.Router`.

---

## Explicitly NOT requested — recorded deliberately

A `mix crosswake.doctor --strict` / warnings-as-errors flag. The adopter considered and **rejected**
it: their register-plus-bidirectional-diff gate is strictly stronger, because it catches a finding
*disappearing* as drift, not only a finding appearing. Pushing Crosswake to conflate
"incremental-adoption warning" with "blocking failure" would degrade the library for adopters
legitimately mid-migration. **The host, not the library, should hold that policy opinion.**

Worth treating as a design principle, not just a declined request.

## Loose end — CLOSED 2026-09-15

~~The adopter's `mix.exs` still pins `crosswake_sigra` as a git/sparse dep at an old SHA.~~ The
premise was a stale snapshot. The adopter's `mix.exs` is `{:crosswake_sigra, "~> 0.1.3"}` with
`crosswake` alongside at `~> 0.2.1, override: true`; both moved in the same commit. Their `mix.lock`
carries `crosswake_sigra 0.1.3` as a `:hex` tuple with a package hash, which is registry truth
rather than an aspiration — a hex tuple with a hash is only written for a package actually resolved
from the registry. **`crosswake_sigra 0.1.3` published, and the promised pairing holds.**

Worth generalizing: the git pin read here on 2026-09-14 no longer existed in the adopter tree at the
time it was read. When triaging an adopter dependency claim, prefer their `mix.lock` over their
`mix.exs` and over any snapshot in a report, and check whether the report predates a dep-bump commit.

## Breadcrumbs

- `.planning/seeds/SEED-013-adopter-device-proof-lane-reachability.md` — the 2026-09-14 device-proof
  batch; same adopter, same frontier.
- `.planning/todos/TODO-003`, `TODO-006`, `TODO-007` — the actionable high/medium items pulled out
  of both batches.
- `.planning/seeds/SEED-005-themable-web-control-equivalents.md` — CW-REQ-D belongs to that theme.
- `.planning/seeds/SEED-008-native-denial-vocabulary.md` — CW-REQ-D's denial surface.

## Provenance

First B2C Adopter Phase 6, filed 2026-09-11 against a git pin ancestral to 0.2.1, paired with
`crosswake_sigra` at the same SHA and `crosswake-shell-core-ios@0.2.0` via SwiftPM. Claims
re-verified against this working tree 2026-09-14. Adopter-side identifiers, commit SHAs, team ids,
and bundle identifiers are deliberately excluded.
