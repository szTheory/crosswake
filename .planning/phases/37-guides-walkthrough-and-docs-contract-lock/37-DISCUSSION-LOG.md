# Phase 37: Guides Walkthrough And Docs-Contract Lock - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 37-Guides Walkthrough And Docs-Contract Lock
**Areas discussed:** Walkthrough placement, Code rendering depth, Docs-contract binding strength, Proof-file citation

**Mode:** advisor (calibration tier `minimal_decisive`, vendor_philosophy: opinionated). Owner is
technical (`technical_background: true` overrides non-technical signals → product-outcome reframing
NOT applied). No web-research agents spawned — decisions are internal-repo-convention judgment
calls fully grounded in the read of `guides/commerce.md`, `commerce_test.exs`, and the Phase 34–36
contexts; advisor acted as inline recommender.

---

## Walkthrough placement

| Option | Description | Selected |
|--------|-------------|----------|
| H3 in Layer 1 | `### Paywall Corridor Walkthrough` inside `## Commerce Support Truth`; preserves the three-layer intro + phase23 H2 assertions verbatim | ✓ |
| New 4th H2 layer | Promote to top-level `## Paywall Corridor Walkthrough`; needs intro rewording, risks phase23 layer-structure drift | |

**User's choice:** H3 in Layer 1 (Recommended)
**Notes:** The runnable corridor is canonical support truth, so it belongs in Layer 1. Keeps SC#4
(phase23 three-H2-heading test) green structurally.

---

## Code rendering depth

| Option | Description | Selected |
|--------|-------------|----------|
| Anchor-only | Prose + named module/function + relative file path per step; no copied code blocks | ✓ |
| Anchor + short snippets | Also embed 3–6 line snippets copied from example modules; more copy-able but drifts unless test-extracted | |

**User's choice:** Anchor-only (Recommended)
**Notes:** Zero drift risk; the docs-contract test locks names rather than snippet bodies. Directly
satisfies SC#1.

---

## Docs-contract binding strength

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: strings + live guard | String-presence for structure (heading, canonical field names, non-claims) PLUS `Code.require_file` pure example modules + `function_exported?/3` so renames break the test; stays hermetic | ✓ |
| String-presence only | Keep existing `content =~` idiom only; simplest, pure markdown, but `MockStorefront` could survive as a dead string after a rename | |

**User's choice:** Hybrid: strings + live guard (Recommended)
**Notes:** The crux of "docs-contract lock". Truest reading of the phase goal's "lock references
against the shipped example". Hermetic via the established Phase 34/36 require-file-pure-modules
idiom, so merge-blocking-safe.

---

## Proof-file citation

| Option | Description | Selected |
|--------|-------------|----------|
| Cite the proof | Reference `phase34_paywall_corridor_proof_test.exs` as the merge-blocking evidence behind the walkthrough | ✓ |
| Don't cite | Leave proof-lane mechanics to CI/proof-posture sections; "merge-blocking" stays implicit | |

**User's choice:** Cite the proof (Recommended)
**Notes:** Makes "the guide is a merge-blocking artifact" literally true (Phase 36 deferred note)
and hands adopters runnable evidence.

## Claude's Discretion

- `async: false` vs `async: true` for the guide test once it `Code.require_file`s pure modules.
- Exact relative require_file paths from `test/crosswake/guides/`.
- Whether to also assert the proof-file path string in the guide (locking D-08).
- Step prose, anchor formatting, describe/test naming, assertion message wording.
- Optional `@anchored_functions` attribute for readability.

## Deferred Ideas

- Embedded/extracted code snippets in the walkthrough (rejected for v3.4; future snippet-extraction
  test possible).
- Live-guarding `PaywallLive` / runtime modules (breaks hermetic-lane discipline; anchored by name
  only).
- ROADMAP SC#3/SC#4 rewording carried over from Phase 36.
- ExDoc zero-warnings cleanup (HEX-03), deferred in STATE.
