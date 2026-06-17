---
status: passed
phase: 110-native-publish-lockstep-infrastructure
source: [110-VERIFICATION.md]
started: 2026-06-14T20:30:00Z
updated: 2026-06-17T15:45:00Z
---

## Current Test

[all 4 passed — credentials provisioned and 0.1.2 shipped 2026-06-17]

## Tests

### 1. Android publish fire-drill (validated-upload → drop)
expected: After provisioning all 8 secrets per SETUP.md, dispatching the `android-publish-fire-drill` workflow_dispatch lane: preflight passes (all 8 secrets present), local publish produces AAR + sources.jar + javadoc.jar + POM + each `.asc` in `~/.m2`, POM fields validate, Central Portal upload reaches VALIDATED, the deployment is DROPped via DELETE, and the job reports "Version coordinate is FREE".
result: PASS (2026-06-17). After fixing two latent bugs the drill exposed (artifact-name classifier assertion; Central Portal poll using Basic auth + a non-existent list endpoint → rewritten to Bearer + POST /upload → POST /status?id= → DELETE /deployment/{id}), run 27698696683 uploaded, reached VALIDATED (2/2 components), and DROPped deployment 0764a5d6 — "Version coordinate is FREE".

### 2. Lockstep-truth CI lane
expected: Dispatching the `lockstep-truth` workflow_dispatch lane completes with "LOCKSTEP OK: all coordinates agree on version 0.1.0" — the four coordinates (mix.exs @version, build.gradle.kts version, manifest `.` and android baselines) are mutually consistent.
result: PASS (2026-06-17). Dispatched lanes (runs 27698696683 / 27695996838) completed with "LOCKSTEP OK".

### 3. GPG public key discoverable on two keyservers
expected: `gpg --keyserver keys.openpgp.org --recv-keys <KEYID>` (and `keyserver.ubuntu.com`) returns "imported: 1" from a clean environment.
result: PASS (2026-06-17). Key 6F3BDA6B (UID szTheory@users.noreply.github.com, primary signing key, no subkey) live on keys.openpgp.org (VKS by-fingerprint 200) and keyserver.ubuntu.com. Implicitly confirmed by Central accepting the signature at VALIDATED.

### 4. Sonatype namespace `io.github.sztheory` verified
expected: Login to central.sonatype.com confirms the `io.github.sztheory` namespace is verified and active.
result: PASS (2026-06-17). `io.github.sztheory` shows under central.sonatype.com → Namespaces (auto-provisioned via GitHub OAuth); operationally proven by the fire-drill reaching VALIDATED (2/2 components) and the real 0.1.2 Android publish landing on Maven Central (repo1.maven.org 200).

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- All 8 secrets provisioned (verified via `gh secret list`); 0.1.2 shipped to Hex + Maven Central + SwiftPM mirror on 2026-06-17.
- RESIDUAL: `MIRROR_PUSH_TOKEN` scope is still unexercised — the splitsh-lite v2.0.0 404 failed before the iOS push, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. Scope validated on the first iOS mirror of the next release.
- Pipeline bugs found during the live run are fixed on main (PRs #20/#21/#22): artifact-name assertion, Android auto-publish, Central Portal API auth/endpoint, splitsh-lite version.
