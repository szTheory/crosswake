# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- 🔄 **v11.0 Release & Distribution Truth** — Phases 110-111 (active 2026-06-14)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

</details>

<details>
<summary>✅ v9.0 Brand System & Visual Identity (Phases 102-106) — SHIPPED 2026-06-13</summary>

- [x] Phase 102: Brand Audit & Token Foundation (4/4 plans) — completed 2026-06-12
- [x] Phase 103: Logo Tournament (4/4 plans) — completed 2026-06-12
- [x] Phase 104: Logo Refinement & Production Suite (3/3 plans) — completed 2026-06-12
- [x] Phase 105: HTML Brand Book (3/3 plans) — completed 2026-06-12
- [x] Phase 106: Collateral, Integration & Closeout (2/2 plans) — completed 2026-06-13

Full phase detail archived in `.planning/milestones/v9.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v10.0 Brand Normalization (Phases 107-109) — SHIPPED 2026-06-14</summary>

- [x] Phase 107: Token Source & Distribution (3/3 plans) — completed 2026-06-13
- [x] Phase 108: Consumer Normalization (4/4 plans) — completed 2026-06-14
- [x] Phase 109: Drift-Prevention Gate (3/3 plans) — completed 2026-06-14

Full phase detail archived in `.planning/milestones/v10.0-ROADMAP.md`.

</details>

### v11.0 Release & Distribution Truth (Phases 110-111)

- [ ] **Phase 110: Native Publish & Lockstep Infrastructure** - Publish iOS core to subtree-mirror repo with semver tags, publish Android core to Maven Central, wire release-please linked-versions so all three registries advance together
- [ ] **Phase 111: Generator Rewire, Clean-Room Proof & Release** - Rewire gen.shell templates to published coordinates with version derived from Application.spec, prove the thesis outside the monorepo via clean-room CI, add permanent published-dep parity check, reconcile docs, cut Hex 0.1.2

## Phase Details

### Phase 110: Native Publish & Lockstep Infrastructure
**Goal**: Published native cores exist at correct coordinates and lockstep versioning ensures one release bumps all three registries
**Depends on**: Nothing (first phase of v11.0)
**Requirements**: PUB-01, PUB-02, PUB-03, LOCK-01, LOCK-02
**Success Criteria** (what must be TRUE):
  1. Running `swift package resolve` against `github.com/szTheory/crosswake-shell-core-ios` with a semver tag resolves successfully from a clean environment outside the monorepo
  2. `io.github.sztheory:crosswake-shell-core-android:0.1.2` is visible in Maven Central search and resolves via `mavenCentral()` in a clean Gradle project
  3. A GPG public key is on at least two public keyservers, Central Portal namespace `io.github.sztheory` is verified, all five `ORG_GRADLE_PROJECT_*` CI secrets are set, and a local dry-run (`publishToMavenLocal`) passes inspection before any real Central Portal publish
  4. Merging a release PR causes a single release-please run to advance Hex, the iOS mirror tag, and the Android Maven artifact to identical version numbers — no manual per-registry step required
  5. The `ios-mirror` and `android-publish` CI jobs live inside `release-please.yml` under `needs: release-please` + `if: releases_created` — there is no separate `release: published` listener that would silently never fire
**Plans**: TBD

### Phase 111: Generator Rewire, Clean-Room Proof & Release
**Goal**: An adopter outside this monorepo can add the Hex dep, run `mix crosswake.gen.shell` (default), and get iOS and Android projects that resolve published, version-matched deps and build — proven by a clean-room CI lane, guarded permanently by a published-dep parity check, and consolidated into the published Hex 0.1.2 release
**Depends on**: Phase 110 (cannot clean-room-prove an unpublished dep; template rewire targets final published coordinates that only exist after Phase 110)
**Requirements**: GEN-01, GEN-02, PROOF-01, PROOF-02, DOCS-01, REL-01
**Success Criteria** (what must be TRUE):
  1. Running `mix crosswake.gen.shell ios` and `mix crosswake.gen.shell android` (without `--local`) emits dep coordinates that include the live `crosswake` version derived from `Application.spec(:crosswake, :vsn)` — no literal version string appears in any non-local template branch
  2. A CI lane scaffolds a host project in `$RUNNER_TEMP` outside the monorepo (no `--local`, no access to `packages/`), runs `gen.shell`, and exits 0 after both `swift build` and `gradle build` resolve the published deps and compile
  3. Running `mix doctor --check-publish` (or equivalent parity check) fails the build if the generated native dep coordinates point at monorepo paths, unresolvable coordinates, or a version that does not match the published `crosswake` Hex version
  4. `guides/adoption.md` documents the actual published install path with no 404 URL and no install route that requires monorepo access; `guides/support_matrix.md` reflects current published truth
  5. Hex `0.1.2` is published and the published Hex package version, the iOS mirror tag, and the Android Maven artifact are all at `0.1.2` — an adopter adding the Hex dep and running `gen.shell` gets a buildable scaffold without any manual coordinate correction
**Plans**: TBD
**UI hint**: no

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 4/4 | Complete | 2026-06-12 |
| 103. Logo Tournament | v9.0 | 4/4 | Complete | 2026-06-12 |
| 104. Logo Refinement & Production Suite | v9.0 | 3/3 | Complete | 2026-06-12 |
| 105. HTML Brand Book | v9.0 | 3/3 | Complete | 2026-06-12 |
| 106. Collateral, Integration & Closeout | v9.0 | 2/2 | Complete | 2026-06-13 |
| 107. Token Source & Distribution | v10.0 | 3/3 | Complete | 2026-06-13 |
| 108. Consumer Normalization | v10.0 | 4/4 | Complete | 2026-06-14 |
| 109. Drift-Prevention Gate | v10.0 | 3/3 | Complete | 2026-06-14 |
| 110. Native Publish & Lockstep Infrastructure | v11.0 | 0/TBD | Not started | - |
| 111. Generator Rewire, Clean-Room Proof & Release | v11.0 | 0/TBD | Not started | - |
