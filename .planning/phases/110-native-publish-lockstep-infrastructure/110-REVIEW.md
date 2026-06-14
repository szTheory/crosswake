---
phase: 110-native-publish-lockstep-infrastructure
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/release-please.yml
  - .release-please-manifest.json
  - SETUP.md
  - mix.exs
  - packages/crosswake-shell-core-android/build.gradle.kts
  - release-please-config.json
findings:
  critical: 3
  warning: 6
  info: 4
  total: 13
status: issues_found
---

# Phase 110: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This phase wires release/publish infrastructure: a release-please lockstep config + manifest, a
GitHub Actions workflow with Hex/iOS/Android publish jobs plus dispatch-only fire-drill and
lockstep-assertion lanes, the Android Maven Central publish config, and the SETUP.md credential
runbook.

The action pinning (all third-party actions pinned to commit SHAs), secret handling (no echoing,
preflight presence checks), and shell-step hygiene (`set -euo pipefail` on the non-trivial steps)
are good. However there are three release-blocking defects that would cause this infrastructure to
either silently never run, mislabel the published artifact's license, or drop the wrong Maven
deployment. There are also several correctness gaps around the version-coordinate lockstep that the
phase's own self-test job will not catch.

## Critical Issues

### CR-01: All publish jobs gated on wrong output name (`release_created` vs `releases_created`) — publish path silently never fires

**File:** `.github/workflows/release-please.yml:33,54,128,161`
**Issue:** The `release-please` job exposes `release_created` (singular) and the four downstream
jobs gate on `needs.release-please.outputs.release_created == 'true'`. With a **manifest-driven
config using the `linked-versions` plugin and multiple packages** (which this config is —
`release-please-config.json` defines `.`, `packages/crosswake-shell-core-ios`,
`packages/crosswake-shell-core-android`), `googleapis/release-please-action@v4` emits the
**plural** `releases_created` as the aggregate flag, plus per-path outputs like
`<path>--release_created`. The singular top-level `release_created` is a single-package-mode
output and will be empty/undefined here. Result: `'' == 'true'` is false, so `publish-hex`,
`publish-ios-core`, and `publish-android-core` are **all skipped on every release** — the entire
publish path is dead. The phase's own SETUP.md (line 246) even describes the gate as
"`releases_created`", contradicting the workflow.
**Fix:** Use the plural aggregate output (and the path-scoped tag/version outputs):
```yaml
    outputs:
      releases_created: ${{ steps.release.outputs.releases_created }}
      hex_release_created: ${{ steps.release.outputs['--release_created'] }}
      tag_name: ${{ steps.release.outputs['--tag_name'] }}
      version: ${{ steps.release.outputs['--version'] }}
# then on each publish job:
    if: ${{ needs.release-please.outputs.releases_created == 'true' }}
```
Verify the exact output keys against the action version (`v4.1.3`) before merging — the per-path
prefix is the package path (`.` → empty prefix → `--release_created`). Do not ship until a
`workflow_dispatch` dry run confirms the outputs resolve non-empty.

### CR-02: Android artifact published with the wrong license (MIT) — repo + Hex are Apache-2.0

**File:** `packages/crosswake-shell-core-android/build.gradle.kts:54-57`
**Issue:** The POM declares `name.set("MIT License")` with the MIT URL. The repository `LICENSE`
file is Apache 2.0, and `mix.exs:72` publishes the Hex package as `licenses: ["Apache-2.0"]`.
Publishing the Android artifact to Maven Central under MIT misrepresents the license of the same
project's code to every downstream consumer, and is immutable once `PUBLISHED` (Central Portal
does not allow re-publishing the same coordinate). This is a legal/correctness defect, not a style
nit. Note the fire-drill POM check (line 260) only greps for the presence of a `<license` tag — it
will pass with the wrong license, so the self-test does not catch this.
**Fix:**
```kotlin
        licenses {
            license {
                name.set("The Apache License, Version 2.0")
                url.set("https://www.apache.org/licenses/LICENSE-2.0.txt")
                distribution.set("repo")
            }
        }
```

### CR-03: Fire-drill drops `deployments[0]` from a state-filtered list — can DROP an unrelated/concurrent deployment

**File:** `.github/workflows/release-please.yml:286-323`
**Issue:** The validated-upload→drop loop queries
`/deployments?size=10&state=VALIDATED`, then blindly takes `deployments[0]['id']` and issues a
`DELETE` against it. There is no correlation between the uploaded artifact and the deployment that
gets dropped — `deployments[0]` is simply whatever the API returns first. If any *other* validated
deployment exists for the account (a concurrent real release in `publish-android-core`, a
left-over validated deployment from a prior run, a different artifact pending manual release), the
fire-drill will `DELETE` that deployment instead of its own. Because the fire-drill is described as
a "mandatory pre-publish rehearsal" run "before every real release," it is specifically likely to
race with or clobber a legitimately validated deployment. Same flaw applies to the `FAILED` branch
(line 288-296), which `exit 1`s on *any* failed deployment in the account, not necessarily this
run's.
**Fix:** Capture the deployment ID returned by the upload itself and poll/drop only that ID. The
Gradle/Central publish plugin or the upload API response yields a deployment ID — persist it and
filter the list by that ID rather than taking index `[0]`. At minimum, filter by the artifact's
`deploymentName`/coordinate+version and assert exactly one match before deleting:
```bash
# pseudo: extract this run's deployment id from the publish output, then
MATCH=$(curl ... | python3 -c "import sys,json;d=json.load(sys.stdin);\
  ids=[x['id'] for x in d.get('deployments',[]) if x.get('deploymentName')=='$EXPECTED'];\
  print(ids[0] if len(ids)==1 else '')")
[ -n "$MATCH" ] || { echo 'no unambiguous match; refusing to drop'; exit 1; }
```

## Warnings

### WR-01: `release-as: "0.1.2"` on root only — linked-versions vs manifest baseline can desync the lockstep

**File:** `release-please-config.json:16` / `.release-please-manifest.json:1-5`
**Issue:** The root package pins `"release-as": "0.1.2"` while the manifest records all three
components at `0.1.0`, and only `.` carries `release-as`. The `linked-versions` plugin is supposed
to drag `ios-core`/`android-core` up to match, but `release-as` is a forced override that
interacts unpredictably with linked-versions — the documented behavior is that `release-as`
applies to the package it is set on, and linked-versions then reconciles the group to the highest.
The intended jump is 0.1.0 → 0.1.2 (skipping 0.1.1), which is unusual and undocumented in the
config comments. If linked-versions does not propagate `release-as` to the native components, the
release PR will bump Hex to 0.1.2 while the native coordinates follow their own conventional-commit
bump, silently breaking the lockstep this phase exists to guarantee.
**Fix:** Either set `release-as: "0.1.2"` on all three packages explicitly, or remove it and let
conventional commits drive the bump. Document why 0.1.1 is skipped. Add a post-release assertion
(reuse `lockstep-truth`) that runs *after* the release PR is generated, not just on dispatch.

### WR-02: `lockstep-truth` self-test asserts the wrong invariant — passes while config will produce a mismatch

**File:** `.github/workflows/release-please.yml:330-372`
**Issue:** The job asserts `mix.exs == build.gradle.kts == manifest['.'] == manifest['android']`,
all currently `0.1.0` — so it passes. But it does **not** validate the iOS component
(`packages/crosswake-shell-core-ios` in the manifest), and it does not account for
`release-as: "0.1.2"` in the config. The "lockstep is correct" claim is therefore only checking
that the *current source baselines* agree, not that the *release machinery* will keep them in
lockstep. It will report "LOCKSTEP OK" even though the next release will push Hex to 0.1.2 (per
WR-01).
**Fix:** Include the iOS manifest baseline in the equality check, and add an assertion that the
config's `release-as` (if present) is consistent across packages or absent. Read the iOS coordinate
the same way the other three are read.

### WR-03: `Verify release version in mix.exs` uses the possibly-empty `version` output and an unanchored grep

**File:** `.github/workflows/release-please.yml:87-88`
**Issue:** `grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs` — if the
top-level `version` output is empty (see CR-01, manifest mode emits path-scoped outputs), this
becomes `grep -n '@version ""' mix.exs`, which fails the step with a confusing message. Even when
populated, the pattern is not anchored and would match a substring version (e.g. searching `0.1.2`
matches `0.1.20`). The interpolated value is injected directly into the `grep` pattern.
**Fix:** Use the path-scoped output and a fixed-string/anchored match, passing the value via env to
avoid interpolation into the command line:
```yaml
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          set -euo pipefail
          [ -n "$VERSION" ] || { echo "empty version output"; exit 1; }
          grep -Fq "@version \"${VERSION}\" # x-release-please-version" mix.exs
```

### WR-04: `publish-ios-core` mirror-push step has no `set -euo pipefail` and silently tolerates a stale remote

**File:** `.github/workflows/release-please.yml:152-156`
**Issue:** Unlike the other multi-line steps, the "Push split to mirror and tag" step does not set
`pipefail`/`-e`. `git remote add mirror ...` fails non-fatally only if pipefail is off and the line
is the last in a `&&` chain — here each command is on its own line, so `-e` would be the safety
net, but it is absent. If `git remote add` fails (remote already exists from a retry) the step
keeps going; more importantly without `-e` a failed `git push mirror "${SPLIT_SHA}:refs/heads/main"`
would not necessarily fail the job depending on shell behavior, allowing the tag push to be skipped
or the job to report success on a partial mirror. The split-SHA push to `refs/heads/main` is also a
non-forced update that will fail on the second-ever release (mirror main already has history) — the
runbook (SETUP.md:190-192) acknowledges this only for the *first* push.
**Fix:** Add `set -euo pipefail` at the top of the `run:` block; use
`git remote add mirror ... || git remote set-url mirror ...` for idempotency; and confirm the
intended ref update for `refs/heads/main` on subsequent releases (fast-forward vs the subtree-split
SHA history is not guaranteed to be a descendant).

### WR-05: `splitsh-lite` downloaded over the network without checksum/signature verification

**File:** `.github/workflows/release-please.yml:138-141`
**Issue:** The iOS mirror job `curl -L`s a `lite_linux_amd64.tar.gz` from a GitHub release and
`sudo mv`s the extracted binary into `/usr/local/bin` with no SHA-256 / signature check. A
compromised or swapped release asset would run with the job's privileges and has access to
`MIRROR_PUSH_TOKEN` in the following step. This is the standard supply-chain pin gap — the rest of
the workflow correctly pins actions to SHAs, but this binary is unpinned by digest.
**Fix:** Pin and verify the download:
```bash
set -euo pipefail
EXPECTED=<known-sha256>
curl -fsSL -o lite.tgz https://github.com/splitsh/lite/releases/download/v2.0.0/lite_linux_amd64.tar.gz
echo "${EXPECTED}  lite.tgz" | sha256sum -c -
tar xzf lite.tgz
sudo mv splitsh-lite /usr/local/bin/splitsh-lite
```

### WR-06: Hex verify and Central polling loops use `curl -fs ... | python3`/`grep` where a transport error and a "not yet ready" are indistinguishable

**File:** `.github/workflows/release-please.yml:114-122, 288-303`
**Issue:** In `Verify version on Hex.pm`, `curl -fsS ... | grep -q` inside `if` masks the difference
between "Hex 404 (not indexed yet)" and a genuine network/DNS failure — both just retry until the
36-attempt timeout. In the Central poll, `curl -fs ... | python3 ... 2>/dev/null || echo ""`
swallows auth failures (401/403 from wrong `MAVEN_USERNAME`/`PASSWORD`) and JSON parse errors as
"empty," so a misconfigured credential presents as "timed out waiting for VALIDATED" after 5
minutes rather than failing fast with the real cause. Combined with `set -euo pipefail`, the
`|| echo ""` deliberately defeats `-e` for these curls.
**Fix:** Distinguish HTTP status from emptiness — capture the status code separately
(`curl -s -o body -w '%{http_code}'`), `exit 1` immediately on 401/403/5xx, and only treat 404 /
empty-list as the retry condition.

## Info

### IN-01: Android `kotlinx-serialization` and Kotlin/AGP plugins declared without versions and no version catalog/buildscript classpath

**File:** `packages/crosswake-shell-core-android/build.gradle.kts:1-6`
**Issue:** `id("kotlinx-serialization")`, `id("com.android.library")`, and
`id("org.jetbrains.kotlin.android")` carry no `version`, and `settings.gradle.kts` has no
`pluginManagement { plugins { ... } }` version block, version catalog, or root buildscript
classpath. `./gradlew publishToMavenCentral` will fail to resolve these plugins unless a parent
build supplies versions. This predates the phase but the publish job (line 183) is the first thing
to depend on it resolving standalone. Confirm the publish runner resolves all plugin versions.
**Fix:** Declare plugin versions in `settings.gradle.kts` `pluginManagement.plugins` or pin them
inline, and run the fire-drill `workflow_dispatch` once to prove the standalone build resolves.

### IN-02: `inceptionYear` 2024 vs runbook/phase dates of 2026

**File:** `packages/crosswake-shell-core-android/build.gradle.kts:50`
**Issue:** `inceptionYear.set("2024")` while SETUP.md is dated 2026 and the project's first release
is `0.1.x`. Minor metadata inconsistency; harmless but worth confirming the intended inception
year for the published POM.
**Fix:** Confirm and set the correct inception year.

### IN-03: SETUP.md hardcodes a personal email and account identity throughout the runbook

**File:** `SETUP.md:77,97,149,159,375` (and the `developer`/`scm` blocks in build.gradle.kts)
**Issue:** `qiksnare13@gmail.com` and `szTheory` are embedded in the committed runbook and POM. Not
a secret, but it ties published artifacts and committed docs to a personal email used for GPG
keyserver confirmation and the Sonatype account. Consider a role/project alias for the published
`developer` metadata to avoid leaking a personal address into every Maven POM consumer fetches.
**Fix:** Use a project contact alias in the POM `developer` block and runbook where a public-facing
email would otherwise be exposed.

### IN-04: `concurrency` cancels in-progress release-please runs — a publish-in-flight could be cancelled mid-publish

**File:** `.github/workflows/release-please.yml:24-26`
**Issue:** `cancel-in-progress: true` on the whole-workflow concurrency group means a new push to
`main` while `publish-hex`/`publish-android-core` is mid-publish will cancel the running workflow.
A cancellation between `mix hex.publish` and `Verify version on Hex.pm`, or mid Maven upload, can
leave a partially-completed publish with no verification. Cancellation is appropriate for the
release-please PR-management job but risky for the publish jobs.
**Fix:** Scope `cancel-in-progress: true` to the release-please planning job only, and use a
separate non-cancelling concurrency group (or no cancellation) for the publish jobs.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
