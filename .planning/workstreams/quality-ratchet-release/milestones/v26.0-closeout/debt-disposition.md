# v26.0 debt disposition

Accepted at closeout on 2026-10-16. None of these items is a broken requirement. Each one names when it should be handled. The full per-phase list is in the [audit](../v26.0-MILESTONE-AUDIT.md) `tech_debt` frontmatter and each phase's REVIEW-DISPOSITION.

## Can pass while checking nothing, or degrade silently: handle before the next twin run or twin-touching change

| Item | Source | Disposition |
|---|---|---|
| The privacy scan reports `files 0, hits 0` and exits 0 on an empty scope. | 188 WR-01 | Count the expanded regular files and exit 2 on zero. Not triggered: every real scan in 188 had a non-empty scope. |
| Several gate labels never fail in the selftests (`port_4790_free`, `head_equals_record`, `tree_equals_record` and others). | 188 WR-08 | Add one negative control per label before the gate is reused. |
| The run gate's shell git helper `g()` does not pin global config the way the shared Elixir funnel does. | integration check | Pin it the same way. The Elixir probe still gated twin-05. |
| A 5-second `Agent.get` timeout reads as `:registry_gone`, so `stop_all` can stop a live registry and lose its child list. | 185 WR-02 | Fix in the next twin-touching change. Reopen trigger (leftover Simulators) did not fire after twin-05. |
| `Provenance.commit_ref` scrubs only three `GIT_*` variables and can report an enclosing repo's HEAD for a nested host without its own `.git`. | 187 WR-02 | Fix before provenance from a nested host is relied on. |
| The guard's test-files pin is still 249 with 253 test files at `a53fbef`. | 185 / 186-05 hand-off | Raise the pin. It was deferred to the Phase 188 freeze, which changed no code. The check still passes (floor). |
| A FIFO at `.git/info/attributes` makes `probe_source/2` wait forever. | 184 GAP4-WR-01 | Bound the read. Never reports allowed, but a read-only check can hang. |

## Needs an owner decision

- **186 WR-01 (LOOP-07 residual):** the physical preflight passes when `Info.plist` is unreadable or `route_activation.json` is malformed and no local declaration exists.

## Hand-offs that were not done

- Swift suite: the pre-existing G4 failure (89 run, 1 failure, matching baseline) was deferred to Phase 188 and not addressed.
- The loopback harness build-addition allow-list (186 IN-01, research assumption A2) still lacks confirmation from a real Simulator run; 188 ran only twin-05.
- The 180 handoff record's `authorized_paths` (a Phase 181 scope list) was not extended; only repaired head/tree were refreshed.

## Retained review findings

- **184:** GAP4-WR-02, GAP4-IN-01..03, IN-02/GAP-IN-02. See `184-REVIEW-DISPOSITION.md`.
- **185:** WR-03..05 (WR-01 kept by decision D-14); example-host G2/G6 test failures. See `185-REVIEW-DISPOSITION.md`.
- **186:** WR-02, IN-02..04. See `186-REVIEW-DISPOSITION.md`.
- **187:** WR-03 (deferred, D-09), WR-04, IN-03; doctor `Path.relative_to` fallbacks at `doctor.ex:2288/2345/2404` return an absolute path outside cwd unchanged. CW-REQ-A, CW-REQ-D and the compile-time `:local_first` rule have reopen triggers in `187-DEFERRALS.md`.
- **188:** WR-03 (receipt carries no head/tree), WR-05..07, IN-01..03. See `188-REVIEW-DISPOSITION.md`.
- **Carried from v25:** see the [v25 debt disposition](../v25.0-closeout/debt-disposition.md); 183 WR-01/02 were closed by Phase 184.

## Validation coverage

Nyquist validation: all five VALIDATION.md files (184–188) are `status: draft`. Phase 188's rows are all green but were not reconciled. `/gsd-validate-phase <N> --ws quality-ratchet-release` can settle each one.

## Delivery and external gates

- All Phase 184–187 product commits exist only in `/private/tmp/crosswake-phase180-impl` (HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, tree `f7c4d7dc`). Moving them into the authoritative tree needs separate authorization.
- Residual external gates (by design): a physical signed-iPhone run; the first adopter's sanitized route handoff.
