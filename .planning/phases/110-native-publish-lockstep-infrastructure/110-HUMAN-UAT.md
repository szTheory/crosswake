---
status: partial
phase: 110-native-publish-lockstep-infrastructure
source: [110-VERIFICATION.md]
started: 2026-06-14T20:30:00Z
updated: 2026-06-14T20:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Android publish fire-drill (validated-upload → drop)
expected: After provisioning all 8 secrets per SETUP.md, dispatching the `android-publish-fire-drill` workflow_dispatch lane: preflight passes (all 8 secrets present), local publish produces AAR + sources.jar + javadoc.jar + POM + each `.asc` in `~/.m2`, POM fields validate, Central Portal upload reaches VALIDATED, the deployment is DROPped via DELETE, and the job reports "Version coordinate is FREE".
result: [pending]
why_human: Requires provisioned credentials (8 GitHub Actions secrets), a real Sonatype account, a GPG key on keyservers, and live Central Portal network access. Cannot be verified by static analysis.

### 2. Lockstep-truth CI lane
expected: Dispatching the `lockstep-truth` workflow_dispatch lane completes with "LOCKSTEP OK: all coordinates agree on version 0.1.0" — the four coordinates (mix.exs @version, build.gradle.kts version, manifest `.` and android baselines) are mutually consistent.
result: [pending]
why_human: Requires a GitHub Actions runner to dispatch and observe job output. The assertion logic is verified locally (all four agree on 0.1.0), but the CI job itself has not run.

### 3. GPG public key discoverable on two keyservers
expected: `gpg --keyserver keys.openpgp.org --recv-keys <KEYID>` (and `keyserver.ubuntu.com`) returns "imported: 1" from a clean environment.
result: [pending]
why_human: Requires a human to run SETUP.md sections 3–4: generate the GPG keypair (primary-key-with-signing, no signing subkey), export, upload to both keyservers, verify receipt. Cannot be checked from code.

### 4. Sonatype namespace `io.github.sztheory` verified
expected: Login to central.sonatype.com confirms the `io.github.sztheory` namespace is verified and active.
result: [pending]
why_human: No status API exists for Central Portal namespace verification — documented as a known preflight blind spot in SETUP.md.

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
