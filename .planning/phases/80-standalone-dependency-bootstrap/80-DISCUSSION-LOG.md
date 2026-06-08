# Phase 80: Standalone Dependency Bootstrap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 80-standalone-dependency-bootstrap
**Areas discussed:** Dependency Version Strategy, Host Structure

---

## Dependency Version Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Update existing projects | Modify `examples/ios_shell_host` and `examples/android_shell_host` | ✓ |
| Create new projects | Start fresh in `examples/demo_ios`, etc. | |

**User's choice:** Autonomous decision (YOLO mode)
**Notes:** Proceeding with updating existing example hosts to keep project structure clean and directly migrate the "old way" to the "new way".

---

## Host Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Remove generated code | Native hosts must not contain generated ActivationCoordinator/BridgeChannel | ✓ |
| Keep generated code | Allow partial generation for some components | |

**User's choice:** Autonomous decision (YOLO mode)
**Notes:** Adhering strictly to SETUP-02 requirement which mandates zero generated `ActivationCoordinator` or `BridgeChannel` source files.

---

## Claude's Discretion

- Selected SwiftUI and Jetpack Compose for any new UI components required by the demo apps.
- Opted to pin to the released packages over local source paths to accurately simulate adoption evidence.

## Deferred Ideas

None
