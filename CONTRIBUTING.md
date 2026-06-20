# Contributing to Crosswake

Thank you for contributing to Crosswake. This guide covers the conventions you need to follow when authoring changelog entries and choosing upgrade-impact labels.

## Upgrade Impact Labels

Every published `## [x.y.z]` release in `CHANGELOG.md` must carry an `### Upgrade Impact` subsection as the **first subsection** under the release heading (before `### Added`, `### Fixed`, `### Notes`, or any other subsections). This subsection tells adopters whether they need to rebuild and resubmit their native host app before deploying the Crosswake update.

### The four canonical change-class strings

Use one of these four strings **verbatim** as the headline — do not mint synonyms, abbreviations, or alternative tokens:

| String | Meaning |
|--------|---------|
| `docs-only` | Only guides, wording, examples, or advisory docs changed. No compatibility-axis or capability-version change. |
| `core-only/no native rebuild` | Core Elixir behavior, docs generation, doctor, or support rendering changed inside the existing contract axes. No native rebuild required. |
| `compatibility-bump only` | Compatibility declarations or package windows narrowed; a fresh binary is not automatically required for already-compatible adopters. |
| `native or companion rebuild required` | Native code, generated shell projects, entitlements, platform config, native dependencies, or companion-native integration code changed. Adopters must rebuild and resubmit their native host app. |

These strings come from the **single canonical taxonomy** in `Crosswake.SupportMatrix.change_class_entries/0` and are documented in the Change Classes table in [`guides/support_matrix.md`](guides/support_matrix.md#change-classes). Do not introduce a fifth class or a synonym — a rename that breaks this vocabulary will break the vocabulary/legend-parity test in `test/crosswake/guides/release_boundaries_test.exs`.

### Worst-case-wins rule

When a release bundles changes from multiple change classes, the `### Upgrade Impact` headline **must report the highest-impact class** (fail-safe toward rebuild). Then enumerate which specific bullets are actually lower-impact. Never under-report toward a lower class to reassure adopters.

**Example — a mixed release:**

```markdown
### Upgrade Impact

**native or companion rebuild required**

This release publishes updated native shell-core packages. Adopters must rebuild and resubmit.

Lower-impact changes bundled in this release (no native rebuild needed):

* **core-only/no native rebuild** — Threadline observability and doctor checks are Elixir-only additions; no native rebuild required.
```

### How to choose the correct class (human intent gate)

Crosswake's CHANGELOG is **hand-authored**. The release-please workflow runs `skip-changelog: true`, so there is no automatic conventional-commit derivation of the upgrade impact. The label is a human judgment call, reviewed at release time. Use this checklist:

1. **Did any native code, generated shell templates, entitlements, platform config, or companion-native integration change?**
   If YES → `native or companion rebuild required` (regardless of other changes in the same release).

2. **Did no native code change, but did compatibility-axis declarations or package version windows change?**
   If YES → `compatibility-bump only` (check that already-compatible adopters are not forced to rebuild).

3. **Did only core Elixir behavior change inside the existing contract axes, without touching native code or compatibility windows?**
   If YES → `core-only/no native rebuild`.

4. **Did only guides, wording, or advisory docs change?**
   If YES → `docs-only`.

When uncertain, **fail-safe toward the higher-impact class**. It is better to over-warn adopters (ask them to rebuild unnecessarily) than to under-report (cause silent native incompatibility in production).

### Link to the full compatibility guide

For a complete explanation of what each class means for adopters — including the denial signals they will see if they skip the required action — see:

- [`guides/compatibility.md`](guides/compatibility.md) — the primary adopter decision guide
- [`guides/support_matrix.md#change-classes`](guides/support_matrix.md#change-classes) — the canonical Change Classes table

### This is a human review gate

The intent-gate (choosing the correct class for a specific release) is a **human review step**, not an automated detection. Crosswake does not mechanically assert "this diff touches the contract" from prose — that would produce false positives and erode trust in the check. Instead:

- The `release_boundaries_test.exs` vocabulary/legend parity test ensures that any label used in the CHANGELOG is drawn from the locked four-string vocabulary AND still exists verbatim in the support matrix Change Classes table.
- The structural test ensures every non-historical `## [x.y.z]` release has exactly one `### Upgrade Impact` block.
- **Choosing the right class** for the specific changes in a release remains a documented human responsibility — a PR reviewer responsibility, not a CI detector.
