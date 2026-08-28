# Phase 154: The Control-Contract Seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-29
**Phase:** 154-the-control-contract-seam
**Areas discussed:** all 8 presented — raise-vs-deny, denial shape, JS hook distribution, reply routing/concurrency, PROOF-04 assertions, capability vocabulary migration, haptics blast radius, CTRL-05 rebuild class + `interaction`

---

## How this discussion ran

Claude presented 8 gray areas across two multi-select questions. The user selected **all
eight** and directed: research each with subagents across ecosystem/idiom/prior-art/DX/
architecture/UX lenses, then *"think deeply one-shot a perfect set of recommendations so I
don't have to think"* — coherent with each other, consumer-perspective API design, brand-book
compliant, with the newer `brandbook/` superseding the older `prompts/` copy.

Five `gsd-advisor-researcher` agents ran in parallel, grouped so coupled decisions resolved
together rather than in isolation:

| Agent | Areas | Notable output |
|---|---|---|
| 1 | raise-vs-deny + denial shape | The two-moments reframe that dissolves the CTRL-02/CTRL-03 tension |
| 2 | JS hook distribution + misconfiguration detection | Found the iOS reply gap; found the latent transport bug in the draft hook |
| 3 | reply routing, correlation, timeouts, races | Found the same iOS gap independently; found the natives' vocabulary violation; disproved the double-answer fix |
| 4 | PROOF-04 + CTRL-05 + `interaction` | Found the catalog file already exists; found the `rebuild: nil` → `"nil"`-in-published-matrix bug |
| 5 | vocabulary migration + haptics blast radius | Found `legacy_ids` already fully wired; found the self-referential manifest entry |

No AskUserQuestion turns followed the initial selection — per the user's explicit instruction
to one-shot the recommendations rather than arbitrate sequentially.

---

## Raise vs. deny on undeclared capability

| Option | Description | Selected |
|--------|-------------|----------|
| Typed denial for undeclared too | Literal CTRL-02 reading; one code path; zero production crash risk | |
| Raise in `:dev`/`:test`, deny in `:prod` | No production crash | |
| Raise always (named exception); deny only for client-detectable states | Two undeclared-capability moments, split by direction | ✓ |
| Compile-time verification | Earliest possible signal | infeasible |

**Rationale:** the LiveView compiles before the router that assigns its route id, so
compile-time detection is structurally impossible (`~p`-style verified routes solve the same
ordering problem with a separate pass — adopted as a supplementary static check, not a
replacement). The decisive argument was honesty rather than DX: a `Shell.Denial` is evidence
*about the shell*, and in the undeclared case no request was made and no shell answered.
Environment-dependent semantics were rejected outright — `API-DESIGN.md`'s own consumer
critique names it the 3am footgun, correctly.

**Precedent that settled the "chainable can't raise" objection:** `Phoenix.LiveView.stream_insert/3`.

---

## Which denial shape adopters match on

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse `:unavailable_capability` for no-shell | Zero vocabulary growth, no vector regeneration | |
| New reason synthesized in JavaScript | Simplest hook | |
| New reason `:shell_unreachable`, minted in Elixir; hook reports a fact only | Collapse at `status`, distinguish at `reason` | ✓ |

**Rationale:** reusing `:unavailable_capability` would make the denial *false* — it asserts a
shell exists and lacks something — and merges two opposite remediations ("you're in a browser,
this is correct" vs "your binary is stale"). Capacitor independently reached the same split.
Minting in JS was rejected because it puts denial microcopy where it drifts and cannot be
gettext'd, and lets a non-core surface construct a `Denial`, which that module's own moduledoc
forbids.

**Naming conflict resolved:** agent 1 proposed `:shell_unavailable`, agent 3 `:shell_unreachable`.
Chose `unreachable` because it also honestly covers the timeout case.

---

## JS hook distribution

| Option | Description | Selected |
|--------|-------------|----------|
| Generate into host verbatim-copy (`gen.offline_ui` precedent) | Matches the "host owns it" ethos | |
| npm package | Familiar to JS devs | |
| Shell injects the hook (Cordova-style) | Zero adopter wiring in the native case | |
| LiveView 1.1 colocated hook | No shipped asset surface | |
| Ship `priv/static/crosswake.esm.js`, library-owned, `--eject` valve | The `phoenix`/`phoenix_live_view` convention | ✓ |

**Rationale:** shell-injection is definitionally fatal — the detector cannot be distributed by
the thing being detected, and it would put JS behind App Store review. Generation was rejected
on two grounds: silent protocol drift on the one file that decides whether the fail-closed
contract holds, and the discovery that the reference host **has no bundler at all**, so a
generator would write into a directory nothing builds. The no-component-tier anti-feature was
found not to apply — the project's own DNA distinguishes editable app code (generate) from
protocol-sensitive behavior (library-owned).

**Detection mechanism:** server-armed two-stage ack deadline, chosen over a mount handshake
because a handshake false-negatives per route. No comparable server-side detector was found
anywhere in the Phoenix ecosystem — every surveyed library fails silently.

---

## Reply routing and concurrency

| Option | Description | Selected |
|--------|-------------|----------|
| Per-call `reply_to:` event name | Reads nicely at one call site | |
| `handle_event` + raw string map | Literally the LiveView docs' pattern | |
| `start_async` / `AsyncResult` | Nice loading/failed shape | impossible |
| `handle_info` + typed `%Bridge.Reply{}` + opt-in opaque `ref:` | Typed at the seam; library owns the reserved event | ✓ |

**Rationale — three researchers proposed three incompatible contracts; this was the hardest
reconciliation.** Per-call `reply_to:` was disproved by prior art: Hotwire Native correlates by
event name and `receivedMessage(for:)` returns only the *last* message of that name, which
breaks at 20 rows. `start_async` is structurally impossible — it runs a `Task` on the server
while a bridge ask completes on the client. Raw string maps were rejected as off-DNA for a
protocol-typed library, especially given the wire denial is *doubly* nested today.

**Caveat recorded in CONTEXT.md:** the `handle_info` choice partly rests on `attach_hook(:handle_event)`
having no documented way to rewrite the params the adopter's clause receives. Planning must
verify that against the installed `phoenix_live_view` before locking it.

**`API-DESIGN.md`'s double-answer fix was disproved:** identical event names do not deduplicate;
they guarantee the same mutation runs twice. Replaced with `Bridge.resolve(socket, ref)`.

---

## What PROOF-04 actually asserts

| Option | Description | Selected |
|--------|-------------|----------|
| New `priv/control_catalog.exs` attestation file | Uniform six-criteria coverage | |
| Pure code-shape guards | Real teeth, drift-proof | |
| `boundary` lib / credo custom check | Off-the-shelf | |
| Both, on the **existing** `capability_catalog/0` | Full coverage, no new data file | ✓ |

**Rationale:** the attestation file already exists and is already committed — creating a second
one would produce five-way drift (new file + catalog + `@commands` + `@capability_commands` +
two native enums), recreating exactly the problem `API-DESIGN.md` rejects for a separate
`controls:` block. Credo was rejected because its checks carry `# credo:disable-for-next-line`
— a gate with an inline escape hatch is not a gate.

**Honesty note carried into CONTEXT.md:** four criteria are mechanical, one is mechanical only
in the negative, one is attested with a structural proxy. The test's moduledoc must say so
rather than fake six checks. PROOF-04 closes the *mechanical* road to a plugin catalog; it does
not stop maintainers adding forty controls one string at a time.

---

## `haptics.impact` → `haptics`

| Option | Description | Selected |
|--------|-------------|----------|
| Hard-switch + reject legacy ids | Single vocabulary, no drift possible | |
| Compile-time deprecation warning | Loudest signal | impossible |
| Status quo | Zero work | |
| Hard-switch published vocabulary; keep `legacy_ids` accepted; doctor advisory | Docs-only change | ✓ |

**The reframe that decided it:** this is not an API change. `legacy_ids` is already fully wired
and both forms already authorize — zero adopter code breaks under any option, so two of the four
"options" were descriptions of the shipped state rather than alternatives. A compile-time warning
was found mechanically impossible (`Policy.Validator` never runs at router expansion). Breaking
the legacy form was rejected on the Ash 3.0 precedent — that rename shipped codemods and an
upgrade guide, at a major; Absinthe 1.4→1.5 is the cautionary counter-case.

---

## Haptics migration blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| Panel deleted | Smallest diff | |
| Panel frozen as-is (dispatch fields only) | Tests barely change | |
| Panel evolves to dispatch **and** reply, with a live region | Proves the whole round trip | ✓ |

**Rationale:** the JTBD lens decided it. The reader is a skeptical developer running the
showcase in a desktop browser, where there is no shell — so after migration the *default*
experience becomes the strongest demo Crosswake has. Freezing the panel was rejected as
"cheap and dishonest": it would show a hand-copied summary of an envelope it no longer builds,
reintroducing the exact drift `API-DESIGN.md` §0 names as problem #1.

**Highest-risk edit identified:** the e2e helper regex-scrapes a `<script>` tag that is being
deleted, and it gates a required check.

---

## CTRL-05 rebuild class + `interaction`

| Option | Description | Selected |
|--------|-------------|----------|
| CTRL-05 as new machinery | Build changelog/matrix/doctor surfacing from scratch | |
| CTRL-05 as a surfacing pass over existing v14 machinery | ~85% already wired | ✓ |
| `interaction` deferred to 156 | Avoid an unused enum value | |
| `interaction` in 154, two values (`:fire_and_forget \| :answering`) | As proposed in `API-DESIGN.md` §4 | |
| `interaction` in 154, **three** values | `:fire_and_forget \| :device_answer \| :user_answer` | ✓ |

**Rationale:** the two-value enum is ambiguous for four already-shipped commands, and the
ambiguity lands hardest on **share** — which returns a payload, so a maintainer would
reasonably mark it `:answering`, which is precisely the lie the honesty rule exists to prevent.
Deferring to 156 would mean two manifest schema bumps in one milestone, in a project whose
brand is compatibility honesty.

---

## Claude's Discretion

Per the user's explicit instruction (*"one-shot a perfect set of recommendations so I don't
have to think"*), **every** decision D-01 through D-77 is Claude's call from researched
evidence rather than a user selection. Four are flagged in CONTEXT.md as worth a human glance
before execution: D-02 (iOS return leg — touches milestone sequencing), D-16 (a structural
test that fails today), D-17 (one-way, with a verification caveat), D-77 (scope).

---

## Deferred Ideas

Captured in full in CONTEXT.md's `<deferred>` section. Summary: flattening the wire double-nest
(frozen until a protocol major), the typed `Outcome` sum type (157), payload widening beyond
`[String: String]` (156), per-capability default timeouts (156), `action_menu.dismiss` (156),
per-family HEEx wrappers (155/156), whether the builder should mint compat registry entries at
all, and — if not affordable in 154 — the natives' out-of-vocabulary denial reasons, which must
be deferred with a named seed rather than silently.

No scope creep was proposed during this discussion; the phase boundary from ROADMAP.md held.
