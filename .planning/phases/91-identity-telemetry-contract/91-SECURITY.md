---
phase: 91
slug: identity-telemetry-contract
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-09
---

# Phase 91 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| caller → `Threadline.Telemetry.metadata/1` | Arbitrary caller-supplied metadata map crosses into the telemetry bus; untrusted keys/values must be filtered before emission | metadata map (potentially PII-bearing) |
| `Threadline.Telemetry.execute/3` → `:telemetry` bus | Only allowlisted, safe-valued, non-forbidden metadata may reach attached handlers | sanitized 4-key allowlist metadata |
| native shell / Plug → bridge & activation envelopes | `thread_id` is opaque caller-supplied input; rides the wire but is never enforced or format-validated at the envelope (validation lives at Phase 92 Plug / Phase 94 ledger) | opaque `thread_id` string |
| envelope struct → `to_map/1` wire serialization | nil `thread_id` must serialize as absent, never as an explicit null key, to avoid wire-key drift for native JSON decoders | serialized envelope map |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-91-PII | Information Disclosure | `metadata/1` reduce-filter | mitigate | `@forbidden_metadata_keys` (20 keys incl. `:actor_ref`) at `telemetry.ex:41-62`; `metadata/1` reduce-filter `telemetry.ex:109`. Proven by `telemetry_test.exs:53-76`, `:134-170`. | closed |
| T-91-CARD | Denial of Service (cardinality) | `safe_value?/1` | mitigate | `safe_value?/1` binary bound `String.length(value) <= 128` at `telemetry.ex:150`. Proven by `telemetry_test.exs:102-105`, `:108-111`. | closed |
| T-91-UNK | Information Disclosure | `metadata/1` allowlist | mitigate | All-or-nothing allowlist: only `key in @metadata_keys and safe_value?(value)` passes (`telemetry.ex:112-116`); catch-all drops unknown keys. Proven by `telemetry_test.exs:53-76`. | closed |
| T-91-SC | Tampering (supply chain) | dependency surface | accept | Zero new packages; only existing `{:telemetry, "~> 1.0"}` used; no OTel references in `telemetry.ex` or `mix.exs`. | closed |
| T-91-WIRE | Tampering (wire nil drift) | `to_map/1` (Request + Denial) | mitigate | `Enum.reject(is_nil)` on Request (`contract.ex:189`), Reply (`contract.ex:205`), Activation (`activation.ex:166`), and local nil-filter before `Types.to_map()` in `denial.ex:52-54`; shared `Types.to_map/1` unchanged. Proven by `contract_test.exs:275-289`, `:308-337`, `activation_test.exs:416-443`. | closed |
| T-91-ENF | Denial of Service (self-imposed deadlock) | `@enforce_keys` | mitigate | `thread_id` absent from `@enforce_keys` on all four structs (`contract.ex:27-37`, `:74`, `denial.ex:10`, `activation.ex:16-23`); carried as defaulted `thread_id: nil` only. Proven by `contract_test.exs:152-189`, `activation_test.exs:387-399`, closeout proof `:73-111`. | closed |
| T-91-VER | Repudiation (dishonest version signal) | `@version` bump | accept | Additive-minor `@version "1.1.0"` (`contract.ex:10`), Hex `"0.1.1"` (`mix.exs:4`); compatibility gate uses `Version.compare(...) != :lt` (`compatibility.ex:620`), not string equality, so 1.1.0 satisfies 1.0.0. | closed |
| T-91-PII-PROOF | Information Disclosure (closeout lock) | closeout proof (`Threadline.Telemetry`) | mitigate | Closeout proof locks published denylist + `execute/3` rejection: `phase91_threadline_contract_closeout_test.exs:27-67` (forbidden membership, `MapSet.disjoint?`, handler confirms `:access_token` absent). | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-91-01 | T-91-SC | Phase introduces zero new package dependencies — only the pre-existing `:telemetry` dep is used. No new supply-chain surface to mitigate; verified by no-OTel grep returning 0 and `mix.exs` deps unchanged. | gsd-security-auditor (verified) | 2026-06-09 |
| AR-91-02 | T-91-VER | Envelope `@version` 1.0.0 → 1.1.0 is an honest additive-minor signal ("envelope can now carry thread_id"), not a breaking 2.0.0. It is informational, not gate-wired; the compatibility gate uses semver `>=` so 1.1.0 satisfies a 1.0.0 requirement. No mitigation required. | gsd-security-auditor (verified) | 2026-06-09 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-09 | 8 | 8 | 0 | gsd-security-auditor (sonnet), verify-mode |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-09
