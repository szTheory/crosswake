---
phase: 60
slug: example-host-registry-and-phoenix-wiring
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-02
---

# Phase 60 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Example Phoenix host Chimeway token-binding registry (push-token lifecycle persistence + audit).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| bridge/provider evidence → example-host persistence | Raw token and provider metadata arrive from untrusted runtime/provider sources and must be redacted before storage. | Raw push tokens, provider metadata |
| backend auth/session context → registry API / binding schema | Auth/session scope is backend-owned and must not be inferred from token possession. | `subject_ref`, `org_ref`, `session_ref` |
| mutable binding rows → append-only audit rows | Lifecycle state changes must preserve audit truth instead of overwriting or deleting it. | Binding state transitions |
| registry transaction → mutable/audit tables | Lifecycle writes must stay atomic so state and audit truth cannot diverge. | Binding + event rows |
| provider feedback → public lifecycle state | Provider-native facts must normalize into Chimeway reasons without widening support claims. | APNs/FCM feedback enums |
| committed transaction → telemetry | Success telemetry must reflect committed state only and stay redacted. | Telemetry metadata |
| shipped registry API → public proof/docs surface | Public proof and guidance must preserve the same authority and non-claim boundaries as the code. | README claims, proof assertions |
| dependency file → compiled runtime | Background-job dependencies or worker code can silently widen the shipped surface. | `mix.exs` deps, compiled modules |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-60-01A | Information Disclosure | `token_binding.ex`, `metadata_sanitizer.ex`, binding migration | mitigate | Only `token_ref`/`token_fingerprint` fields (`token_binding.ex:35-36`); sanitizer drops 16 forbidden atom+string keys (`metadata_sanitizer.ex:10-43`); no raw-token columns in migration | closed |
| T-60-01B | Spoofing | `token_binding.ex` scope validation | mitigate | `validate_scope_consistency/1` enforces `subject_scope` enum (`token_binding.ex:128-143`); context required from backend map, not token evidence | closed |
| T-60-01C | Tampering | binding migration partial unique indexes | mitigate | Three named `WHERE state='active'` partial unique indexes (`20260602100000:51-97`) + matching `unique_constraint` calls (`token_binding.ex:111-125`) | closed |
| T-60-01D | Repudiation | `token_binding_event.ex`, audit migration | mitigate | No `references/2`, no `on_delete: :delete_all` (`20260602100100:46-50`); insert-only, no update/delete functions | closed |
| T-60-01E | Information Disclosure | phase proof scaffold | mitigate | Source-level + runtime sentinel assertions (`phase60_chimeway_registry_test.exs:137-159, 543-555`); 0 sentinel matches across production files | closed |
| T-60-01F | Elevation of Privilege | Phase 60 schema scope | accept with proof | See Accepted Risks Log. Merge-blocking worker/scheduler exclusion proof (`phase60_...:100-135`) | closed |
| T-60-02A | Spoofing | `registry.ex` context normalization | mitigate | `validate_context/1` requires backend `subject_ref`/`org_ref` (`registry.ex:1196-1213`); `normalize_evidence/1` rejects raw-token keys (`:1220-1242`) | closed |
| T-60-02B | Tampering | `bind_or_rotate/3`, revocation/pruning | mitigate | Named `Ecto.Multi` steps + guarded `update_all` (`b.state == :active`) + same-transaction audit inserts (`registry.ex:212-437, 510-985, 1078-1160`) | closed |
| T-60-02C | Repudiation | audit event creation | mitigate | `TokenBindingEvent` inserted in same `Ecto.Multi` before `Repo.transaction/1`; rows asserted present post-revoke/prune (`phase60_...:729-731, 774-776, 884-886`) | closed |
| T-60-02D | Information Disclosure | returned maps + telemetry metadata | mitigate | `telemetry_meta/2` emits only low-cardinality canonical fields (`registry.ex:1447-1460`); `MetadataSanitizer.sanitize/1` on all metadata (`:1298`) | closed |
| T-60-02E | Information Disclosure | provider feedback mapping | mitigate | `feedback_to_lifecycle/1` maps all provider events to canonical Chimeway atoms (`registry.ex:1260-1270`); no provider-native enum names in state/reason | closed |
| T-60-02F | Elevation of Privilege | registry API surface | accept with proof | See Accepted Risks Log. Registry exports only synchronous functions; merge-blocking scan (`phase60_...:92-135`) | closed |
| T-60-03A | Information Disclosure | `phase60_chimeway_registry_test.exs` | mitigate | Dedicated source-level + runtime inspect assertions (`:137-159, 543-555`); 0 sentinel occurrences in production source | closed |
| T-60-03B | Repudiation | proof/source assertions | mitigate | Asserts no `on_delete: :delete_all`/`references(` in audit migration (`:55-68`); audit + binding rows present post-revoke/prune (`:729-731, 884-897`) | closed |
| T-60-03C | Spoofing | `README.md` guidance | mitigate | Non-claim wording (`README.md:76, 80-81`); merge-blocking refutation of 4 forbidden overclaim phrases (`phase60_...:176-216`) | closed |
| T-60-03D | Tampering | dependency/runtime scope | mitigate | Strict package-name denial (`{:oban,`/`{:quantum,`/`{:broadway,`/`{:gen_stage,`) + source scan for scheduler loops (`phase60_...:100-135`); deps clean (`mix.exs:21-30`) | closed |
| T-60-03E | Information Disclosure | docs/proof examples | mitigate | Worker examples markdown-only, call registry APIs with sanitized refs (`README.md:83-135`); no raw-token strings in README | closed |
| T-60-03F | Elevation of Privilege | worker guidance | mitigate | Workers documented as host-owned optional recipes (`README.md:76-81, 133-135`); no compiled worker modules; merge-blocking boundary check (`phase60_...:100-125`) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-60-01 | T-60-01F | Worker/delivery orchestration kept outside Phase 60 schema scope; schema layer models only backend-owned lifecycle state. Residual: a future plan adding compiled workers needs a new threat assessment — Phase 60 proof catches such additions pre-merge. | gsd-secure-phase (auditor: sonnet) | 2026-06-02 |
| AR-60-02 | T-60-02F | Registry is synchronous and host-owned in Phase 60; background worker orchestration remains outside compiled scope, checked by Plan 03 assertions. Residual: identical to AR-60-01 — any compiled worker expansion is caught by the existing proof lane. | gsd-secure-phase (auditor: sonnet) | 2026-06-02 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-02 | 18 | 18 | 0 | gsd-secure-phase (gsd-security-auditor, sonnet) |

**Method:** State B — register built from plan-time `<threat_model>` blocks across 60-01/02/03-PLAN.md (`register_authored_at_plan_time: true`). Auditor verified each mitigation exists in implementation; no new-threat scanning. All 13 SUMMARY.md threat flags mapped to registered threat IDs; no unregistered flags.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-02
