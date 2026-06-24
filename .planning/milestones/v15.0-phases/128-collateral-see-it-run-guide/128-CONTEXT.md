# Phase 128: Collateral + "See It Run" Guide - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

The **v15.0 capstone**: make the "See It Run" first-run DX *visible and followable*.
Deliver four tightly-coupled artifacts against the one shared backend (port 4700):

1. **COLL-01** — committed screenshots of all three runtimes (web, iOS **simulator**,
   Android **emulator**) running against the one shared backend, honestly labeled as
   advisory native evidence (simulator/emulator ≠ physical device).
2. **COLL-02** — a short screen recording of the three-runtime comparison, captured
   and linked/referenced from the docs/README.
3. **DOCS-01** — a new `guides/see_it_run.md` with a **gameplan summary at the top**,
   **JTBD-driven sections**, **linking to (not duplicating)** `examples/QUICK_START.md`,
   slotted into the ExDoc **"Start" group after README**.
4. **DOCS-02** — README **and** `examples/QUICK_START.md` route readers to the new guide
   and the one-command path, **preserving honest support labels** (no native overclaim).
5. **DOCS-03** — guide truth (ports, routes, commands) guarded by ≥1 source-derived
   `test/crosswake/guides/see_it_run_test.exs`, consistent with the existing
   `test/crosswake/guides/*_test.exs` drift-test culture.

**Core posture (inherited, locked):** the **web path is the proof**; everything native
is **advisory** (simulator/emulator, never device). Honesty culture is paramount —
"install truth is product truth", no overclaim, every fact source-derived + drift-tested.

**NOT in this phase / explicitly out:**
- The banner string itself — already drift-tested in Phase 127 (`see_it_run_banner_test.exs`,
  D-21). This phase's test scopes to the **guide markdown only**; zero banner-string duplication.
- `bin/see-it-run.sh` logic / native dev wiring / the Docker backend — all shipped (Phases 125-127).
- A `--backend-url`/port override; Dockerizing the Android emulator; auto-creating an AVD.
- Automating native sim/emulator capture in CI (out — requires macOS+Xcode+SDK runners).

**Method:** four parallel research subagents (one per gray area) each weighed
pros/cons/tradeoffs, Elixir/Hex/ExDoc idiom, named ecosystem lessons (Phoenix, Vite,
Supabase, Tauri, tldraw, Astro, Prisma, Drizzle, Expo, Excalidraw; Diátaxis; Elixir/Rust
doctests, mdBook/markdown-link-check/Vale), JTBD/who-what-where-when-why, brand voice,
and accessibility — synthesized into the single coherent set below. The one cross-area
tension (where collateral lives) resolved consistently to `brandbook/collateral/`
(Hex-excluded, raw-URL referenced). Confidence: high on all four.
</domain>

<decisions>
## Implementation Decisions

### Collateral capture & storage (COLL-01, COLL-02)

- **D-01 (storage = `brandbook/collateral/see-it-run/`, NOT `guides/`):** All screenshots
  and the recording live under `brandbook/collateral/see-it-run/`, which is **excluded from
  the Hex tarball** (`mix.exs` `exclude_patterns: ["brandbook"]`). **Rejected `guides/`:** it
  is in the package `files:` allowlist, so any binary there ships to every downstream
  `mix deps.get` — a severe DX regression (the #1 footgun; v9.0 deliberately kept brandbook
  <1MB and excluded). This mirrors the existing committed collateral (`social-card.png`,
  `readme-header*.svg`).
- **D-02 (reference via `raw.githubusercontent.com` absolute URLs):** README and
  `guides/see_it_run.md` embed images via
  `https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/<file>`
  — the **exact pattern already used for `readme-header.svg`/`readme-header-dark.svg`**. ExDoc
  (HexDocs) and GitHub both render these inline at build time; no binary enters the tarball.
- **D-03 (capture split — web automated, native human-captured):** A capture harness
  `bin/capture-collateral.sh` (a) runs the **web** shots via the in-repo Playwright (deterministic,
  localhost:4700 at `/`, `/offline`, `/bridge-proof`), and (b) prints exact copy-paste commands
  for the **human-gated** native shots (`xcrun simctl io booted screenshot …`,
  `adb exec-out screencap -p > …`), since iOS sim / Android emulator require Xcode + SDK + the
  Phase-126 Dev build on the maintainer's Mac. `--web-only` flag for headless/CI. The phase
  ships the harness **and** real committed files (NOT placeholders — a placeholder PNG would be a
  lie under the honesty culture). **Manual gate (flag for planner/executor):** the maintainer must
  run `bin/see-it-run.sh --build` → `bin/capture-collateral.sh` → capture native + recording →
  commit, before the phase can close. This is inherent to advisory-native evidence and cannot be
  automated.
- **D-04 (file set):** `web-home.png`, `web-offline.png`, `web-bridge-proof.png` (Playwright);
  `ios-simulator.png`, `android-emulator.png` (human); `three-runtime-montage.png` (the README
  hero, all three side-by-side); `see-it-run.gif` (the recording). Capture web at 1x / ~900px-wide
  readable width (not Retina — avoids illegible terminal text at GitHub's column).
- **D-05 (recording = committed optimized GIF, NOT MP4/external):** A committed **GIF** under
  ~5MB (hard cap 8MB) in `brandbook/collateral/see-it-run/`. GIF **auto-plays inline** in GitHub
  markdown + ExDoc; **MP4 renders as a download link** (rejected); external Loom/YouTube has
  link-rot + account-maintenance risk (rejected). Discipline: crop to ~900px, 12fps, ~10-15s,
  optimize with `gifsicle -O3`. Scope: terminal (`bin/see-it-run.sh` → banner → browser auto-open)
  is fully capturable; native frames can be the static `three-runtime-montage.png` if a single
  screen recording across all three windows is impractical (planner's call).
- **D-06 (honest labeling everywhere — canonical term `emulator evidence`):** Every native shot
  carries the support-matrix legend term **`emulator evidence`** plus the plain sentence
  *"Advisory native evidence — simulator/emulator, not a physical device."* Placement: (a) alt
  text on every native `<img>`, (b) a caption line under each native embed, (c) a `> Advisory
  native collateral` blockquote adjacent to the README montage (reader meets the caveat before/with
  the image, never after), (d) a `brandbook/collateral/see-it-run/README.md` label table mirroring
  the existing `brandbook/collateral/README.md`. Never use unqualified "supported"/"proven"/"works
  on device"/"cross-platform" near native collateral; "proven" stays reserved for the web path.

### `guides/see_it_run.md` structure & ExDoc placement (DOCS-01)

- **D-07 (gameplan = a top-of-page blockquote "declaration block"):** Open with a `>` blockquote:
  one-sentence journey promise with honest scope ("…advisorily, without proving device support"),
  the zero-toolchain caveat ("works from Docker with no local Elixir toolchain"), **the single hero
  command `bin/see-it-run.sh` in a code block**, "the banner prints your next steps", and a link to
  `examples/QUICK_START.md` as the proof ladder. Payoff-first; mirrors the brand promise "declare
  the crossing".
- **D-08 (section outline — JTBD, payoff-first, each a clean exit point):**
  `# See It Run` → gameplan blockquote (D-07) → **`## What You'll See`** (the montage/recording +
  honest labels — visual proof before prose; the collateral's canonical display home) →
  **`## Run It Now (Zero Toolchain)`** (JTBD-A: Docker one-command → web; links QUICK_START Option A)
  → **`## Browse the Route Owners`** (names `/`, `/offline`, `/bridge-proof` by owner label; links
  QUICK_START "See The Route Owners" for URLs/what-to-look-for) → **`## Compare All Three Runtimes
  (Web, iOS, Android)`** (JTBD-B: the comparison, advisory-labeled) → **`## Wire a Native Runtime to
  the Local Backend`** (JTBD-C: Phase-126 dev wiring; quotes the one advisory sentence verbatim;
  links QUICK_START dev-wiring section for the actual `xcodebuild`/`gradlew` commands) → **`## What
  This Proves (And What It Doesn't)`** (echoes the banner's D-06 proven/needs-build block) →
  **`## Go Deeper`** (forward-only nav to QUICK_START, install.md, route_policy.md, adopter_profiles.md).
- **D-09 (Diátaxis = orientation/tutorial hybrid; write action-first):** This is the
  orientation gateway ("is this worth 5 more minutes?"), written like a tutorial (action-first,
  copy-paste-ready) but scoped to orientation — NOT the concept explainer (that's route_policy.md /
  user_flows.md). One Diátaxis type per guide is the ExDoc house idiom.
- **D-10 (ExDoc "Start" slot = README → see_it_run → route_policy → install):** Insert
  `"guides/see_it_run.md"` as item **2** in the `Start` group (and 2nd in the `extras:` list, right
  after `"README.md"`). Reading order = progressive commitment: README (what is this?) → see_it_run
  (can I see it work?) → route_policy (the ownership model, now with context) → install (I've decided).
  Putting the demo before the policy theory gives the model its context.

### README + QUICK_START routing (DOCS-02)

- **D-11 (ONE hero command = `bin/see-it-run.sh`):** The repo-root `bin/see-it-run.sh` is THE hero
  command in README and the canonical first-run command in QUICK_START. `cd examples/phoenix_host &&
  docker compose up` is **demoted to a reference/fallback** ("to run the Docker backend directly…")
  — it bypasses the banner, the proven/needs-build block, and auto-open (the whole experiential
  point). Precedent: Supabase CLI's `supabase start` fronting raw `docker compose` (Phase 127 D-01).
- **D-12 (README placement = a new `## See it run` section BETWEEN `## What this is not` and
  `## Choose your path`):** Scope established (what it is/isn't) → **experiential proof** → then
  path-routing. **Rejected** a bullet inside "Evaluating Crosswake" (buries the payoff in link soup)
  and placement above the scope sections (invites the "this is React Native" misread). The section
  carries: the `bin/see-it-run.sh` hero block + Docker caveat, the three route owners named, a
  `> Advisory native collateral` blockquote (with `emulator evidence` + support-matrix legend link),
  and two forward links — to `guides/see_it_run.md` (guided tour) and `examples/QUICK_START.md`
  (command reference). Section name "See it run" mirrors the milestone + the guide for a coherent thread.
- **D-13 (README image = link-to-guide by default; one embedded montage optional):** Keep the README
  lightweight — link to `guides/see_it_run.md` for the visual (satisfies "referenced in the README").
  If the planner wants one inline image for first-screenful impact, embed **only**
  `three-runtime-montage.png` (via the D-02 raw URL, `<picture>` dark/light optional) between the hero
  command block and the route sentence, with the honest label **in the alt text** (`… iOS Simulator
  (emulator evidence) … Android Emulator (emulator evidence) …`).
- **D-14 (QUICK_START routing = a top-of-file `> New here?` blockquote pointer):** Add, before the
  existing intro paragraph: a one-line `> **New here?** Start with [guides/see_it_run.md](../guides/
  see_it_run.md) … Come back here for the full proof command reference.` Then rename `### Option A:
  Docker` → `### Option A: One Command (Docker)`, lead with `bin/see-it-run.sh`, and keep
  `cd examples/phoenix_host && docker compose up` as the "run directly" fallback. Relationship is
  one-directional and non-circular: README → see_it_run → (forward, anchored) QUICK_START. see_it_run
  links **forward** into QUICK_START sections, never back to README.
- **D-15 (honest-label sentence, verbatim, adjacent to any native claim):** *"A successful simulator
  or emulator run confirms the dev wiring reaches the local backend, but does not prove physical-device
  support. This is `emulator evidence` per the [support-truth label legend](guides/support_matrix.md#support-truth-label-legend)."*
  Use the canonical `emulator evidence` term (anchors to the ratified truth table); "advisory" remains
  the banner's word. `mix crosswake.demo` is NOT in the README hero (Docker-only newcomer is primary);
  mention it only as a note inside the guide ("if you have Elixir installed, `mix crosswake.demo` does
  the same").

### Doc-contract test (DOCS-03) — `test/crosswake/guides/see_it_run_test.exs`

- **D-16 (module + template):** `Crosswake.Guides.SeeItRunTest`, mirroring
  `quick_start_adoption_drift_test.exs` (per-file copy of the `require_contains` / `wrong_port_failures`
  / `failure` / `format_failures` / `assert_no_drift_failures` / `assert_failure_category` helpers — the
  house idiom replicates helpers per file). Target = `guides/see_it_run.md` (markdown) **only**.
- **D-17 (assertion set — every fact source-derived):** Assert the guide contains: the
  **port** (`localhost:#{port}`, port derived from `examples/phoenix_host/config/runtime.exs` via the
  shared `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` regex) + `wrong_port_failures/3` line-scan
  for stale ports; routes **`/offline`** and **`/bridge-proof`** (source: `examples/phoenix_host/lib/
  crosswake_example/router.ex`; home `/` covered implicitly by the full URL assertion); the hero
  command **`bin/see-it-run.sh`** (`File.exists?` + string present); **`docker compose`**; a link to
  **`examples/QUICK_START.md`** (file exists + string present); native posture words **`advisory`**,
  **`simulator`**, **`emulator`**; and the honest-label term **`emulator evidence`** (ties DOCS-02 +
  D-06/D-15). Use a `documented_path_failures`-style helper (prefixes `examples/`, `bin/`, `guides/`)
  to catch broken internal links.
- **D-18 (no-overlap boundary with the Phase-127 banner test — reviewer-verifiable):** The banner test
  (`@target = bin/see-it-run.sh`) guards banner internals (whitespace-padded route lines, `-scheme Dev`,
  `installDevDebug`, `adb shell am start…`, `JAVA_HOME=…`, "proven native build"). This test
  (`@target = guides/see_it_run.md`) guards guide narrative facts and does **NOT** assert those
  command-literal/banner strings. Both **independently derive the port from runtime.exs** — that's
  correct (one shared source); the duplication avoided is asserting the same *banner string* in both
  files. Verifiable in 30s: different `@target_path`, no overlapping `require_contains` literals in the
  same document.
- **D-19 (collateral existence guard = OUT of `see_it_run_test.exs`; deferred to a sibling):** Do NOT
  put `File.exists?("…png")` assertions in this test at write-time — the native binaries are
  human-captured later, so it would leave **CI red during the very phase that writes it** (the classic
  brittleness footgun the `evidence_manifest_test.exs` culture avoids). When the binaries are committed,
  add a separate `see_it_run_collateral_test.exs` that derives referenced paths **from the guide text**
  (`documented_path_failures` style) and asserts they exist + carry the `advisory`/`emulator evidence`
  label within proximity (the `native_evidence_drift_test.exs` model). Execution ordering: write the
  guide + this markdown test (green on delivery) → capture + commit binaries → add the collateral sibling.
- **D-20 (minimal anti-vacuity set — exactly three synthetic cases):** Synthetic-failure tests proving
  the scanner isn't a no-op: (1) **wrong port** must fail (`:wrong_port`), (2) **missing route** must
  fail (`:missing_route`), (3) **missing native posture label** must fail (`:missing_native_label`). Do
  NOT add synthetic cases for `missing_command`/`missing_link` (lower drift risk, not worth the
  maintenance) — the house idiom from `native_evidence_drift_test.exs` / `contract_drift_test.exs`.

### Claude's Discretion (planner/executor to settle)
- GIF capture tool (recommend `Kap` or scripted `ffmpeg + gifsicle`) and whether the montage is
  auto-composed (`ImageMagick montage`/`convert +append`, add as a documented dev prereq) or hand-made.
- Whether the GIF spans all three GUI windows or shows terminal+browser with the static montage for native.
- Whether README's "Evaluating Crosswake" list ALSO gets a secondary `guides/see_it_run.md` bullet
  (recommended: yes, secondary to the new `## See it run` section).
- Exact `/`-home-route assertion strategy (full-URL implicit vs. an explicit route-list regex).
- Test-first vs. guide-first authoring order (keep the sanity test from asserting `File.exists?(guide)`
  if test-first).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"COLL" / §"DOCS" — COLL-01, COLL-02, DOCS-01, DOCS-02, DOCS-03 (locked text).
- `.planning/ROADMAP.md` §"Phase 128" — goal + 5 success criteria (the acceptance bar); §"Phase 127" for
  the inherited banner/posture; §"Phase 120" (prior collateral phase — learn from its evidence patterns).
- `.planning/phases/127-launch-orchestration-banner/127-CONTEXT.md` — port 4700, routes `/`,`/offline`,
  `/bridge-proof` (D-05), banner anatomy D-04..D-06 (this guide echoes it), advisory-native voice, the
  banner footer ALREADY pointing to `guides/see_it_run.md`, and the D-21 banner-test boundary.
- `.planning/phases/126-additive-native-dev-wiring/126-CONTEXT.md` — D-16 "advisory native" voice; the
  exact Dev-scheme/flavor commands the guide references (not duplicates).

### Hex package & ExDoc surface (mutate these)
- `mix.exs` — `package` `files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)` +
  `exclude_patterns: ["brandbook"]` (WHY collateral goes in brandbook/, D-01); `docs` `extras:` +
  `groups_for_extras:` "Start" group (insert `guides/see_it_run.md` as item 2, D-10).

### Collateral pattern (mirror)
- `README.md` top — the `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/…`
  image-reference pattern to mirror (D-02); the `## Choose your path`, "What this is not", and
  support-label-legend sections (D-12 placement).
- `brandbook/collateral/` — existing committed `social-card.png`, `readme-header*.svg` + its `README.md`
  label table (the new `see-it-run/` subdir + its label table mirror this, D-01/D-06).
- `guides/support_matrix.md` §"support-truth label legend" — canonical labels incl. `emulator evidence`,
  `advisory evidence` (the honest terms, D-06/D-15).

### Guide siblings & voice (match house style)
- `examples/QUICK_START.md` — the doc this guide LINKS to, not duplicates (D-08/D-14); its First Run /
  Docker / Native / dev-wiring sections and support labels.
- `guides/route_policy.md`, `guides/install.md`, `guides/user_flows.md`, `guides/adoption.md` — house
  guide voice/structure; `guides/adopter_profiles.md` — the 3 evaluator personas the routing serves.
- `brandbook/BRAND-SPEC.md` — **CANONICAL** brand voice/tone + `[crosswake]` prefix (newer than, and
  supersedes, `prompts/crosswake-brand-book.md`); `prompts/crosswake-elixir-oss-dna.md` — honesty culture.

### Drift-test culture (mirror exactly — D-16..D-20)
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — THE template (reads a non-Elixir text
  file, derives PORT via regex, `require_contains`, `wrong_port_failures`, `documented_path_failures`).
- `test/crosswake/guides/see_it_run_banner_test.exs` — the Phase-127 test to stay non-overlapping with (D-18).
- `test/crosswake/guides/native_evidence_drift_test.exs`, `contract_drift_test.exs` — synthetic
  anti-vacuity idiom (D-20); `evidence_manifest_test.exs` — collateral/label-validation culture (D-19).
- `test/crosswake/guides/port_registry_test.exs` — minimal source-derived guard example.

### Source-of-truth for asserted facts (D-17)
- `examples/phoenix_host/config/runtime.exs` — canonical PORT source (4700).
- `examples/phoenix_host/lib/crosswake_example/router.ex` — canonical route source (`/`,`/offline`,`/bridge-proof`).
- `bin/see-it-run.sh` — the hero command the guide/README reference (must exist; Phase 127).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/collateral/` committed-binary + `raw.githubusercontent.com` reference pattern (readme-header
  SVGs, social-card.png) — extend with a `see-it-run/` subdir (D-01/D-02); Hex-excluded already.
- In-repo **Playwright** (route-tour proof behind `evidence_manifest_test.exs`) — drives the deterministic
  web screenshots in `bin/capture-collateral.sh` (D-03).
- `quick_start_adoption_drift_test.exs` — the proven "read a text file, derive port via regex, assert +
  synthetic-failure + documented-path-existence" idiom; `see_it_run_test.exs` copies it nearly verbatim (D-16).
- `bin/see-it-run.sh` (Phase 127) — the canonical hero command; banner footer already points to this guide.
- `guides/support_matrix.md` label legend — the canonical honest vocabulary (`emulator evidence`).

### Established Patterns
- **Web = proof, native = advisory** — "proven" reserved for web; native is `emulator evidence`, never
  device (D-06/D-15). **Honesty culture** — every port/route/command fact source-derived + drift-tested.
- **Hex tarball is a contract** — `files:` allowlists `guides` (ships) and excludes `brandbook` (doesn't);
  binaries belong in brandbook/ + raw-URL referenced, never in guides/ (D-01).
- **Link-not-duplicate** — one canonical home per fact (port→runtime.exs, commands→QUICK_START); the guide
  points, never copies (drift risk). **Proof fixtures are sacred** — this phase only adds docs/collateral.
- **Drift tests stay red-on-delivery, not red-pre-delivery** — defer human-captured-binary existence checks
  to a sibling test added after commit (D-19).

### Integration Points
- ExDoc `extras` + `groups_for_extras` "Start" group registration (D-10) — the one `mix.exs` doc change.
- README `## See it run` section + `## Choose your path` secondary bullet (D-12/D-13); QUICK_START top
  pointer + Option-A rename (D-14).
- `see_it_run_test.exs` reads runtime.exs (port) and router.ex (routes) as source; non-overlapping with
  the banner test (D-18); future collateral sibling reads the guide for referenced paths (D-19).
</code_context>

<specifics>
## Specific Ideas

- The maintainer asked for one coherent, one-shot recommendation set (NOT sequential questions) —
  delivered via four parallel research subagents (collateral capture & storage; guide structure & ExDoc
  slot; README/QUICK_START routing; doc-contract test scope), each weighing pros/cons/tradeoffs,
  Elixir/Hex/ExDoc idiom, named ecosystem lessons, JTBD/who-what-where-when-why, brand voice, and
  accessibility — synthesized into D-01..D-20.
- The one cross-area tension — **where collateral lives** — resolved consistently across all four agents:
  `brandbook/collateral/see-it-run/` (Hex-excluded) referenced via `raw.githubusercontent.com` URLs, the
  exact existing readme-header pattern. This is the load-bearing decision (D-01/D-02) that keeps the Hex
  tarball lean while keeping images ExDoc/GitHub-renderable.
- Ecosystem lessons applied: payoff/command-before-context + screenshot-before-prose (Phoenix "Up and
  Running", Vite, Supabase, tldraw, Excalidraw — D-07/D-08/D-12); one named hero command fronting raw
  compose (Supabase CLI — D-11); Diátaxis one-type-per-guide (D-09); committed-optimized-GIF over MP4/
  external for inline autoplay + no link-rot (charmbracelet/vhs "script the capture, commit the output";
  Expo's `user-images.githubusercontent.com` GC footgun — D-05/D-03); assert-the-contract-not-the-prose +
  derive-from-source-never-hardcode + don't-go-red-before-the-artifact-exists (Elixir/Rust doctests,
  mdBook link-check — D-17/D-19).

### The one cross-area tension, resolved
- **Collateral in `guides/` (ExDoc-native, ships in tarball) vs. `brandbook/` (excluded, raw-URL referenced):**
  resolved to **brandbook/ + raw URL** (D-01/D-02). No compromise on either goal — images render inline in
  HexDocs/GitHub AND nothing bloats the Hex package for downstream consumers.
</specifics>

<deferred>
## Deferred Ideas

- `see_it_run_collateral_test.exs` (binary-existence + label-proximity guard) — written **after** the
  human-captured native screenshots/recording are committed, NOT in this phase's markdown test (D-19),
  so CI never goes red before the binaries exist. May land same-phase post-capture or as a fast follow.
- An automated CI lane that captures native sim/emulator collateral on macOS+Xcode+SDK runners — out
  (expensive, out of v15.0 scope); native capture stays human-gated/advisory.
- A `bin/see-it-run.sh --backend-url`/port override — deferred (port 4700 locked by Phase 125).
- Auto-composing the three-runtime montage in CI / a Vale prose-linter / markdown-link-check toolchain —
  out; the in-process Elixir drift test + optional local ImageMagick compose are sufficient (D-17, discretion).

None beyond the above — discussion stayed within phase scope.
</deferred>

---

*Phase: 128-collateral-see-it-run-guide*
*Context gathered: 2026-06-22*
