# Phase 94: Audit Ledger Contract + Generator - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

A host team can run `mix crosswake.gen.audit` to scaffold a fully-formed, PII-free, append-only Ecto audit ledger with ProvenanceLane and advisory hash columns. The `Crosswake.Audit.Ledger` contract struct is available in core so producers know the canonical event shape.

**Delivers (LEDG-01..LEDG-06):**
- Generator `mix crosswake.gen.audit` that idempotently outputs a host-owned Ecto schema and migration.
- The `Crosswake.Audit.Ledger` struct defining the event shape.
- First-class `provenance` (`:device_claimed` vs `:backend_accepted`).
- Fail-closed PII guard `reject_pii_in_metadata/1` and HMAC `actor_ref` helper.
- `record/1` and `record_in_multi/2` write paths.

**Explicitly NOT in this phase:** Operator surfaces/CLI viewing (Phase 95), docs guide (Phase 96), cross-service propagation, APM/OTel functionality, or any UI dashboard (deferred).
</domain>

<decisions>
## Implementation Decisions

### Schema and Ecto Types
- **D-01: Provenance Field as Ecto.Enum:** Use `Ecto.Enum` for the `provenance` field `{:device_claimed, :backend_accepted}` to enforce at the application layer while generating a standard string or integer column in the database, avoiding native DB enums for simpler migrations.
- **D-02: Opaque Actor Ref and HMAC Helper:** The `actor_ref` is stored as an opaque string. Provide a helper (e.g., `Crosswake.Audit.actor_ref/2`) that uses `:crypto.mac` to anonymize internal user IDs, mirroring the pattern in `Chimeway.Redaction.fingerprint_token/2`.

### Security and PII Guard
- **D-03: Changeset Fail-Closed Guard:** The `reject_pii_in_metadata/1` is implemented as an Ecto Changeset function. It iterates over the keys in the `metadata` map and adds an error if any key matches a generated `@forbidden_keys` list (e.g., email, ip, name). This ensures records cannot be inserted if PII slips in.

### Immutability and Hashing
- **D-04: Append-Only by Omission:** Do not generate any `update` or `delete` functions or changeset wrappers for them. The Ecto schema should be treated as insert-only.
- **D-05: Advisory Hash Computation:** The `row_hash` and `prev_hash` are computed prior to insert. To avoid race conditions blocking concurrent inserts, `prev_hash` is "best effort" or "advisory" at insert time (e.g. fetching the max ID's hash via a quick query in `record_in_multi`, or just accepting gaps if concurrent). The docstrings must explicitly state this is advisory for offline tamper detection, not cryptographic transaction serialization. Use `:crypto.hash(:sha256, ...)` for the `row_hash`.

### Generator UX
- **D-06: Idempotent File Generation:** If the target migration or schema file already exists, `mix crosswake.gen.audit` prints `[crosswake] reused` and skips overwriting, matching `gen.sync` behavior.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Threadline Capstone
- `.planning/threads/threadline-audit.md` — Canonical definition of the v7.0 Threadline capstone.
- `.planning/phases/91-identity-telemetry-contract/91-CONTEXT.md` — To ensure alignment on the `thread_id` type and `source` semantics.
- `.planning/REQUIREMENTS.md` — Requirements LEDG-01 through LEDG-06.

</canonical_refs>

<code_context>
## Existing Code Insights

### Established Patterns
- **`gen.sync`:** The `mix crosswake.gen.sync` task provides the template for idempotent generation and file checking.
- **HMAC:** `Chimeway.Redaction.fingerprint_token/2` (`lib/crosswake/companions/chimeway/redaction.ex`) provides the blueprint for the `actor_ref` HMAC function.
- **Telemetry:** `Crosswake.Threadline.Telemetry` provides the existing metadata allowlist logic, complementing the PII guard on the DB side.

</code_context>

<specifics>
## Specific Ideas

- The `record_in_multi/2` helper should append to an `Ecto.Multi` struct, making it easy for the host app to insert an audit log transactionally alongside their domain mutations.
- The default `@forbidden_keys` list for metadata should be heavily populated with standard PII terms (`email`, `phone`, `ip_address`, `ssn`, `name`, `first_name`, `last_name`, `address`).

</specifics>

<deferred>
## Deferred Ideas

None.
</deferred>
