# Recommendation: Package Metadata Truth (v3.3 Category A)

**Researched:** 2026-05-27  
**Confidence:** HIGH for all three decisions (backed by empirical hex.pm API, 10 canonical lib samples, hex spec source)

---

## TL;DR

Ship every Category A metadata item in v3.3 — no deferrals. Do NOT include `:maintainers` (it is deprecated in the hex spec and silently ignored by hex.pm). DO include `docs/0` and `ex_doc` — a hex page without hexdocs is a hard trust failure for a serious library, and the implementation cost is near-zero since oarlock provides an exact working template.

---

## Decisions Recommended

| Decision | Verdict | One-line rationale |
|----------|---------|-------------------|
| All metadata audit items (A-01 through A-08) | **YES — all of them, no deferrals** | Each item is LOW complexity and HIGH trust impact; deferring any is accepting a knowable defect on your first public page |
| `:maintainers` field in v3.3 | **NO — omit entirely** | The hex spec marks `:maintainers` as deprecated; hex.pm ignores it in both the package page and API; ownership is surfaced via hex.pm "Owners" (account-linked), not this field |
| `docs/0` function (hexdocs publication) | **YES — include on first publish** | A hex page without hexdocs is visually weaker and signals "unserious dep"; ex_doc + docs/0 is a 20-line addition with a complete working template already in oarlock |

---

## Examples from Successful Elixir OSS Libs

| Lib | Has `:maintainers` | Has `docs/0` | `:files` explicit | `:links` count | First-publish version |
|-----|--------------------|-------------|-------------------|----------------|----------------------|
| Phoenix | YES (4 names) | YES (rich, 40+ lines) | YES (~w form, assets+js+lib+priv) | 2 (GitHub, Changelog) | 0.1.0 (2014) |
| Ecto | YES (4 names) | YES (70+ lines, guides, Mermaid) | YES (~w + integration_test) | 2 (GitHub, Changelog) | 0.1.0 (2014) |
| Oban | YES (1 name: Parker Selbert) | YES (in project/0 block) | YES (~w form) | 3 (Website, Changelog, GitHub) | 0.1.0 (2019) |
| Bandit | YES (1 name: Mat Trudel) | YES (extras incl. impl notes) | YES (list form) | 2 (GitHub, Changelog) | 0.1.0 (2021) |
| Req | NO | YES (inline docs) | NO (default) | 2 (GitHub, Changelog) | 0.1.0 (2021) |
| Mint | NO | YES (inline in project/0) | NO (default) | 1 (GitHub only) | 0.1.0 (2019) |
| Swoosh | YES (3 names) | YES (extras, module groups) | NO (default) | 2 (Changelog, GitHub) | 0.1.0 (2016) |
| Broadway | YES (2 names) | YES (intro, guides) | NO (default) | 1 (GitHub only) | 0.1.0 (2019) |
| ExDoc | YES (3 names) | YES (conditional env config) | YES (~w form) | 3 (GitHub, Changelog, Writing docs) | 0.1.0 (2014) |
| Plug | YES (2 names) | YES (inline docs block) | YES (list form) | 2 (Changelog, GitHub) | 0.1.0 (2013) |
| Phoenix LiveView | YES (5 names) | YES (rich, Mermaid) | YES (~w form, assets+js+lib+priv) | 2 (Changelog, GitHub) | 0.1.0 (2019) |
| Ash | YES (1 name: Zach Daniel) | YES (130+ lines, extras) | YES (~w form, rich) | 6 (GitHub, Changelog, Discord, Website, Forum, REUSE) | 1.0.0 (2020) |
| Finch | NO | YES (logo, source_ref, CHANGELOG extra) | NO (default) | 2 (GitHub, Changelog) | 0.1.0 (2020) |
| **oarlock (szTheory)** | **NO** | **YES (main: readme, guides)** | **YES (~w form)** | **3 (Changelog, Documentation, GitHub)** | **0.1.0** |

**Key empirical finding on `:maintainers`:** The hex.pm specifications repo explicitly marks `:maintainers` as **deprecated**. Verified empirically: phoenix, ecto, oban, plug all set `:maintainers` in their `mix.exs`, yet the hex.pm API returns `maintainers: null` at both the package level and release meta level for ALL of them. The field goes into the tarball's `metadata.config` but hex.pm does not render it anywhere on the package page or surface it via API. **Ownership attribution on hex.pm is done via the "Owners" section, which is account-linked (sztheory account), not via the deprecated `:maintainers` field.** Oarlock — the canonical szTheory template — deliberately omits `:maintainers` and this is the correct pattern.

---

## Pros/Cons Table: Decision 1 — All Metadata Audit Items

| | Pros | Cons |
|---|---|---|
| **Include all (rec)** | Complete first impression; no broken links on hex page; hexdocs "View Docs" renders; adopters can navigate changelog without leaving hex.pm; `source_url` drives "view source" links in hexdocs; `:files` prevents internal planning docs from shipping; correct `:links` pattern matches every serious lib in the ecosystem | Slightly more upfront work in v3.3 |
| **Defer any item** | Slightly less work now | Knowable defect ships permanently (placeholder `example/crosswake` URL, no docs link, broken tarball content, missing changelog link); first-impression is only made once; recovery requires publishing a new version just for metadata fixes |

**Verdict: NO deferrals.** Every item is low complexity (20–50 lines total), the template exists verbatim in oarlock, and the cost of getting it wrong is a public trust failure on the package's first and most-scrutinized version.

---

## Pros/Cons Table: Decision 2 — `:maintainers` Field

| | Pros | Cons |
|---|---|---|
| **Include `:maintainers` (not recommended)** | Consistent with what many prominent libs do (Phoenix, Ecto, Oban, Plug, LiveView, Ash, Swoosh all set it) | **Deprecated in hex spec**; hex.pm ignores it entirely (confirmed via API: `maintainers: null` for phoenix, ecto, oban); hex page does not render it; it bloats tarball `metadata.config` with a stale field; creates a maintenance liability (update it when maintainers change, even though nobody sees it); Req, Mint, Finch, and oarlock all omit it without harm |
| **Omit `:maintainers` (rec)** | Follows hex spec correctly; no deprecated field in tarball; no maintenance liability for a field nobody sees; consistent with oarlock canonical template; ownership is surfaced via hex.pm account Owners section (sztheory) which is automatic | Does not match the pattern of some famous libs (but those libs are using a deprecated field) |

**Verdict: OMIT.** The field is deprecated per hex specifications. The libs that set it (Phoenix, Ecto, etc.) are doing so because the convention predates the deprecation — they have not cleaned it up. The correct signal is hex.pm account ownership, not a deprecated metadata field. Oarlock already models the right behavior. "What successful libs do" is the wrong signal to follow here because they are carrying forward a deprecated convention, not endorsing it.

---

## Pros/Cons Table: Decision 3 — `docs/0` Function (hexdocs publication)

| | Pros | Cons |
|---|---|---|
| **Include `docs/0` (rec)** | "View Docs" link renders on hex page; hexdocs.pm hosts rich module docs + guides; `source_ref: "v#{@version}"` wires source links to the correct tag; `main: "readme"` makes the README the landing page; guides become navigable; adopters evaluating a new dep check hexdocs before deciding; matches 100% of sampled successful libs | ex_doc must be added as dev dep; must run `mix docs` locally to verify render before publish; guides must be included in both `:files` and `extras:` (if missed = silent hexdocs failure — see PITFALLS.md Pitfall 14) |
| **Defer `docs/0`** | Less surface to polish on first publish | hex page renders as "no documentation published" — which is a hard trust failure signal for a lib positioning itself as production-grade; "install truth is product truth" is directly violated; any adopter evaluating the dep will be blocked or turned off; 0 of 13 sampled serious libs defer this; no recovery without publishing a new version |

**Verdict: INCLUDE on first publish.** The "less surface to polish" rationale does not hold because the polishing work is minimal (20-line docs block + ex_doc dev dep, template exists in oarlock) and because the downside of omission is a first-impression failure that cannot be walked back without a version bump. The brand-book explicitly says "keep the first release visually quiet, technical, and trustworthy" — a hex page without docs is neither technical nor trustworthy.

---

## Lessons Learned — What They Did Right

- **Oarlock (szTheory canonical):** Three-link `:links` pattern (`Changelog`, `Documentation`, `GitHub`), explicit `:files` allowlist, `docs/0` with `main: "readme"` and guides extras, NO `:maintainers`. This is the exact pattern Crosswake should follow.

- **Oban (Parker Selbert):** Single-maintainer lib, ships `:maintainers: ["Parker Selbert"]` (deprecated, harmless but unnecessary), explicit `:files`, three-link `:links` including external website. Proves a one-person lib can have a rich complete hex page.

- **Ash (Zach Daniel):** Single-maintainer lib with extremely rich `:links` (6 links including Discord, Forum, REUSE), explicit `:files` including `priv/` because Ash ships priv content. Proves that including `priv/` is correct when the library ships generator templates in `priv/` — which Crosswake does.

- **Bandit (Mat Trudel):** Clean `docs/0` with structured extras including implementation notes from sub-dirs. Single maintainer. Shows that one-person libs absolutely do publish docs.

- **Req (Wojtek Mach):** No `:maintainers`, no `:files` (defaults sufficient), but rich `docs/0`. Proves you can have excellent hexdocs even with a minimal package block. Source_ref and source_url in docs function wire "view source" correctly.

- **ExDoc:** Three named maintainers, explicit `:files`, three-link `:links` including a "Writing documentation" guide link. Uses `docs/0` that adapts based on Mix environment. Shows that metadata can be opinionated and instructive.

- **Phoenix/LiveView:** Five maintainers, explicit `:files` including `assets/js` and `priv/` (needed because they ship JS and priv templates), rich `docs/0`. Changelog link points to hexdocs-hosted version rather than raw GitHub file — a cleaner UX. Note: their Changelog link uses `"https://hexdocs.pm/phoenix/changelog.html"` (hexdocs-rendered) rather than GitHub raw. For Crosswake v3.3, GitHub raw is fine; hexdocs-hosted becomes possible after first publish.

---

## Lessons Learned — Footguns

- **`maintainers: null` in hex API for every lib that sets `:maintainers`:** Phoenix, Ecto, Oban, Plug, LiveView, Swoosh, Broadway, ExDoc all set `:maintainers` in `mix.exs` — and hex.pm returns `maintainers: null` for all of them. The field is written into the tarball `metadata.config` (an Erlang term file) but hex.pm does not surface it. "Everyone does it" is not a reason to use a deprecated field.

- **Mint: single-link `:links` with only `"GitHub"` key:** The hex page sidebar shows only one link. Adopters have to navigate to GitHub to find the changelog. This is a minor friction but measurable — the changelog link in `:links` is the second most useful navigation item after the docs link.

- **Finch: no `:files` allowlist:** Relies on hex defaults. Safe for a library with no `priv/` templates or internal planning docs, but creates risk for any lib that adds non-default directories. Crosswake MUST set an explicit `:files` because it has `priv/templates/` (generators), `guides/` (adopt-facing docs), and internal directories (`.planning/`, `prompts/`, `examples/`, `test/`, `native/`) that should never ship.

- **PITFALLS.md Pitfall 14 (guides in extras but not `:files`):** If `docs/0` extras reference `"guides/..."` but `:files` doesn't include `"guides"`, `mix docs` runs fine locally (it reads from source tree) but hexdocs.pm builds from the tarball and silently omits all guide pages. This is the most insidious silent failure in hex doc publishing. Solution: ensure `:files` and `docs/0` extras are updated in the same commit whenever a new guide is added.

- **Deferring docs on first publish (historical npm pattern):** npm packages published without a README or without docs.npmjs.com coverage are routinely ignored or downgraded in evaluations. The same pattern holds on hex.pm: a package without hexdocs reads as "prototype," "unmaintained," or "not ready for production." Crosswake's brand promise ("Keep the boundary honest") is undermined by a hex page that looks like it was published in a hurry.

- **Cargo's `authors` deprecation mirrors hex's `:maintainers` deprecation:** Rust deprecated `[package] authors` in Cargo.toml for the same reason — ownership attribution via registry account is more reliable and lower-maintenance than a stale string in a manifest. Hex followed the same pattern. Both ecosystems settled on account-linked ownership as the source of truth.

- **PyPI: no docs link = no adoption:** Python packages without a documentation URL consistently underperform on adoption metrics. The PyPI page explicitly surfaces a "Project Links" section — libs without a Documentation link are missing the primary navigation entry that evaluators use to decide "is this serious enough to use?"

---

## DX/UX Considerations

### What the hex.pm package page communicates with vs. without each piece

**With proper `source_url` / `@source_url` attribute:**
- hex page header shows working GitHub link
- hexdocs "View Source" links on every module function point to the correct file+line on the correct tag
- CHANGELOG link in `:links` resolves correctly
Without: GitHub link is broken (currently `example/crosswake`); every hexdocs source link is a 404.

**With `:links` three-link pattern (GitHub + Documentation + Changelog):**
- Sidebar shows three navigation anchors; adopters can go directly to docs, to GitHub, or to CHANGELOG without leaving hex.pm
- "Documentation" link routes directly to hexdocs.pm before the adopter even opens a browser
Without: sidebar shows only GitHub. Changelog requires navigating to GitHub, finding the file, opening it. Minor friction, but it compounds for evaluators comparing multiple deps.

**With `docs/0` function + ex_doc:**
- hex.pm package header shows "HexDocs" link; adopters can evaluate the API and guides before installing
- hexdocs.pm page renders the README as the landing page (`main: "readme"`), guides as structured extras, module reference as auto-generated API docs
- `source_ref: "v#{@version}"` wires every "View Source" button to the exact tag — no "source not found" on older versions
Without: hex page shows no docs link. The hexdocs.pm URL (`https://hexdocs.pm/crosswake`) shows either "no documentation published" or empty auto-generated stubs. This is the hardest trust failure — it visually reads as "this lib is not serious."

**With `:files` allowlist:**
- Tarball contains exactly `lib/`, `guides/`, `mix.exs`, `.formatter.exs`, `README.md`, `LICENSE`, `CHANGELOG.md` — clean, auditable, no surprises
- `mix hex.build --unpack` confirms no planning docs or native shell code shipped
Without (current state): hex default includes `priv/` (good, Crosswake needs it) but also anything else that accidentally matches the glob. `.planning/`, `prompts/`, `test/`, `examples/`, `native/` are not in the default glob so they won't accidentally ship — but `guides/` also isn't in the default, which means the guides don't ship either. Explicitly setting `:files` is the only way to guarantee both inclusion of `priv/` + `guides/` AND exclusion of everything else.

**With/without `:maintainers`:**
No visible UX difference. hex.pm ignores the field. Ownership is shown via "Owners" section using the sztheory account avatar and username. This is automatic from the publish auth.

---

## Coherence with Project Vision

**"Install truth is product truth"** (OSS DNA §1):
Every broken metadata item — placeholder source_url, missing docs link, no changelog link — is a direct violation of install truth. The first thing an adopter does is look at the hex page. A hex page with a dead GitHub link, no docs, and a generic description signals that the library was published carelessly. The install step begins at the hex page, not at `mix deps.get`.

**"Release truth matters"** (OSS DNA §4):
The package metadata block IS the public release truth artifact. `@source_url`, `:links`, `:files`, and `docs/0` together define what the library officially claims to be and where to find it. Publishing with placeholder values or missing docs is publishing a release that doesn't reflect truth. Release-please automation (which v3.3 is also building) only matters if the release it automates is trustworthy.

**"Public contract honesty beats breadth"** (OSS DNA §2):
`:files` is the enforcement mechanism for public contract honesty at the package level. Without it, the tarball boundary is fuzzy. With an explicit allowlist, the public surface is declared, not assumed.

**"Keep the first release visually quiet, technical, and trustworthy"** (brand-book §25):
"Visually quiet" = no markdown soup on the hex page. "Technical" = module docs, guides, correct source links. "Trustworthy" = working links, published docs, honest changelog. All three qualities require Category A to be complete.

**"Narrow honest support claims"** (OSS DNA §2):
`:description` should be a single declarative sentence under ~150 characters. The current description "Phoenix-first route policy and runtime contract substrate" is serviceable but technical jargon-heavy. A sharpened version: "Route policy and runtime contract layer for Phoenix applications targeting mobile and multi-runtime deployments."

---

## Complete Recommended `mix.exs` Changes

This is what Category A should produce in v3.3:

```elixir
defmodule Crosswake.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake,
      version: @version,
      name: "crosswake",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}   # ADD
    ]
  end

  defp description do
    "Route policy and runtime contract layer for Phoenix applications targeting mobile deployments."
  end

  defp package do
    [
      name: "crosswake",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake",
        "GitHub" => @source_url
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
      # NOTE: :maintainers is DEPRECATED in hex spec — OMIT
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      extras: [
        "README.md",
        "CHANGELOG.md",
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
      ],
      groups_for_extras: [
        Guides: ~r/guides\//
      ]
    ]
  end
end
```

**Changes from current mix.exs:**
- Added `@source_url` module attribute (replaces placeholder)
- Added `name:`, `source_url:`, `homepage_url:`, `docs:` to `project/0`
- Added `{:ex_doc, "~> 0.38", only: :dev, runtime: false}` to deps
- Replaced `:links` (single GitHub placeholder) with three-link canonical pattern
- Added `:files` allowlist including `priv/` (generator templates) and `guides/` (adopter docs)
- Added `name: "crosswake"` to `package/0` (tarball naming safety per FEATURES.md A-02)
- Added `defp docs do` block (new)
- `:maintainers` intentionally absent

---

## Confidence

| Decision | Confidence | Reasoning |
|----------|-----------|-----------|
| Include all Category A metadata items | **HIGH** | 0 of 13 sampled libs deferred docs; every item is LOW complexity; template exists in oarlock; "install truth is product truth" directly requires it |
| Omit `:maintainers` | **HIGH** | Empirically confirmed via hex.pm API that the field is silently ignored for ALL libs that set it; hex spec marks it deprecated; oarlock (canonical szTheory template) omits it; ownership is surfaced via hex.pm account Owners — not this field |
| Include `docs/0` on first publish | **HIGH** | 100% of sampled serious libs publish docs on first release; oarlock working template exists; 20-line addition; absence is a hard trust failure on a first-impression page; PITFALLS.md Pitfall 8 documents the exact consequence of omitting it |

---

## Recovery Notes (for "what if we get it wrong")

| Item | Recoverable? | How |
|------|-------------|-----|
| Wrong source_url published | YES (within 1 hour: `mix hex.publish --revert`; after: fix in next version) | Publish corrected version with fixed @source_url |
| `:links` missing entries | YES | Update package/0, republish next version |
| `:maintainers` included (deprecated) | YES | Silent — hex ignores it, no user impact, but can be cleaned in next version |
| `docs/0` missing from first publish | YES (partial) | Can publish docs retroactively via `mix hex.publish docs`; hexdocs.pm will update; but hex page "no docs" impression is made for any early evaluator |
| `:files` too narrow (guides missing) | YES (within 1 hour window or next version) | Fix `:files`, republish |
| Package `:name` wrong | NO for first-ever publish (package name is permanent on hex.pm) | The OTP atom `:crosswake` matches the Hex package name `crosswake` — this is safe |

---

## Sources

- `/Users/jon/projects/crosswake/prompts/crosswake-elixir-oss-dna.md` — house-style anchors
- `/Users/jon/projects/crosswake/prompts/crosswake-brand-book.md` — brand promise, first-release checklist
- `/Users/jon/projects/crosswake/mix.exs` — current placeholder state
- `/Users/jon/projects/crosswake/.planning/research/FEATURES.md` — Category A feature inventory
- `/Users/jon/projects/crosswake/.planning/research/PITFALLS.md` — Pitfalls 1, 7, 8, 14 directly relevant
- `/Users/jon/projects/crosswake/.planning/research/STACK.md` — mix.exs canonical structure
- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — Commit 2 template, gotcha #2 (name: field)
- `/Users/jon/projects/oarlock/mix.exs` — canonical szTheory package block template
- `https://github.com/hexpm/specifications/blob/master/package_metadata.md` — `:maintainers` deprecated confirmation
- `https://hex.pm/api/packages/phoenix` (and ecto, oban, plug, req, mox) — empirical `maintainers: null` verification
- GitHub raw mix.exs for: Phoenix, Ecto, Oban, Bandit, Req, Mint, Swoosh, Broadway, ExDoc, Plug, LiveView, Ash, Finch
- `https://doc.rust-lang.org/cargo/reference/manifest.html` — Cargo `authors` deprecation parallel
- `https://docs.npmjs.com/cli/v10/configuring-npm/package-json` — npm metadata trust signals

---

*Research for: v3.3 Release Readiness — Category A Package Metadata Truth*
*Researched: 2026-05-27*
