# Phase 201: Fix the exact-public companion digest proof so a release run can complete - Research

**Researched:** 2026-11-09
**Domain:** Hex release-candidate artifact proof (Elixir `Crosswake.ReleaseCandidate.*`, Hex tarball metadata, GitHub release workflows)
**Confidence:** HIGH on root cause and fix shape (reproduced on real tarballs, prototype run); MEDIUM on the 0.2.14 sequencing (read from plans and workflow YAML, not yet executed)

<user_constraints>
## User Constraints (from CONTEXT.md)

No `201-CONTEXT.md` exists for this phase. The constraints below are copied from the ROADMAP Phase 201 section, the orchestrator brief and AGENTS.md; treat them as locked.

### Locked Decisions
- Goal: a release run can reach COMPLETE; the exact-public proof stops failing every published companion with `digest_mismatch`, without loosening what it proves about the core or about a companion's contents.
- Scope (1): find the differing metadata field with evidence. Scope (2): decide with a recommendation whether the expectation or the candidate build is wrong; fix forward with a regression test on real tarballs, not invented fixtures. Scope (3): measure the proof's findings before it stays merge- or release-blocking. Scope (4): the 0.2.14 release PR 283 is the vehicle that proves it, run under the standing approvals (merge, tags, publishes need no gate; the Maven fire-drill dispatch and remote-branch deletion keep theirs).
- Requirement IDs: REL-08, REL-09 (closeout of Phase 200 plans 200-08 and 200-09 follows a COMPLETE run).
- Nothing already published is re-run, re-approved or retried; 0.2.13 is permanent (AGENTS.md "never retry an uncertain delivery", Phase 200 rule).
- Do not record or infer the real adopter name or any adopter-identifying detail.

### Claude's Discretion
- Which side is wrong (expectation vs candidate build) and the exact shape of the fix.
- Test fixture shape, whether to add a diagnosability aid, and how the proof's findings are measured.

### Deferred Ideas (OUT OF SCOPE)
- Anything in the BEARINGS.md "Do not re-open" list; Android emulator/device claims; retiring 0.2.12 on Hex (its own gated decision); threadline 0.1.1 (PR 262) release.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-08 | Default iOS generation builds; regression test on real generator output; pre-release gate | Already delivered by 0.2.13 (iOS clean-room proof passed in run 42639651064). Phase 201 only needs REL-08's closeout to be re-evidenced by a COMPLETE run; no new REL-08 code. |
| REL-09 | 0.2.13 released with separate gates; "its release run ends COMPLETE including the iOS clean-room and exact-public proofs, and its ledger line lands on `main`" | The 0.2.13 run ended FAILURE and can never be COMPLETE (no re-run allowed). Wording must be reconciled (see Open Question 1). The fix in this research is what lets a later run (0.2.14) reach COMPLETE. |
</phase_requirements>

## Project Constraints (from CLAUDE.md / AGENTS.md)

No `CLAUDE.md` exists; `~/projects/crosswake/AGENTS.md` is authoritative. Directives that bear on this phase:
- Preserve fail-closed explicit denials; flag any path that can degrade silently. The fix must not turn a mismatch into a silent pass.
- Test adapters against the dependency's real output, not invented fixtures (the existing `artifact_test.exs` fixtures are invented, which is why the defect was never caught pre-release).
- Default to zero-human verification: every check below is a runnable command; no `checkpoint:human-verify`.
- Promote checks into CI only when they protect a recurring contract; one-time reconciliation commands stay in phase evidence.
- Work in the one main checkout, branch from current origin/main as `fix/<topic>`; every change through a PR with Crosswake CI green on the head; merge commit only (merge needs no gate under the 2026-11-05 standing exception, pinned with `--match-head-commit`); say which commit CI ran on.
- Run the privacy scan before every push and rescan after any new commit. Never name the adopter.
- Release PR merge, tags and Hex/Maven/iOS publishes need no gate under the standing approvals recorded in AGENTS.md (PR 284); the Maven fire-drill dispatch and remote-branch deletion still need their own `allow`.
- Update requirements, roadmap, state and the planning truth together when a decision changes; blocked plans are named `NN-BLOCKED.md` (200-08 already is).
- Tripwires (BEARINGS.md): a check needs a non-empty floor and a mutation that turns it red; no piped gate commands (`cmd | tail && echo OK` masks the exit code); do not pin a literal digest/version, assert shape or derive; measure findings on main before a check becomes merge-blocking.

## Summary

**Root cause (reproduced, HIGH):** Hex 2.6.0 started writing a `build_env` field, `[{"hex", "<Hex version>"}]`, into every package's `metadata.config`. The six-package candidate build in CI runs `mix local.hex --force` (latest Hex), so the 0.2.13 candidate receipt was built with Hex 2.7.0 and its companion metadata digests include `build_env`. The five companions on hex.pm were published months earlier with older Hex and have no `build_env`. `Artifact.inspect_metadata!` digests the whole normalized metadata map (only `files` and `requirements` are normalized), so `build_env` flips `metadata_digest` for every companion while the payload digest stays identical. The core passed only because it was published in the same run, by the same Hex 2.7.0, so both sides carry `build_env = 2.7.0`. The earlier diagnosis "a `build_env` key with prod, dev, test or docs" tested the wrong value: the field records the Hex version, not the Mix environment.

**Evidence chain (all executed this session):** the five public companion tarballs fetched from repo.hex.pm, run through the repo's own `Artifact.inspect_cli!`, give metadata digests 5e444f8c, 7c0765a3, 76d69c05, b791d5ee, 794181a8 (public, no `build_env`); the same tarballs with one line `{<<"build_env">>,[{<<"hex">>,<<"2.7.0">>}]}.` appended to `hex_metadata.config` give edff10ce, 608a7cf1, b19af602, cae518f2, 05c50af1, which equal the approved CI manifest digests from candidate run 42633255271 for all five. Independently, a genuine Hex 2.7.0 rebuild of `crosswake_rulestead` at tag `crosswake_rulestead-v0.1.1` produced metadata digest edff10ce and payload digest 2b147a3d, byte-for-byte the approved CI values. The 0.2.11 release (Hex 2.5.1 on both sides, run 38155320492) recorded exact-public state COMPLETE with all six packages fully proven, so the proof design works; only the Hex version changed.

**Which side is wrong:** the expectation (the digest definition), not the candidate build. `build_env` is toolchain provenance (which Hex built the tarball), not package identity or content. The proof demands a bit-identical rebuild of a field that records the rebuilder, and a rebuild under a later Hex can never reproduce it for any package published before Hex 2.6.0. Pinning Hex in CI is the wrong fix (it cannot reproduce 0.2.13's core, which was published with 2.7.0, and it would break the next time a companion is published with a newer Hex). The core is also exposed in principle: a Hex release landing between candidate build and publish would mismatch it too.

**Primary recommendation:** drop `build_env` from the normalized metadata before digesting in `Crosswake.ReleaseCandidate.Artifact.inspect_metadata!/3` (one place, both candidate and public sides use it), but first validate its shape fail-closed (`nil` or exactly `[{"hex", <parseable semver>}]`, anything else `invalid!()`). Everything content-bearing stays in the digest (name, version, app, description, elixir, licenses, links, build_tools, normalized files and requirements, plus the payload digest of every file, mode and sha256). Add a real-tarball regression test (a real pre-2.6 public tarball and a real Hex 2.7.0 rebuild of the same tag) with a non-vacuity floor and negative controls. No workflow change is required for the fix; 0.2.14 (PR 283) is the first live proof, after the fix is on `main` and release-please has refreshed the PR head.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Metadata digest definition (what counts as package identity) | Library (`Crosswake.ReleaseCandidate.Artifact`, pure Elixir) | - | Single normalizer used by both the candidate build manifest and the public-tarball observation, so symmetry is structural. |
| Candidate family build (`mix hex.build` x6, official unpack) | Shell adapter (`script/release_candidate/hex_artifacts.sh`) | CI workflow (`release-please.yml`, iOS mirror authority) | Owns Hex invocation and `mix local.hex --force`; emits the manifest consumed later. |
| Public tarball fetch + unpack | Shell adapter (`script/verify_companion_cleanroom.sh` `matrix_fetch_public_family`) | Hex registry | Fetches `mix hex.package fetch`, official unpack, then same `Artifact.inspect_cli!`. |
| Verdict (`digest_mismatch`, COMPLETE/BLOCKED) | Library (`Crosswake.ReleaseCandidate.Cleanroom.public_artifact_reason/3`) | Workflow rollup | Pure comparison of approved vs observed digests and refs; rollup turns BLOCKED into a failed release job. |
| Durable verdict record | CI (`exact-public-proof.yml` `record-ledger`) | `docs/release-ledger/RELEASE-LEDGER.jsonl` in git | Append-only ledger via bot PR; PR 285 holds the 0.2.13 failure row. |
| Source-ref resolution for a published companion | Shell (`package_source_ref.sh`) | - | Returns the package's own tag commit in both modes (see Pitfall 4). Not part of the defect. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | 1.19.5-otp-27 / 27.3 | Runtime for `Artifact`/`Cleanroom` and ExUnit | `.tool-versions` pins them [VERIFIED: .tool-versions read this session: `erlang 27.3`, `elixir 1.19.5-otp-27`] |
| Hex (build tool, not a dependency) | 2.7.0 in CI on 2026-11-09; 2.5.1 in CI on 2026-10-11 | Builds and unpacks tarballs; the source of `build_env` | CI log lines `creating /home/runner/.mix/archives/hex-2.7.0` (candidate run 42633255271) and `hex-2.5.1` (run 38155320492) [VERIFIED: `gh run view --log`] |
| `:erl_tar` (OTP stdlib) | OTP 27.3 | Unpack real Hex tarballs in the regression test without Hex installed | Real tarball = outer tar of `VERSION`, `CHECKSUM`, `metadata.config`, `contents.tar.gz`; verified to reproduce the layout `Artifact` walks (see Code Examples) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled | Regression test | New file under `test/crosswake/release_candidate/` |
| `jq`, `gh`, `curl`, `python3` | host | Evidence commands only | Measurement and fixture regeneration |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Strip `build_env` from the digest (recommended) | Pin Hex to one version in all workflows | Cannot reproduce 0.2.13 core (built by 2.7.0) or pre-2.6 companions; breaks on the next Hex bump or companion republish; hides drift instead of classifying it. Rejected. |
| Strip `build_env` for all six | Strip for companions only; compare `build_env` for core | Core candidate vs publish can straddle a Hex release (candidate built before merge, publish after); a toolchain stamp is not content. Companion-only is the minimal-loosening fallback if the user wants it; costs a per-package branch. |
| Digest-level fix | Rebuild each companion with the Hex version recorded in `build_env` and compare outer checksums (Hex 2.6+ builds are deterministic per its changelog) | Stronger, but pre-2.6 packages record nothing, so it cannot cover the current companions. Possible later hardening for post-2.6 releases only. |

**Installation:** none. No new packages. Fixture regeneration commands are in Code Examples.

**Version verification:** Hex releases read via `gh api repos/hexpm/hex/releases`: v2.5.1 2026-07-09, v2.5.2 2026-10-12, v2.5.3 2026-10-14, v2.5.4 2026-10-20, v2.6.0 2026-10-23, v2.7.0 2026-11-06. `build_env` occurrences in `lib/mix/tasks/hex.build.ex`: v2.5.1 0, v2.5.2 0, v2.5.4 0, v2.6.0 2 [VERIFIED: `gh api .../contents/lib/mix/tasks/hex.build.ex?ref=<tag> | grep -c build_env`].

## Package Legitimacy Audit

No external packages are installed or recommended by this phase (no `mix.exs` dependency change, no npm/pip/cargo). The audit gate is not applicable.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | - | - | - | - | n/a | n/a |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

Note: the Hex 2.7.0 archive used to rebuild one fixture comes from `mix local.hex --force`, the same step CI already runs; it is the toolchain under test, not a new dependency.

## Architecture Patterns

### System Architecture Diagram

```
 candidate run (iOS mirror authority / hex_artifacts.sh)            exact-public proof (post-publish)
 -------------------------------------------------------            ---------------------------------
 git ref (approved head)                                            approved manifest (artifact
   |                                                                 phase168-candidate-receipt-<head>)
   +--> core: mix hex.build  (Hex = latest at run time)                        |
   +--> companion x5: package_source_ref.sh -> its own tag commit              |
         git archive packages -> mix hex.build (Hex = latest)                  |
                    |                                                          v
                    v                                       for each of 6 packages:
        official unpack -> Artifact.inspect_metadata!        mix hex.package fetch (registry tarball)
                    |        digest_term(normalized map)        official unpack
                    |        [DEFECT: map includes build_env]       |
                    v                                               v
          approved manifest:                              Artifact.inspect_cli!  (same module)
          {package, candidate_ref,   <---- compared by ---- {package, candidate_ref, metadata_digest,
           metadata_digest, payload_digest}   Cleanroom       payload_digest}
                                              public_artifact_reason/3
                                                  |
        same ref AND digests differ -> "digest_mismatch" -> state BLOCKED -> release rollup FAILURE
        same ref AND digests equal  -> nil (fully_proven)
        (different ref AND equal    -> reachable_and_compatible: cannot occur for published companions)
```

### Recommended Project Structure
```
lib/crosswake/release_candidate/artifact.ex          # the one-place fix (metadata normalization)
test/crosswake/release_candidate/
  artifact_test.exs                                   # existing synthetic fixtures, keep (add one case: shape)
  artifact_real_tarball_test.exs                      # NEW: real tarballs, floor + negative controls
test/fixtures/hex_tarballs/
  crosswake_rulestead-0.1.1.public.tar                # real, from repo.hex.pm (pre-2.6 Hex, no build_env)
  crosswake_rulestead-0.1.1.hex-2.7.0.tar             # real, mix hex.build at tag crosswake_rulestead-v0.1.1 with Hex 2.7.0
  README.md                                           # how each was produced + sha256 (provenance, not a pinned digest)
```
(Each tarball is 15-16 KB. Do not check in the 604 KB core tarball; the defect is the companion/Hex-version interaction and two rulestead tarballs reproduce it.)

### Pattern 1: Normalize provenance out of identity, validate it fail-closed
**What:** Treat toolchain stamps as provenance: validate exact shape, then exclude from the digest.
**When to use:** any metadata key that records the builder, not the package.
**Example (prototype executed this session against the repo module; see Code Examples for the diff):**
```elixir
# In inspect_metadata!/3, before building normalized_metadata:
build_env!(metadata["build_env"])          # nil | [{"hex", semver}] else invalid!()
normalized_metadata = metadata |> Map.delete("build_env") |> Map.put("files", declared_paths) ...
```

### Pattern 2: Real-output fixtures with a divergence floor and mutation controls
**What:** A test whose fixture provably contains the divergence (the 2.7.0 tarball has `build_env`, the public one lacks it), asserts equality across it, and asserts that real mutations still change the digest.
**When to use:** BEARINGS tripwire "a check with no negative control passes by asserting nothing".

### Anti-Patterns to Avoid
- **Pinning the literal digest in the new test:** assert the relation (public digest == rebuild digest), never a hex literal; a literal pins today's normalization.
- **Loosening by deletion of the whole key family:** do not drop unknown keys or weaken `@metadata_keys`; an unknown future Hex key must still fail closed.
- **Fixing the expectation in the workflow YAML only:** the digest definition lives in `Artifact`; both manifest sides must use the same code (the proof runs the approved-head tree's code).
- **Re-running or re-approving 0.2.13:** forbidden; the proof for this fix is the 0.2.14 run.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unpacking a Hex tarball in a test | A custom tar/gzip reader | `:erl_tar` outer extract, then `:erl_tar` with `:compressed` on `contents.tar.gz`, copy `metadata.config` to `hex_metadata.config` | Same layout the official unpack produces; verified against the real tarballs |
| Metadata term normalization | A second normalizer in a script or Python | `Artifact.inspect_metadata!` only | Two normalizers can disagree; `companion_attestation.py` and `verify_hex_publish_dry_run.sh` only read the manifest, they must not recompute |
| Detecting toolchain drift by rebuilding | Pin/downgrade Hex per package | Provenance exclusion + (optionally) log the observed Hex version | A pin cannot match packages built by different Hex versions |
| Fetching public tarballs | ad hoc curl in the proof | existing `mix hex.package fetch` step in `verify_companion_cleanroom.sh` | Hex >= 2.5.2 verifies the registry checksum of the fetched tarball |

**Key insight:** the proof compares two observations produced by one module; making them differ only in a recorded-builder field is a definitional error, so the repair belongs in the definition, once.

## Common Pitfalls

### Pitfall 1: Testing the wrong value of `build_env`
**What goes wrong:** diagnosis in 200-08 tried `prod/dev/test/docs`, ruled `build_env` out, and left the cause unknown.
**Why it happens:** the name suggests Mix env; Hex 2.6.0 uses it for the Hex version (`Map.put(:build_env, %{hex: Hex.version()})`, hex.build.ex:193 at v2.7.0).
**How to avoid:** the regression test uses a real Hex 2.7.0 tarball, not a guessed value.
**Warning signs:** `metadata_digest` differs, `payload_digest` equal, `requirements` equal, only for packages whose publish date predates 2026-10-23.

### Pitfall 2: Fixing only the candidate side or only the public side
**What goes wrong:** the proof runs the approved-head tree's `Artifact` on both the candidate build and the public fetch; patching one invocation path (e.g. only `hex_artifacts.sh`) leaves the other asymmetric.
**How to avoid:** change `Artifact.inspect_metadata!/3` (used by `inspect_cli!` for both). Verify with the six-tarball run in Validation Architecture.

### Pitfall 3: Old receipts are not comparable after the fix
**What goes wrong:** the core digest changes under the new rule (397a3a1c to 426488ef in the prototype). The existing 0.2.13 approved manifest (old rule) cannot be re-used to re-prove 0.2.13 with new code.
**How to avoid:** do not attempt to re-prove 0.2.13; the 0.2.14 candidate run builds its own manifest at the same head as the proof code. Record this in the evidence so nobody "re-checks" 0.2.13.

### Pitfall 4: `reachable_and_compatible` is unreachable for published companions
**What goes wrong:** assuming a ref-drift escape hatch exists. `package_source_ref.sh` returns the tag commit for a published companion in both `candidate` and `public` modes, so the approved ref and observed ref are equal and any digest difference lands in `digest_mismatch`.
**Why it matters:** there is no softer verdict to fall back on; the digest definition is the whole behavior. Do not "fix" this by weakening the ref comparison (BEARINGS: fail-closed).

### Pitfall 5: Other Hex 2.6+ behavior changes can legitimately change a rebuild of an old tag
**What goes wrong:** Hex 2.6.0 also changed which files are excluded at any depth (OS/editor files) and made builds deterministic; a rebuild of a very old tag under a newer Hex could change the payload digest. 0.2.13 payloads matched for all five, so this is latent, not current.
**How to avoid:** do not widen scope now; note it so a future payload-only `digest_mismatch` is first checked against Hex release notes. Optional aid: print the observed Hex version (`build_env`) per package in the proof log.

### Pitfall 6: Vacuous new test
**What goes wrong:** a regression test that passes because neither fixture exercises the divergence.
**How to avoid:** assert the 2.7.0 fixture contains `build_env` and the public fixture lacks it (floor), and assert the test is red on the unpatched `Artifact` (see Validation Architecture "red before fix").

### Pitfall 7: New assertion shapes trip the repo's absence ledgers
**What goes wrong:** `script/inventory_collection_assertions.exs` and `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` audit `assert Enum.all?` / `refute Enum.any?` sites; a new site needs a ledger row.
**How to avoid:** write explicit `for` loops with a floor assertion, or avoid those shapes; run `elixir script/check_absence_is_not_success.exs` and `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`.

## Code Examples

### The defect site (current code) [VERIFIED: lib/crosswake/release_candidate/artifact.ex:19 and 170-176, read this session]
```elixir
@metadata_keys ~w(app build_env build_tools description elixir files licenses links name requirements version)
...
    normalized_metadata =
      metadata
      |> Map.put("files", declared_paths)
      |> Map.put("requirements", requirements)
      |> normalize_term()

    {normalized_metadata, digest_term(normalized_metadata), declared_paths, requirements}
```
`build_env` is already an allowed key, so it is digested as-is.

### The verdict that fired [VERIFIED: lib/crosswake/release_candidate/cleanroom.ex:320-323]
```elixir
      ref!(artifact.candidate_ref) == expected.candidate_ref and
          (artifact.metadata_digest != expected.metadata_digest or
             artifact.payload_digest != expected.payload_digest) ->
        "digest_mismatch"
```

### Proposed fix (prototype run this session via a scratch copy; tree not modified)
```elixir
    build_env!(metadata["build_env"])

    normalized_metadata =
      metadata
      |> Map.delete("build_env")
      |> Map.put("files", declared_paths)
      |> Map.put("requirements", requirements)
      |> normalize_term()
...
  # Toolchain provenance (the Hex version that built the tarball, Hex >= 2.6.0), not package
  # identity. Validate the exact shape so an unexpected value still fails closed.
  defp build_env!(nil), do: :ok

  defp build_env!([{"hex", version}]) when is_binary(version) do
    case Version.parse(version) do
      {:ok, _parsed} -> :ok
      :error -> invalid!()
    end
  end

  defp build_env!(_other), do: invalid!()
```
Prototype result (metadata digest prefixes): public as-is, public + injected `build_env`, and real Hex 2.7.0 rebuild of rulestead all give `5e444f8c`; the other four companions give 7c0765a3, 76d69c05, b791d5ee, 794181a8 in both variants; payload digests unchanged. Core moves 397a3a1c to 426488ef under the new rule on both sides.

### Real-tarball unpack helper for the test (executed against both real fixtures)
```elixir
defp unpack_real_tarball!(tar, dest) do
  outer = Path.join(dest, "outer")
  root = Path.join(dest, "unpacked")
  File.mkdir_p!(outer)
  File.mkdir_p!(root)
  :ok = :erl_tar.extract(String.to_charlist(tar), [{:cwd, String.to_charlist(outer)}])

  :ok =
    :erl_tar.extract(
      String.to_charlist(Path.join(outer, "contents.tar.gz")),
      [:compressed, {:cwd, String.to_charlist(root)}]
    )

  File.cp!(Path.join(outer, "metadata.config"), Path.join(root, "hex_metadata.config"))
  root
end
```
`Artifact` today exposes only `inspect_family!/1` (six packages). Add a small `@doc false` single-artifact entry point that delegates to the existing private `inspect_artifact!/2` (or have the test supply the real rulestead pair plus the existing synthetic five only for the family call). Prefer the single-artifact entry point so the test is all real data. [ASSUMED: planner picks the entry-point name; either keeps `inspect_artifact!/2` semantics.]

### Regenerating the fixtures (commands, run from the repo root; do not run inside the unpacked directory)
```bash
mkdir -p test/fixtures/hex_tarballs
curl -sSf -o test/fixtures/hex_tarballs/crosswake_rulestead-0.1.1.public.tar \
  https://repo.hex.pm/tarballs/crosswake_rulestead-0.1.1.tar
# Hex 2.7.0 rebuild of the same tag, isolated Mix/Hex homes so the global Hex is untouched:
S=$(mktemp -d); export MIX_HOME=$S/mix HEX_HOME=$S/hex
mix local.hex --force && mix hex.info | head -1            # expect: Hex: 2.7.0 (or newer; then README the version)
git archive crosswake_rulestead-v0.1.1 packages/crosswake_rulestead | tar -x -C "$S"
( cd "$S/packages/crosswake_rulestead" && \
  ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.19.5-otp-27 CROSSWAKE_RELEASE=1 HEX_OFFLINE=1 \
  mix hex.build --output "$OLDPWD/test/fixtures/hex_tarballs/crosswake_rulestead-0.1.1.hex-2.7.0.tar" )
```
(If `mix local.hex` installs a newer Hex than 2.7.0, rename the fixture to the observed version; the test must not hard-code it.)

### Fetching the 0.2.13 evidence (all read-only)
```bash
gh run download 42633255271 --name phase168-candidate-receipt-5a6a752185cc557af30b0f87244b8088ac83ff93 --dir <new-empty-dir>
gh run view 42633255271 --log --job 129214685403 | grep 'creating .*hex-'     # candidate Hex version
gh run view 38155320492 --log --job 114522406255 | grep -E 'creating .*hex-|"state":"COMPLETE"'   # 0.2.11
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hex `metadata.config` has no builder record | `build_env` records the Hex version that built the package | Hex 2.6.0, 2026-10-23 [CITED: github.com/hexpm/hex release v2.6.0 changelog: "The `build_env` field of the package metadata records the Hex version that built the package"] | Any rebuild under a later Hex differs from an older public tarball in this field |
| Hex builds depended on OS/FS/umask/order | Deterministic builds from identical files | Hex 2.6.0 [CITED: same changelog] | A post-2.6 package can later be rebuilt at its recorded Hex version and compared by checksum (future hardening) |
| Only `.DS_Store` excluded from packages | OS/editor/VCS files excluded at any depth | Hex 2.6.0 [CITED: same changelog] | Latent payload-drift risk for old tags (Pitfall 5) |

**Deprecated/outdated:**
- TODO-012 (`.planning/todos/TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md`, status `open`): its premise (single candidate ref for six packages) is superseded; `verify_companion_cleanroom.sh` now resolves a per-package approved ref (`approved_ref=$(jq ... .candidate_ref ...)` and `package_source_ref.sh ... public`, lines 215-217) and run 38155320492 reached COMPLETE with all six. Recommend dispositioning it with that evidence when Phase 201 closes (planner's call; do not edit it blind).

## Evidence: release history of the exact-public proof (measurement for scope item 3)

| Run | Release | Hex on both sides | Exact-public result | Cause of non-success |
|-----|---------|-------------------|---------------------|----------------------|
| 28675522926 | crosswake 0.2.0 | n/a | `skipped` (backfilled row) | proof did not exist yet |
| 38155320492 (2026-10-11) | crosswake 0.2.11 | 2.5.1 | COMPLETE: six packages succeeded, `failed_packages: []`, ledger row `success` | none |
| 42494651844 | crosswake 0.2.12 | n/a | not reached (iOS clean-room failed first) | ordering |
| 42639651064 (2026-11-09) | crosswake 0.2.13 | 2.7.0 (candidate) vs pre-2.6 (companions) | BLOCKED: core fully proven, five companions `digest_mismatch` | `build_env` (this research); ledger row for it is in open PR 285 |

- Live exact-public runs ever to reach a verdict: 2. COMPLETE 1, BLOCKED 1. True positives (content drift or tampering): 0. False positives: 1 run, 5 findings, one cause.
- Correction to the brief: the ledger's chimeway 0.1.0 and sigra 0.1.3 failures (2026-09-18) are backfilled rows for the per-companion clean-room proof lane, a different job; the ledger header says "No backfilled row claims an exact-public proof job that did not exist." They are not evidence about `digest_mismatch` [VERIFIED: docs/release-ledger/RELEASE-LEDGER.jsonl header read this session].
- The proof is a release-lane job feeding `release: linked release rollup`; it is not in `script/required_check_policy.json` (grep returned nothing), so it is release-blocking, not merge-blocking. Recommendation: keep it release-blocking (it caught a real asymmetry honestly), do not promote it to a merge check, and measure the fix with the commands below before the 0.2.14 run.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CI will keep running unpinned `mix local.hex --force`, so future Hex releases may add further metadata keys or change values | Pitfall 5, fix scope | A pin would be added by someone later; harmless. An unknown new key fails closed as `invalid` (not a silent pass) |
| A2 | After the fix lands on `main`, Release Please refreshes PR 283's head and the candidate attestation re-runs for the new head, so the 0.2.14 proof uses the fixed tree on both sides | Summary, 0.2.14 sequencing | If the PR head is not refreshed, the proof would run old code on an old head and fail again; plan must verify the head contains the fix before merging 283 |
| A3 | The single-artifact `Artifact` entry point name/shape is the planner's choice | Code Examples | None beyond naming |
| A4 | The user accepts excluding `build_env` for all six packages (including core) rather than companions only | Alternatives, Open Question 2 | RESOLVED 2026-11-09: the user chose companions only; the plans use the companion-only variant (see Open Question 2) |
| A5 | Hex 2.7.0+ rebuild of rulestead at its tag matches the public payload on every platform used (verified on macOS arm64 only for rulestead; CI proved Linux for all five via digest equality with injected `build_env`) | Evidence | Payload digests already matched on Linux CI for all five, so risk is low |

## Open Questions (RESOLVED)

All four were resolved on 2026-11-09: Q1 and Q2 by the user's own answers (AskUserQuestion during plan revision), Q3 by a planning decision, and Q4 by restating its answer under the user's Q2 decision.

1. **How does REL-09 close when 0.2.13's own run can never be COMPLETE?** (RESOLVED: user decision 2026-11-09, amend REL-09 to name 0.2.14)
   - What we know: REL-09 and the ROADMAP Phase 200 SC3 say 0.2.13's run "ends COMPLETE"; it ended FAILURE and a re-run is forbidden. STATE.md already names two outcomes: a COMPLETE run, or the user accepts 0.2.13 as closed with the recorded failure.
   - Resolution: the user chose to amend REL-09. The original sentence stays as history, and an appended amendment says REL-09 is met when the 0.2.14 release run, which carries the Phase 201 fix, ends COMPLETE (iOS clean-room and exact-public proofs included) and its ledger line lands on `main`. The amendment records what the user approved on 2026-11-09, the direction (name the 0.2.14 run, keep the original sentence), and that the planner drafted the wording. REQUIREMENTS, ROADMAP and STATE are updated together at closeout (201-08 Task 2), so no further checkpoint is needed for the wording.
2. **Strip `build_env` for all six or for companions only?** (RESOLVED: user decision 2026-11-09, companions only)
   - Research recommendation was all six. The user chose **companions only**: `build_env` stays in the digested metadata for the core package `crosswake`, still shape-validated fail-closed, and is excluded only for the five companions (`crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline`), after the same validation. The exclusion is a fixed rule on the package name already in the artifact data (`inspect_metadata!/3` has already checked `metadata["name"] == package`): an explicit module-attribute list of the five companion names; any other package, the core included, keeps `build_env` in its digest.
   - Consequences: the core's metadata digest stays sensitive to the Hex version that built it. The core passes only when its candidate build and its publish run under the same Hex (true for 0.2.13: Hex 2.7.0 on both sides). A Hex release landing between the core's candidate build and its publish makes the proof fail closed with `digest_mismatch`, exactly as today. Measurement M3 (Hex 2.5.1 build against the public family) therefore expects 5/6 metadata equal with `crosswake` the one difference, and the release plan re-reads the newest Hex before the core merge and the core Hex publish.
3. **Add a per-field diagnosability aid?** (RESOLVED: implement the minimum aid, planning decision PD-08)
   - What we know: the proof reports only `digest_mismatch`; diagnosis took a full phase because the approved manifest has no per-key digests and the candidate kept no tarballs.
   - Resolution: implement the small aid. `Crosswake.ReleaseCandidate.Artifact.inspect_cli!/1` prints one stderr line per package, `artifact-provenance: package=<p> version=<v> build_env_hex=<semver|none> build_env_digested=<yes|no>`, after the family validates and before the manifest is written. Both sides call `inspect_cli!/1` (`script/release_candidate/hex_artifacts.sh` for the candidate build and `script/verify_companion_cleanroom.sh` `matrix_fetch_public_family` for the exact-public proof), and both send only stdout to `/dev/null`, so the line reaches both CI logs with no script or workflow change. It is built in 201-03 Task 2 with tests on the three real fixtures, checked on the real 0.2.13 family in 201-04, and read from the 0.2.14 attestation and release logs in 201-05 and 201-07. The richer per-key digest variant is declined: it widens the observation keys, the `evidence_input.ex` allowlist and the exact-key assertion in `artifact_test.exs`.
4. **Do the 0.2.14 candidate and publish run under the same Hex?** (RESOLVED: still not asserted by any existing gate; it matters for the core only, and Phase 201 checks it)
   - For the five companions it does not matter for the proof under the fix. (The outer checksum is not compared against the publish in `guarded_hex_publish.sh`; grep found no `outer_checksum` use there.)
   - For the core it does matter under the Q2 decision. Phase 201 records the newest Hex (`hex_latest`) at candidate capture (201-05 Task 1), records the Hex version that built the core candidate from the attestation's `artifact-provenance:` line (201-05 Task 3), and re-reads `hex_latest` in the `core-merge` and `core-hex` prechecks (201-07). If the version moved, the plan stops with `201-07-BLOCKED.md` before the irreversible step.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP via asdf | `mix test`, `Artifact` | yes | 1.19.5 / OTP 27.3 | none needed |
| Hex 2.7.0 (isolated `MIX_HOME`) | regenerate the Hex-2.7.0 fixture | yes (installed in scratch this session) | 2.7.0 | none needed |
| Network to repo.hex.pm | fetch public tarballs | yes | - | fixtures are checked in after one fetch |
| `gh` (authenticated), `jq`, `curl`, `python3` | evidence commands | yes | - | - |
| GitHub Actions logs for runs 38155320492 and 42633255271 | evidence | yes (readable now; logs expire, so copy the two `hex-` lines into phase evidence) | - | the artifact `artifacts.json` is also readable |

Missing dependencies: none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (default excludes: `requires_example_host`, `engine_present`, `collateral_binaries`, `advisory_only`, `generated_manifest`) |
| Quick run command | `mix test test/crosswake/release_candidate/artifact_test.exs test/crosswake/release_candidate/cleanroom_test.exs test/crosswake/release_candidate/artifact_real_tarball_test.exs` (baseline for the first two: 38 tests, 0 failures, 0.5 s) |
| Full suite command | `mix test test/crosswake/release_candidate/ test/crosswake/proof/phase172_per_package_ref_test.exs` then `mix test --exclude requires_example_host --exclude advisory_only` (the merge-blocking hermetic selector from `script/check_exunit_ownership.exs`) |

Run each command on its own (no `| tail && echo OK`); read the exit status.

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-09 | Real pre-2.6 public tarball and real Hex 2.7.0 rebuild of the same tag yield equal `metadata_digest` and `payload_digest` | unit (real data) | `mix test test/crosswake/release_candidate/artifact_real_tarball_test.exs` | Wave 0 (new) |
| REL-09 | Floor: the 2.7.0 fixture's `hex_metadata.config` contains `build_env`; the public one does not | unit (real data) | same file | Wave 0 (new) |
| REL-09 | Negative controls on real data: changing `description`, a `requirements` entry, `links`, or one payload byte changes the relevant digest | unit (real data) | same file | Wave 0 (new) |
| REL-09 | `build_env` of unexpected shape (`[{"hex","not-semver"}]`, extra tuple, non-list) raises `ArgumentError` | unit | same file | Wave 0 (new) |
| REL-09 | `Cleanroom.evaluate_public!` still reports `digest_mismatch` for a metadata-digest change with no ref drift | unit | `mix test test/crosswake/release_candidate/cleanroom_test.exs` (existing anchors at lines 380-409) | yes |
| REL-09 | Family-level: six real public 0.2.13 tarballs vs a fresh Hex-2.7.0 candidate build under the new rule match 6/6 | manual-equivalent command (measurement, phase evidence) | see "Measurement commands" | evidence only |
| REL-08 | No regression of the iOS default-generation gate | existing | `mix test test/crosswake/release_candidate/` and CI on the PR | yes |

### Red-before-fix and green-after-fix (required, zero-human)
```bash
# 1. Add the new test and fixtures only, leave artifact.ex unchanged:
mix test test/crosswake/release_candidate/artifact_real_tarball_test.exs      # MUST exit non-zero (equality test red)
# 2. Apply the artifact.ex change:
mix test test/crosswake/release_candidate/artifact_real_tarball_test.exs      # MUST exit 0
# 3. Guards that watch new assertions and test ownership:
elixir script/check_absence_is_not_success.exs      # baseline exit 0
elixir script/check_exunit_ownership.exs            # baseline exit 0
mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
elixir script/check_release_workflow_integrity.exs  # baseline exit 0 (only if a workflow file changes)
```

### Measurement commands (before the proof is trusted on 0.2.14; keep in phase evidence, not CI)
```bash
# M1: re-run the pre-fix defect on the real 0.2.13 family (6 public tarballs vs approved receipt of run 42633255271):
#     expect 1 of 6 metadata digests equal (core only) under the old rule, 5 of 5 companion diffs explained by build_env.
# M2: after the fix is committed on a clean checkout of the fix head (hex_artifacts.sh refuses a dirty tree or HEAD != --ref):
bash script/release_candidate/hex_artifacts.sh --ref "$(git rev-parse HEAD)" --output-dir <new-empty-dir> --manifest <new-dir>/artifacts.json
#     then fetch the six public 0.2.13 tarballs and run Artifact.inspect_cli! on them; expect metadata and payload digests equal 6/6.
# M3: toolchain-invariance control: repeat M2 once with Hex 2.5.1 (MIX_HOME holding hex-2.5.1) and once with Hex 2.7.0; expect identical manifests. This is the property the old rule lacked.
# M4: run history table above, regenerated from `docs/release-ledger/RELEASE-LEDGER.jsonl` plus `gh run view` for runs 38155320492 and 42639651064.
```
Success threshold: M2 and M3 6/6 equal on both toolchains. A non-zero count of unexplained differences means do not rely on 0.2.14 as the proof; investigate first.

### Sampling Rate
- **Per task commit:** the quick run command (about 1 s).
- **Per wave merge:** `mix test test/crosswake/release_candidate/ test/crosswake/proof/phase172_per_package_ref_test.exs` plus the three `elixir script/...` guards.
- **Phase gate:** hermetic full suite green, PR CI green on the exact head, then the 0.2.14 release run ends COMPLETE (the live proof). Check `script/ci_cost_report.sh` against its baseline after CI (advisory).

### Wave 0 Gaps
- [ ] `test/crosswake/release_candidate/artifact_real_tarball_test.exs` covering the four behaviors above
- [ ] `test/fixtures/hex_tarballs/` with the two real rulestead tarballs and a README recording how each was produced
- [ ] a single-artifact `@doc false` entry point in `Artifact` (or equivalent) so real single tarballs can be tested
- Framework install: none.

## Security Domain

`security_enforcement` is not disabled (key absent), so this section applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | no credentials touched; the fix and tests are credential-free |
| V3 Session Management | no | - |
| V4 Access Control | no (release gates unchanged) | AGENTS.md approval gate stays as is |
| V5 Input Validation | yes | `build_env!/1` fail-closed shape validation; tarball paths already guarded by `safe_relative_path!/1` |
| V6 Cryptography | yes | digests via `:crypto.hash(:sha256, ...)` and `:crypto.hash_equals/2` already in `Artifact`; no new crypto |
| V10/V14 Supply-chain integrity | yes | the proof's purpose; the fix must not weaken what a digest match asserts about content |

### Known Threat Patterns for this change

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Smuggling content through the now-excluded field | Tampering | exclusion only after exact-shape validation (`nil` or `[{"hex", semver}]`); files, requirements, links, description, licenses, elixir, app, name, version, build_tools remain digested; payload digest covers every file, mode and sha256 |
| Tampered registry tarball hidden by a weaker digest | Tampering | negative controls on real data prove a description, requirement, link or payload byte change still turns the proof red; Hex >= 2.5.2 verifies the registry checksum on fetch |
| Silent degradation (unknown future metadata key skipped) | Repudiation/Tampering | `@metadata_keys` allow-list unchanged; unknown keys raise `invalid!()` (fail closed) |
| Privacy leak via new fixtures/evidence | Information disclosure | fixtures are public Apache-2.0 Hex tarballs of this repo's own companion; no adopter data; run the privacy scan (`privacy-193.sh`, absolute paths as separate zsh args) before each push |

## Sources

### Primary (HIGH confidence)
- Repo files read this session: `lib/crosswake/release_candidate/artifact.ex`, `.../cleanroom.ex`, `script/release_candidate/hex_artifacts.sh`, `script/release_candidate/package_source_ref.sh`, `script/verify_companion_cleanroom.sh` (lines 196-282), `.github/workflows/exact-public-proof.yml`, `.github/workflows/release-please.yml` (exact-public job), `.github/workflows/hex-publish.yml` (recovery and fire drill), `.github/workflows/weekly-canary.yml`, `docs/release-ledger/RELEASE-LEDGER.jsonl`, `test/crosswake/release_candidate/artifact_test.exs`, `cleanroom_test.exs`, `.planning/.../200-08-BLOCKED.md`, `TODO-012`.
- GitHub Actions: run 42633255271 (candidate attestation, Hex 2.7.0, artifact `phase168-candidate-receipt-5a6a752...`), run 38155320492 (0.2.11: Hex 2.5.1, exact-public COMPLETE, six packages), job logs read via `gh run view --log`.
- hex.pm public tarballs fetched from `https://repo.hex.pm/tarballs/<pkg>-<version>.tar` for crosswake 0.2.13 and the five companions; `build_env` present only in the core (`[{<<"hex">>,<<"2.7.0">>}]`).
- Hex source `lib/mix/tasks/hex.build.ex` at v2.5.1, v2.5.2, v2.5.4, v2.6.0, v2.7.0 via `gh api` (build_env counts 0,0,0,2; `Map.put(:build_env, %{hex: Hex.version()})` in `meta_for/4` at v2.7.0).
- Executed reproductions: real `Artifact.inspect_cli!` on public tarballs with and without injected `build_env`; real Hex 2.7.0 rebuild of rulestead at its tag; prototype patched `Artifact` on all three variants.

### Secondary (MEDIUM confidence)
- Hex release notes (`gh api repos/hexpm/hex/releases`) for v2.6.0 and v2.7.0 (changelog statements about `build_env`, determinism, file exclusion).

### Tertiary (LOW confidence)
- None. The research-plan/provider cache seam was not used: every question was answerable from the repo, GitHub run logs, hex.pm and the Hex source directly.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new packages, toolchain versions read from logs and `.tool-versions`.
- Architecture / root cause: HIGH, reproduced three independent ways (digest arithmetic on public tarballs, real Hex 2.7.0 rebuild, run history 0.2.11 vs 0.2.13).
- Fix design and which side is wrong: HIGH on mechanism, MEDIUM on "all six vs companions only" (user preference).
- 0.2.14 sequencing (PR 283 head refresh, receipt regeneration): MEDIUM, read from plans and workflows, not executed.
- Pitfalls: HIGH for 1-4, MEDIUM for 5 (latent, unobserved).

**Research date:** 2026-11-09
**Valid until:** 2026-11-16 (Hex is releasing roughly weekly; re-read the Hex release list and re-run M3 if a newer Hex ships before the 0.2.14 run)
