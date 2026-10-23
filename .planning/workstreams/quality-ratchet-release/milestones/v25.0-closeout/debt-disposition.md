# v25.0 debt disposition

Accepted at closeout on 2026-10-15. None of these items is a broken requirement. Each one names when it should be handled.

## Can degrade silently: handle before the next twin run

| Item | Source | Disposition |
|---|---|---|
| The clean-tree probe ignores git index flags (`assume-unchanged`, `skip-worktree`), so a modified file carrying a flag passes. | 183 WR-01 | Fix in the next twin-touching change: count non-`H` `git ls-files -v` entries as dirty and add a test. That change needs a new run root (twin-05). |
| The probe does not pin `core.filemode=true`, so a repo or global `false` hides mode-only changes. | 183 WR-02 | Fix in the same change: pass `-c core.filemode=true` and add a test. |
| An edit made and reverted during a run is not detected. | 183 limit | Disclosed as fidelity limit 5. Never describe a run as verifying the source for its whole duration. |

Neither WR-01 nor WR-02 was present at twin-04: all 3257 index entries were `H` and filemode was true. The twin-04 attestation stands.

## Retained review findings

- **181:** 13 open findings (4 medium), notably M-02 (the legacy path grants any registered `host.*` key silently) and M-04 (a local username appears in package-path messages). See `181-REVIEW-DISPOSITION.md`.
- **182:** 10 open findings, including WR-03 (a harness hash assertion that cannot fail) and WR-05 (the harness passes despite a failed cleanup). See `182-REVIEW-DISPOSITION.md`.
- **183:** WR-03, WR-04 and IN-01..04, besides WR-01/02. See `183-REVIEW-DISPOSITION.md`.

## Deferred scope and wiring

- The twin does not join the Phase 179 identity projection; the bundle id is hardcoded. Deferred by user decision in 183-CONTEXT.
- `script/verify_loopback_origin_simulator.sh` and `script/loopback_origin_simulator/*` are unreferenced. Wire them up or remove them.
- The physical-iPhone preflight has no origin-mode check; refusal happens only at generation.
- Route id mismatch: the example island uses `study-session`, the router uses `offline-study`.
- Generator friction: the drift check reports stale unless run with `MIX_ENV=test`; `local_ios_package` resolves from the current directory; hosts outside the monorepo get a remote package reference with no seam release yet.
- `WKAppBoundDomains` is a hardcoded `example.com` (pre-existing).

## Unknowns

- Why case 3 stalled in twin-02 is not known, because that run kept no cause for it. Do not infer one.

## Validation coverage

Nyquist validation: 179 compliant; 181, 182 and 183 draft; 180 has none. `/gsd-validate-phase <N> --ws quality-ratchet-release` can fill these.

## Delivery and external gates

- All Phase 179–183 product code exists only in `/private/tmp/crosswake-phase180-impl` (HEAD `50fcd5743243c0b20275a7e2bd9338bf25468687`). Moving it into the authoritative tree needs separate authorization.
- Residual external gates (by design): a physical signed-iPhone run; the first adopter's sanitized route handoff.
