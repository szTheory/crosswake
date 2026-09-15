---
id: SEED-018
title: 173 collection assertions are vacuously true on an empty collection
status: dormant
severity: medium
trigger_when: >-
  Surface when hardening proof quality, or when any check is found to have been
  green while asserting nothing. NOT blocking — this is a remediation project,
  not a guard that can be switched on.
created: 2026-09-15
related: [SEED-017, TODO-009, TODO-011, TODO-012]
---

# SEED-018: `assert Enum.all?(collection, ...)` passes on an empty collection

## The finding

`Enum.all?([], fn _ -> false end)` is `true`. So is every `assert Enum.all?(...)`
whose collection turns out empty — the assertion passes while examining nothing.

The repository has **173 such call sites across 42 test files**:

```
grep -rnE 'assert Enum\.(all\?|any\?)' test --include='*.exs' | wc -l
```

Not all are defects. Many iterate a collection that cannot be empty — a literal
list, a fixed fixture. The defect is the subset whose collection is derived at
runtime from a glob, a parse, a filter, or a file read, where "found nothing" and
"everything passed" are the same result.

## Why this is a seed and not a check

It was scoped during the v22.0 close as a third check for
`script/check_absence_is_not_success.exs` and deliberately **not landed**.

A merge-blocking guard emitting 173 findings does not get fixed; it gets waived.
And a waived guard is worth less than no guard, because it additionally teaches
the team that red is negotiable. The two checks that did land
(`absence.mutation_control_asserts_change` and
`absence.open_finding_citation_resolves`) each had fewer than five real findings
and were fixed in the same change that introduced them.

This one needs the reverse order: audit and repair first, then a guard to hold
the line.

## Why it matters

This is the same defect class the v22.0 retrospective names — **absence scored as
success** — which showed up five independent times in a single milestone:

| Where | Shape |
|---|---|
| Release graph | Publication jobs skip on version mismatch, publish nothing, report nothing |
| Test citations | `mix test path:63` on a moved test prints `0 tests, 0 failures`, **exits 0** |
| Negative control | `\1` + digit read as capture group 10; mutation no-op, control asserted nothing |
| Exact-public proof | The job `needs:` ordinary publish jobs; 0.2.1 shipped via recovery, so it never ran |
| Receipt identity | Resolving `INVENTORY_PATH` globally would have made a receipt comparison permanently, vacuously true |

Each was green. Four were green for months.

## Suggested approach

1. Classify the 173 sites: collection provably non-empty vs. derived at runtime.
2. For the derived ones, add an explicit non-emptiness assertion **before** the
   `Enum.all?` — `assert [_ | _] = collection` or `refute Enum.empty?(collection)`.
3. Only once the count is at zero, add
   `absence.collection_assertion_non_empty` to
   `script/check_absence_is_not_success.exs`, restricted to collections derived
   from `Path.wildcard`, `File.read!`, `Regex.scan`, or a `Enum.filter` chain.

Step 3 without steps 1-2 produces a wall of red and teaches people to ignore it.
