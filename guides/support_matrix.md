# Crosswake Support Matrix

This guide stays narrow and proof-oriented. The published iOS and Android shell claims
below are backed by the checked-in example hosts plus the generated-shell verification
hooks that now pass on the same host-owned artifact classes adopters ship.

## Status Legend

- supported
- verification required
- unsupported

## Phoenix

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| phoenix | ~> 1.8 | supported | phase-2-proof-lane | - | Phoenix host install and manifest generation are the stable baseline. |

## LiveView

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| phoenix_live_view | ~> 1.1 | supported | phase-2-proof-lane | [View Boundaries](offline.md#boundary-warnings--rough-edges) | LiveView remains server-owned and route-first. |

## iOS

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| ios | 17.0 | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned iOS shell boot is proof-backed by the checked-in example host and generated-shell verification hook. |

## Android

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| android | 26 | supported | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned Android shell boot is proof-backed by the checked-in example host and generated-shell verification hook. |

## Shell Artifacts

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| ios_shell | 0.1.0 | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated iOS shell artifacts are supported while the Phase 5 iOS verification hook stays green. |
| android_shell | 0.1.0 | supported | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated Android shell artifacts are supported while the Phase 5 Android verification hook stays green. |
