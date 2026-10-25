# v25 Proof Operations: Twin Evidence, Privacy, and Isolation

**Scope:** TWIN-01–06 evidence and execution posture for the proposed v25 bounded digital twin.
**Research date:** 2026-10-13
**Confidence:** HIGH for pinned source and official-tool behavior; MEDIUM for the proposed integration design.

## Recommendation

Compose the existing Phoenix reference host, browser corpus, generated iOS host, and XCTest adapter, but keep their observations owned by their actual runtime. Produce one small, versioned **twin run receipt** that joins those observations under a single exact source/run identity. Keep this receipt distinct from the physical-iPhone promotion artifact. Reuse the existing scenario IDs and redaction discipline; do not add a general evidence taxonomy, `device_class` value, support-matrix row, or physical promotion route.

This is the smallest compatible design because the existing physical report path is intentionally physical-only: the contract envelope requires `device_class: "physical_iphone"`; its parser rejects other classes; the join passes only when every device-local and backend-authority assertion passes; and a non-pass collapses to a blocked result rather than preserving per-scenario outcomes. The canonical physical evidence schema also requires the full passed physical assertion set, bounded iOS runtime line, and approved physical run-contract hash. Reusing it for simulator/twin output would either mislabel simulator observations or weaken the physical contract. Existing generic evidence can say `simulator`, but it has no per-scenario owner/outcome rows or twin-source bindings, so it cannot satisfy TWIN-05. See the [pinned contract](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/proof_lane/physical_iphone_contract.ex), [pinned report join](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex), and [pinned evidence allowlist](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/proof_lane/evidence.ex).

| Choice | Benefit | Conflict or cost | Decision |
|---|---|---|---|
| Reuse `proof-lane-evidence.json` / physical report | Existing closed privacy scanner, canonical writer, and source-hash verification | Physical class is complete-pass-only; cannot truthfully report simulator, partial scenarios, or distinct runtime owners | Keep for physical-device promotion only |
| Reuse `NavigationShellAdvisory` or generic `simulator` evidence | Very little new code and existing advisory vocabulary | Navigation advisory is all-pass for a different seven-assertion contract; generic evidence lacks per-scenario result rows, fixture provenance, and source/run join | Reuse its low-cardinality style, not its schema |
| Add a twin-only versioned receipt | Preserves every fixed scenario result and runtime boundary with one source-bound join | Requires a small strict parser/validator and privacy contract | Recommended; keep local/advisory and non-promoting |
| Add a reusable, general-purpose evidence taxonomy | Could represent future device classes and arbitrary proof owners | Expands labels, consumers, migration and claim policy beyond v25; creates a second framework without repeated need | Reject until distinct active use cases justify it |

Use the receipt as an execution record, not a public support claim or CI attestation. It should contain a closed roster, closed outcomes, sanitized provenance, and only the minimal evidence digest needed to verify the join. Do not add an attestation service: GitHub positions artifact attestations for release artifacts consumers verify and says attestations alone do not establish that content is safe; it does not recommend signing frequent test builds. [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)

## Existing proof owners and conflicts

At the requested production pin `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, the current boundaries are:

| Owner | Current observable | What it can establish | Twin limitation |
|---|---|---|---|
| Phoenix host | Actual reference endpoint, controller/domain logic, Ecto `ReviewEvent` state | Host/backend behavior on the reference fixture | Synthetic test authority is not first-adopter auth or account policy |
| Playwright | Browser UI, IndexedDB offline mutation, reconnect, backend confirmation, duplicate request, empty outbox | Real browser/browser-storage behavior on the host | Browser is not the visible iOS WebView or native bridge |
| XCTest/XCUITest | A selected signed physical destination in the physical proof; `.xcresult` attachment carries the closed report | Physical-device assertions only when that destination really is a physical iPhone | Existing collector rejects simulator observations; simulator must remain explicitly simulator-class |
| `Evidence` | Closed canonical physical artifact, privacy scan, approved-source digest check, exact two-leaf publication | Retained physical record integrity | It does not model a partial multi-runtime twin run |

The reference host uses a one-use process-local nonce and mutation ID to bind backend observations to a test run. Its report verifies expected outcomes after the normal replay path. This is useful to reuse, but the authority fixture is synthetic and must be labeled `synthetic_test_authority`; never report it as real adopter credentials or adopter authorization. The reference host currently calls `Repo.delete_all(ReviewEvent)` during report cleanup, and the deterministic fixture helper does the same before cases. A twin must not run this cleanup against a shared/pre-existing database. The physical host also writes its generated Xcode result bundle and DerivedData below a private random run root and extracts a closed attachment before removing that root; preserve that ownership pattern. Sources: [pinned Phoenix host](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex), [pinned authority producer](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex), [pinned test fixture](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/test/support/physical_iphone_authority_fixture.ex).

There is another dangerous interaction in the available checkout: `playwright.config.ts` starts the Phoenix server with `ecto.drop`, `ecto.create`, and `ecto.migrate` against the default database, on port 4700; its non-repository mode can reuse a server already on that port. The example host defaults to a stable SQLite file. A concurrent twin invocation could therefore reset another host's database or attach to the wrong process. The exact production ref could not be resolved in the local checkout (`HEAD` is a recovery checkout at `d0f3e2f…`); this working-tree observation must be reconfirmed against the pin before implementing a harness. Regardless, the twin runner should explicitly own its server, port, DB, browser context, and temporary files.

## Minimal receipt and result semantics

Use a twin-only closed envelope, for example:

```json
{
  "schema_version": 1,
  "claim": "reference_twin_advisory",
  "result": "blocked",
  "source": {
    "crosswake_commit": "git-<full-commit>",
    "host_commit": "git-<full-commit>",
    "generated_contract_digest": "<sha256-of-sanitized-allowlisted-contract>"
  },
  "runtime": [
    {"owner": "phoenix_backend", "kind": "reference_host", "mode": "test"},
    {"owner": "browser", "kind": "chromium", "version": "<version>"},
    {"owner": "ios", "kind": "ios_simulator", "runtime_line": "<major.minor>"}
  ],
  "fixture": {"kind": "synthetic_test_authority", "manifest_digest": "<sha256>"},
  "observations": [
    {"scenario": "offline.relaunch_persistence", "owner": "ios_simulator", "outcome": "passed"},
    {"scenario": "bridge.visible_instance", "owner": "ios_simulator", "outcome": "unavailable", "reason": "host_observation_missing"}
  ],
  "residual_gates": ["physical_iphone", "validated_adopter_authority"]
}
```

The real roster comes from the ten fixed scenarios in the proposal, mapped to existing owners. Every selected scenario gets exactly one row with a declared owner and one of three outcomes: `passed` means it ran and its assertion held; `failed` means it ran and contradicted the expected behavior; `unavailable` means the harness could not collect the required observation. Keep prerequisites as explicit `blocked` rows when an external or setup condition prevents a required automated check. The aggregate result is `failed` if any executed assertion failed; otherwise `blocked` if a required scenario was unavailable or a prerequisite unmet; otherwise `passed`. No missing row, missing artifact, thrown callback, parse error, command exit code, or artifact existence check can default to success. A report consumer must verify the exact roster, no duplicates, owner mapping, outcome vocabulary, run identity, source identity, and result binding before deriving the aggregate.

Do not include UDID, Team ID, provisioning-profile UUID, bundle identity, endpoint/URL, secret, token, account/scope identifier, raw mutation ID, answer text, audio bytes, transcript, screenshot, browser trace, console/network log, raw stdout, or `.xcresult` path/content. For provisioning, record only the setting predicates required by IOS-02 (`bundle_identifier_present`, `test_signing_setting_propagated`, `device_target_build_setting_observed`) and the sanitized configuration digest; no actual team or profile values. Runtime provenance can include toolchain and simulator runtime versions and the class (`ios_simulator`), never a device identifier. Bind each scenario report to the run-specific challenge in the private adapter, then bind the sanitized canonical report bytes to the receipt digest. Never derive the tested source or expected identity from the output under verification.

Xcode's `.xcresult` contains session results, logs, and possibly coverage; keep the bundle private, then extract only the closed assertion attachment. Apple explicitly distinguishes simulated from physical run destinations and warns that simulators do not reproduce physical performance or features. A simulator report must therefore say `ios_simulator`; there is no promotion mapping from this receipt to `physical_iphone`. [Apple test results](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results) · [Apple simulated and physical destinations](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)

## Isolation, setup, and cleanup controls

1. **Run-owned host and DB.** Create a fresh mode-0700 run root and a new SQLite DB path (the example host already uses SQLite); migrate and seed only that DB. Allocate an exclusive loopback port, start only the runner's Phoenix child process, wait for readiness bound to this run, and terminate that exact child/process group before deleting the DB. If the host exits unexpectedly, fail closed and retain its private logs. Do not `ecto.drop` a default DB, reuse port 4700, kill a process discovered only by port, or connect to a pre-existing server. Cleanup must remove only paths and records created under the run ID.
2. **Run-owned backend rows.** Make fixture rows attributable to one opaque run reference and query/assert/clean them by that reference. Do not use whole-table `delete_all` in a shared reference DB. Current `Repo.delete_all(ReviewEvent)` is safe only after the DB has been created for this invocation and proven to be its owned empty test DB; row-scoped cleanup is safer and composes with concurrent work.
3. **ExUnit vs end-to-end DBs.** Use `Ecto.Adapters.SQL.Sandbox.start_owner!/2` with `on_exit` cleanup for ExUnit tests whose BEAM processes can be explicitly allowed to use the transactional connection. Use shared mode only for sync tests because it disables concurrent tests and workers must finish before owner cleanup. Ecto documents concurrent Sandbox tests for PostgreSQL, not MySQL. A Playwright browser, standalone Phoenix server, and XCTest process cannot share an ExUnit process-owned transaction; use a per-run committed DB for that genuine HTTP integration flow. Keep the current SQLite engine for this example rather than silently changing DB semantics. [Ecto SQL Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html) · [Phoenix endpoint testing](https://phoenix.hexdocs.pm/testing.html)
4. **Browser lifecycle.** Preserve the current browser corpus and fixtures. Run existing tests as-is in their isolated Playwright contexts; for a lifecycle that must span offline mutation, app relaunch, reconnect and replay, keep that sequence in one dedicated test/context and do not call reset helpers between its steps. Playwright isolates cookies and storage per context, and traces can contain DOM state; use `retain-on-failure` in the private run directory, delete traces on success, and never upload raw traces. A retry is a new attempt, not proof that the first failure did not happen. [Playwright isolation](https://playwright.dev/docs/browser-contexts) · [Trace retention modes](https://playwright.dev/docs/test-use-options) · [Playwright retries](https://playwright.dev/docs/test-retries)
5. **Faults and time.** Inject one deterministic fault at its named seam (missing/corrupt pack, rejected mutation, conflict, logout/account switch, entry/replay disablement). Assert that the injector changed the intended state before asserting denial. Never retry a failed scenario until green and overwrite the first receipt; a code repair creates a new run and retains the earlier failed record. Bound each process and the overall command; timeout means `unavailable`/`blocked`, not pass. Kill only owned subprocesses. Existing physical `System.cmd/3` execution has no explicit timeout in the inspected host code; TWIN should add a bounded runner rather than inherit unbounded waiting.
6. **Failure diagnostics.** Capture raw subprocess output, Playwright trace, and `.xcresult` only inside the private run root; on failure retain them locally for diagnosis, but keep only stable error IDs and closed outcomes in the receipt and CI summary. On success remove the private root. Synthetic fixtures must contain no real adopter data. Final receipt scanning rejects unknown keys and sensitive values rather than relying on general logger redaction.

## CI/SRE boundary and diminishing returns

The complete twin is a one-time, locally reproducible milestone demonstration, not a new standing CI workflow. Reuse existing recurring `mix test`, `script/verify_repository.sh --stage browser-proof`, and generated iOS proof coverage. Add only stable receipt-schema/anti-overclaim tests to the existing relevant ExUnit lane if they protect a contract for every future change. Do not add a recurring simulator/Xcode service lane merely to retain this one run: it would duplicate cost and still could not answer the physical/iPhone question. The repository's existing CI already runs the browser lane and retains browser failure artifacts for 14 days; the twin's raw evidence should follow its private-run policy rather than broadening those uploads.

The ten proposed scenarios are the stop boundary. A completed pass means all virtual checks are observed and passed, with the remaining physical-hardware and adopter-authority gates plainly listed. Stop there; do not add scenarios because more checks are imaginable. A real virtual failure can justify one focused repair; require a reproducible cause, deterministic fault/negative control where applicable, and a fresh uniquely identified run. If an automatable virtual check cannot run, the milestone remains blocked/incomplete. Only a limitation that the proposal explicitly assigns to physical hardware or real adopter authority can be reported as a residual gate after virtual completion. This follows the fixed-scope rule in the [v25 scope proposal](/private/tmp/crosswake-v25-scope-proposal.md) and the existing physical boundary in [the route-policy map](../../FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md).

### Suggested scope wording

**TWIN-05:** “For each fixed scenario, the runner emits a closed, source-bound, privacy-scanned observation with its runtime owner and `passed`, `failed`, or `unavailable` outcome. Required unmet prerequisites are `blocked`. The final result preserves every scenario outcome; missing, synthetic, stale, fabricated, or simulator observations cannot produce a physical-iPhone or adopter-authority claim.”

**TWIN-06:** “The final handoff reports the exact source/run, all ten scenario outcomes, runtime owners, synthetic authority and other fidelity limits, and remaining physical/adopter gates. Completion requires every automatable twin scenario to have run and pass. Stop after that bounded result; an unavailable required automation remains blocked. Do not add scenarios without a concrete observed defect or new adopter evidence.”

## Source notes

- Pinned production owners read through the read-only GitHub Contents API at `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`; that object is absent from the local checkout. Code-specific concerns above refer to that pin unless explicitly identified as available-checkout configuration.
- Local lessons: `.planning/RETROSPECTIVE.md` v23/v24 (preserve failed causes, exact-source binding, private isolation, no reconstructed green); `.planning/research/v23/{ARCHITECTURE,PITFALLS,DX,SUMMARY}.md` (separate proof classes, no weakening, retain diagnostic owner detail); current `.planning/ADR-FIRST-B2C-ADOPTER.md`, route-policy map, and `AGENTS.md` (physical-device boundary, privacy and CI restraint).
- External source confidence: HIGH for Ecto, Phoenix, Playwright and Apple tool behavior from their official documentation; MEDIUM for CI recommendations because the specific retention and runner choices depend on this repository's privacy and operations policy.
