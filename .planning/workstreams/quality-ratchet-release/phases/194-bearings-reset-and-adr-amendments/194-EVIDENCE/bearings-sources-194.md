# BEARINGS tripwire sources (194-04)

Each path was checked with `git ls-files --error-unmatch`; PRs with `gh pr view`. A claim is kept only with two or more sources. BEARINGS uses the heading "Tripwires: check at plan time" and carries no "at least twice" wording, because three tripwires have fewer than two verified sources.

| tripwire | source 1 | source 2 | more | claim kept |
|---|---|---|---|---|
| Check with no negative control | PR #173 | .planning/seeds/SEED-018-vacuous-collection-assertions.md | | yes |
| Check pins the false value | .planning/seeds/SEED-022-sha-pin-provenance-audit.md | | | no (1 source) |
| Piped gate reports the tail status | | | | no (0 verified in repo) |
| Status written before the event goes stale | .planning/seeds/SEED-021-verification-fingerprint-stales-on-successor-edits.md | .planning/workstreams/quality-ratchet-release/milestones/v26.0-MILESTONE-AUDIT.md | .planning/workstreams/quality-ratchet-release/milestones/v27.0-MILESTONE-AUDIT.md | yes |
| Deferral without a receiver | .planning/workstreams/quality-ratchet-release/milestones/v26.0-MILESTONE-AUDIT.md | .planning/workstreams/quality-ratchet-release/milestones/v27.0-MILESTONE-AUDIT.md | .planning/workstreams/quality-ratchet-release/milestones/v27.0-closeout/debt-disposition.md | yes |
| Recurring gate living only in a phase folder | .planning/workstreams/quality-ratchet-release/milestones/v27.0-MILESTONE-AUDIT.md | .planning/workstreams/quality-ratchet-release/milestones/v27.0-closeout/CLOSEOUT.md | PR #173 | yes |
| Simulator-green is not device-green | .planning/seeds/SEED-013-adopter-device-proof-lane-reachability.md | .planning/seeds/SEED-015-sso-cold-boot-cross-origin-loses-native-layer.md | | yes |
| Line-number citations rot | .planning/seeds/SEED-006-native-navigation-shell.md | .planning/seeds/SEED-013-adopter-device-proof-lane-reachability.md | | yes |
| Path-dependency rehearsals miss published-core resolution | .planning/seeds/SEED-004-cleanroom-proof-harness.md | .planning/seeds/SEED-003-ios-mirror-push-token.md | | yes |
| Hand-maintained version/date tables drift | | | | no (0 verified in repo) |
