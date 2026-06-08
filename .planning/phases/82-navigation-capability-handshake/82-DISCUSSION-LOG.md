# Phase 82: Navigation & Capability Handshake - Discussion Log

**Date:** 2026-06-08

## Areas Discussed

### 1. Native Route Mapping (Navigation Triggering)
- **Options presented:** Hardcoded switch vs. Registry/Delegate pattern.
- **Selection:** Registry/Delegate pattern.
- **Notes:** Keeps host-specific screens out of the standalone shell dependency. Excellent DX, fail-closed design.

### 2. Capability Handshake Timing
- **Options presented:** Headers/params during socket connect vs. Immediate bridge event after connect.
- **Selection:** Connection params during socket connect.
- **Notes:** Idiomatic Phoenix pattern. Prevents race conditions and flashes of unsupported UI on initial mount.

### 3. Return Flow from Native Screen
- **Options presented:** Dismiss + bridge event vs. Dismiss + generic refresh/polling.
- **Selection:** Native dismissal + explicit bridge event.
- **Notes:** Explicit state management. Fits perfectly with the bounded, request/reply bridge contract.

## Deferred Ideas
- None
