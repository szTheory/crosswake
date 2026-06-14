# Phase 111: Generator Rewire, Clean-Room Proof & Release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 111-generator-rewire-clean-room-proof-release
**Areas discussed:** Clean-room proof sequencing, Parity-check home & strictness, Doc reconciliation canonical path
**Mode:** advisor (USER-PROFILE.md present; calibration tier `minimal_decisive` from `vendor_philosophy: opinionated`)

---

## Gray-area selection

The template rewire itself (GEN-01/GEN-02) and several adjacent decisions were already locked by requirements + carried-forward Phase 110 decisions (D-12 version sourcing & `upToNextMajorVersion`/`from:` pinning, D-13 tag format, D-02 `0.1.2` target, D-04 `release-as` removal) — so they were NOT re-asked. User selected all three genuinely-open areas to lock down.

| Area presented | Selected for discussion |
|----------------|--------------------------|
| Clean-room proof sequencing | ✓ |
| Parity-check home & strictness | ✓ |
| Doc reconciliation canonical path | ✓ |

Each selected area was researched by a parallel `gsd-advisor-researcher` (Sonnet, minimal_decisive tier).

---

## Clean-room proof sequencing (PROOF-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Verify-after-publish, permanent release-time lane | Lane runs after the coordinated publish (`needs: [release-please, publish-hex, ios-mirror, android-publish]`), pinned to the just-cut version, polls for Maven propagation | ✓ |
| Gate-before-publish | Lane runs before publish against soon-to-be-published coordinates | (rejected — logically incoherent; can't resolve an unpublished dep without synthetic/fake paths) |

**User's choice:** Lock all three (verify-after).
**Notes:** Research confirmed gate-before requires synthetic registries/fake tags that prove a fake path, violating "install truth = product truth." The existing `publish-hex` hex.pm availability poll is the precedent for the Maven Central propagation patience-loop. Per-merge regression protection delegated to the static parity guard (complementary, not redundant). First green run is post-`0.1.2`-cut (in-phase).

---

## Parity-check home & strictness (PROOF-02)

| Option | Description | Selected |
|--------|-------------|----------|
| New static `ReadinessCheck` in existing `--check-publish` + test assertion | Extend `Crosswake.Doctor.PublishReadiness` with a `generator_coordinate_parity` check (static EEx render + parse, `local: false`); mirror assertions in `crosswake_gen_shell_test.exs` | ✓ |
| Standalone CI closeout-gate workflow | Separate `.github/workflows` gate (brand-structural sibling) | (rejected — duplicates existing logic, ~3 min BEAM startup for a ~100 ms assertion, no structural benefit) |

**User's choice:** Lock all three (static ReadinessCheck).
**Notes:** `--check-publish` infra already exists with `blocking`/`proof_class: :merge_blocking`. Static parse (assert correct published coordinates + live version + no monorepo/local leak) is the cheap deterministic per-merge layer; live resolution stays in the clean-room lane. Dual surface (doctor + `mix test`) so regressions surface locally.

---

## Doc reconciliation canonical path (DOCS-01)

| Option | Description | Selected |
|--------|-------------|----------|
| `install.md` canonical; surgically fix `adoption.md` | Keep existing canonical install guide; add `adoption.md` to `@allowed_docs`, reframe the "avoid generating shell" sentence, add cross-links | ✓ |
| New `guides/quickstart.md` as single entry point | Extract a fresh canonical install doc, demote install.md/adoption.md to satellites | (rejected — adds files + cross-link rot, doesn't solve the wording contradiction) |

**User's choice:** Lock all three (install.md canonical).
**Notes:** `install.md` already IS canonical (numbered walkthrough, in `@allowed_docs`, enforced by `docs_support_parity_check`). The `@allowed_docs` whitelist is inconsistent (adoption.md is a mix.exs extra but not whitelisted). Reframe makes "standalone published deps" and the gen.shell thesis simultaneously true: the shell is a thin host-owned wrapper depending on published cores.

---

## Claude's Discretion

- Exact CI job/step structure, runner matrix, SHA-pins, poll/backoff script shapes (within D-01).
- Generated app's own `versionName`/`MARKETING_VERSION` (adopter app version ≠ Crosswake dep coordinate) — sensible default, not a GEN-01 satellite version.
- Exact wording of `adoption.md` reframe + cross-link copy (within D-03b/D-03c).

## Deferred Ideas

- Per-PR clean-room variant (requires pre-published artifacts; static guard covers per-merge for now).
- GitHub Immutable Releases / mirror landing-page README (write at first mirror seed during the `0.1.2` cut).
- Real device/emulator proof lanes, route-policy-101 / troubleshooting guides, companion extraction, SPI submission (post-v11.0).
