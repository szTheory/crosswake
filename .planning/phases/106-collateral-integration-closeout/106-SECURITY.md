---
phase: 106
slug: collateral-integration-closeout
status: secured
threats_open: 0
asvs_level: 1
created: 2026-06-13
---

# Phase 106 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Covers plans 01 + 02 **and** the COLL-05 increment (automated brand-verification
> suite + hybrid CI gate added in PR #13).

**Audited:** 2026-06-13 · **ASVS Level:** 1 · **Threats:** 8 closed / 0 open

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| local rasterizer (Playwright/Chromium) → committed PNG | Headless browser renders local `file://` SVGs; output bytes committed | image bytes (public) |
| brandbook tools → existing node_modules | export-raster / render-verify reuse Playwright from `examples/phoenix_host` | none (local) |
| repo edit → hex package contents | `mix.exs` `:files`/`:exclude_patterns` control what ships to hex.pm | source files (public) |
| GitHub CI runner → repo | `brandbook-verify.yml` runs on PR/push; read-only | none |
| README raw URLs → GitHub/hexdocs renderers | absolute `raw.githubusercontent.com` URLs fetched by remote renderers | public assets |
| brand e2e static server → localhost | `static-server.mjs` serves `brandbook/` on an ephemeral localhost port (test/CI only) | public brand assets |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-106-01 | Tampering | SVG sources with `<script>`/external `href` rendered by Chromium | mitigate | Path-only, literal-hex, self-contained SVGs; grep gate rejects `href=http`/`<style`/`@media`/`<script`; local `file://` render only. Re-asserted every CI run by `static.spec.ts:75-88`. | closed |
| T-106-02 | Information Disclosure | `export-raster.mjs` loading remote resources during render | accept | Inputs are local self-contained SVGs, no external refs, no secrets/network in scope. | closed |
| T-106-03 | Tampering | `mix.exs` edit breaking the hex package | mitigate | `:files` allowlist (no `brandbook`) + `exclude_patterns: ["brandbook"]`; tarball brandbook count = 0. Re-asserted by `static.spec.ts:53-60`. | closed |
| T-106-04 | Elevation of Privilege | `brandbook-verify.yml` gaining write/merge-gate power | mitigate (premise changed) | Workflow retains `permissions: contents: read`, no `secrets.*`, no job override. Required-gate promotion is an external branch-protection decision documented in REQUIREMENTS.md — not a workflow self-grant. `brand-visual` stays `continue-on-error`. | closed |
| T-106-05 | Tampering | unpinned third-party GitHub Actions | mitigate | `actions/checkout` + `actions/setup-node` SHA-pinned in both jobs; no floating tags. | closed |
| T-106-SC | Supply chain | `@playwright/test` devDependency added in `brandbook/e2e` | mitigate (premise changed) | Same version (1.60.0) + identical SHA512 integrity as existing vetted `examples/phoenix_host` usage; lockfile-pinned (`npm ci`); all entries `dev: true`; hex-excluded. | closed |
| NEW-static-server | Path Traversal | `static-server.mjs` serving `brandbook/` over localhost | accept | `normalize(join(ROOT, urlPath))` + `startsWith(ROOT)` confinement (`static-server.mjs:31-36`); traversal attempts return 403. Ephemeral localhost test/CI only, never shipped, no secrets in scope. | closed |
| NEW-readme-urls | Information Disclosure | `check-readme-urls.mjs` network fetch to `raw.githubusercontent.com` | accept | Read-only fetch of public assets; advisory job (`continue-on-error`); `push`-to-`main` only; no auth/secrets/write path. | closed |

*Status: open · closed* — *Disposition: mitigate · accept · transfer*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-106-1 | T-106-02 | `export-raster.mjs` renders local self-contained `file://` SVGs; no external refs, no secrets, no network targets. Negligible. | szTheory | 2026-06-13 |
| AR-106-2 | NEW-static-server | Path-traversal confinement present and verified correct; server ephemeral localhost-only, never shipped. Negligible. | szTheory | 2026-06-13 |
| AR-106-3 | NEW-readme-urls | Read-only fetch of public assets; advisory-only on `main`; no auth/secrets/user data; no write path. Negligible. | szTheory | 2026-06-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Audit Trail

### Security Audit 2026-06-13 (gsd-security-auditor, sonnet)

| Metric | Count |
|--------|-------|
| Threats found | 8 |
| Closed | 8 |
| Open | 0 |

Verdict: **SECURED**. Register authored at plan time (both plans carry `<threat_model>`).
Re-verified against current code because the COLL-05 increment changed two premises:

- **T-106-04** — promotion of `brand-structural` to a required gate is a deliberate, documented branch-protection decision; the workflow itself holds only `contents: read` (no self-escalation).
- **T-106-SC** — `@playwright/test` is a real new devDependency but resolves to the same vetted version + integrity hash already in the repo, lockfile-pinned, dev-only, hex-excluded.

Two new surfaces (`static-server.mjs`, `check-readme-urls.mjs`) assessed and accepted with evidence. No implementation gaps found.
