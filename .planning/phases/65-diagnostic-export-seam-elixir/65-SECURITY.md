---
phase: 65
slug: diagnostic-export-seam-elixir
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-04
---

# Phase 65 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Diagnostic Export Seam (Elixir): redaction allowlist + typed envelope BEFORE any
> native export code. Behaviour-only `@callback export/1` — no transport ships.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| untrusted attrs map → `sanitize/1` | A caller (eventually the native shell in Phase 67) hands an arbitrary map that must become a typed `Envelope` or be rejected. The only untrusted-input crossing in this phase. | Arbitrary key/value map — potentially token/PII bearing |
| Crosswake lib → host-owned endpoint | Transport boundary documented (POST contract) but NOT implemented here. Network threats are host-owned, out of scope for Phase 65. | Serialized `Envelope` (typed codes only) — deferred to Phase 67 |
| Crosswake readiness reporting → operator | Operator reads `SupportMatrix` truth + `mix crosswake.doctor`; risk is misrepresentation (overclaiming a first-party reporter), not data leakage. | Readiness atoms + advisory doctor finding |
| proof lane → merge gate | The proof lane converts locked DIAG decisions into merge-blocking assertions; a weak/missing assertion is the threat (regression slips through). | Test assertions (`posture: :merge_blocking`) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-65-01 | Information Disclosure | Envelope / NativeDiagnostic struct shape | mitigate | Allowlist-by-construction. `diagnostic_export.ex:111-138` — `NativeDiagnostic` defstruct is exactly `[:source, :exit_reason]`; no `raw_payload`, no open map field. `Envelope` has 7 enforce-keys + nil-default `native_diagnostic`. | closed |
| T-65-02 | Information Disclosure | `sanitize/1` input map | mitigate | `diagnostic_export.ex:313-334` — checks `@forbidden_keys` (19-key set, lines 62-82) then `@envelope_fields` allowlist; returns `{:error, :redaction_failed}` on any hit. Proof DIAG-03 at `phase65_diagnostic_export_seam_test.exs:399-654`. | closed |
| T-65-03 | Repudiation | `sanitize/1` partial-data behavior | mitigate | Fail-closed `cond` (no drop-and-continue). `diagnostic_export.ex:388-401` routes nested `native_diagnostic` map through `new_native_diagnostic/1` (CR-01 fix). Proof tests reject all 19 nested forbidden keys at `:564-622`. | closed |
| T-65-04 | Information Disclosure | free-form crash text | accept (out of scope) | Stack traces are host-owned and un-allowlistable; contract carries typed codes only. See Accepted Risks Log. | closed |
| T-65-NET | Spoofing / Tampering | network transport to host endpoint | accept (host-owned) | No transport ships in Phase 65; POST implemented by native shell + host in Phase 67. See Accepted Risks Log. | closed |
| T-65-05 | Spoofing (misrepresentation) | SupportMatrix `@diagnostic_export_support_truth` | mitigate | `support_matrix.ex:271-290` — `delivery_supported: false`, 3 deferred atoms, `authority_source: :host_configured_endpoint`, posture "not a crash-reporting service". Proof `:668-750`. | closed |
| T-65-06 | Spoofing (misrepresentation) | Doctor `diagnostic_export.contract_shipped` finding | mitigate | `doctor.ex:848-868` — `:advisory` severity, message excludes "crash-reporting service"; wired into `run/1` at `:153,170`. Proof `:752-817`. | closed |
| T-65-07 | Tampering | `Bridge.Contract.commands/0` vocabulary | mitigate | `phase65_diagnostic_export_seam_test.exs:19-32` — `refute Enum.any?(commands, &String.starts_with?(&1, "diagnostics"))`, `posture: :merge_blocking`. | closed |
| T-65-08 | Elevation of Privilege | mix.exs deps + DiagnosticExport source | mitigate | `phase65_diagnostic_export_seam_test.exs:35-77` — greps mix.exs and module source for Req/Finch/HTTPoison/Mint/:httpc; merge-blocking. | closed |
| T-65-09 | Information Disclosure | `forbidden_keys` ⟂ `allowed_keys` + `sanitize/1` | mitigate | `phase65_diagnostic_export_seam_test.exs:398-654` — 19 inclusion + 19 exclusion + round-trip + forbidden-inject (×19) + out-of-enum + non-map + nested guards; all merge-blocking. | closed |
| T-65-10 | Spoofing (misrepresentation) | SupportMatrix truth + doctor finding | mitigate | `phase65_diagnostic_export_seam_test.exs:668-817` — asserts delivery_supported false, deferred atoms, host_configured_endpoint, posture, exactly one advisory, non-overclaim message. | closed |
| T-65-11 | Tampering | fixture drift | mitigate | `phase65_diagnostic_export_seam_test.exs:202-363` — six `assert_normalized_json_fixture` calls (one per axis), fixtures generated from `to_map/1`; merge-blocking. | closed |
| T-65-SC | Tampering | npm/pip/cargo/hex installs | mitigate | Phase adds NO dependency. mix.exs has no HTTP-client dep; proof lane asserts both mix.exs and module-source are HTTP-client-free as merge-blocking tests (`:35-77`). Registered in all 3 plans; single underlying evidence. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-65-01 | T-65-04 | Free-form crash text (stack traces, exception messages) is produced by the host process and is inherently un-allowlistable. The Elixir contract carries only typed closed-enum codes (`source`, `kind`, `exit_reason`); no free-form/open-map field exists in `Envelope` or `NativeDiagnostic`. The host endpoint owns any free-form text it appends. Confirmed: `diagnostic_export.ex` structs contain zero free-form or open-map fields. | gsd-security-auditor | 2026-06-04 |
| AR-65-02 | T-65-NET | No network transport ships in Phase 65. `@callback export(Envelope.t()) :: :ok \| {:error, term()}` (`diagnostic_export.ex:207`) is behaviour-only; no HTTP client/connection code exists. Native shell implements the POST in Phase 67; network-layer threats (TLS pinning, replay, MITM) are host-owned at the endpoint. Confirmed: grep for Req/Finch/HTTPoison/Mint/:httpc returns zero hits. | gsd-security-auditor | 2026-06-04 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-04 | 13 | 13 | 0 | gsd-security-auditor (sonnet) |

### Security Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Threats found | 13 |
| Closed | 13 |
| Open | 0 |

**Verdict:** SECURED. Register authored at plan time (all 3 PLAN files carry parseable `<threat_model>` blocks); auditor verified each `mitigate`-disposition mitigation exists in the implementation rather than scanning for new threats.

**Audit notes:**
- CR-01 (nested `native_diagnostic` redaction bypass) was found in code review and resolved before this audit. The fix (`diagnostic_export.ex:388-401`) routes untrusted nested maps through `new_native_diagnostic/1`; proof tests cover all 19 nested forbidden keys + a nested unexpected key. This is a strengthening beyond the plan-time mitigation, not a gap.
- T-65-SC appears in all three plans; all instances resolve to one underlying evidence set (no HTTP-client dep in mix.exs, no HTTP-client reference in module source, merge-blocking proof enforcement).
- No `@derive Jason.Encoder` invocation exists in `diagnostic_export.ex` (the string appears only in comments).
- No consolidated SUMMARY `## Threat Flags` section was produced (per-plan SUMMARYs only); no unregistered attack surface identified during verification.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-04
