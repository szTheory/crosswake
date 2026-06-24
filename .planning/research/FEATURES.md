# Runtime-Contract Compatibility Semantics & Adopter Communication

**Project:** Crosswake v14.0 Runtime Contract Confidence  
**Researched:** 2026-06-20  
**Type:** API design from the consumer's perspective + docs-UX  
**Audience:** Single maintainer turning this into milestone requirements + roadmap

---

## Context: The Drift Problem This Solves

The immediate trigger for this research: `Crosswake.Bridge.Contract` defaults `@version "1.1.0"` but the manifest types module uses `@bridge_protocol_version "1.0.0"` and existing example/native proof paths emit `1.0.0`. An otherwise valid bridge request is silently denied because two canonical surfaces disagree. This is not an academic versioning question — it is an active production-confidence defect in a library that asks adopters to trust a runtime contract.

The milestone goal: a skeptical Phoenix SaaS developer should be able to answer "do I need to rebuild my native shell?" without reading source code.

---

## Part 1: Versioning Semantics

### The Three Axes and Their Meaning

Crosswake tracks three independent contract axes. Each has a distinct physical meaning that determines what "breaking" means:

| Axis | What it describes | Who reads it | What changes it |
|------|-------------------|--------------|-----------------|
| `manifest_schema_version` | The shape of the JSON/struct manifest itself — which top-level sections exist, what fields routes carry, what keys capability registries use | Native shell at boot, when parsing the bundled manifest file | Adding new top-level manifest sections; changing required vs optional field semantics; removing fields the shell depends on at parse time |
| `bridge_protocol_version` | The wire envelope for request/reply — which fields the envelope carries, what commands are legal, what `status`/`denial` shapes look like at the JSON level | Native shell bridge implementation, for every bridge round-trip | Adding envelope fields the shell must understand to function; changing field types; renaming denial reasons; removing commands |
| `native_runtime_version` | The compiled native binary's capability surface — entitlements declared, SDK dependencies linked, platform APIs available | Elixir side, during activation and bridge checks | Changes requiring recompilation of the native binary: entitlement changes, new SDK deps, platform API availability changes, any change that cannot be deployed as an OTA manifest swap |

**The existing `compatible_version?/2` function already implements `>=` semantics (`Version.compare != :lt`).** This is the correct call for `manifest_schema_version` and correct for `bridge_protocol_version` too. The current drift problem is not with the comparison logic — it is with the source-of-truth constants being out of sync across modules.

---

### Exact-Match vs. Negotiated Range: The Decision

**Recommendation: Keep `>=` (minimum-version) semantics for `bridge_protocol_version`, not exact-match. Do not introduce a max ceiling at this stage.**

Rationale drawn from real precedents:

**Why exact-match is a footgun for bridge protocol:**
- PostgreSQL wire protocol uses `major.minor` where major mismatch rejects, minor mismatch negotiates downward. The server responds with the highest minor version it supports; the client accepts. This is the canonical model for "I need at least this protocol, but I can run with older if the server supports it."
- Phoenix Channels `vsn` negotiation: clients advertise `vsn=2.0.0` in the connection request; the server and client settle on the intersection. Neither side requires exact equality.
- TLS 1.3 negotiation: the client's `ClientHello` sends its highest supported version; the server selects the highest version both sides can use. Strict equality on protocol version was explicitly abandoned in TLS 1.3 because it caused unnecessary breakage.
- Exact-match causes the specific failure mode Crosswake has now: a shell built against `1.0.0` is denied by a server running `1.1.0` even if `1.1.0` added no breaking changes to the envelope the shell uses. This is a "version string equality check as a poor substitute for actual compatibility evaluation."

**Why `>=` (min-version floor) is correct for Crosswake's bridge protocol:**
- The shell presents `bridge_protocol_version: "1.0.0"`. The manifest declares `bridge_protocol_version: "1.1.0"`. With `>=` semantics, this fails (1.0.0 < 1.1.0), which is correct when 1.1.0 introduced required wire changes.
- The shell presents `bridge_protocol_version: "1.1.0"`. The manifest declares `bridge_protocol_version: "1.0.0"`. With `>=` semantics, this passes (1.1.0 >= 1.0.0), which is correct: a newer shell can always speak an older protocol it is a superset of.
- Additive changes (new optional commands, new optional envelope fields) do NOT need a `major` bump — they are `minor` bumps, and shells with `major.minor >= required` continue working without rebuild.

**Why NOT a max ceiling now:**
- A max ceiling (e.g., `bridge_protocol_version` must be `>= 1.0.0 AND < 2.0.0`) is the right model when you have a published protocol spec with multiple deployed major generations in the field at once. Crosswake is pre-1.0 on the bridge protocol, has one release in the wild, and does not yet have the operational history that warrants upper-bound management. The footgun of a max ceiling is that it requires coordinated bumps when you want to extend support — and produces "version too new" errors that are equally confusing as "version too old" errors. Introduce upper bounds only when a major breaking generation needs to be sunset.

**Summary stance:** `available >= required` for all three axes. Major bump = breaking = native rebuild required. Minor bump = additive = no rebuild required (for `bridge_protocol_version`). No upper-bound enforcement until two incompatible major generations coexist in production.

---

### SemVer Meaning for Each Axis

**`manifest_schema_version` SemVer rules:**

| Change | SemVer | Rebuild outcome | Examples |
|--------|--------|-----------------|---------|
| Add a new optional top-level section | MINOR | (a) core-only / no rebuild | Adding `offline_islands` key to manifest |
| Add a new optional field to an existing route entry | MINOR | (a) core-only / no rebuild | Adding `offline_policy` as an optional route field |
| Make a previously optional manifest field required | MAJOR | (b) compat-bump only | Requiring `capability_registry` to be non-empty |
| Remove a field the shell reads at boot time | MAJOR | (c) native rebuild required | Removing `bridge_protocol_version` from compatibility section |
| Rename a required manifest key | MAJOR | (c) native rebuild required | Renaming `host.origin` to `host.origins` |
| Change the type of a required manifest field | MAJOR | (c) native rebuild required | Changing `routes` from a list to a map |

**`bridge_protocol_version` SemVer rules:**

| Change | SemVer | Rebuild outcome | Examples |
|--------|--------|-----------------|---------|
| Add a new optional command to the allowed set | MINOR | (a) core-only / no rebuild | Adding `share.invoke` command |
| Add a new optional field to the bridge envelope | MINOR | (a) core-only / no rebuild | Adding `thread_id` as an optional correlation field |
| Add a new optional field to a reply payload | MINOR | (a) core-only / no rebuild | Adding `metadata` to an `app.info.get` reply |
| Add a new REQUIRED field to the bridge envelope | MAJOR | (c) native rebuild required | Making a previously-optional field required |
| Remove an existing command | MAJOR | (c) native rebuild required | Removing `haptics.impact` from the command set |
| Rename a denial reason code | MAJOR | (c) native rebuild required | Renaming `compatibility_mismatch` to `contract_mismatch` |
| Change a field type in the envelope | MAJOR | (c) native rebuild required | Changing `capabilities` from `map<string,string>` to a list |
| Change the meaning of an existing command's payload | MAJOR | (c) native rebuild required | Changing `haptics.impact` payload shape |

**`native_runtime_version` SemVer rules:**

| Change | SemVer | Rebuild outcome | Examples |
|--------|--------|-----------------|---------|
| Pure Elixir logic change inside existing contract | no bump | (a) core-only / no rebuild | Tightening manifest validation on the Elixir side |
| Compatibility window narrowed (no binary change) | MINOR | (b) compat-bump only | Dropping support for shells older than `1.0.0` |
| New optional capability added, binary ships it | MINOR | (b) compat-bump only | Adding `file_picker` to the native binary; old shells continue |
| Entitlement added or changed | MAJOR | (c) native rebuild required | Adding push notification entitlement |
| SDK dependency added or version bumped in native binary | MAJOR | (c) native rebuild required | Updating `crosswake-shell-core-ios` to use new platform API |
| Platform permission or API surface changed | MAJOR | (c) native rebuild required | Using a new iOS API gated by a new privacy description |
| Generated shell project template changed | MAJOR | (c) native rebuild required | Changing `AppDelegate.swift` generated bootstrap |

---

### The (a)/(b)/(c) Rebuild Outcome Mapped to Each Axis

**(a) Core-only / no native rebuild required**

The change is entirely Elixir-side. The manifest compatibility declarations, the native binary, and the bridge wire format are untouched. Adopters run `mix deps.update crosswake` and rerun their core proof lane. No shell project change needed.

Triggers:
- Elixir behavior fixes inside existing schema/bridge/runtime constraints
- New doctor findings or support-matrix rows (purely Elixir surface)
- Tightened manifest validation that keeps existing valid manifests valid
- New optional manifest sections that the shell ignores (MINOR `manifest_schema_version` bump)
- New optional bridge commands (MINOR `bridge_protocol_version` bump) — old shells cannot call them but are not broken
- Docs-only changes (zero axis movement)

**(b) Compatibility-bump only**

The compatibility declarations in the manifest change — a version number moved, a support window narrowed, or a new minimum is declared — but an already-compatible shell continues to work without a binary rebuild. The adopter checks whether their shipped shell is still within the new window, runs fail-closed compatibility fixtures, and potentially tells end users to update the app if their installed version predates the new minimum.

Triggers:
- Narrowing the minimum supported `bridge_protocol_version` (dropping old shell compatibility)
- Narrowing the minimum supported `native_runtime_version`
- Bumping `manifest_schema_version` MAJOR when the change is additive-breaking at the parsing level but the existing shell already has the new fields (unlikely in practice but possible)

The key characteristic: a published binary that was already compatible remains compatible. This is a "you may be breaking some of your installed base" warning, not a "rebuild and ship a new binary" mandate for the maintainer.

**(c) Native rebuild required**

The change touches code that lives in the compiled native binary, in the generated shell project template, or in the bridge wire format in a way that an existing native binary cannot handle. The adopter must generate a new shell project (or update their checked-in shell), rebuild, and submit to the App Store / Play Store.

Triggers:
- Any MAJOR bump of `bridge_protocol_version` that changes the wire envelope fields the native side must parse
- Any bump of `native_runtime_version` that reflects a native binary change
- New entitlements or permissions declarations in the shell template
- New SDK dependencies added to the native package
- Generated shell template changes (e.g., new `ActivationCoordinator` method the shell must implement)

---

## Part 2: Adopter Communication / DX

### Lessons from Real Projects

**Stripe API Versioning (gold standard for "communicate compatibility to consumers")**

Stripe pins each account to a specific API version (date-based, e.g., `2024-09-30.acacia`). Every breaking change gets its own dated version. The changelog is narrative — "here is what changed, here is what you must do, here is a migration example." Key lesson: the version string alone is not enough. The Stripe changelog entry per version tells you *what class of change* it is and *what the adopter action is*. The dated version itself is a forcing function: you will encounter it in a changelog and be forced to read the migration note before upgrading.

For Crosswake: the axis version string is not the communication. The communication is the upgrade-impact label in the changelog + the doctor finding + the support-matrix row.

**Phoenix Channels `vsn` / Postgres Wire Protocol Negotiation**

Phoenix Channels sends `vsn` during WebSocket connect. The server selects the serializer matching the client's requested version. Postgres wire protocol uses `major.minor` where major mismatch rejects and minor mismatch negotiates (server responds with its supported minor, client accepts the lower). TLS 1.3 generalizes this: client sends a preference list, server picks the best overlap.

Lesson: negotiated-range semantics (min floor, no exact equality) prevent spurious failures on minor version bumps. Crosswake's existing `compatible_version?/2` (`>=` check) is the right model. The footgun to avoid is requiring exact equality, which causes rejections when a newer shell encounters an older manifest or vice versa even if they are fully wire-compatible.

**Protocol Buffers / gRPC Wire Compat Rules**

Proto3 rules: adding optional fields is always safe (old readers ignore unknown fields); removing fields is breaking (old senders stop populating them, old readers expect them); renaming a field without changing its field number is safe at the binary level but breaking at the JSON/schema level; changing a field type is breaking. The gRPC community documents every change as either "non-breaking" or "breaking" in a per-version changelog.

Lesson: the classification at the *change level*, not at the version-bump level, is what communicates impact to adopters. A `MINOR` bump with three "non-breaking" changes is a different adopter action than a `MAJOR` bump with one "breaking" change. Crosswake should attach a change-class label (the existing `core-only/no native rebuild`, `compatibility-bump only`, `native or companion rebuild required`) to every changelog entry and every doctor finding.

**Erlang/OTP BEAM ABI Versioning**

BEAM bytecode compiled for one Erlang/OTP version is not guaranteed to run on another. The error surface is honest and explicit: "This BEAM file was compiled for a later version of the run-time system." Elixir's compatibility guide publishes a matrix of which Elixir version supports which OTP range. The lesson: the error message names the incompatibility precisely and tells you what to do (recompile). The Elixir docs matrix maps the two-dimensional version space into a human-readable compatibility table.

For Crosswake: the `native_runtime_version` axis is structurally analogous to the OTP major version. When a native binary is built against `native_runtime_version: 1.0.0` and the manifest requires `1.1.0`, the failure is analogous to running BEAM files compiled for OTP 24 under OTP 23. The doctor finding should be as explicit as Erlang's error: name the mismatch, name the axis, name the required action.

**Stripe Mobile SDK Compatibility Matrix**

Stripe's mobile SDK uses strict SemVer with dedicated migration guides per major version. iOS minimum deployment target bumps (e.g., iOS 14 to iOS 15) are always MAJOR version bumps with explicit changelog entries. The SDK docs carry a "minimum supported platform versions" table updated per release. When a new major requires a rebuild and App Store submission, the migration guide says so in the first sentence.

Lesson: the compatibility matrix table in the docs is a first-class product surface, not an afterthought. Each row maps a library version to the native platform requirements that determine whether a rebuild is needed. Crosswake's `guides/support_matrix.md` already follows this pattern; the gap is that the three compatibility axes are not yet mapped to a per-release "upgrade impact" label visible in the changelog and doctor output.

**Capacitor Plugin Versioning**

Capacitor uses SemVer for the core and `npx cap sync` as the "run this after updating" ceremony. The `cap doctor` command surfaces version mismatches. Version mismatch errors manifest as "the plugin requires Capacitor 5.x but you're using 6.x." The lesson: a dedicated doctor/CLI command that surfaces compatibility mismatches by name, names the action (`npx cap sync` or "rebuild required"), and gives the user exactly one next step is far more useful than release notes alone.

---

### The Clearest Communication Strategy

**Recommendation: four surfaces working together, not four alternatives.**

1. **The changelog entry with an upgrade-impact label** (prevents surprise, informs before the adopter runs `mix deps.update`)
2. **The support-matrix change-class row** (the durable lookup table, already exists)
3. **The `mix crosswake.doctor` finding** (the runtime surface, acts when a mismatch is actually present)
4. **The `guides/compatibility.md` rebuild decision tree** (the authoritative yes/no answer with examples, already exists)

The four surfaces reinforce each other. An adopter reading the changelog sees the label first. An adopter running doctor sees the finding. An adopter reading the guide sees the examples. They converge on the same answer.

#### Changelog Entry Format

Every release entry that touches a compatibility axis should begin with an upgrade-impact label on the first line, before any prose:

```
## [0.2.0] — 2026-MM-DD

**Upgrade impact: native rebuild required** — bridge_protocol_version bumped to 2.0.0;
denial reason codes renamed; existing native shells must be regenerated and resubmitted.

**Upgrade impact: core-only / no rebuild** — manifest_schema_version minor bump (1.1.0)
adds optional offline_islands section; existing shells continue without change.
```

Labels should be one of exactly these strings (matching the existing support-matrix change-class vocabulary):
- `docs-only`
- `core-only / no rebuild`
- `compatibility-bump only`
- `native rebuild required`

#### Wording Principles for "You Must Rebuild"

The Stripe, Capacitor, and gRPC migration guide styles share one pattern: the "you must rebuild" statement comes first, in the simplest possible English, before any explanation. The explanation follows. The next step follows the explanation.

Wrong (buries the lead):
> In this release, we updated the bridge envelope to include a new required `thread_id` field for cross-boundary correlation. This was necessary for the Threadline integration. Because the bridge protocol version was bumped to 2.0.0, shells built against 1.x will receive a denial with reason `compatibility_mismatch`. You will need to regenerate your shell and rebuild.

Right (front-loads the action):
> **Your native shell must be rebuilt and resubmitted to the App Store / Play Store.**
> The bridge protocol version moved to 2.0.0. The `thread_id` field is now required in every bridge envelope. Your existing installed app will receive `compatibility_mismatch` denials until users update to the new binary.
>
> **What to do:** Run `mix crosswake.gen.shell` to regenerate your shell projects, rebuild for iOS and Android, and submit for review before deploying this server update.

The key microcopy principles:
- Lead with the binary action, not the technical reason
- Name "App Store / Play Store" explicitly — it communicates that this is a multi-day or multi-week process, not a `mix deps.update`
- Name the denial reason the adopter will see in logs
- Give a single concrete next step

---

## Part 3: The Doctor / Support-Matrix Surface

### What `mix crosswake.doctor` Should Output for Version Mismatches

The existing doctor already produces structured findings. The gap is that findings involving compatibility axes do not yet name the rebuild outcome class explicitly. They should.

**Current finding format (from `compatibility.ex`):**
```
route requires bridge protocol 1.1.0 but the shell exposes 1.0.0
hint: upgrade the shell bridge before activating /study/session
```

This is factually correct but incomplete. It names what is wrong, gives a hint toward the solution, but does not:
- Tell the adopter whether "upgrade the shell bridge" means `mix deps.update` or a full App Store submission
- Give the change class name that cross-references the support matrix
- State the adopter's complete action sequence

**Recommended doctor finding format for bridge protocol mismatch:**

```
[ERROR] bridge_protocol_version mismatch — native rebuild required
  Required:  1.1.0 (manifest compatibility declaration)
  Available: 1.0.0 (shell's reported version)
  Route:     /study/session

  The active native shell was built against bridge protocol 1.0.0.
  The manifest requires 1.1.0 or newer. Existing shells report
  compatibility_mismatch and deny bridge requests until updated.

  Change class: native rebuild required
  Adopter action:
    1. Run `mix crosswake.gen.shell` to regenerate shell projects.
    2. Rebuild the iOS app (Xcode) and Android app (Gradle).
    3. Submit updates to the App Store and Play Store.
    4. Deploy the server update after users can receive the new binary.

  Until the new binary reaches users, bridge-dependent routes will
  fail closed with denial reason: compatibility_mismatch.

  See: https://hexdocs.pm/crosswake/compatibility.html#native-rebuild-required
```

**Recommended doctor finding format for native runtime version mismatch:**

```
[ERROR] native_runtime_version mismatch — native rebuild required
  Required:  1.1.0 (manifest compatibility declaration)
  Available: 1.0.0 (shell's reported version)
  Route:     /device/capture

  The active native shell runtime does not satisfy the minimum
  version declared in the manifest. Routes requiring this runtime
  version will deny activation until the shell binary is updated.

  Change class: native rebuild required
  Adopter action:
    1. Update your shell project dependency on crosswake-shell-core-ios
       or crosswake-shell-core-android to the version matching this
       crosswake release.
    2. Rebuild and submit to App Store / Play Store.

  Until the new binary reaches users, affected routes will fail
  closed with denial reason: compatibility_mismatch.

  See: https://hexdocs.pm/crosswake/compatibility.html#native-rebuild-required
```

**Recommended doctor finding format for manifest schema version mismatch (core-only case):**

```
[WARNING] manifest_schema_version mismatch — no native rebuild required
  Required:  1.1.0 (manifest compatibility declaration)
  Available: 1.0.0 (shell's manifest parse contract)

  The shell can parse manifest schema 1.0.0 but the manifest declares
  1.1.0. The shell will ignore new optional manifest sections.
  No native binary update is needed if your routes do not depend
  on the new sections.

  Change class: core-only / no rebuild
  Adopter action: Update the crosswake Hex package and regenerate
  the manifest. Run `mix crosswake.doctor` after update to verify.

  See: https://hexdocs.pm/crosswake/compatibility.html#core-only-no-rebuild
```

### What Doctor Should Not Do

- Do not silently pass a version mismatch. Fail closed on any finding that rises to `native rebuild required`. The existing behavior of returning typed denial and executing no side effect is correct; the doctor finding must explain it.
- Do not conflate the three axes. Each axis gets its own finding with its own rebuild outcome class. Do not merge a `bridge_protocol_version` mismatch with a `native_runtime_version` mismatch into a single "compatibility mismatch" finding.
- Do not omit the adopter action sequence from the finding. The hint alone ("upgrade the shell bridge before activating /study/session") is insufficient when the action requires an App Store submission.

---

## Part 4: Support-Matrix Table Shape

### Recommended Table for Compatibility Axes Section

Add a dedicated "Compatibility Axis Change Classes" section to `guides/support_matrix.md` (the existing change-class table covers it in prose but lacks per-axis examples with rebuild-outcome callouts):

**`manifest_schema_version`**

| Change | SemVer Bump | Change Class | Adopter Action |
|--------|-------------|--------------|----------------|
| Add optional top-level section | MINOR | core-only / no rebuild | `mix deps.update crosswake`; rerun core proof |
| Add optional route field | MINOR | core-only / no rebuild | `mix deps.update crosswake`; rerun core proof |
| Make optional field required | MAJOR | compatibility-bump only | Check manifest; run fail-closed fixtures |
| Remove field the shell reads | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Change type of required field | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |

**`bridge_protocol_version`**

| Change | SemVer Bump | Change Class | Adopter Action |
|--------|-------------|--------------|----------------|
| Add optional command | MINOR | core-only / no rebuild | `mix deps.update crosswake`; rerun core proof |
| Add optional envelope field | MINOR | core-only / no rebuild | `mix deps.update crosswake`; rerun core proof |
| Add required envelope field | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Remove command | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Rename denial reason code | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Change envelope field type | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |

**`native_runtime_version`**

| Change | SemVer Bump | Change Class | Adopter Action |
|--------|-------------|--------------|----------------|
| Elixir-only logic change | none | core-only / no rebuild | `mix deps.update crosswake`; rerun core proof |
| Compat window narrowed | MINOR | compatibility-bump only | Verify shipped shell is in range; run fixtures |
| New capability added to binary | MINOR | compatibility-bump only | Old shells continue; new capability available after update |
| Entitlement or permission changed | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Native SDK dependency changed | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |
| Generated shell template changed | MAJOR | native rebuild required | Regenerate shell; rebuild; submit to stores |

### The Support-Matrix "Rebuild Matrix" Column

The existing `RuntimeLineRow` struct already has a `rebuild_required` boolean. The support matrix should surface this as a human-readable column in the capability families table:

Add column `Rebuild When Changed` with values drawn from:
- `never — Elixir-only capability`
- `native rebuild required — bridge or runtime axis bump`
- `companion rebuild required — companion native surface changed`

This mirrors how Stripe's mobile SDK docs surface "Requires rebuild" per feature in their compatibility tables.

---

## Part 5: The Coherent Recommendation

### Compatibility Model Crosswake Should Adopt

**Bridge protocol versioning: minimum-version floor (`>=`), no upper bound, major = breaking = native rebuild required, minor = additive = no rebuild.**

The current `compatible_version?/2` already implements `>=`. The fix is ensuring one canonical source (`Crosswake.Bridge.Contract.@version`) drives every other reference: the manifest types defaults, the example payloads, the native package fixtures, the route-tour proof assertions, and the docs. The version comparison logic does not need to change. The source-of-truth plumbing does.

**Axis independence: each axis moves on its own schedule.**

`manifest_schema_version` can bump MINOR when a new optional manifest section is added without any change to the bridge wire format or the compiled native binary. `bridge_protocol_version` can bump MAJOR when the wire envelope changes without any manifest-shape change. `native_runtime_version` bumps when compiled code changes. Adopters and the doctor/support-matrix must present these as distinct signals, not merged into a single "compatibility mismatch."

**The single source rule: `Crosswake.Bridge.Contract` drives everything.**

The three version constants must live in exactly one place, ideally `Crosswake.Bridge.Contract` (or a dedicated `Crosswake.Contract.Versions` module if the axes need to be decoupled from the bridge module specifically), and every other reference — manifest type defaults, compatibility struct defaults, generated shell fixtures, example payloads, native package test fixtures, route-tour proof — must derive from that one source at compile time, not duplicate a literal. Any duplicated literal is a future drift risk of the kind that produced the current `1.0.0`/`1.1.0` split.

**The incompatibility posture: fail closed, name the axis, name the class, name the action.**

When a version mismatch is detected, the denial reason (`compatibility_mismatch`) is surfaced as before, but the doctor finding adds the axis name (`bridge_protocol_version`), the change class (`native rebuild required`), and the full adopter action sequence (regenerate → rebuild → submit). This is the only posture consistent with the maintainer's "install truth matters as much as the happy path" principle and the existing "fail-closed activation" architecture.

---

### Docs Structure Recommendation

The existing `guides/compatibility.md` is the right home. It should be restructured to front-load the decision tree:

```
# Compatibility Boundaries

## Do I need to rebuild my native shell?

| What changed | Do I need to rebuild? |
|---|---|
| crosswake Hex package updated (Elixir only) | No, unless the changelog says "native rebuild required" |
| bridge_protocol_version MINOR bump | No — update the Hex package; no shell change needed |
| bridge_protocol_version MAJOR bump | YES — regenerate shell, rebuild, submit to stores |
| native_runtime_version bumped | YES — regenerate shell, rebuild, submit to stores |
| manifest_schema_version MINOR bump | No — new optional sections; shell ignores them safely |
| manifest_schema_version MAJOR bump | Check changelog — may require compat fixtures; rarely requires rebuild |
| companion package updated | Check companion's changelog for rebuild guidance |

## Three axes, three meanings
[existing axis explanation]

## Per-axis change examples
[the per-axis tables from Part 4 above]

## What mix crosswake.doctor tells you
[examples of the three finding formats from Part 3 above]
```

The key structural change: put the decision tree *before* the detailed explanation. The skeptical Phoenix SaaS developer reading the guide wants the yes/no answer on the first screen, not after three paragraphs of background.

---

### Example Microcopy for Rebuild Notices

**In a CHANGELOG.md entry (native rebuild required):**

```
## [0.2.0] — 2026-MM-DD

**NATIVE REBUILD REQUIRED.** bridge_protocol_version bumped to 2.0.0.
Your native shells must be regenerated, rebuilt, and submitted to
the App Store / Play Store before you deploy this server update.
Run `mix crosswake.gen.shell` to regenerate.

Until updated binaries reach your users, bridge-dependent routes
return `compatibility_mismatch` denials. Plan a coordinated rollout.

### What changed
- Renamed denial reason `compatibility_mismatch` to `contract_mismatch`
- Added required `thread_id` field to bridge envelope
- Removed deprecated `haptics.light` command (use `haptics.impact`)
```

**In a CHANGELOG.md entry (no rebuild):**

```
## [0.1.3] — 2026-MM-DD

No native rebuild required. Update the Hex package and rerun `mix crosswake.doctor`.

### What changed
- manifest_schema_version 1.1.0 (MINOR): added optional `offline_islands`
  manifest section. Existing shells ignore the new section safely.
- Tightened manifest validator to reject empty capability_registry when any
  route declares a capability.
```

**In a `mix crosswake.doctor` summary line (healthy installation):**

```
[OK] bridge_protocol_version: 1.1.0 (shell: 1.1.0 >= required: 1.1.0)
[OK] native_runtime_version: 1.0.0 (shell: 1.0.0 >= required: 1.0.0)
[OK] manifest_schema_version: 1.0.0 (shell: 1.0.0 >= required: 1.0.0)
No compatibility findings. Native shell does not require rebuild.
```

**In a `mix crosswake.doctor` summary line (mismatch present):**

```
[ERROR] bridge_protocol_version: NATIVE REBUILD REQUIRED
  Shell reports 1.0.0; manifest requires >= 1.1.0.
  Action: mix crosswake.gen.shell -> rebuild -> submit to stores.
  Routes /study/session, /capture/photo will deny bridge requests until updated.
  See: https://hexdocs.pm/crosswake/compatibility.html#native-rebuild-required

[OK] native_runtime_version: 1.0.0
[OK] manifest_schema_version: 1.0.0

1 compatibility finding. Run `mix crosswake.doctor --verbose` for full details.
```

---

## Gaps and Open Questions

1. **The `1.0.0`/`1.1.0` drift is the immediate fix.** Before implementing any of this recommendation, the bridge protocol version constants must be unified. The canonical version for the current supported bridge protocol (reflecting `thread_id`, `share.invoke`, `transfer.*` commands) must be identified, agreed upon, and set as the single constant that all other references derive from at compile time.

2. **The `compatible_version?/2` function uses `>=` correctly.** Once the canonical version is agreed, the comparison logic is already correct. The fix is source-of-truth plumbing, not comparison semantics.

3. **Drift guards are the structural fix.** The main contribution of v14.0 on the tooling side should be a compile-time or CI-time check that rejects any pull request where the bridge protocol version constant in `Crosswake.Bridge.Contract` differs from the default in `Crosswake.Manifest.Types`. This is analogous to the existing `generator_coordinate_parity` guard and the `brand-structural` gate.

4. **Native package behavioral tests must be anchored to the Elixir canonical source.** The doctor output describes what the Elixir side expects. The native package tests (iOS/Android) must assert the same version strings. Without native-side tests anchored to the Elixir canonical source, drift reappears at the platform boundary.

5. **Max-version ceiling deferred.** When Crosswake has two incompatible major bridge protocol generations simultaneously in the field (e.g., shells running `1.x` and `2.x` both needing support), introduce a `min_bridge_protocol_version` + `max_bridge_protocol_version` pair in the manifest compatibility section. That design is premature now but should be noted as the planned extension point.

---

## Sources

- [Stripe API Versioning — APIs as infrastructure: future-proofing Stripe with versioning](https://stripe.com/blog/api-versioning)
- [Stripe API Versioning Reference](https://docs.stripe.com/api/versioning)
- [Stripe Mobile SDK Versioning and Support Policy](https://docs.stripe.com/sdks/mobile-sdk-versioning)
- [Stripe Terminal SDK Migration Guide](https://docs.stripe.com/terminal/references/sdk-migration-guide?locale=en-GB)
- [Phoenix Channels — Writing a Channels Client (vsn negotiation)](https://hexdocs.pm/phoenix/writing_a_channels_client.html)
- [Protocol Buffers Language Guide — proto3 compatibility rules](https://protobuf.dev/programming-guides/proto3/)
- [Protocol Buffer Evolution — best practices](https://oneuptime.com/blog/post/2026-01-24-protocol-buffer-evolution/view)
- [Backward and Forward Compatibility with Protobuf — Earthly Blog](https://earthly.dev/blog/backward-and-forward-compatibility/)
- [Versioning gRPC services — Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/grpc/versioning?view=aspnetcore-10.0)
- [gRPC Non-breaking and Breaking Changes](https://medium.com/@hoangxuantoank13/grpc-non-breaking-changes-breaking-changes-and-versioning-solution-1dcb989beb16)
- [PostgreSQL Wire Protocol — Frontend/Backend Protocol Overview](https://www.postgresql.org/docs/current/protocol-overview.html)
- [PostgreSQL Wire Protocol — Message Flow](https://www.postgresql.org/docs/current/protocol-flow.html)
- [RFC 8446 — TLS 1.3 (version negotiation via supported_versions extension)](https://datatracker.ietf.org/doc/html/rfc8446)
- [Elixir Compatibility and Deprecations](https://hexdocs.pm/elixir/compatibility-and-deprecations.html)
- [Capacitor Updating to 8.0](https://capacitorjs.com/docs/updating/8-0)
- [Capacitor Version Mismatch Errors](https://capgo.app/blog/fix-capacitor-version-mismatch-errors/)
- [SemVer and Wire Protocols — moving away from SemVer (libp2p discussion)](https://github.com/libp2p/specs/issues/203)
