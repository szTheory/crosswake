---
phase: 187-doctor-and-proof-fidelity
review: 187-REVIEW.md
critical: 0
warning: 4
info: 3
recorded: 2026-10-16
---

# Phase 187 review disposition

The standard-depth review of `fix(187)` `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (over `bd29400722e14bed74c987bf5a9903f486dc6fc2`) found no critical issue. It confirmed that the sentinels are matched exactly, that an all-zero commit is rejected on decode (so stored all-zero evidence is refused too), that physical-iPhone validation and promotion both require known provenance, that the offline precedence is incomplete > not_claimed > supported, that the harness `--evidence` parsing is correct, and that no home path or username leaks. The reviewer read code and tests; it ran nothing. No finding blocks completion. Two warnings are behaviour the phase decided on; the rest carry forward as advisory debt.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| WR-01 | warning | accepted (by design, D-01) | A missing or malformed host `shell.json` falls back to the generator's `template_version`, which counts as known. D-01 specifies exactly this order (host manifest, then generator constant, then sentinel). Revisit only if the template version is ever used to gate promotion. |
| WR-02 | warning | open | `Provenance.commit_ref/1` scrubs only `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`; a host directory without its own `.git` inside an enclosing repo can report the enclosing repo's HEAD, and other inherited `GIT_*` variables are not scrubbed. Fix before Phase 188 relies on advisory provenance from a nested host: check that `git rev-parse --show-toplevel` equals the host directory (else `git-unknown`) and scrub the remaining `GIT_*` variables. |
| WR-03 | warning | deferred (D-09) | `:cached_read_only` without `cache_contract` (and a non-island `:local_first` route without a contract) still reports `supported`. This is the known gap D-09 kept out of scope; the exact doctor output and triggers are in `187-DEFERRALS.md`, and control T_P pins it. |
| WR-04 | warning | open | `Evidence.provenance_known?/1` is public and only compares against the sentinels, so it returns true for an all-zero or malformed commit if called on unvalidated input. Safe today (every caller validates first). Fix in the next evidence change: make it private, or document and enforce validated-input only. |
| IN-01 | info | open | Noise in `provenance_test.exs` (a no-op pipe, `length` asserts). Cosmetic. |
| IN-02 | info | open | Ledger line numbers are display-only and drift with edits; 187-06 confirmed keys, rows and classifications unchanged. `--check` catches drift. |
| IN-03 | info | open | Doctor JSON now includes the router module name. `guides/install.md` (D-11) already says doctor JSON should not be pasted publicly; confirm no proof artifact retains doctor JSON before Phase 188. |
