# Phase 97: Fix Guide Accuracy — conn.assigns Claim + record_in_multi Arity — Research

**Researched:** 2026-06-10
**Domain:** Elixir documentation accuracy — targeted guide line edits + hermetic parity test assertions
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (WR-03 fix wording):** Replace "places it in `conn.assigns[:thread_id]`" with:
  > "It stores the id in `Logger.metadata` under the `:crosswake_thread_id` key — read it in downstream plugs or controllers via `Logger.metadata()[:crosswake_thread_id]`."
  Rationale: Closes the adoption footgun by giving the explicit read path. The string `Logger.metadata()[:crosswake_thread_id]` is already exercised verbatim in `test/crosswake/plug/threadline_test.exs`. Do not weaken to a vague "Logger.metadata" mention without the read-path example.

- **D-02 (WR-02 fix):** Change `record_in_multi/2` to `record_in_multi/3` (multi, name, attrs) in the guide. The generated template in `priv/templates/crosswake/audit/ledger.ex.eex` already ships the correct 3-arity function. Guide is the only wrong artifact.

- **D-03 (parity test regression prevention):** Add 2 targeted assertions to the existing `test/crosswake/proof/phase96_threadline_docs_contract_test.exs`:
  1. `assert guide =~ "Logger.metadata"` — verifies the conn.assigns fix persists.
  2. `assert guide =~ "record_in_multi/3"` — verifies the arity fix persists.
  Both must follow the established custom-failure-message pattern (name the missing contract element + which file to update). Add to the phase96 file, not a new phase97 file.

### Claude's Discretion

- Exact prose surrounding the fixed lines (e.g., whether to retain the `(posture: :inbound) or mints a new id (posture: :minted)` rhythm or trim slightly).
- Whether to add a brief note about the configurable `:logger_metadata_key` NimbleOptions option alongside D-01 wording (approved as-is by user, so at planner's discretion if it aids clarity without adding verbosity).

### Deferred Ideas (OUT OF SCOPE)

- Configurable `:logger_metadata_key` documentation expansion — low-risk edge case; full NimbleOptions options table in the guide is a future documentation enrichment.
- Sweep for other guide inaccuracies beyond WR-02/WR-03 — explicitly out of scope. File a new phase if additional inaccuracies are found during implementation.
</user_constraints>

---

## Summary

Phase 97 is a targeted correctness patch for `guides/threadline.md`. Two documentation inaccuracies were surfaced in the v7.0 milestone audit (WR-02, WR-03): the guide claims `conn.assigns[:thread_id]` when the Plug never calls `Conn.assign/3` (it uses `Logger.metadata`), and the guide references `record_in_multi/2` when the generated template ships arity 3.

Both bugs are single-line fixes with zero ambiguity. The source of truth for each fix is already in the codebase: `lib/crosswake/plug/threadline.ex` for WR-03, and `priv/templates/crosswake/audit/ledger.ex.eex` for WR-02. The replacement wording for WR-03 is locked in D-01. Two regression-prevention assertions must be added to the existing Phase 96 hermetic parity test file.

The only coordination requirement is that the guide edits and the parity test assertions must be authored to match each other exactly — the test asserts substring presence in the guide, so the guide text must contain the substrings the test checks. The planner should treat these as a single atomic task/commit.

**Primary recommendation:** One atomic task — edit guide + add two test assertions — in one commit. No new files, no new test infrastructure, no new packages.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guide doc accuracy (WR-03) | Documentation | — | Single markdown line edit in `guides/threadline.md` |
| Guide doc accuracy (WR-02) | Documentation | — | Single markdown line edit in `guides/threadline.md` |
| Regression prevention (D-03) | Test layer | — | Two assertions added to existing hermetic ExUnit test file |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | built-in (Elixir 1.19) | Test framework for parity assertions | Already used in `phase96_threadline_docs_contract_test.exs` [VERIFIED: existing codebase] |
| Mix | 1.19.5 | Build tool / test runner | Project standard [VERIFIED: existing codebase] |

### Supporting
None — this phase installs zero external packages. All changes are documentation edits and test assertion additions within existing files.

### Alternatives Considered
None applicable — no library choices to make.

**Installation:** None required.

---

## Package Legitimacy Audit

No external packages are installed in this phase. This section is intentionally empty.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
guides/threadline.md  (markdown source of truth for adopters)
      |
      | line 22 edit: "conn.assigns[:thread_id]"  →  "Logger.metadata..."  (WR-03)
      | line 128 edit: "record_in_multi/2"  →  "record_in_multi/3"  (WR-02)
      v
test/crosswake/proof/phase96_threadline_docs_contract_test.exs
      |
      | File.read!("guides/threadline.md")  →  guide
      | assert guide =~ "Logger.metadata"   (new D-03 assertion #1)
      | assert guide =~ "record_in_multi/3" (new D-03 assertion #2)
      v
CI hermetic proof lane (phase96-proof.yml) — merge-blocking gate
```

### Recommended Project Structure

No structural changes. All edits are within existing files:

```
guides/
└── threadline.md           # 2 line edits (WR-02 + WR-03)

test/crosswake/proof/
└── phase96_threadline_docs_contract_test.exs   # 2 new assertions added
```

### Pattern 1: Hermetic Parity Assertion with Custom Failure Message

The existing Phase 96 test establishes this pattern. New assertions MUST follow it exactly.

**What:** `assert guide =~ "exact substring"` with a named-contract failure message pointing to the file to update.

**When to use:** Whenever a documentation contract string must be mechanically enforced against guide drift.

**Example (from existing `phase96_threadline_docs_contract_test.exs` lines 192–194):**
```elixir
# Source: existing test/crosswake/proof/phase96_threadline_docs_contract_test.exs
assert guide =~ "Hash-chaining does not prevent tampering — it reports it.",
       "guides/threadline.md must contain the verbatim D-10 hash-chain sentence: " <>
       "'Hash-chaining does not prevent tampering — it reports it.' — do not paraphrase"
```

**Pattern for D-03 assertions:**
```elixir
# WR-03 regression prevention (add near Propagation Contract assertions, ~line 50-70)
assert guide =~ "Logger.metadata",
       "guides/threadline.md must document Logger.metadata as the thread id storage location (WR-03) — " <>
       "update the Propagation Contract section, not conn.assigns"

# WR-02 regression prevention (add near record_in_multi usage)
assert guide =~ "record_in_multi/3",
       "guides/threadline.md must document record_in_multi/3 arity (WR-02) — " <>
       "update the Operations > Scaffolding the ledger section"
```

**Important coordination constraint:** The guide text written in the WR-03 fix must contain the substring `"Logger.metadata"`. The guide text written in the WR-02 fix must contain the substring `"record_in_multi/3"`. These are the exact strings the assertions check. [VERIFIED: codebase — D-01 wording contains "Logger.metadata"; D-02 fix produces "record_in_multi/3"]

### Anti-Patterns to Avoid

- **Splitting guide edit and test assertion into separate commits:** The assertion would fail between commits, causing a broken CI state. These must land together.
- **Weakening D-01 wording:** Do not replace `Logger.metadata()[:crosswake_thread_id]` with a vague mention of "Logger.metadata" without the read path. The read path is the DX win.
- **Adding a new test file:** D-03 explicitly targets the existing `phase96_threadline_docs_contract_test.exs`. A new file would fragment the hermetic lane.
- **Paraphrasing the parity assertion string:** The `guide =~ substring` check is exact. If the guide text changes, the assertion string must match. Coordinate the two edits.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Regression prevention | New test file/module | Add assertions to existing `phase96_threadline_docs_contract_test.exs` | D-03 is explicit; new file adds fragmentation overhead |
| WR-03 wording | New wording | D-01 wording verbatim | User-approved Option C; planner must not improvise a different phrasing |

---

## Runtime State Inventory

Step 2.5 SKIPPED: Phase 97 has no rename, refactor, or migration. This is a documentation line edit and test assertion addition.

---

## Common Pitfalls

### Pitfall 1: Assertion String Does Not Match Guide Text

**What goes wrong:** The new parity assertion checks for `"Logger.metadata"` but the guide edit writes something different (e.g., `"Logger.metadata()"` or `"logger metadata"`).
**Why it happens:** Guide edit and test assertion written in separate task steps without coordination check.
**How to avoid:** The planner should make both edits in a single atomic task. The executor should write the guide text first, then copy-verify the assertion substring matches a substring of what was written.
**Warning signs:** Test passes locally if assertions are added after guide is already wrong — run the test before and after to confirm the new assertions are actually catching the pre-fix state (optional, but useful for confidence).

### Pitfall 2: Breaking an Existing Parity Assertion

**What goes wrong:** The WR-03 fix rewrites line 22. If the rewrite accidentally removes text that an existing parity assertion checks for (e.g., `"posture: :inbound"`, `"posture: :minted"`), those tests will fail.
**Why it happens:** The existing line 22 contains `"(posture: :inbound) or mints a new id (posture: :minted)"`. The D-01 replacement wording does not explicitly call out whether to preserve this posture rhythm.
**How to avoid:** Review the existing 21 assertions in `phase96_threadline_docs_contract_test.exs` and confirm none of them assert against text that will be deleted by the WR-03 edit. None of the existing assertions check for `"conn.assigns"`, `"posture: :inbound"`, or `"posture: :minted"` in isolation — so the fix is safe. [VERIFIED: codebase grep of assertion strings]
**Warning signs:** Running `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` after the guide edit fails on a pre-existing assertion.

### Pitfall 3: WR-02 Fix Leaves "record_in_multi/2" Elsewhere

**What goes wrong:** Line 128 is fixed but a second instance of `record_in_multi/2` exists somewhere else in the guide.
**Why it happens:** Guide may have been edited multiple times; search + replace misses a second occurrence.
**How to avoid:** After the fix, grep the guide for `record_in_multi/2` to confirm zero occurrences remain. [VERIFIED: current guide has exactly one occurrence — line 128 only]

---

## Code Examples

### WR-03: Exact Current Text (line 22) — to be replaced

```markdown
# Source: guides/threadline.md line 22 (verified by grep)
The header name is `X-Crosswake-Thread-Id`. The plug reads an inbound header (posture: `:inbound`) or mints a new id (posture: `:minted`) and places it in `conn.assigns[:thread_id]`.
```

### WR-03: Replacement (D-01 wording)

```markdown
The header name is `X-Crosswake-Thread-Id`. The plug reads an inbound header (posture: `:inbound`) or mints a new id (posture: `:minted`). It stores the id in `Logger.metadata` under the `:crosswake_thread_id` key — read it in downstream plugs or controllers via `Logger.metadata()[:crosswake_thread_id]`.
```

Notes:
- The posture rhythm `(posture: :inbound) or mints a new id (posture: :minted)` is preserved (Claude's Discretion — retained for consistency with existing guide voice).
- The sentence is split into two: the posture description and the storage description. This is the clearest reading.
- The assertion substring `"Logger.metadata"` is present in this text. [VERIFIED: string appears in D-01 wording from CONTEXT.md]

### WR-02: Exact Current Text (line 128) — to be replaced

```markdown
# Source: guides/threadline.md line 128 (verified by grep)
Use `record_in_multi/2` to insert audit events inside an existing `Ecto.Multi` in the same transaction as the action they describe.
```

### WR-02: Replacement (D-02)

```markdown
Use `record_in_multi/3` to insert audit events inside an existing `Ecto.Multi` in the same transaction as the action they describe.
```

Notes:
- Only `record_in_multi/2` → `record_in_multi/3` changes. No surrounding prose changes needed.
- The assertion substring `"record_in_multi/3"` is present in this text. [VERIFIED: string directly from D-02]

### D-03: New Parity Assertions (to be added to phase96 test)

```elixir
# Source: pattern from existing phase96_threadline_docs_contract_test.exs lines 192–194
# Add near the Propagation Contract block (approximately after the telemetry event name tests, ~line 106)

# -------------------------------------------------------------------------
# conn.assigns fix regression guard (WR-03)
# -------------------------------------------------------------------------

test "guides/threadline.md documents Logger.metadata as thread id storage (WR-03)" do
  guide = File.read!("guides/threadline.md")

  assert guide =~ "Logger.metadata",
         "guides/threadline.md must document Logger.metadata as the thread id storage location (WR-03) — " <>
         "update the Propagation Contract section; the plug never calls Conn.assign/3"
end

# -------------------------------------------------------------------------
# record_in_multi arity regression guard (WR-02)
# -------------------------------------------------------------------------

test "guides/threadline.md documents record_in_multi/3 arity (WR-02)" do
  guide = File.read!("guides/threadline.md")

  assert guide =~ "record_in_multi/3",
         "guides/threadline.md must document record_in_multi/3 (WR-02) — " <>
         "update the Operations > Scaffolding the ledger section; the generated template ships arity 3"
end
```

### Confirmed Code Truth: Plug Never Calls Conn.assign/3

```elixir
# Source: lib/crosswake/plug/threadline.ex lines 44-47 (verified by Read tool)
logger_key = opts[:logger_metadata_key]
Logger.metadata([{logger_key, id}])

conn = Conn.put_resp_header(conn, header_name, id)
# No Conn.assign/3 call anywhere in the module.
```

### Confirmed Code Truth: Template Ships record_in_multi/3

```elixir
# Source: priv/templates/crosswake/audit/ledger.ex.eex lines 126-128 (verified by Read tool)
def record_in_multi(multi, name, attrs) do
  Ecto.Multi.insert(multi, name, changeset(%__MODULE__{}, attrs))
end
```

### Existing Test Confirms Logger.metadata Read Path

```elixir
# Source: test/crosswake/plug/threadline_test.exs line 62 (verified by Read tool)
assert Logger.metadata()[:crosswake_thread_id] == "logger-test-id"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `conn.assigns[:thread_id]` (incorrect) | `Logger.metadata()[:crosswake_thread_id]` | Phase 92 implementation (guide was written incorrectly) | Adopters following the old guide get nil from conn.assigns |
| `record_in_multi/2` (incorrect arity in guide) | `record_in_multi/3` (multi, name, attrs) | Phase 94 implementation (guide was written incorrectly) | Adopters copying the guide signature get a FunctionClauseError |

---

## Assumptions Log

No claims tagged `[ASSUMED]` in this research. All findings were verified directly against the codebase using Read tool or Bash grep.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims in this research were verified against the live codebase.**

---

## Open Questions

None. All decisions are locked in D-01, D-02, D-03. All source code verified. No ambiguity remains.

---

## Environment Availability

This phase is code/config changes only (markdown edits + Elixir test assertions). No new external dependencies.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Running tests | ✓ | Mix 1.19.5 / OTP 28 | — |
| ExUnit | Parity test assertions | ✓ | built-in (Elixir 1.19) | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `mix.exs` (standard) |
| Quick run command | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WR-03 | Guide says `Logger.metadata`, not `conn.assigns` | hermetic parity | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | ✅ (existing file; new assertion added) |
| WR-02 | Guide says `record_in_multi/3`, not `/2` | hermetic parity | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | ✅ (existing file; new assertion added) |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — the existing test infrastructure covers all phase requirements. No new test files or fixtures needed. Two assertions are added to an existing test file.

---

## Security Domain

This phase edits only documentation and non-sensitive test assertions. No authentication, session management, input validation, cryptography, or access control surfaces are touched. ASVS categories are not applicable.

---

## Sources

### Primary (HIGH confidence)

- `lib/crosswake/plug/threadline.ex` — Verified `call/2` never calls `Conn.assign/3`; `Logger.metadata([{logger_key, id}])` on line 45 is the storage mechanism.
- `priv/templates/crosswake/audit/ledger.ex.eex` — Verified `record_in_multi(multi, name, attrs)` on line 126 is arity 3.
- `guides/threadline.md` — Verified WR-03 text on line 22 and WR-02 text on line 128.
- `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — Verified assertion pattern and confirmed zero existing assertions will be broken by the guide edits.
- `test/crosswake/plug/threadline_test.exs` — Verified `Logger.metadata()[:crosswake_thread_id]` pattern on line 62 is stable public surface.
- `.planning/phases/97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity/97-CONTEXT.md` — Locked decisions D-01, D-02, D-03.
- `.planning/v7.0-MILESTONE-AUDIT.md` — WR-02 and WR-03 authoritative bug reports.

### Secondary (MEDIUM confidence)

None — no web sources needed; all answers derived from codebase inspection.

---

## Metadata

**Confidence breakdown:**
- Exact bugs: HIGH — both verified by direct grep/read of live files
- Replacement wording: HIGH — D-01 verbatim from CONTEXT.md
- Test assertion pattern: HIGH — copied from established Phase 96 pattern
- Coordination constraint (guide+test must match): HIGH — derived from `=~` substring semantics of ExUnit

**Research date:** 2026-06-10
**Valid until:** No expiry — codebase-grounded, not documentation-dependent
