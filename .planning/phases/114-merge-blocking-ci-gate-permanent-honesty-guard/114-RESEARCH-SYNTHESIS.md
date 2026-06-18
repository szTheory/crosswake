# Phase 114 — Research Synthesis (decision rationale + concrete artifacts)

**Compiled:** 2026-06-18 from four parallel `gsd-advisor-researcher` deliverables
(advisory-lane mechanism, required-check topology, GUARD-02 prod-absence idiom,
workflow-file rename) plus the earlier requirement-level research (GATE-01 / GUARD-01 /
GUARD-02). This is the implementation-ready backing for `114-CONTEXT.md`'s D-01…D-10.
The planner should lift the sketches below; they are validated against the live repo.

> Ground truth (verified, not assumed): `main` runs **classic** branch protection
> (rulesets array empty), `strict: true`, `enforce_admins: true`, required checks
> `merge-blocking rulestead proof (hermetic)` + `brand-structural`, both `app_id: 15368`
> (GitHub Actions). Neither E2E job name is currently required → no stale-check deadlock
> today, but the registration must still GET-then-replace.

---

## 1. Required-check topology — Option C (aggregator) [D-01]

Three sibling jobs for signal + one aggregator that is the **only** required check.

```yaml
name: Offline-Sync E2E Gate
# Renamed from phase90-proof.yml (2026-06). Permanent merge gate — purpose-named, not phase-scoped.
on: [pull_request, push]
permissions: { contents: read }

jobs:
  guard-01-e2e-honesty:                 # ~2s, no browser, no Elixir
    name: guard-01-e2e-honesty
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: node script/check-e2e-honesty.mjs
      - run: echo "GUARD-01 e2e-honesty: structural check passed" >> "$GITHUB_STEP_SUMMARY"

  guard-02-prod-route-absence:          # MIX_ENV=prod — ISOLATED runner
    name: guard-02-prod-route-absence
    runs-on: ubuntu-latest
    env: { MIX_ENV: prod }
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0 (pin as existing)
        with: { version-file: .tool-versions, version-type: strict }
      - uses: actions/cache@v4
        with: { path: examples/phoenix_host/_build/prod, key: build-prod-${{ hashFiles('examples/phoenix_host/mix.lock') }} }
      - name: Assert NO /_e2e route in a prod compile
        working-directory: examples/phoenix_host
        run: |
          set -euo pipefail
          rm -rf _build/prod                 # never inspect a :test-compiled router beam
          mix deps.get --only prod
          ROUTES="$(mix phx.routes CrosswakeExample.Router)"
          echo "$ROUTES"
          if echo "$ROUTES" | grep -qE '/_e2e(/|$)'; then
            echo "::error::GUARD-02 FAILED — /_e2e route present in a MIX_ENV=prod compile."
            echo "Gate test-only routes with 'if Mix.env() in [:test, :e2e]' so they compile OUT of prod."
            echo "$ROUTES" | grep -E '/_e2e(/|$)'
            exit 1
          fi
          echo "GUARD-02 OK — no /_e2e routes in prod." >> "$GITHUB_STEP_SUMMARY"

  e2e-proof:                            # MIX_ENV=test — ISOLATED runner
    name: e2e-proof
    runs-on: ubuntu-latest
    env: { MIX_ENV: test }
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93
        with: { version-file: .tool-versions, version-type: strict }
      - uses: actions/cache@v4
        with: { path: examples/phoenix_host/_build/test, key: build-test-${{ hashFiles('examples/phoenix_host/mix.lock') }} }
      - name: Mix deps + compile (warnings as errors)
        working-directory: examples/phoenix_host
        run: { mix deps.get && mix compile --warnings-as-errors }   # (split into two run: lines in real YAML)
      - name: Phoenix route + controller assertions (GUARD-02 in-suite half)
        working-directory: examples/phoenix_host
        run: mix test test/crosswake_example/router_test.exs test/crosswake_example/e2e/sync_state_controller_test.exs
      - run: npm ci
        working-directory: examples/phoenix_host
      - run: npx playwright install --with-deps
        working-directory: examples/phoenix_host
      - run: npx playwright test
        working-directory: examples/phoenix_host
      - run: echo "E2E: offline-sync IndexedDB-outbox → reconnect-flush → one Ecto row proven" >> "$GITHUB_STEP_SUMMARY"

  merge-blocking-offline-sync-e2e:      # THE ONLY required check (GATE-01 name)
    name: merge-blocking-offline-sync-e2e
    if: always()
    needs: [guard-01-e2e-honesty, guard-02-prod-route-absence, e2e-proof]
    runs-on: ubuntu-latest
    steps:
      - name: Roll up guard results
        uses: re-actors/alls-green@release/v1
        with:
          jobs: ${{ toJSON(needs) }}
```

**Why C over A/B:** one immutable string in branch protection (rename sub-jobs freely);
per-guard red/green dots; parallel runners isolate `MIX_ENV=test` vs `MIX_ENV=prod`
(Mix writes `_build/<env>/` but a *shared cache key* would cross-contaminate — env-scoped
keys above close it). `alls-green` correctly fails on a skipped/failed voting job (a plain
`needs:` + path-filter would let a skipped required job report success → silent pass).

---

## 2. Advisory-lane pattern — honest-red, never continue-on-error [D-02/D-03]

`continue-on-error: true` makes a failed job resolve as **success** (counts as pass for
required checks and downstream `needs:` — dangerous on a lockstep-publishing lib), so it
can never be promoted to a real gate. Oban (`fail-fast: false` + `if: matrix.lint`, no
continue-on-error), Phoenix, Ecto all avoid it for advisory signal. Mirror the repo's own
D-06 (`phase96-proof-advisory.yml`).

```yaml
jobs:
  advisory-<name>:                      # NOT in branch-protection checks[] => non-blocking
    name: advisory-<name>
    runs-on: ubuntu-latest
    # NO continue-on-error: a failure is an honest red X, just not a merge gate.
    steps:
      - if: always()
        run: echo "::notice title=Advisory lane::Non-blocking (omitted from required checks[]). Honest red, never a soft-passed green."
      - run: <the advisory proof>        # allowed to fail RED
      - if: always()
        run: |
          { echo "## Advisory lane — promotion path";
            echo "Promote: sustained green here, then add \`advisory-<name>\` to branch-protection checks[] via the gh api PATCH in this workflow's header comment."; } >> "$GITHUB_STEP_SUMMARY"
```
For lanes that shouldn't run per-PR at all, trigger-scope to `on: {schedule, workflow_dispatch}` (the existing `phase96-proof-advisory.yml` shape).

### REQUIREMENTS.md GATE-01 wording amendment (D-03)
Replace (REQUIREMENTS.md line 27 final sentence; mirror ROADMAP.md ~line 116):
> "Every non-required CI lane keeps `continue-on-error: true` and a `::notice` marking its advisory status."

With:
> "Every non-required CI lane is non-blocking by **omission from the branch-protection `checks[]` array** (and, where it should not run per-PR, by trigger-scoping to `schedule`/`workflow_dispatch`) — **never** via `continue-on-error: true`, which would paint a failed lane green and make it permanently unpromotable (D-06). Each advisory lane carries an `advisory-`-prefixed job `name:`, a `::notice` annotation, and a `$GITHUB_STEP_SUMMARY` promotion-path note; failures surface as honest red."

Also correct `.planning/research/PITFALLS.md` (~lines 117/284/306/322/337) which currently prescribe `continue-on-error`.

---

## 3. GUARD-01 honesty check — zero-new-dep TS AST [D-04/D-05]

`script/check-e2e-honesty.mjs` (run via Node ESM; `typescript` resolves via `@playwright/test` — pin it explicitly in `examples/phoenix_host/package.json` devDependencies).

```js
import ts from 'typescript';
import { readFileSync, existsSync } from 'node:fs';

const FILE = 'examples/phoenix_host/e2e/offline_sync.spec.ts';
if (!existsSync(FILE)) { console.error(`✖ ${FILE} missing — honesty guard cannot run.`); process.exit(1); }
const src = readFileSync(FILE, 'utf8');
const sf = ts.createSourceFile(FILE, src, ts.ScriptTarget.Latest, true);
const V = [];
const at = n => sf.getLineAndCharacterOfPosition(n.getStart(sf)).line + 1;

const isEvaluate = n => ts.isCallExpression(n) && ts.isPropertyAccessExpression(n.expression) && n.expression.name.text === 'evaluate';
const isNetwork = n => {
  if (!ts.isCallExpression(n)) return false;
  const c = n.expression;
  if (ts.isIdentifier(c)) return c.text === 'fetch' || c.text === 'XMLHttpRequest';
  if (ts.isPropertyAccessExpression(c)) return c.name.text === 'fetch' || c.name.text === 'sendBeacon';
  return false;
};

(function walk(node) {
  if (ts.isStringLiteral(node) && /crosswake_offline_mutations/.test(node.text))
    V.push([at(node), 'inject-global', "Forbidden global 'crosswake_offline_mutations' — the fake injected fabricated mutations here."]);
  if (ts.isPropertyAccessExpression(node) && node.name.text === 'randomUUID')
    V.push([at(node), 'minted-uuid', "crypto.randomUUID in spec — the honest test READS client_mutation_id from IndexedDB, never mints it."]);
  if (isEvaluate(node) && node.arguments[0])
    (function scan(inner) {
      if (isNetwork(inner)) V.push([at(inner), 'fetch-in-evaluate', "fetch()/XHR inside page.evaluate — app code must flush the outbox on reconnect, not the test."]);
      ts.forEachChild(inner, scan);
    })(node.arguments[0]);   // IndexedDB reads + window.dispatchEvent in the same callback are intentionally NOT flagged
  ts.forEachChild(node, walk);
})(sf);

if (V.length) {
  console.error(`\n  ✖ E2E honesty check FAILED — ${FILE} regressed toward fabrication.\n`);
  for (const [ln, rule, msg] of V) console.error(`  [${rule}] line ${ln}\n      ${msg}\n`);
  console.error('  The offline-sync E2E must prove the REAL path (UI click → IndexedDB outbox →');
  console.error('  app-driven reconnect flush → Ecto confirms one row), not fabricate it.');
  console.error('  See REQUIREMENTS.md GUARD-01 and the phase 112–113 honest rewrite.\n');
  process.exit(1);
}
console.log('  ✓ E2E honesty check passed — offline-sync spec exercises the real path.');
```

Necessary-not-sufficient: the spec's own exactly-one-row / duplicate-idempotency
assertions are the behavioral backstop against a renamed-symbol evasion.

---

## 4. GATE-01 registration — GET-then-replace + green-first preflight [D-06]

`script/register-e2e-gate.sh` (run out-of-band by the maintainer; branch-protection
writes are harness-blocked). Mirror the one-liner as a comment block in the workflow.

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO="${REPO:-szTheory/crosswake}"; BRANCH="${BRANCH:-main}"
NEW_CHECK="merge-blocking-offline-sync-e2e"; ACTIONS_APP_ID="${ACTIONS_APP_ID:-15368}"
OLD_CHECK="${OLD_CHECK:-e2e-offline-sync}"; DRY_RUN="${DRY_RUN:-0}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"

current="$(gh api "${EP}")"
desired="$(jq -n --argjson cur "$current" --arg new "$NEW_CHECK" --arg old "$OLD_CHECK" --argjson app "$ACTIONS_APP_ID" '
  { strict: $cur.strict,
    checks: (($cur.checks // []) | map(select(.context != $old)) + [{context:$new, app_id:$app}] | unique_by(.context)) }')"
echo "$desired" | jq .
[ "$DRY_RUN" = "1" ] && { echo "DRY_RUN — not writing."; exit 0; }

# Preflight: refuse until the new check has gone green on BRANCH (avoids "Expected — Waiting for status" deadlock).
gh api "repos/${REPO}/commits/${BRANCH}/check-runs" \
  | jq -e --arg n "$NEW_CHECK" '.check_runs | any(.name==$n and .conclusion=="success")' >/dev/null \
  || { echo "REFUSING: '${NEW_CHECK}' has no successful run on ${BRANCH} yet. Merge the rename, let it go green, then re-run."; exit 2; }

gh api -X PATCH "${EP}" --input <(echo "$desired")
gh api "${EP}" | jq '{strict, checks}'
```
**Ordering:** merge the rename → green on `main` → run this script. Preserves the two
existing required checks + `strict`; granular endpoint leaves `enforce_admins`/reviews
untouched (beats full `PUT .../protection`).

---

## 5. GUARD-02 in-suite assertions [D-08]

`examples/phoenix_host/test/crosswake_example/router_test.exs` (plain `ExUnit.Case`, no `~p`):
```elixir
defmodule CrosswakeExample.RouterTest do
  use ExUnit.Case, async: true
  @path "/_e2e/sync-state/:client_mutation_id"
  test "E2E sync-state route present in :test, wired to scoping controller" do
    route = CrosswakeExample.Router |> Phoenix.Router.routes() |> Enum.find(&(&1.path == @path))
    assert route, "expected #{@path} compiled in :test"
    assert route.verb == :get
    assert route.plug == CrosswakeExample.E2E.SyncStateController
    assert route.plug_opts == :show
  end
end
```
Controller scoping test — insert ≥2 rows with distinct `client_mutation_id`, assert
`count == 1` for one id (guards the bare-`Repo.aggregate(:count)` whole-table footgun).
Planner picks lowest-footprint case (no `DataCase`/`ConnCase` exists yet).

---

## 6. File rename [D-10]
`git mv .github/workflows/phase90-proof.yml .github/workflows/offline-sync-e2e-gate.yml`.
Required-check string is **job-name-keyed**, not path-keyed → rename is safe. Keep a stable
top-level `name: Offline-Sync E2E Gate` + archaeology comment. Update the ~13 `.planning/*.md`
references to `phase90-proof` in the same commit. (Required-*workflows* rulesets ARE
path-keyed — noted as a future-migration footgun, not in use today.)

---

## Sources (selected)
- GitHub Docs — About status checks / Troubleshooting required status checks (soft-fail resolves as success; rename deadlock).
- GitHub Docs — Workflow commands (`::notice`, `$GITHUB_STEP_SUMMARY`); REST branch-protection & rulesets.
- `re-actors/alls-green`; community discussions #15452, #45546, #9141, #26822 (continue-on-error + matrix/skip semantics).
- Oban / Phoenix / Ecto `ci.yml` (advisory patterns; matrix-name drift).
- elixirforum "conditionally compiled routes with verified routes" (José Valim: `Mix.env()` in router OK at compile time; avoid `~p` for env-gated routes).
- hexdocs: `Mix.Tasks.Phx.Routes`, `Phoenix.Router`, LiveDashboard `:dev_routes`.
</content>
