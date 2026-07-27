---
quick_id: 260719-nxm
slug: implement-the-architecture-and-code-walk
description: Implement the architecture and code walkthrough guides end-to-end with dark-mode Mermaid diagrams and the Crosswake docs favicon
date: 2026-07-19
mode: quick-full
must_haves:
  truths:
    - "A senior Phoenix engineer can follow one consistent route declaration -> validated policy -> versioned manifest -> activation owner-or-denial -> bounded native affordance story across the two guides, then name the next Crosswake modules to inspect."
    - "The guides describe only current shipped behavior: per-route ownership remains central, activation remains fail-closed, cached read-only is not called local-first mutation, example hosts remain proof/integration surfaces, and the Phase 154 `Crosswake.Bridge.push/3` API is not presented as available."
    - "The package map distinguishes core, the reusable iOS/Android shell cores, five independently versioned in-repo companion projects, and host-owned examples without turning repository presence into a publication claim; live presence is delegated to `mix crosswake.release.status --live`."
    - "Every architecture diagram has an accessible title and description, renders legibly in ExDoc light and dark themes, rerenders after ExDoc navigation/theme changes, and leaves readable Mermaid source visible if the pinned renderer is unavailable or fails."
    - "README stays the ExDoc main page, See It Run stays extras/Start item 2, both new guides follow it before route-policy/install material, and the existing extras-group key sequence is unchanged."
    - "The canonical dedicated Crosswake favicon is copied into generated docs and linked as the documentation favicon while the existing ExDoc logo remains unchanged."
    - "A focused, source-derived contract test guards guide ordering, accessible diagrams, parseable walkthrough excerpts, stable documented exports, portable links, mutual navigation, Mermaid hooks, and favicon configuration without freezing incidental prose."
  artifacts:
    - "guides/architecture.md — outside-in architecture guide with the required 13-section journey and four accessible Mermaid diagrams"
    - "guides/code-walkthrough.md — inside-out walkthrough with 12-18 current, representative Elixir/Swift/Kotlin excerpts"
    - "mix.exs — ExDoc registration, canonical favicon, and pinned failure-safe light/dark Mermaid HTML hooks"
    - "README.md and CHANGELOG.md — reader-lane discoverability and a documentation-only Unreleased entry"
    - "test/crosswake/guides/architecture_code_walkthrough_test.exs — maintainability and rendering-contract guard"
  key_links:
    - "Phoenix route `crosswake:` metadata -> `Crosswake.Router` -> `Crosswake.Policy.Compiler` / `Crosswake.Policy.Route` / schema and cross-route validation -> `Crosswake.Manifest` builder/validator/serializer"
    - "Versioned manifest + normalized activation request -> `Crosswake.Shell.Activation.resolve/2` -> `Crosswake.Compatibility.RouteGate.evaluate/4` -> exactly one runtime owner or stable denial"
    - "`Crosswake.Bridge.Contract` closed vocabulary -> `Crosswake.Bridge.Registry.lookup/4` supported-command, manifest-route, and declared capability/transfer checks -> Swift/Kotlin bridge channel/session active-route equality"
    - "Fenced `mermaid` source -> ExDoc HTML callbacks -> pinned Mermaid 11.15.0 strict renderer -> brand-token light/dark SVG or visible raw-source fallback"
    - "Guide claims and excerpts -> architecture_code_walkthrough_test exports/syntax checks -> focused Elixir/native behavioral suites and Hex packaging checks"
---

# Quick Task 260719-nxm: Architecture guide and code walkthrough

## Context

This is a documentation-only quick task alongside active Phase 153. It must not implement or
imply Phase 154's planned native-control seam, broaden support, change a runtime contract, run
contract code generation, publish anything, or edit current milestone artifacts. The large
existing `.planning/phases/147-*` through `152.1-*` deletion set, the untracked Phase 153
patterns file, and `.planning/research/.cache/` are user-owned and must never be restored,
formatted, staged, or committed by these tasks. Before each task commit, inspect the staged
file list and allow only that task's declared files.

The user's pre-existing `.planning/STATE.md` edit is isolated in the exact named stash
`codex-preserve-state-before-architecture-docs`. Before implementation, resolve that stash by
its exact subject, assert its diff contains only `.planning/STATE.md`, and leave it unapplied.
Record the current post-stash dirty baseline as NUL-delimited status entries outside the repo
at `/tmp/crosswake-260719-nxm-dirty-baseline.status`; the final recovery step compares against
this baseline plus the declared agent-owned paths instead of requiring a globally clean tree.

The audience is a senior Elixir/Phoenix engineer. Teach one system twice: the architecture
guide works outside-in through purposes, ownership boundaries, journeys, and package shape;
the walkthrough works inside-out through values and decisions in current source. Prefer
documented module/function links and their ExDoc View Source pages over repository paths,
GitHub blob links, or line anchors.

Current truth to preserve:

- Router metadata becomes normalized and validated route policy before manifest generation;
  native activation consumes the manifest rather than raw Phoenix declarations.
- Activation selects `:live_view`, `:offline_island`, or `:native_screen`, or returns an
  explicit denial. Companions may further restrict a route but cannot reopen a core denial.
- The bridge is typed, versioned, request/reply-only, semantic, route-local, closed-vocabulary,
  and low-frequency. The example host's handwritten message-handler script is checked-in
  proof/current host plumbing, not a stable push API or general application runtime.
- `Crosswake.Bridge.Registry` validates that a command is supported, the manifest route exists,
  and that route declared the required capability or transfer. Active-route equality is a
  separate runtime defense enforced by the Swift/Kotlin bridge channel/session boundaries.
- The five companion directories are independently versioned package projects. Do not claim
  all five are live; publication is per-package and current live state belongs to
  `mix crosswake.release.status --live`.
- The native package implementations and shared contract vectors are public proof of the
  reusable SwiftPM/Maven shell cores; generated and checked-in host shells remain adopter-owned.
- Crosswake core owns no database. Host applications or optional packages own durable audit,
  correlation, engine, and integration persistence; client evidence never silently becomes
  backend authority.
- Phoenix supplies routing and LiveView's server-owned UI lifecycle, NimbleOptions supplies
  option-shape validation, Jason supplies JSON encoding, and `:telemetry` supplies event
  dispatch. Crosswake still owns route semantics, cross-field validation, deterministic
  manifest shape, event vocabulary, redaction, ownership decisions, and failure posture.
- Browser assertions, hermetic native package tests, emulator/device evidence, provider
  evidence, and live publication evidence are distinct proof classes and must not collapse
  into one vague "supported" label.
- `Crosswake.Bridge.Contract.version/0` is the canonical bridge version. Generated fixtures and
  Elixir/Swift/Kotlin contract vectors derive from that source and are protected by generation
  and drift guards; regeneration is an architectural contract operation, not docs cleanup.

---

## Task 1 — Write the outside-in architecture guide and inside-out source walkthrough

**Files:** `guides/architecture.md`, `guides/code-walkthrough.md`

**Action:**

1. Write `guides/architecture.md` in this exact narrative order:
   1. Opening promise
   2. Crosswake in one picture
   3. Vocabulary for the trip
   4. Journey 1: a route becomes shared runtime truth
   5. Journey 2: activation chooses an owner or stops
   6. A bounded bridge is not a second application runtime
   7. Offline, packs, transfers, commerce, and auth hang from ownership
   8. The package family preserves optionality
   9. Support truth is part of the runtime contract
   10. Module atlas
   11. Code-reading routes
   12. Changing Crosswake safely
   13. Where to go next

   Reach Journey 1 quickly. Define managed route, runtime owner, manifest, activation,
   capability, finding/denial, companion, proof class, and rebuild posture only when they first
   carry meaning. For each major boundary state the value crossing, the owner, the failure and
   retained evidence, and why the boundary exists. Use short prose, a compact module-atlas
   table, and only tactical Elixir examples (roughly 4-8 blocks across this guide).

   Make dependency ownership explicit rather than listing libraries: Phoenix owns router and
   LiveView primitives; NimbleOptions validates option shapes; Jason encodes JSON; `:telemetry`
   dispatches events; Crosswake owns route/runtime semantics, cross-route validation,
   deterministic manifest ordering, stable event contracts, redaction, and fail-closed
   decisions. State that core has no database and durable persistence belongs to hosts or
   optional integration packages.

2. Add exactly four focused Mermaid diagrams to the architecture guide:
   - The unnumbered top-level happy path: Phoenix router declares ownership, Crosswake compiles
     shared truth, and the native shell selects one owner or stops; bridge, companions, and
     doctor/support truth sit around the spine without becoming authorities.
   - Authoring: router metadata -> defaults/normalization -> schema + semantic validation ->
     manifest builder/validator -> deterministic serialization.
   - Runtime: activation request -> compatibility/RouteGate and optional restrictive gates ->
     runtime owner or denial.
   - Package ownership: core, reusable SwiftPM/Maven cores, independent companions,
     generated/host-owned surfaces, and checked-in proof hosts.

   Give every block Mermaid `accTitle` and `accDescr` directives, use short accessible labels,
   and put no colors/styles in diagram source. Keep the main diagram free of denial catalogs,
   provider detail, offline sub-branches, and proof-lane inventories.

   In the support/package sections, distinguish browser proof, hermetic Swift/Kotlin package
   proof, advisory emulator/device evidence, provider evidence, and live publication evidence.
   Explain the single canonical `Crosswake.Bridge.Contract.version/0`, generated fixture and
   Elixir/Swift/Kotlin vector surfaces, `mix crosswake.contract.gen`, and the drift guards that
   force them to move together. Do not run generation for this documentation-only change.

3. Write `guides/code-walkthrough.md` as the deeper source-reading trail. Open with one current
   `/bridge-proof` route from the checked-in Phoenix example host and an early warning that
   internal modules/private functions and example-host code are teaching material, not public
   API. Include 12-18 representative fenced excerpts total; target these 18 leverage points:
   - example route declaration;
   - `Crosswake.Router.__route_options__/3` metadata attachment;
   - `Crosswake.Policy.Compiler.compile/2`;
   - `Crosswake.Policy.Route.new/1` and schema validation;
   - cross-route semantic validation;
   - `Crosswake.Manifest.compile/2`;
   - route-entry building;
   - manifest validation;
   - deterministic serialization;
   - `Crosswake.Shell.Activation.new_request/1` and `resolve/2` together;
   - `Crosswake.Compatibility.RouteGate.evaluate/4` and Finding-to-Denial ownership;
   - `Crosswake.Bridge.Contract` version/closed request-reply vocabulary;
   - `Crosswake.Bridge.Registry.lookup/4` for a representative current command such as share;
   - the narrow `Crosswake.Companion` behavior/runtime registry;
   - installer/generator ownership (`Crosswake.Install.Patcher` and shell generation);
   - `Crosswake.Doctor.run/1`;
   - one Swift activation counterpart;
   - one Kotlin bridge counterpart.

   Each excerpt should show one decision or transformation, normally 8-35 lines. Copy current
   source and remove secondary branches. Mark Elixir cuts with `# ...`; mark Swift and Kotlin
   cuts with `// ...`. Keep every Elixir block parseable by `Code.string_to_quoted/1` and label
   Swift/Kotlin blocks correctly. Describe tests by their suite/module intent rather than
   publishing brittle repository paths. End with concrete module/package reading sequences and
   the question each answers.

4. Cross-link the two new guides and link outward to existing route-policy, install,
   native-shell, bridge, offline, packs, companion contract/compatibility, support-matrix,
   telemetry, compatibility, and troubleshooting guides instead of duplicating instructions.
   Use only Hex-safe relative links to packaged guides. Do not expose `/Users/`, `/home/`,
   `/tmp/`, GitHub `blob` URLs, or `#L...` source anchors.

**Verify:**

- `test "$(rg -c '^```mermaid$' guides/architecture.md)" -eq 4`
- `test "$(rg -c 'accTitle:' guides/architecture.md)" -eq 4 && test "$(rg -c 'accDescr:' guides/architecture.md)" -eq 4`
- `rg -n 'Crosswake\.Bridge\.push|/Users/|/home/|/tmp/|github\.com/.*/blob|#L[0-9]+' guides/architecture.md guides/code-walkthrough.md` returns no matches.
- Manually compare every excerpt against current Elixir/Swift/Kotlin source and confirm all
  omissions are marked and no future API is invented.

**Done:** The pair teaches the same current system from both directions, makes route ownership
and the manifest boundary memorable, and leaves the reader with concrete source-entry routes.

---

## Task 2 — Wire ExDoc discovery, responsive light/dark Mermaid rendering, favicon, and reader lanes

**Files:** `mix.exs`, `README.md`, `CHANGELOG.md`

**Action:**

1. Update `docs/0` in `mix.exs` without changing the existing module/extra group taxonomy:
   - Keep `logo: "brandbook/logo/crosswake-mark.svg"` and add
     `favicon: "brandbook/logo/favicon.svg"`.
   - Make extras start exactly with README, See It Run, Architecture, Code Walkthrough, then
     the existing CHANGELOG/LICENSE/task-guide sequence. See It Run must remain global item 2.
   - Make `Start` begin exactly with README, See It Run, Architecture, Code Walkthrough,
     Route Policy, Install. Preserve the exact group-key sequence:
     `Start`, `Adopt`, `Runtime Owners`, `Truth`, `Telemetry`, `Extension Authors`,
     `Advanced/Companions`.

2. Add private ExDoc `before_closing_head_tag` and `before_closing_body_tag` callbacks to the
   project module and pass them from `docs/0`. Each callback must return `""` for `:epub` and
   other non-HTML formatters.

   The HTML head callback must load exactly
   `https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js` with `defer`,
   `crossorigin="anonymous"`, and integrity
   `sha384-yQ4mmBBT+vhTAwjFH0toJXNYJ6O4usWnt6EPIdWwrRvx2V/n5lXuDZQwQFeSFydF`. Include small
   scoped CSS that gives rendered diagrams a transparent background, centered responsive SVG
   (`max-width: 100%; height: auto`), horizontal overflow when necessary, and reduced-motion
   behavior. Do not restyle unrelated ExDoc elements.

   The body callback must install one idempotent controller that:
   - discovers `pre > code.mermaid` on `DOMContentLoaded` and every `exdoc:loaded` event;
   - serializes render passes and gives every `mermaid.render/2` call a unique DOM id;
   - initializes Mermaid with `startOnLoad: false`, `securityLevel: "strict"`, theme `base`, and
     `flowchart: {htmlLabels: false}`;
   - chooses brand-derived `themeVariables` from `body.dark`: light uses Current 950
     `#09141A`, Foam 50/100 `#F7F1E6`/`#EFE6D6`, Wake 700 `#2B756A`, Harbor 700 `#254855`,
     and Mist 200 `#C9D4CF`; dark uses Current 950 background `#09141A`, raised/inset
     `#0F1E26`/`#162B35`, Foam 50 text `#F7F1E6`, Harbor 700 borders `#254855`, and Wake 500
     lines/accents `#4E9A8E`;
   - renders into a sibling `.crosswake-mermaid` container while retaining the original source
     block in the DOM, and hides that source only after the replacement SVG succeeds;
   - on load/render failure removes partial/stale output, unhides the source, and emits one
     useful `console.warn`, so the page never becomes blank;
   - observes `body.class` with `MutationObserver` and queues a full rerender only when dark-mode
     state changes. A successful theme toggle replaces, rather than duplicates, the old SVG.

3. Add concise README links in both existing discovery surfaces:
   - Architecture under `Evaluating Crosswake` and Code Walkthrough under
     `Contributing or maintaining` (do not put either in another choose-your-path lane).
   - Both guides at the top of `Guide map`, before task-oriented guides.

4. Add a `### Documentation` subsection under `[Unreleased]` with one bullet describing the
   architecture/code-learning path, accessible light/dark Mermaid diagrams, and docs favicon.
   Explicitly call it documentation-only and make no new runtime or support claim.

**Verify:**

- `mix docs` succeeds; compare warnings to the pre-task warning set and treat only new warnings
  as regressions.
- `test -f doc/architecture.html && test -f doc/code-walkthrough.html && test -f doc/assets/favicon.svg`
- `rg -n 'mermaid@11\.15\.0|yQ4mmBBT\+vhTAwjFH0toJXNYJ6O4usWnt6EPIdWwrRvx2V/n5lXuDZQwQFeSFydF|securityLevel|exdoc:loaded|MutationObserver' doc/architecture.html doc/code-walkthrough.html`

**Done:** Both guides are first-class HexDocs entry points, the Crosswake favicon is emitted,
and diagrams render accessibly in either ExDoc theme without sacrificing no-JavaScript/CDN
failure readability.

---

## Task 3 — Add the maintainability contract and run behavioral, packaging, native, and visual proof

**Files:** `test/crosswake/guides/architecture_code_walkthrough_test.exs`

**Action:**

1. Add one focused async ExUnit contract test module that reads current `Mix.Project.config()`
   and both guides. Guard behavior rather than sentence-level prose:
   - Assert README and See It Run retain extras/Start indices 0 and 1; Architecture and Code
     Walkthrough occupy indices 2 and 3; Start then contains Route Policy and Install; assert
     the full existing extras-group key order.
   - Assert README places Architecture inside the Evaluating section, Code Walkthrough inside
     Contributing/Maintaining, and both in Guide map.
   - Assert the 13 architecture headings exist in required order; find exactly four Mermaid
     blocks and require `accTitle` and `accDescr` in each.
   - Count representative walkthrough `elixir`, `swift`, and `kotlin` fenced excerpts and keep
     the total in 12..18. Extract every Elixir fence and require
     `Code.string_to_quoted/1 == {:ok, _}` with an actionable block-number failure.
   - Require that the guide names and the loaded module exports still provide:
     `Crosswake.Policy.Compiler.compile/2`, `Crosswake.Manifest.compile/2`,
     `Crosswake.Shell.Activation.resolve/2`, `Crosswake.Compatibility.RouteGate.evaluate/4`,
     `Crosswake.Bridge.Contract.version/0`, `Crosswake.Bridge.Contract.new_request/1`,
     `Crosswake.Bridge.Registry.lookup/4`, and `Crosswake.Doctor.run/1`.
   - Reject machine-local absolute paths, GitHub blob URLs, and line anchors; require mutual
     guide links.
   - Assert docs configure `brandbook/logo/favicon.svg` and the file exists. Invoke the head/body
     callback function values from config: HTML must contain the exact pinned version/integrity,
     strict rendering, fallback behavior, `exdoc:loaded`, and dark-mode observation; EPUB must
     return an empty string.

2. Run focused behavior proof for every source anchor, then the full hermetic regression:

   ```sh
   mix test \
     test/crosswake/guides/architecture_code_walkthrough_test.exs \
     test/crosswake/hex_page_test.exs \
     test/crosswake/guides/see_it_run_test.exs

   mix test \
     test/crosswake/router_test.exs \
     test/crosswake/policy/compiler_test.exs \
     test/crosswake/policy/route_test.exs \
     test/crosswake/policy/schema_test.exs \
     test/crosswake/manifest/manifest_test.exs \
     test/crosswake/manifest/builder_test.exs \
     test/crosswake/manifest/validator_test.exs \
     test/crosswake/shell/activation_test.exs \
     test/crosswake/bridge/contract_test.exs \
     test/crosswake/bridge/registry_test.exs \
     test/crosswake/bridge/bridge_behavioral_vector_test.exs \
     test/crosswake/contract/contract_drift_test.exs \
     test/crosswake/proof/phase129_companion_contract_freeze_test.exs \
     test/crosswake/proof/phase130_extraction_guards_test.exs \
     test/crosswake/proof/phase130_fail_closed_contract_test.exs \
     test/crosswake/doctor/doctor_test.exs

   mix test --exclude requires_example_host
   ```

3. Run native package proof without simulators/emulators, followed by docs/package gates:

   ```sh
   (cd packages/crosswake-shell-core-ios && swift test)
   (cd packages/crosswake-shell-core-android && ./gradlew testDebugUnitTest)
   mix format --check-formatted
   mix docs
   bash script/verify_hex_tarball.sh
   ```

4. Serve `doc/` on a temporary localhost port and use the agent-browser workflow for a true
   cold-read/visual check. Inspect Architecture and Code Walkthrough at desktop and narrow
   widths with `?theme=light` and `?theme=dark`; wait for `.crosswake-mermaid svg`, assert the
   rendered count equals four architecture Mermaid blocks, and inspect full-page screenshots.
   Check label/edge contrast, wrapping, horizontal overflow, code-block width, first-screen
   clarity, favicon linkage, SVG title/description accessibility, and that a live theme toggle
   rerenders without duplicate SVGs. Use `view_image` on screenshots rather than trusting DOM
   assertions alone.

   Repeat in a browser session that allows localhost but blocks `cdn.jsdelivr.net`; confirm the
   original Mermaid code blocks remain visible and the page contains no blank diagram slots.
   Revise only the declared implementation files if the cold read or screenshots expose a real
   issue, then rerun the relevant contract/docs checks. Close browser sessions and stop the
   local server.

5. Open the final generated pages locally:

   ```sh
   open doc/architecture.html
   open doc/code-walkthrough.html
   ```

   Record verification evidence and the current implementation/documentation mismatch in the
   quick summary: the example-host handwritten bridge script is present now, while the typed
   `Crosswake.Bridge.push/3` control seam remains planned Phase 154 work and was intentionally
   not documented as shipped. Do not push, publish, tag, release, or regenerate the canonical
   bridge surfaces.

6. **Final workflow recovery — run only after the executor/verifier and all GSD quick
   bookkeeping commits, including the quick-task row in `.planning/STATE.md`, are complete.**
   This is an orchestrator-owned finalization step, not an executor task commit:

   - Resolve exactly one stash whose subject ends in
     `codex-preserve-state-before-architecture-docs`. Fail and stop if it is missing or
     ambiguous. Before applying it, require
     `git diff --name-only "${state_stash}^1" "$state_stash"` to equal exactly
     `.planning/STATE.md`; this proves applying the stash cannot restore or rewrite any other
     dirty path.
   - Save its exact State patch outside the repo with
     `git diff "${state_stash}^1" "$state_stash" -- .planning/STATE.md > "$state_patch"`,
     where `state_patch` is a fresh `mktemp` file.
   - Run `git stash apply "$state_stash"`. If it exits nonzero or
     `git ls-files -u -- .planning/STATE.md` is non-empty, **retain the stash, do not drop it,
     do not reset/checkout the file, stop immediately, and report the conflict for recovery**.
   - On a clean apply, require both:
     - the new `260719-nxm` quick-task row is still present in `.planning/STATE.md`; and
     - `git apply --reverse --check "$state_patch"` succeeds, proving every original stashed
       user hunk is present and reversible alongside the committed quick bookkeeping.
   - Compare final NUL-delimited `git status --porcelain=v1 -z` entries with
     `/tmp/crosswake-260719-nxm-dirty-baseline.status` after removing the following declared
     agent-owned paths from both sides and removing the intentionally restored
     `.planning/STATE.md` entry from the final side:
     `guides/architecture.md`, `guides/code-walkthrough.md`, `mix.exs`, `README.md`,
     `CHANGELOG.md`, `test/crosswake/guides/architecture_code_walkthrough_test.exs`, and
     `.planning/quick/260719-nxm-implement-the-architecture-and-code-walk/**`.
     The remaining status/path pairs must match byte-for-byte, proving the pre-existing phase
     deletions and untracked planning/cache paths were neither lost nor expanded. Any extra or
     missing user-owned pair is a stop condition.
   - Only after all patch, quick-row, conflict, and dirty-baseline checks pass, run
     `git stash drop "$state_stash"`. Delete the temporary patch/baseline snapshots afterward.

**Verify:** Every command and both normal/offline browser sessions above complete with the
expected result. `git diff --check` is clean and generated `doc/` remains ignored. The final
status comparison matches the recorded dirty baseline after subtracting only the declared
agent-owned paths and restored State entry; the State patch passes reverse-apply validation,
the quick-task row remains present, and the named stash is dropped only after those checks.

**Done:** The documentation contract, current Elixir/native behavior, Hex package, generated
HTML, dark/light rendering, CDN-failure fallback, and end-to-end reading experience all agree.

## Out of scope

- Implementing or documenting `Crosswake.Bridge.push/3` as shipped before Phase 154.
- Changing route policy, manifests, bridge/native contracts, generated contract vectors, or
  package versions.
- Broadening capability, offline, companion, publication, emulator/device, or provider support
  claims.
- Editing roadmap/requirements/phase artifacts beyond normal quick-workflow bookkeeping,
  touching the user's planning cleanup, or pushing/publishing/releasing anything.
