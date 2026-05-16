# Crosswake Integrations and Companions

Purpose: identify which existing `szTheory` libraries create meaningful value for Crosswake adopters and for those libraries' user personas, and classify how those integrations should influence planning.

## Classification Model

Use one of four classifications for each integration:

- `core` - belongs inside Crosswake's first-party contract
- `companion` - should exist as a first-party optional package or tight integration
- `example/docs-only` - valuable to demonstrate, but not part of core contract
- `defer` - record as future context, not early roadmap scope

## Strong Early Candidates

### Sigra

Classification: `companion`

Why it matters:

- mobile apps still need auth, session, MFA, account recovery, and organization context
- Crosswake adopters building Phoenix companion apps will often need this immediately
- Sigra already has a generator-plus-library philosophy that aligns with host-owned app surfaces

Potential integration value:

- mobile auth/session handoff patterns
- secure account bootstrap inside native shell
- passkey/MFA/account-security flows that can selectively go native
- route policy examples for auth-sensitive screens

Persona/JTBD fit:

- Phoenix SaaS teams turning existing web auth into a mobile-capable account system

### Rulestead

Classification: `companion`

Why it matters:

- route policy and capability policy pair naturally with feature flags and remote config
- staged rollout of mobile runtime modes is safer with deterministic evaluation and explainability

Potential integration value:

- gating new native screens or offline islands
- runtime policy experiments
- kill switches for bad mobile features
- remote config for capability rollouts and route ownership changes

Persona/JTBD fit:

- teams rolling mobile capabilities out gradually or differently by environment, cohort, or org

### Rindle

Classification: `companion`

Why it matters:

- media lifecycle, uploads, variants, and secure delivery are central to mobile realities
- Crosswake research explicitly calls out media packs and native-media concerns

Potential integration value:

- media pack support
- presigned upload flows inside native shell
- native capture -> upload -> verification paths
- offline-aware queued media upload examples

Persona/JTBD fit:

- teams building camera, audio, video, or rich-content mobile features

### Chimeway

Classification: `companion`

Why it matters:

- mobile apps need notification delivery truth, suppression, and operator visibility
- push/inbox/event visibility fits the Crosswake mobile story

Potential integration value:

- notification journey tracing
- app inbox or event-driven mobile notifications
- route policies for notification deep links

Persona/JTBD fit:

- teams wanting explainable notifications instead of ad hoc push glue

### Threadline

Classification: `companion`

Why it matters:

- mobile route decisions, sync mutations, and offline replay all benefit from auditability
- support and incident response improve if actor/action/device context is preserved

Potential integration value:

- audit trails for mobile-originated actions
- sync/replay investigation
- route/runtime decision observability

Persona/JTBD fit:

- operators and teams debugging high-trust workflows or support incidents

### Parapet

Classification: `example/docs-only` early, likely `companion` later

Why it matters:

- mobile quality needs route and journey health, not just server metrics
- app teams need health signals for critical user flows

Potential integration value:

- health SLOs for route classes or mobile user journeys
- deployment markers tied to mobile shell/runtime releases

Persona/JTBD fit:

- teams operating serious production mobile surfaces, especially SaaS companions

## Bounded or Later Candidates

### Accrue

Classification: `example/docs-only` initially, `companion` later

Why it matters:

- billing and subscription apps are a strong Crosswake target
- app-store billing policy is a major mobile concern

Potential integration value:

- examples showing when billing overview stays LiveView and when purchase/paywall flows go native
- entitlement sync patterns

Reason not core:

- billing policy and provider specifics are large enough to distort v1 core

### Lattice Stripe / Oarlock

Classification: `defer`

Why they matter:

- potential low-level billing/payment provider integrations

Reason not early:

- they are too provider-specific for early Crosswake core
- better treated through Accrue-facing examples or later adapters

### Lockspire / Relyra

Classification: `defer`

Why they matter:

- some Phoenix teams may need provider-side identity or enterprise federation in mobile flows

Reason not early:

- not central to Crosswake's initial runtime-policy thesis

### Mailglass

Classification: `example/docs-only`

Why it matters:

- account lifecycle and transactional messaging often accompany mobile adoption

Reason not core:

- email is adjacent, not central, to route/runtime/mobile-shell architecture

## Contextual Candidates

### Scoria

Classification: `defer`

Value:

- useful for AI app archetypes that later use Crosswake, not core to the mobile substrate itself

### Scrypath

Classification: `defer`

Value:

- search indexing may matter in downstream apps, not in early Crosswake architecture

### Rendro

Classification: `defer`

Value:

- document generation may appear in app examples, but not in mobile-core design

### Cairnloop / Kiln

Classification: `defer`

Value:

- domain-specific downstream app integrations rather than core platform leverage

## Integration Heuristics

Crosswake should only pull an integration into core or a first-party companion when it does at least one of these:

- sharpens route/runtime policy meaningfully
- improves mobile install or operator truth materially
- solves a common mobile boundary problem for Phoenix teams
- creates meaningful value for the other library's existing user persona

It should stay out of core when it mainly:

- adds domain-specific feature weight
- depends on provider-specific behavior
- distracts from the route policy and runtime manifest thesis
- requires a new trust surface that Crosswake cannot prove early

## Recommended Planning Bias

For project initialization and early roadmap work:

- design with `sigra`, `rulestead`, `rindle`, `chimeway`, and `threadline` in mind
- explicitly mention `parapet` as an operational quality follow-on
- keep `accrue` and billing/provider work present in examples and constraints, not in v1 core
- record the rest as future ecosystem context so development decisions stay integration-aware without boiling the ocean
