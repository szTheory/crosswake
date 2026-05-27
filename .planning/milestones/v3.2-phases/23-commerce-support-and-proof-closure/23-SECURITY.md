---
phase: 23-commerce-support-and-proof-closure
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
threats_total: 15
threats_closed: 15
threats_open: 0
audited: 2026-05-27
---

# Phase 23 Security Audit — Commerce Support And Proof Closure

Verification of the STRIDE threat register declared in plans 23-01 through 23-04. Each threat is `mitigated` per plan disposition; this audit confirms the declared mitigation is present in implementation code.

## Audit Scope

Threats verified by grep + targeted file inspection against:

- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/json_formatter.ex`
- `guides/commerce.md`
- `guides/support_matrix.md`
- `test/crosswake/support_matrix/support_matrix_test.exs`
- `test/crosswake/support_matrix/renderer_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- `test/crosswake/doctor/formatter_test.exs`
- `test/crosswake/guides/commerce_test.exs`
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs`
- `.github/workflows/phase23-proof.yml`

Hermetic proof lane executed during audit: `mix test test/crosswake/proof/phase23_commerce_support_proof_test.exs` -> 14 tests, 0 failures.

## Threat Verification Matrix

| threat_id | status | category | disposition | evidence |
|-----------|--------|----------|-------------|----------|
| P23-01-T01 | CLOSED | tampering | mitigate | `lib/crosswake/support_matrix/support_matrix.ex:44,68,93,118` declare `proof_class` on every `@commerce_corridor_entries` entry; `:259-269` exposes `commerce_corridor_proof_classes/0` canonical mapping; `test/crosswake/support_matrix/support_matrix_test.exs:231-289` asserts every corridor has `proof_class`, restricted to `[:merge_blocking, :advisory]`, and `:254,257,266,269` locks expected `:merge_blocking` values for paywall_entry/account_management/purchase_intent/restore_intent. |
| P23-01-T02 | CLOSED | elevation_of_privilege | mitigate | `lib/crosswake/doctor/doctor.ex:657-673` `stale_snapshot_findings/2` emits `commerce.entitlement.stale_snapshot` with `proof_class: "merge_blocking"` whenever freshness is `:stale` or `:unknown`; `:621-638` coerces `nil` and `:not_applicable` (when routes exist) to `:unknown` so fail-closed lane always fires; `test/crosswake/doctor/doctor_test.exs:419-431,443-447,452-475` assert merge-blocking finding fires for `:stale`, `:unknown`, and `:not_applicable`-with-routes; `test/crosswake/proof/phase23_commerce_support_proof_test.exs:228,242` re-asserts at proof-lane level. |
| P23-01-T03 | CLOSED | information_disclosure | mitigate | `lib/crosswake/doctor/doctor.ex:549-582` `commerce_corridors_summary/2` emits only `route_id` (logical id), `corridor_ref`, `role`, `owner_posture`, `native_rebuild_required`, `proof_class`, `advisory_provider_proof` — no URL paths, no provider identifiers; `test/crosswake/proof/phase23_commerce_support_proof_test.exs:34-37,355-379` enforces provider-vocabulary fence (`store`+`kit`, `play`+`_billing`, etc. compile-time concatenated) on canonical `SupportMatrix.commerce_corridors()` data and `:401-435` on merge-blocking doctor findings. |
| P23-01-T04 | CLOSED | denial_of_service | mitigate | `lib/crosswake/support_matrix/support_matrix.ex:39-43,63-67,88-92,113-117` declare structured `rebuild_requirement` map on every corridor (sourced from support matrix metadata, not heuristics); `lib/crosswake/doctor/doctor.ex:677-684+` derives `native_rebuild_findings/2` from canonical entries; advisory provider proof is supplementary (`advisory_provider_proof` flag, never substitutes for core proof_class) — workflow `.github/workflows/phase23-proof.yml:111-116` keeps `advisory-commerce-proof` non-gating (`continue-on-error: true`, scheduled/dispatch-only `if:` gate). |
| P23-02-T01 | CLOSED | tampering | mitigate | `test/crosswake/support_matrix/renderer_test.exs:137-145,178` asserts `File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())` byte-identity; `test/crosswake/guides/commerce_test.exs:173-212` asserts corridor roles in `guides/commerce.md` ownership matrix match `Crosswake.SupportMatrix.commerce_corridors/0` exactly (no extra/missing roles). |
| P23-02-T02 | CLOSED | spoofing | mitigate | `guides/commerce.md:47,150,250-251,260` carries explicit "Advisory checks cannot redefine core support truth" / "advisory lanes are not core support truth" language; `test/crosswake/support_matrix/support_matrix_test.exs:238-239,402` restricts proof_class enum to `[:merge_blocking, :advisory]` at every corridor entry; `test/crosswake/guides/commerce_test.exs:156` ("commerce guide publishes explicit non-claim that advisory checks cannot redefine core support truth") locks the docs-contract assertion. |
| P23-02-T03 | CLOSED | repudiation | mitigate | `lib/crosswake/support_matrix/support_matrix.ex:16-23,248-249` declares canonical `@commerce_corridor_prerequisite_taxonomy` and exposes `commerce_corridor_prerequisite_taxonomy/0`; `test/crosswake/support_matrix/support_matrix_test.exs:327-335` asserts every corridor's `prerequisite_classes` is drawn from the canonical taxonomy MapSet; `:337+` asserts taxonomy contents are stable. |
| P23-03-T01 | CLOSED | spoofing | mitigate | `guides/commerce.md:150,176,204` carries layer-level + per-template (App Store / Play Store) `> Advisory — provider-specific guidance` callouts; Layer 3 non-claims section contains explicit "X is not shipped" statements for StoreKit, Play Billing, device-local authority, offline replay, storefront purchase UI; `test/crosswake/guides/commerce_test.exs:230-261` asserts callouts in playbook section, `:265-288` asserts every non-claim is explicit. |
| P23-03-T02 | CLOSED | repudiation | mitigate | `test/crosswake/guides/commerce_test.exs:339-360` ("reviewer template corridor roles cross-reference canonical SupportMatrix corridor roles") asserts every canonical role from `SupportMatrix.commerce_corridors/0` is present in the playbook section; `:366-382` asserts "How To Use These Templates" preamble cites both `commerce_corridor_denial_codes/0` and `commerce_corridors/0` accessors. |
| P23-03-T03 | CLOSED | information_disclosure | mitigate | `guides/commerce.md:178,206` contains sandbox account *setup instructions* (e.g. "Provide the App Store reviewer with a sandbox Apple ID provisioned with...", "Add the Play Store reviewer's Google account to the host app's licensed testers list") — no actual credentials, only placeholder/provisioning guidance pointing to `provider_setup` prerequisite; grep for credential patterns (`password`, `api_key`, `secret`, literal tokens) on `guides/commerce.md` returns zero hits. |
| P23-03-T04 | CLOSED | tampering | mitigate | `test/crosswake/guides/commerce_test.exs:310-338` ("reviewer fallback language uses canonical commerce.corridor.* denial codes") asserts every code returned by `SupportMatrix.commerce_corridor_denial_codes/0` appears in the playbook section's fallback descriptions; codes are cross-referenced against the canonical SupportMatrix accessor (not duplicated literally). |
| P23-04-T01 | CLOSED | elevation_of_privilege | mitigate | `.github/workflows/phase23-proof.yml:92-116` `advisory-commerce-proof` job is gated by `if: github.event_name == 'schedule' \|\| github.event_name == 'workflow_dispatch'` and carries `continue-on-error: true` — it never runs on `pull_request`/`push` and cannot fail the merge gate; `test/crosswake/proof/phase23_commerce_support_proof_test.exs:34-37,355-435` enforces provider-vocabulary fence on canonical support matrix data, the canonical reconciliation flow doc subsection, and every merge-blocking doctor finding. |
| P23-04-T02 | CLOSED | denial_of_service | mitigate | `test/crosswake/proof/phase23_commerce_support_proof_test.exs:510-549` self-test refutes `Code.require_file` lines loading non-fixture files and refutes call-shape regexes for `System.cmd(`, `Port.open(`, `:gen_tcp.X(`, `:httpc.X(`, `Req.get(`, `Tesla.get(`; `.github/workflows/phase23-proof.yml:77-90` `merge-blocking-commerce-proof` runs only the hermetic proof lane + 4 contract tests; lane executes in 0.3s with 14/14 passing during this audit. |
| P23-04-T03 | CLOSED | tampering | mitigate | `test/crosswake/proof/phase23_commerce_support_proof_test.exs:133-189,256,307,359` independently exercises `Doctor.commerce_summary`, `SupportMatrix.commerce_corridors/0`, and `SupportMatrix.commerce_corridor_denial_codes/0` and asserts the full commerce truth contract — a workflow YAML modification alone cannot suppress hermetic assertions because they live in the test source; the workflow file would have to *delete* the test step to silence the lane, which is a visible, reviewable diff. |
| P23-04-T04 | CLOSED | repudiation | mitigate | `.github/workflows/phase23-proof.yml:39-43` declares `workflow_dispatch:` and `schedule: - cron: "0 6 * * 1"` (weekly Monday 06:00 UTC); `:163-171` emits `::notice title=Advisory lane::` annotations so absence/presence of advisory runs is visible in the GitHub Actions dashboard. |

## Unregistered Flags

None.

`23-04-SUMMARY.md` "## Threat Flags" table explicitly declares no new security-relevant surface (`| (none) | — | No new security-relevant surface introduced. ... Threat register entries P23-04-T01..T04 are all mitigated as planned. |`). Plans 23-01, 23-02, and 23-03 SUMMARY frontmatter and bodies introduce no new attack surface beyond what the plan-time threat register already covers.

## Accepted Risks Log

None for this phase. Every declared mitigation is `mitigate` disposition and verified present.

## Notes On Verification Method

- Each `mitigate` threat was verified by grep-locating both the declared implementation pattern AND the test asserting the contract — declaration without test coverage was not accepted as evidence.
- The hermetic proof lane (`test/crosswake/proof/phase23_commerce_support_proof_test.exs`) acts as the cross-cutting integration verifier for P23-01-T02, P23-01-T03, P23-02-T01, P23-03-T01, P23-04-T01, P23-04-T02, and P23-04-T03; it was executed during the audit (14/14 passing) to confirm the assertions are live, not just compiled.
- Implementation files were read-only during this audit. No SECURITY.md write outside this file.

## Audit Result

**SECURED — 15/15 threats CLOSED.**
