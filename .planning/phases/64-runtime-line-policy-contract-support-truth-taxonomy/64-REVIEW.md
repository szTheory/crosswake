---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
reviewed: 2026-06-03T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/doctor/finding_policy.ex
  - lib/crosswake/doctor/formatter.ex
  - lib/crosswake/doctor/json_formatter.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/runtime_line/rebuild_policy.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/manifest/types_phase64_test.exs
  - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
  - guides/support_matrix.md
findings:
  critical: 1
  warning: 8
  info: 4
  total: 13
status: issues_found
---

# Phase 64: Code Review Report

**Reviewed:** 2026-06-03T00:00:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 64 adds the `RebuildPolicy` derivation engine, additive manifest type fields
(`RuntimeLineRow`, `verification_method`, `required_verification_method`,
`rebuild_matrix`), the support-matrix rebuild/evidence taxonomy, and doctor rendering
of the rebuild & compatibility matrix plus an evidence-posture line.

The three watch items called out in the brief were each examined:

1. **`:jvm_hermetic` honesty invariant** — The render path keeps `:jvm_hermetic`
   ("jvm-hermetic (CI only)") and `:device_verified` ("device-verified") textually
   distinct, and `validate_verification_method_invariant/2` rejects `:device_verified`
   on an advisory (CI-only) `CapabilitySupportEntry`. **However, the invariant is
   under-enforced in two places** (CR-01, WR-01): the `rebuild_matrix` rows are never
   validated, and a non-advisory CI-only entry can still claim `:device_verified`.
2. **RLINE-02 (no `Compatibility` field / schema bump)** — Honored. The struct keeps
   exactly its 5 keys and `manifest_schema_version` stays `"1.0.0"`. Good.
3. **Change-class classification in `rebuild_policy.ex`** — `classify/2` is correct,
   but `diff/2` only ever emits 3 of the 8 declared change classes and the
   "All 8 change classes" comment is wrong (WR-02, WR-03).

Separately, this phase quietly **downgrades four doctor findings from `:error` to
`:warning`** (finding_policy + doctor), flipping doctor `status` from `:error` to
`:ok` for an unverified host. That is a support-truth posture change with no obvious
phase-64 mandate and deserves scrutiny (WR-04).

## Critical Issues

### CR-01: `rebuild_matrix` evidence_tier is never validated — `:device_verified` can be claimed with zero device proof

**File:** `lib/crosswake/support_matrix/support_matrix.ex:276-315`, `lib/crosswake/support_matrix/support_matrix.ex:875-895`

**Issue:** The support-truth honesty invariant the phase is built around
("`:jvm_hermetic` (CI-only) must never be rendered or promoted as `:device_verified`")
is only enforced for `capability_families` entries via
`validate_verification_method_invariant/2`. The `@rebuild_matrix_rows` evidence_tier
values are **not** subject to any validation. The canonical matrix ships a `"2.x"` row
with `evidence_tier: :device_verified`:

```elixir
Types.new_runtime_line_row(
  runtime_line: "2.x",
  ...
  evidence_tier: :device_verified
)
```

There is no `"2.x"` runtime line in existence (`native_runtime_version` is `"1.0.0"`,
i.e. the 1.x band), and no device-verified proof corpus exists yet (the
`shell.android.device_verified` promotion rule is explicitly GATED until Phases 67/68).
This row is rendered verbatim by both the human formatter
(`format_rebuild_matrix/1` → "evidence_tier=device-verified") and the JSON formatter
(`format_runtime_line_row/1` → `"evidence_tier": "device_verified"`). The doctor
therefore publishes a `device-verified` evidence claim that has no backing proof and
no validation gate — exactly the "evidence laundering" the D-10a invariant exists to
prevent, but routed around it through the unvalidated `rebuild_matrix` surface.

**Fix:** Either (a) remove the speculative `"2.x"` row until a real 2.x band with
device proof exists, or (b) extend the validate pipeline to cover rebuild_matrix rows.
Minimum: add a rebuild_matrix validator that rejects `:device_verified` rows whose
runtime_line has no corresponding passed device-verified promotion evidence.

```elixir
defp validate_rebuild_matrix_evidence(errors, %SupportMatrix{} = sm) do
  Enum.reduce(sm.rebuild_matrix, errors, fn row, acc ->
    if row.evidence_tier == :device_verified and not device_proof_available?(row.runtime_line) do
      [%{key: :rebuild_matrix,
         message: "runtime_line #{row.runtime_line} claims :device_verified but no device-verified proof corpus exists (D-19 gates this until Phase 67/68)",
         hint: "use :jvm_hermetic, :emulator_advisory, or :none until device proof lands"} | acc]
    else
      acc
    end
  end)
end
```

## Warnings

### WR-01: `validate_verification_method_invariant/2` only blocks `:device_verified` on `:advisory` entries — a `:merge_blocking` CI-only entry escapes

**File:** `lib/crosswake/support_matrix/support_matrix.ex:875-895`

**Issue:** The invariant guard is:

```elixir
entry.verification_method == :device_verified and entry.proof_class == :advisory ->
```

It assumes "CI-only" is fully captured by `proof_class == :advisory`. But the
evidence corpus and the proof_class are independent axes: an entry can be
`proof_class: :merge_blocking` and still have only CI/JVM-hermetic evidence (Android
shell entries are exactly this — baseline merge-blocking, JVM-hermetic evidence). Such
an entry could set `verification_method: :device_verified` and pass validation,
laundering CI evidence as device evidence under a merge-blocking label. The brief's
honesty invariant is about the *evidence tier vs. the actual proof corpus*, not about
proof_class.

**Fix:** Key the check on the evidence corpus, not proof_class. Reject
`:device_verified` whenever the entry's actual verification lane is CI-only,
regardless of proof_class — e.g. require an explicit allowlist of families/owners that
legitimately carry device evidence (today only `owner: :native_screen` iOS entries),
and reject `:device_verified` for everything else.

### WR-02: `diff/2` can never produce 5 of the 8 declared change classes — dead classification paths

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:146-203`

**Issue:** `classify/2` accepts and the `@type change_class` declares 8 atoms, but
`capability_changes/2` (the only producer feeding `diff/2`) emits only
`:capability_family_add`, `:sdk_floor_bump`, and `:privacy_manifest_entry`. The
classes `:bridge_schema_change`, `:permission_add`, `:entitlement_add`,
`:push_capability_change`, and `:url_scheme_change` are declared, documented as
first-class derivation inputs in the moduledoc, and handled by `classify/2`, but
`diff/2` will never detect them. A caller relying on `diff/2` to surface a
permission/url-scheme/push change between two manifests gets a silent miss — the same
"it's-just-JS OTA break" footgun the moduledoc warns about, reintroduced at the
detection layer.

**Fix:** Either detect these classes in `capability_changes/2` (compare the relevant
manifest fields), or narrow the moduledoc and `@type` to the classes `diff/2` actually
produces and document that the others are `classify/2`-only inputs supplied by external
detectors. Do not leave the gap implicit.

### WR-03: Moduledoc / constant disagreement — "All 8 change classes" labels a 6-element list

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:46-54`

**Issue:**

```elixir
# All 8 change classes in the taxonomy.
@capability_axis_classes [
  :bridge_schema_change,
  :capability_family_add,
  :permission_add,
  :entitlement_add,
  :push_capability_change,
  :url_scheme_change
]
```

The comment says "All 8 change classes" but the list has 6 (the 2 system classes
`:sdk_floor_bump`, `:privacy_manifest_entry` live in `@system_rebuild_classes`). The
comment is on the wrong constant and the number is wrong for this list. A future
maintainer auditing "are all 8 covered?" will be misled.

**Fix:** Change the comment to "The 6 capability-axis change classes (system classes
are in @system_rebuild_classes)." or remove the count.

### WR-04: Four doctor findings silently downgraded from `:error` to `:warning`, flipping doctor status to `:ok` for unverified hosts

**File:** `lib/crosswake/doctor/finding_policy.ex:27,39`, `lib/crosswake/doctor/doctor.ex:235,1304`

**Issue:** This phase downgrades severity in four places:
- `finding_policy.ex:27` `proof_hook_verification_required` `:error` → `:warning`
- `finding_policy.ex:39` `support_claim_verification_required` `:error` → `:warning`
- `doctor.ex:235` `install_manifest_missing` `:error` → `:warning`
- `doctor.ex:1304` `capability_proof_merge_blocking` (verification_required branch) `:error` → `:warning`

Because `Report.status` is `:error` only when some finding has `severity == :error`
(doctor.ex:172), these downgrades mean a host whose shell proofs are unverified now
reports `status: :ok`. The `doctor_test.exs` change confirms this intent
(`report.status == :error` → `== :ok`). Phase 64's mandate is the runtime-line
*evidence taxonomy* — it is not obviously a remit to relax the doctor's pass/fail
posture. "Support claims remain verification required" reported as a non-blocking
`:warning` (and an overall `:ok`) is a meaningful weakening of support-truth honesty:
CI/tooling that gates on `status: :error` will now pass for an unverified host.

**Fix:** Confirm this severity policy change was an explicit phase decision with a
recorded rationale (D-number). If it was not, revert the four downgrades. If it was,
document in the phase summary why support-claim verification is no longer
status-blocking, and ensure any CI gate that depended on `:error` status is updated
deliberately rather than silently.

### WR-05: `evidence_posture_snapshot/1` is hardcoded but its comment claims derivation from rebuild_matrix

**File:** `lib/crosswake/doctor/doctor.ex:1210-1215`

**Issue:**

```elixir
# D-16: Evidence posture summary keyed by platform — derived from the rebuild_matrix
# evidence_tier values. iOS uses :device_verified; Android uses :jvm_hermetic (CI only).
defp evidence_posture_snapshot(_support_matrix) do
  %{ios: :device_verified, android: :jvm_hermetic}
end
```

The comment says the posture is "derived from the rebuild_matrix evidence_tier
values," but the function discards its `_support_matrix` argument and returns a
hardcoded literal. The two are already incoherent: the rebuild_matrix has
`"1.x" => :jvm_hermetic` and `"2.x" => :device_verified` (per-runtime-line), while this
summary asserts `ios: :device_verified` / `android: :jvm_hermetic` (per-platform). If
the matrix evidence tiers change, this summary will silently disagree, and a reader
trusting the "derived from" comment will be wrong. This is the load-bearing
"evidence posture" line asserted by the RLINE-04 proof, so drift here is a real
honesty hazard.

**Fix:** Either genuinely derive the per-platform posture from the matrix/capability
data, or change the comment to state it is an intentional hardcoded D-16 summary and
add a test that fails if it diverges from the canonical evidence sources.

### WR-06: JSON `release_policy` drops `evidence_posture`, `capability_families`, and `release_boundaries` that human output renders — formatter parity gap

**File:** `lib/crosswake/doctor/json_formatter.ex:125-145`

**Issue:** `format_release_policy/1` (JSON) builds `base` with only
`crosswake_version, manifest_schema_version, bridge_protocol_version,
native_runtime_version, package_version_truth, companion_requirement,
package_surfaces, change_classes` (+ conditional `rebuild_matrix`). The human
formatter (`formatter.ex:60-98`) additionally renders `capability_families`,
`release_boundaries`, and the new `evidence_posture` line. JSON consumers cannot see
the matrix-level evidence posture summary (only per-row `evidence_tier` inside
rebuild_matrix) or release boundaries / capability families. Machine consumers and
human consumers thus see different release-policy truth. The RLINE-03 parity proof
only checks `runtime_line` values, so this asymmetry is untested.

**Fix:** Add `evidence_posture`, `capability_families`, and `release_boundaries` to the
JSON `format_release_policy/1` payload (serializing atoms via the existing helpers), or
explicitly document that the JSON release_policy is a deliberate subset and why.

### WR-07: `classify/2` is non-total — an unmapped capability-axis class with a Capability raises FunctionClauseError instead of a typed error

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:92-110`

**Issue:** `classify/2` has clauses for system classes, for `nil` + capability-axis,
and for `%Capability{}` + capability-axis. There is no fallback clause. If a caller
passes a `change_class` atom that is neither in `@system_rebuild_classes` nor in
`@capability_axis_classes` (e.g. a typo, or a new taxonomy atom added to `@type` but
not the constants), the call raises `FunctionClauseError` rather than a meaningful
error. The `@type change_class` and the two `@`-constants are already out of sync risk
(see WR-02/WR-03), making this reachable. `diff/2` itself is safe today, but `classify/2`
is a documented public function (`@spec`, moduledoc examples) callable directly.

**Fix:** Add an explicit final clause that raises `ArgumentError` with a clear message
naming the unrecognized change class, mirroring the `nil` clause, so misuse fails
loudly and legibly.

### WR-08: `capability_changes/2` will raise on `nil` capability registries

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:159-203`

**Issue:** `added_capabilities/2` and `privacy_manifest_changes/2` call
`Map.keys(registry_a)` / `MapSet.new(Map.keys(root_a.capability_registry))` directly.
`Root.capability_registry` defaults to `%{}` so a fully-constructed manifest is safe,
but `diff/2` only guards `%Root{}` shape — it does not guard against a `Root` whose
`capability_registry` is `nil` (constructible via `struct/2` or partially-built test
fixtures, and `Map.get` elsewhere in the codebase tolerates nil registries, e.g.
`doctor.ex:804` `manifest.capability_registry || %{}`). A `nil` registry here raises
`BadMapError` from `Map.keys(nil)` with no context.

**Fix:** Normalize defensively: `registry_a = root_a.capability_registry || %{}` (and
same for `root_b`) at the top of `capability_changes/2`, consistent with how the
doctor already defends against nil registries.

## Info

### IN-01: RebuildPolicy moduledoc `iex>` examples are not run as doctests

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:78-89,118-128`

**Issue:** The moduledoc and `classify/2`/`rebuild_required?/1` carry `iex>` examples,
but no `doctest Crosswake.RuntimeLine.RebuildPolicy` exists in any test file. The
examples are decorative — they are never executed, so they can rot without a failing
test. (They also reference `RebuildPolicy.classify/...` with no alias setup, which
would fail if actually run as a doctest.)

**Fix:** Add `doctest Crosswake.RuntimeLine.RebuildPolicy` to a test module (with the
needed `alias`), or convert the examples to plain prose so they do not imply executable
guarantees.

### IN-02: `guides/support_matrix.md` has no rebuild & compatibility matrix or evidence-posture section

**File:** `guides/support_matrix.md` (whole file)

**Issue:** Doctor now emits a "rebuild & compatibility matrix:" block and an
"evidence posture:" line (including the speculative `2.x`/`device-verified` row from
CR-01), but the support_matrix guide documents none of it. The phase's own promotion
rules require "docs-contract parity for Android runtime-line" yet the runtime-line /
rebuild-matrix taxonomy is absent from the canonical guide. Doctor output and docs are
out of parity for the central artifact of this phase.

**Fix:** Add a "Rebuild & Compatibility Matrix" section and an evidence-tier legend
(jvm-hermetic = CI only; device-verified = real device) to `guides/support_matrix.md`,
and ensure it does not assert device-verified for bands without device proof.

### IN-03: `privacy_manifest_changes/2` heuristic is coarse and silently coupled to capability adds

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:190-203`

**Issue:** Privacy-manifest changes are inferred as "native_runtime_version changed AND
at least one capability added." This conflates two unrelated signals: a privacy
manifest entry can change without any capability add, and a capability add with a
runtime bump is not necessarily a privacy-manifest change. The function's own comment
admits it is a "simplified heuristic." It can both false-positive (emitting
`:privacy_manifest_entry` for an unrelated capability add) and false-negative (missing
a real privacy entry with no capability add). Given `diff/2` is "tooling input, not a
release oracle" this is lower risk, but it produces misleading change-class output.

**Fix:** Detect privacy-manifest entries from an explicit signal rather than inferring
from the capability-add + runtime-bump coincidence, or drop the inferred class and
require callers to pass system classes directly (as the comment already suggests is
supported).

### IN-04: `@capability_axis_classes` list ordering does not match `@type change_class` ordering

**File:** `lib/crosswake/runtime_line/rebuild_policy.ex:47-64`

**Issue:** Minor consistency nit: the `@type change_class` union lists the atoms in one
order (`:bridge_schema_change, :capability_family_add, :permission_add,
:entitlement_add, :sdk_floor_bump, :privacy_manifest_entry, :push_capability_change,
:url_scheme_change`) while `@capability_axis_classes` uses a different order. Not a
bug, but it makes cross-checking coverage harder and contributes to the WR-02/WR-03
drift risk.

**Fix:** Keep the taxonomy ordering consistent across the `@type` and the two
constants so coverage is visually auditable.

---

_Reviewed: 2026-06-03T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
