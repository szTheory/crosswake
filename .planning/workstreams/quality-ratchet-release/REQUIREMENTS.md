# Requirements: v22.0 Quality Ratchet & Release Readiness

**Defined:** 2026-08-28
**Core value:** Crosswake stays safe to change, inexpensive to verify, pleasant to review, and ready
to release without weakening its Phoenix-first runtime contracts or its honest support claims.

## v22.0 Requirements

### Dependency Security

- [ ] **SEC-01**: Maintainers can run the root and example-host dependency audits with zero known
  security advisories.
- [ ] **SEC-02**: Phoenix, Phoenix LiveView, Plug, and their lockfiles resolve to patched versions
  that remain inside Crosswake's declared public compatibility ranges.
- [ ] **SEC-03**: Pull requests receive one stable, actionable dependency-security result that
  fails closed when a known advisory is introduced.

### CI Gate Integrity

- [ ] **CIG-01**: Every merge-blocking check context has exactly one authoritative producer, so a
  green duplicate cannot mask a red result.
- [ ] **CIG-02**: Every intended ExUnit test file, including example-host-tagged tests, is exercised
  by at least one merge-blocking CI path.
- [ ] **CIG-03**: Tests that mutate application configuration, code paths, files, or databases
  restore their state and pass both in isolation and in the full suite.
- [ ] **CIG-04**: Required aggregators fail closed for failed, cancelled, or missing required work
  while allowing explicitly irrelevant work to report a visible neutral result.

### CI Efficiency and Maintainability

- [ ] **CIP-01**: Pure Elixir and Android/JVM proof runs use Linux runners; macOS runners are
  reserved for work that actually invokes Apple tooling.
- [ ] **CIP-02**: Pull-request workflows do not duplicate equivalent work through overlapping push
  triggers or superseded cycles.
- [ ] **CIP-03**: Dependency and build caches are keyed by the relevant lockfiles and complete
  OTP/Elixir/JDK/Gradle toolchain identity, and cannot restore incompatible artifacts.
- [ ] **CIP-04**: Long-running jobs have bounded timeouts and concurrency rules that cancel obsolete
  work without cancelling a newer authoritative run.
- [ ] **CIP-05**: A documentation-only pull request completes an always-visible merge gate without
  scheduling unrelated build, browser, Android, or Apple proof jobs.
- [ ] **CIP-06**: Before/after evidence records workflow count, runner selection, queue time, and
  execution time so each optimization claim is reproducible.
- [ ] **CIP-07**: Repeated setup and proof orchestration is consolidated behind a small, readable
  set of reusable workflow or composite-action contracts without erasing named proof evidence.

### Engineering and Repository Quality

- [ ] **ENG-01**: The root suite, example host, browser proof, iOS package, Android package, format,
  and warnings-as-errors checks are deterministic from a clean checkout.
- [ ] **ENG-02**: Code touched by the milestone has explicit ownership boundaries, focused modules,
  and no known dead branches, accidental duplication, or misleading compatibility fallbacks.
- [ ] **ENG-03**: Generated, temporary, secret-bearing, editor, and local-only artifacts are either
  ignored or intentionally tracked, and a clean verification run leaves Git clean.
- [ ] **ENG-04**: Repository quality checks emit concise, actionable failures without stale phase
  labels, contradictory comments, or unactionable warning noise.

### Documentation and Pull-Request Hygiene

- [ ] **DOC-01**: Public guides, support/capability truth, architecture notes, contribution guidance,
  and release runbooks agree with the verified code and current package versions.
- [ ] **DOC-02**: The parked First B2C Adopter work remains codename-only, independently resumable,
  and visibly blocked only on its real external route/device authority.
- [ ] **DOC-03**: Every open pull request is merged, rebased, superseded, closed, or explicitly
  deferred with a current reason; no stale PR is left ambiguous.

### Release Readiness

- [ ] **REL-01**: The companion clean-room harness resolves, compiles, registers, and doctors every
  supported published companion from a throwaway host without false harness failures.
- [ ] **REL-02**: iOS mirror publishing uses explicit cross-repository authority, fails loudly when
  that authority is absent or insufficient, and has an automated, idempotent backfill command for
  the missing 0.2.0 mirror tag.
- [ ] **REL-03**: Core, companion, Android, and iOS release coordinates and compatibility floors are
  internally consistent and protected by drift checks.
- [ ] **REL-04**: The Crosswake 0.2.1 release candidate passes package audit, build, tests,
  documentation generation, clean-room installation, and release-status verification from the
  exact candidate commit.
- [ ] **REL-05**: All reversible release work is automated, leaving at most credentials and one
  explicit irreversible publish approval for the maintainer.

## Future Requirements

- **SEED-009**: Sigra hosted-session interoperability release remains separately gated on Sigra's
  authoritative handoff and independent verification.
- **SEED-010**: Reference-host presentation polish remains dormant until a bounded rehearsal/UI
  improvement is intentionally selected.
- **First-adopter activation**: Plans 163.1-08 through 163.1-10 resume only after the sanitized
  adopter handoff and physical-device authority exist.

## Out of Scope

- New native controls, menus, action buttons, navigation breadth, capture/device packs, commerce,
  dashboards, background sync, generic sync, or generic native storage.
- Android feature, template, generator, Maven, JVM, vector, device-proof, or parity expansion.
- Product-brand or showcase polish and customer-specific implementation.
- Invented adopter routes, identities, payloads, auth behavior, device evidence, or proprietary
  facts.
- Publishing an immutable package or tag without the final explicit maintainer approval.

## Seed Selection

- **SEED-003 selected:** iOS mirror authority and the missing 0.2.0 mirror tag are release debt.
- **SEED-004 selected:** companion clean-room proof must become trustworthy before another release.
- **SEED-007 selected:** CI gate integrity and queue/cost reduction are the milestone's main
  infrastructure ratchet.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|

**Coverage:** 0/26 requirements mapped (roadmap pending)

---
*Last updated: 2026-08-28 after autonomous milestone scoping*
