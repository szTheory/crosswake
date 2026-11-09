# 200-08 blocked: release run 42639651064 ended FAILURE after every publish succeeded

Facts (read 2026-11-09, not inferred):
- Published: Hex crosswake 0.2.13 (with docs), Maven io.github.sztheory:crosswake-shell-core-android 0.2.13 (POM and AAR 200), iOS mirror tag v0.2.13 (mirror main 095267ea, same tree as 0.2.12).
- Passed: clean-room proof for iOS swift build (the 0.2.12 failure is fixed), Android clean-room, ios mirror tag check. Local mirror checks: 0.2.13 PASS; 0.2.12 FAIL reason=newer_mirror_tag (expected).
- Failed: `release: exact-public artifact proof` (job 129269470649) and so `release: linked release rollup` (job 129273886435). Verdict `state=BLOCKED`: crosswake fully_proven; the five companions (rulestead 0.1.1, rindle 0.1.0, sigra 0.1.3, chimeway 0.1.2, threadline 0.1.0) reason=digest_mismatch, claim unproven. All five profile installs and negative controls PASS.
- This was the first live run of that proof: in 0.2.12 it was skipped because the iOS job failed first.

Reading of the code (lib/crosswake/release_candidate/cleanroom.ex `public_artifact_reason`): digest_mismatch means the public Hex tarball's candidate ref equals the approved candidate ref (each companion's own published tag commit) while its metadata or payload digest differs from the digest the candidate run rebuilt (approved manifest from run 42633255271). So the registry tarball and the rebuilt tarball of an unchanged companion differ. Which digest differs and why is NOT yet established.

Not done, by rule: no re-run, no re-approval, no retry of any step.
Next: diagnose which digest differs for each companion (metadata vs payload) from the Hex tarball vs a rebuild at the tag commit; then decide a forward fix (proof expectation, not the release).

## Diagnosis so far (2026-11-09, read-only, nothing published or re-run)

Measured with the proof's own `Artifact.inspect_cli!` on the public Hex tarballs against the approved manifest from candidate run 42633255271 (artifact `phase168-candidate-receipt-5a6a752185cc557af30b0f87244b8088ac83ff93`):
- Core `crosswake` 0.2.13: metadata and payload digests both match.
- All five companions: payload digest matches (file list, modes and sha256 identical); `metadata_digest` differs (rulestead public 5e444f8c vs approved edff10ce; rindle 7c0765a3 vs 608a7cf1; sigra 76d69c05 vs b19af602; chimeway b791d5ee vs cae518f2; threadline 794181a8 vs 05c50af1). The normalized `requirements` lists are identical.
- A local rebuild of the family at the approved head (`hex_artifacts.sh`, no credentials) gave companion metadata digests EQUAL to the public ones, not the approved ones. So the approved CI digest is the odd one out, or the CI build differs from a local build in some metadata field not visible in the manifest.
- Not the cause (tested): any single metadata key dropped; a `build_env` key with prod, dev, test or docs.
- Mechanism: `package_source_ref.sh` returns the same tag commit in candidate and public mode for a published companion, so the proof's "reachable_and_compatible" branch cannot occur for companions; it demands a bit-identical rebuild of metadata.

Still unknown: which metadata field differs in the CI-built candidate. Next step needs the CI candidate's tarball metadata (the candidate run uploaded only the receipt, not tarballs) or a run that prints it.
