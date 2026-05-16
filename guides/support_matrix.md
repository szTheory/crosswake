# Crosswake Support Matrix

This guide stays narrow and proof-oriented. A `supported` shell claim is blocked and
remains `verification required` until both generated-project proof hooks pass on the
same host-owned iOS and Android shell artifacts adopters ship.

## Status Legend

- supported
- verification required
- unsupported

## Phoenix

| Target | Version | Status | Proof | Notes |
|--------|---------|--------|-------|-------|
| phoenix | ~> 1.8 | supported | phase-2-proof-lane | Phoenix host install and manifest generation are the stable baseline. |

## LiveView

| Target | Version | Status | Proof | Notes |
|--------|---------|--------|-------|-------|
| phoenix_live_view | ~> 1.1 | supported | phase-2-proof-lane | LiveView remains server-owned and route-first. |

## iOS

| Target | Version | Status | Proof | Notes |
|--------|---------|--------|-------|-------|
| ios | 17.0 | verification required | script/verify_generated_ios_shell.sh | Host-owned shell boot is only published after the generated-project proof hook passes. |

## Android

| Target | Version | Status | Proof | Notes |
|--------|---------|--------|-------|-------|
| android | 26 | verification required | script/verify_generated_android_shell.sh | Host-owned shell boot is only published after the generated-project proof hook passes. |

## Shell Artifacts

| Target | Version | Status | Proof | Notes |
|--------|---------|--------|-------|-------|
| ios_shell | 0.1.0 | unsupported | script/verify_generated_ios_shell.sh | Unsupported until both platform proof hooks have passed together. |
| android_shell | 0.1.0 | unsupported | script/verify_generated_android_shell.sh | Unsupported until both platform proof hooks have passed together. |
