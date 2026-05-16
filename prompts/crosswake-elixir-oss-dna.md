# Crosswake Elixir OSS DNA

Purpose: capture the maintainer's recent Elixir/Phoenix library patterns, best practices, and footguns so Crosswake starts from repo truth instead of generic advice.

## Source Set

Primary repos sampled from `~/projects` and `gh repo list szTheory --language Elixir`:

- `sigra`
- `parapet`
- `scoria`
- `rindle`
- `chimeway`
- `threadline`
- `lockspire`
- `mailglass`
- `accrue`
- `rulestead`

Secondary contextual repos:

- `lattice_stripe`
- `oarlock`
- `relyra`
- `rendro`
- `scrypath`
- `cairnloop`
- `kiln`

## Core House Style

### 1. Install truth is product truth

The strongest repos repeatedly optimize for the first integrator experience:

- installers or generators for the happy path
- concrete "first hour" docs
- explicit distinction between host-owned code and library-owned code
- narrow supported entrypoints instead of fuzzy "just use internals" guidance

Crosswake implication:

- a crisp install path matters as much as the architecture
- generated host code, runtime config, and native-shell setup boundaries must be explicit
- docs should separate "greenfield happy path" from upgrade and advanced cases

### 2. Public contract honesty beats breadth

Across `sigra`, `threadline`, `mailglass`, `rindle`, `accrue`, and `rulestead`, the stronger pattern is:

- public APIs are named
- optional surfaces are documented as optional
- support matrices are explicit
- non-goals are written down

Crosswake implication:

- do not claim universal mobile support
- publish a capability/support matrix early
- document which route/runtime modes are official and which are future/deferred
- make companion-package or adapter boundaries explicit

### 3. Proof lanes are part of the product

The repo family repeatedly treats verification as first-class:

- CI jobs are named around behavior, not just "test"
- generated-host or example-app lanes prove the public contract
- docs-contract checks prevent README drift
- provider-specific or advanced lanes are often advisory, while hermetic lanes stay merge-blocking

Crosswake implication:

- plan at least one deterministic host-app proof lane
- validate route policy and shell behavior from the same public path users adopt
- split merge-blocking hermetic lanes from advisory device/store/provider lanes

### 4. Release truth matters

Several repos treat release automation and recovery as part of trust:

- `release-please` or equivalent release workflows
- publish gates inside trusted environments
- version verification before publish
- recovery-only manual publish lanes

Crosswake implication:

- release automation should be designed early, not bolted on
- runtime compatibility and multi-package versioning need careful release discipline
- mobile-shell companion artifacts may eventually require a stronger release model than a single Hex publish

### 5. Phoenix-native operator surfaces are acceptable when they earn their keep

`sigra`, `threadline`, `mailglass`, `rulestead`, `accrue`, `scoria`, and `lockspire` all validate the pattern that a mounted LiveView operator/admin surface can be a real adoption accelerator.

Crosswake implication:

- a Phoenix-native diagnostics or manifest-inspection surface may be worth having
- operator screens should exist only when they improve install, debugging, capability inspection, or runtime truth
- do not create UI surface area that outruns the core library contract

## Reusable Best Practices

### CI/CD

- Treat formatting, linting, docs build, package validation, and behavioral proof as separate concerns.
- Use matrix lanes only where compatibility really matters.
- Keep one deterministic core lane merge-blocking.
- Prefer named verification commands (`mix verify.*`, doctor tasks, package checks) over opaque shell soup.

### Docs

- Keep root README as the map, not the whole book.
- Point users into deeper guides after the first-run path.
- Maintain "what ships," "what is stable," and "where code lives" sections.
- Separate public API contract from internal reachability.

### Package design

- Use companion packages when they materially reduce unnecessary dependencies.
- Keep host-owned concerns in host code where practical.
- Use generators when adopters need editable app code.
- Keep security-sensitive or protocol-sensitive behavior library-owned.

### Runtime behavior

- Optional dependencies should fail honestly when enabled but missing.
- Doctor tasks are valuable when runtime surface is broad or platform-sensitive.
- Telemetry should reflect meaningful domain events, not just low-level implementation noise.

### Planning and roadmap discipline

- `.planning/PROJECT.md` should encode north star, core value, constraints, and non-goals.
- milestone and audit artifacts are part of long-term project memory
- later milestones should not reopen already-settled fundamentals casually

## Crosswake-Specific Lessons

### From Sigra

- generator plus library hybrid can balance host ownership with centralized updates
- optional dependency validation is worth the effort
- install/idempotency proof is a powerful trust signal

Crosswake takeaways:

- likely needs explicit host/native boundary generators
- likely benefits from doctor-style checks for native shell, bridge, and capability setup

### From Threadline

- support lanes and integration contracts should be written down
- operator surfaces can remain narrow and still create serious value
- docs can explain when to choose one public API over another

Crosswake takeaways:

- route/runtime support lanes should be explicit
- "which runtime mode should I use first?" needs documentation, not guesswork

### From Rindle

- a focused public onboarding contract is stronger than an all-inclusive README
- media-heavy libraries need runtime/environment doctors and honest prerequisites
- generated-app proof from packaged artifacts is powerful

Crosswake takeaways:

- media packs and native-media integrations need explicit prerequisites and diagnostics
- shell/runtime proof should come from the adopter-facing surface

### From Mailglass

- sibling packages can keep the core lean while enabling richer operator/admin experiences
- stability policy docs help keep ambitious libraries trustworthy

Crosswake takeaways:

- likely benefit from a narrow core package plus optional companions later
- stability and compatibility policy should be spelled out early

### From Lockspire

- protocol-heavy libraries need exactness, test gates, and explicit out-of-scope boundaries
- conformance and security checks can become part of CI, not just docs

Crosswake takeaways:

- bridge protocol and capability negotiation deserve strict versioning and proof
- security constraints around origins, allowlists, and route activation should be explicit and tested

### From Accrue and Rulestead

- sibling package monorepo shapes can work well
- support matrices and operator honesty prevent broad-surface confusion
- linked releases require discipline

Crosswake takeaways:

- if Crosswake becomes a multi-package project, versioning policy must be designed intentionally
- remote config / route gating integration with `rulestead` is likely high-leverage

## Footguns To Avoid

- vague claims about what is production-ready
- broad compatibility claims without CI or example proof
- hidden reliance on live providers or physical devices for the only real proof path
- unclear public-vs-internal API boundaries
- optional dependency sprawl without diagnostics
- README drift from actual shipped behavior
- letting marketing framing outrun architectural truth
- tying the project to one unstable upstream extension point

## Recommended Crosswake Defaults

- Start narrow, document the support envelope, and prove that envelope hard.
- Prefer a deterministic example-host path over store-submission theater in early milestones.
- Make route policy and runtime truth inspectable.
- Keep native integration seams explicit and versioned.
- Add release and publish automation once the package shape is clear, not after the surface sprawls.
