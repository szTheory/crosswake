# Phase 26 Coherent Recommendation — Description Text + docs/0 Extras Scope

**Researched:** 2026-05-27
**Confidence:** HIGH for both decisions

---

## TL;DR

- **Description:** `"Route policy and runtime contracts for Phoenix apps that go mobile."`
- **Extras scope:** phase-split — CHANGELOG.md omitted from Phase 26 extras; Phase 27 adds it when creating the file
- **Coherence:** The description names the two concepts (route policy, runtime contracts) without leaning so hard on "mobile" that the all-guides extras list oversells scope; and the phase-split keeps Phase 26's commit self-consistent — every file referenced in `docs/0` extras exists on disk when Phase 26 closes.

---

## Decision 1: :description text

### Recommendation

```
"Route policy and runtime contracts for Phoenix apps that go mobile."
```

60 characters. This is a fourth-candidate synthesis (D), not A, B, or C verbatim.

---

### Rationale

- **Pattern-match to the strongest canonical libs.** Ecto: "A toolkit for data mapping and language integrated query for Elixir" (67 chars). Mint: "Small and composable HTTP client." (33 chars). Bandit: "A pure-Elixir HTTP server built for Plug & WebSock apps" (55 chars). Oban: "Robust job processing, backed by modern PostgreSQL, SQLite3, and MySQL." (71 chars). The pattern is: noun/concept first, then "for" + platform/use-case, no positioning words like "fast" or "production-ready." Under 80 characters is the clear norm; over 100 reads corporate. The proposed D description (60 chars) sits squarely in the mainstream.

- **"Route policy and runtime contracts" is the dual anchor the library actually ships.** The route policy DSL is the core differentiator. Runtime contracts (manifest, capability ladder, bridge, offline seams, commerce corridors) are the second pillar. Naming both in the description reflects what the library is, not what it aspires to be — satisfying the OSS DNA "public contract honesty beats breadth" anchor.

- **"for Phoenix apps that go mobile" echoes the README tagline without lifting it verbatim.** README opener: "Phoenix-native route policy for apps that go mobile." The description reuses "go mobile" — which is the brand-book's own phrase — but adds "runtime contracts" and drops "Phoenix-native" (redundant with "for Phoenix apps"). This harmonizes the hex search result with the first thing an adopter reads on GitHub without being a copy-paste.

- **"substrate" is struck.** Candidate A's "runtime contract substrate" uses "substrate" as a jargon signal that reads pretentious to evaluators who haven't read the brand-book. It is not a term of art in the Elixir ecosystem. None of the 13 surveyed canonical libs use "substrate" or equivalently insider vocabulary in their description.

- **"targeting mobile deployments" is struck.** Candidate B's corporate phrasing ("Phoenix applications targeting mobile deployments") adds 36 characters to say what "Phoenix apps that go mobile" says in 6 fewer words. "targeting mobile deployments" sounds like a product brief, not a library description.

- **"mobile" is defensible at Phase 26.** The library ships iOS + Android as first-class targets (stated in PROJECT.md under Constraints: "iOS and Android are first-class in v1"). The description does not claim broad UI breadth or "universal mobile app" positioning. The qualifying phrase "apps that go mobile" signals this is about Phoenix apps adding a mobile layer — not a standalone mobile framework. This is the brand-book's own "shorter one-liner": "Route policy for Phoenix apps that go mobile." The proposed D description directly extends that.

- **No "Phoenix-native" — it's redundant.** "for Phoenix apps" already scopes the library. "Phoenix-native" is implied. Every library in the Phoenix ecosystem is Phoenix-native; saying it out loud consumes 14 characters of description real estate to say something obvious.

- **Matches the szTheory house description pattern.** Oarlock (236 chars, content-dense): long technical summary with explicit non-claims and hexdocs pointer. Sigra (246 chars): same pattern. Both are significantly longer than the Crosswake description and have earned that length through shipped surface area + companion relationships. For a first Hex publish from a single-maintainer lib with a single clear positioning, the short authoritative form is more credible. Phoenix itself ships 42 chars ("Peace of mind from prototype to production"). Crosswake at 60 chars is honest and complete.

---

### Pros/cons table

| Candidate | Pros | Cons | Verdict |
|---|---|---|---|
| A. "Phoenix-first route policy and runtime contract substrate" (57 chars) | Short; has "Phoenix-first" differentiation | "substrate" = jargon not used elsewhere in the ecosystem; "Phoenix-first" is redundant for a Phoenix library; no use case signal | Reject — "substrate" is the kill shot |
| B. "Route policy and runtime contract layer for Phoenix applications targeting mobile deployments." (95 chars) | More descriptive; names both pillars | 95 chars is on the long end; "targeting mobile deployments" is corporate; "layer" is only marginally better than "substrate"; no real differentiation gained over shorter forms | Reject — overlong, corporate phrasing |
| C. "Route policy and runtime contracts for Phoenix mobile apps." (59 chars) | Short; names both pillars; under 60 chars | "Phoenix mobile apps" implies the library is for already-mobile apps, not for Phoenix apps adding mobile — subtle positioning error; "mobile apps" reads like a general-purpose mobile app framework | Reject — "Phoenix mobile apps" undersells the Phoenix-first origin and oversells mobile breadth |
| D. "Route policy and runtime contracts for Phoenix apps that go mobile." (60 chars) | Names both pillars; echoes README/brand-book "go mobile" phrase; avoids "substrate" and "layer"; under 65 chars; no corporate phrasing; mobile scoping is directional ("go mobile") not categorical | Loses "Phoenix-native" signal but "for Phoenix apps" does the same work | **SHIP THIS** |

---

### Evidence from canonical Elixir libs

| Lib | hex.pm :description | Length | What we learn |
|---|---|---|---|
| Phoenix | "Peace of mind from prototype to production" | 42 chars | Positioning sentence, no technical terms at all — works because Phoenix doesn't need to explain itself. Crosswake is not Phoenix. |
| Ecto | "A toolkit for data mapping and language integrated query for Elixir" | 67 chars | Noun-first ("A toolkit"), then use-case, then "for Elixir". Pattern to borrow: noun-phrase + use-case. |
| Plug | "Compose web applications with functions" | 40 chars | Verb-first, very short. Works for a foundational primitive. |
| LiveView | "Rich, real-time user experiences with server-rendered HTML" | 58 chars | What it does (rich UX) + how (server-rendered HTML). No "for Phoenix" — it's implied. |
| Bandit | "A pure-Elixir HTTP server built for Plug & WebSock apps" | 55 chars | "built for X" instead of "for X" — adds craft signal. Could be borrowed. |
| Req | "Req is a batteries-included HTTP client for Elixir." | 51 chars | Starts with the lib name; "batteries-included" is positioning. Works because the claim is defensible from day one. |
| Mint | "Small and composable HTTP client." | 33 chars | Adjective-first. Works because Mint's value prop IS "small and composable." |
| Oban | "Robust job processing, backed by modern PostgreSQL, SQLite3, and MySQL." | 71 chars | "Robust" + use-case + technology proof. "Robust" is a claim Oban can back with 5+ years of production history. |
| Ash | "A declarative, extensible framework for building Elixir applications." | 69 chars | "A declarative, extensible framework" — adjectives that directly describe Ash's architecture. |
| Broadway | "Build concurrent and multi-stage data ingestion and data processing pipelines" | 77 chars | Verb-first ("Build"), then what kind ("concurrent and multi-stage"), then use case. |
| ExDoc | "ExDoc is a documentation generation tool for Elixir" | 51 chars | Starts with name, then exactly what it is. Crystal clear. |
| Swoosh | "Compose, deliver and test your emails easily in Elixir." | 55 chars | Verb list + subject + adverb + platform. Brisk. |
| Finch | "An HTTP client focused on performance." | 38 chars | "focused on performance" is the positioning claim. Short and backed by benchmarks. |
| oarlock (szTheory) | "Paddle Billing SDK for Elixir — typed structs, pure-function webhooks…" (236 chars) | 236 chars | szTheory house style: long-form, technical, non-claim-shy. Works for oarlock because of the companion relationship with Accrue. Not the right model for Crosswake's first description. |
| sigra (szTheory) | "Authentication for Phoenix 1.8+ and Ecto. Mix generators emit…" (246 chars) | 246 chars | Same house style. Sigra earns this length because it has a multi-surface install contract. |
| lattice_stripe (szTheory) | "A production-grade, idiomatic Elixir SDK for the Stripe API" | 60 chars | Closer to the right Crosswake model — short, descriptive, positioning word ("production-grade") that Stripe SDK can back. Note: "production-grade" on a first publish is a claim that needs the library's track record to support it. |

**Key finding:** The median among serious canonical libs is 50–70 chars, noun/concept-first, "for X" scoping, no hype words. The proposed D description (60 chars) matches this exactly. szTheory's own longer descriptions (oarlock, sigra) work because those libs have companion context to reference inline; Crosswake at 0.1.0 does not yet have that context.

---

### Brand-book / OSS-DNA alignment

- **Brand-book §25 first-release checklist: "Keep the first release visually quiet, technical, and trustworthy."** The description "Route policy and runtime contracts for Phoenix apps that go mobile." is quiet (no hype), technical (names the two architectural pillars), and trustworthy (the claims are exactly what the library ships). ✓

- **Brand-book §5 shorter one-liner: "Route policy for Phoenix apps that go mobile."** The proposed D description is this exact phrase + "and runtime contracts" added to name the second pillar. It does not stray from the brand-book's own vocabulary. ✓

- **OSS DNA §2: "Public contract honesty beats breadth."** The description says "route policy and runtime contracts" — not "mobile app framework," not "cross-platform toolkit," not "universal runtime." The scope is honest. ✓

- **OSS DNA §1: "Install truth is product truth."** The description will be the first text an evaluator reads at hex.pm search results. It should answer "what does this do" with minimal ambiguity. "Route policy and runtime contracts for Phoenix apps that go mobile" answers that question in 10 words. ✓

- **Brand-book §6 voice: "Write like a careful maintainer. Precise, short, helpful, and candid."** The description is precise (names the two pillars), short (60 chars), helpful (scopes the use case), and candid (no marketing puffery). ✓

- **Brand-book §4 naming system: preferred concept names include "Route Policy," "Runtime," "Bridge Contract."** "Route policy and runtime contracts" maps directly to two of the preferred concept names. ✓

- **OSS DNA footgun: "letting marketing framing outrun architectural truth."** "substrate" (Candidate A) and "targeting mobile deployments" (Candidate B) both outrun architectural truth. The proposed D description does not. ✓

---

### What this sacrifices

- **"Phoenix-native" differentiation signal.** "For Phoenix apps" does the same scoping work but without the "native" emphasis. If an evaluator skims the description without reading further, they will not see "Phoenix-native" — but they will see "for Phoenix apps" which is equivalent disambiguation.
- **Technical depth.** The description does not enumerate the capability ladder, bridge contracts, commerce seams, or offline islands. That is intentional — hex.pm search result descriptions are not API reference docs. The guides and hexdocs carry that load.
- **szTheory house style (long-form, technical, inline non-claims).** Oarlock and sigra use much longer descriptions. This is a departure. Justified because those libs have companion context that needs inline naming; Crosswake at 0.1.0 does not.

---

## Decision 2: docs/0 extras scope

### Recommendation

**Phase-split** — Phase 26 ships `docs/0` extras without `CHANGELOG.md`; Phase 27 adds it to extras when creating the file.

Exact extras list to ship in Phase 26's `docs/0`:

```elixir
extras: [
  "README.md",
  "LICENSE",
  "guides/install.md",
  "guides/support_matrix.md",
  "guides/adopter_profiles.md",
  "guides/user_flows.md",
  "guides/capabilities.md",
  "guides/bridge.md",
  "guides/offline.md",
  "guides/commerce.md",
  "guides/compatibility.md",
  "guides/native_shell.md",
  "guides/packs.md"
]
```

`CHANGELOG.md` is added to extras in Phase 27's commit (the same commit that creates `CHANGELOG.md`).

---

### Rationale

- **Atomic-commit principle is load-bearing here.** Phase 26 SC #5 requires `mix deps.get && mix compile` to succeed with no warnings. The SC does not require `mix docs` clean — but atomic-commit discipline requires that the commit *could* run clean with reasonable effort. A `docs/0` extras list that references a file not on disk violates the spirit of "leave the repo in a consistent state." Not a hard gate, but a smell that will confuse future readers of the git log.

- **Forward-ref creates a category of confusion with no upside.** If a developer checks out the Phase 26 commit and runs `mix docs` — which is a natural thing to do when evaluating a docs setup — it fails with "CHANGELOG.md not found." The failure is not silently wrong (unlike Pitfall 14, where guides in extras but not in `:files` silently produces wrong hexdocs). It is loud and confusing. The Phase 26 commit has no CHANGELOG.md. Listing it in extras sends a message to the reader: "this repo is mid-flight." That is fine if it's true — but in a clean phase commit it should not be true.

- **Phase 27 surface area is not meaningfully increased.** Phase 27 must create CHANGELOG.md. Adding one line to `docs/0` extras in the same commit is negligible. The "minimize Phase 27 mix.exs diff" argument for forward-ref is weak: Phase 27 is explicitly the CHANGELOG phase; adding CHANGELOG to docs/0 extras IN Phase 27 keeps the narrative coherent. Phase 26 is the metadata audit phase. Phase 27 is the CHANGELOG phase. The phase boundary is the right boundary.

- **Stub-out is a hack.** Creating CHANGELOG.md in Phase 26 as a one-line stub just to satisfy extras is a false phase boundary. Phase 26 does not own CHANGELOG content; Phase 27 does. Forcing Phase 26 to create a stub that Phase 27 immediately rewrites creates two git commits touching the same file for non-functional reasons and muddies the blame graph ("why was CHANGELOG created in Phase 26 if Phase 27 is the CHANGELOG phase?").

- **oarlock precedent is exactly the phase-split pattern.** oarlock's `mix.exs` lists `CHANGELOG.md` in extras AND `CHANGELOG.md` exists on disk. The file was created in the same commit as the rest of the docs/0 setup (oarlock was bootstrapped in one pass). For Crosswake, the equivalent "same pass" is phases 26+27 together — but since they are separate phases with separate SCs, the cleanest split is: Phase 26 owns the metadata machinery (docs/0 function, `:files`, `:links`, `source_url`); Phase 27 owns CHANGELOG creation AND the addition of CHANGELOG.md to docs/0 extras. The Phase 27 commit is then "add CHANGELOG.md + wire it into docs/0" — a single coherent unit.

- **PITFALLS.md Pitfall 14 inverse analysis.** Pitfall 14: "guides in extras but not `:files` = silent hexdocs failure." The inverse (file in extras but not on disk) is loud, not silent. Loud failures during development are less harmful than silent failures in production hexdocs. But the argument for forward-ref ("Phase 26 SC #5 doesn't require mix docs to pass") only holds if you are comfortable with a loud failure in the Phase 26 commit state. Phase-split avoids both the loud failure and the silence risk, at the cost of one line added in Phase 27.

- **release-please interaction is neutral for both options.** Once CHANGELOG.md exists (after Phase 27), release-please will rewrite it on every release regardless of whether it was referenced in docs/0 from Phase 26 or Phase 27. The release-please interaction argument does not favor forward-ref or phase-split.

---

### Pros/cons table

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Forward-ref** — include CHANGELOG.md in extras at Phase 26, file doesn't exist yet | Phase 27 needs no mix.exs touch; consistent with REC-METADATA template verbatim | `mix docs` fails at Phase 26 commit state (loud error); violates atomic-commit spirit; confuses anyone who checks out Phase 26 and runs docs; sends "mid-flight" signal | Reject |
| **Phase-split** — omit CHANGELOG.md from extras in Phase 26; Phase 27 adds it | Phase 26 commit is self-consistent; `mix docs` can run at Phase 26 state; phase narrative is clean (metadata phase vs CHANGELOG phase); aligns with atomic-commit principle | Phase 27 requires one-line mix.exs edit (negligible surface area) | **SHIP THIS** |
| **Stub-out** — create CHANGELOG.md stub in Phase 26, Phase 27 fills it in | `mix docs` works at Phase 26 state; consistent with forward-ref extras | Phase 26 owns content it shouldn't own; creates false ownership boundary; Phase 27 rewrites a file Phase 26 created, muddying blame graph; stub CHANGELOG is misleading if anyone reads it before Phase 27 | Reject |

---

### Evidence

**szTheory canonical pattern (oarlock):**
oarlock lists `"CHANGELOG.md"` in extras and `CHANGELOG.md` exists on disk — created in the same bootstrap commit. The canonical pattern is: file in extras AND file on disk in the same commit. Phase-split preserves this invariant by ensuring both happen together in Phase 27.

**sigra:**
sigra lists `"CHANGELOG.md"` in extras and `CHANGELOG.md` exists on disk. Same invariant. sigra was bootstrapped in one pass, so the phase-split question never arose — but the invariant it enforces (file in extras ↔ file on disk) is exactly what phase-split guarantees.

**Major Elixir libs (Phoenix, Ecto, Oban, Plug, LiveView, Finch, Req):**
All list `"CHANGELOG.md"` in extras (either directly or via `CHANGELOG*` glob) AND ship a CHANGELOG.md in the repo. None have a state where CHANGELOG is listed in extras but does not exist. The ecosystem invariant is: file in extras = file on disk.

**No precedent found for forward-ref in the surveyed libs.** The forward-ref option is novel and lacks prior art in the szTheory house or canonical ecosystem libs. Novel conventions require justification. There is no sufficient justification here — the only upside (saves one line in Phase 27) does not outweigh the atomicity violation.

---

### Failure modes guarded against

- **`mix docs` run at Phase 26 commit state fails loudly** — prevented by phase-split (CHANGELOG.md not in extras at Phase 26).
- **Pitfall 14 (guides in extras but not `:files`)** — prevented by the `:files` allowlist including `"guides"` and all 11 guides present in `extras:` at Phase 26.
- **Phase 27 mix.exs diff explodes unexpectedly** — prevented. Phase 27's mix.exs change is exactly one line: add `"CHANGELOG.md",` to extras. This is the smallest possible diff.
- **CHANGELOG.md in extras but not in `:files`** — prevented. The `:files` allowlist (locked per Phase 26 SC #2) includes `"CHANGELOG.md"`. Phase 27 adds the file and it is already in `:files`, so no cross-file sync is required.
- **Stub CHANGELOG misleads pre-Phase-27 readers** — prevented. No stub. Phase 26 leaves CHANGELOG.md absent; Phase 27 creates it correctly.

---

## Coherence check

The description "Route policy and runtime contracts for Phoenix apps that go mobile." scopes the library honestly to Phoenix + mobile without enumerating the 11 guides (commerce, offline, bridge, packs, native shell, etc.) that the full extras list surfaces. The guides represent the full breadth of what ships — which is wider than the description implies, but correctly so: the description answers "what is this" and the guides answer "how deep does it go." The phase-split extras scope has no bearing on the description: at Phase 26 close, all 11 guides ARE in extras, and their breadth (commerce, offline, native shell) is consistent with "runtime contracts" covering all of them. No guide is named in a way that contradicts the description; none surfaces a claim the description hasn't made. The two decisions are mutually consistent.

Both decisions align with the locked decisions: `:files` includes `guides/` and `CHANGELOG.md` (CHANGELOG will exist by Phase 27 when mix docs must run clean for HEX-03); `docs/0` with `main: "readme"`, `source_ref`, `source_url`, `formatters: ["html"]` are all preserved; `ex_doc ~> 0.38` is the dev dep; Phase 26 SC #5 (`mix deps.get && mix compile` clean) is not affected by the extras scope.

---

## Confidence

| Decision | Confidence | Reasoning |
|---|---|---|
| 1 — :description text | HIGH | All 13 canonical lib descriptions confirmed via live hex.pm API; szTheory house pattern confirmed from oarlock/sigra/lattice_stripe mix.exs; brand-book alignment is direct quote-match; the only uncertainty is aesthetic (no external adopter signal) but the evidence from the ecosystem is clear |
| 2 — docs/0 extras scope | HIGH | Phase-split is directly supported by the atomic-commit principle, szTheory canonical invariant (file in extras = file on disk), and the absence of any precedent for forward-ref in the surveyed libs; the only trade-off (one extra line in Phase 27) is negligible and unambiguously worth the consistency gain |

---

*Researched: 2026-05-27 — Phase 26 coherent recommendation for :description + docs/0 extras scope*
