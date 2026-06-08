# Phase 81: Reactive State & Event Bridge - Discussion Log

**Date:** 2026-06-08

## Captured Decisions

### Connection Status UI
- **Presented Options:** Subtle native indicator, Modal dialog, Debug log only.
- **Selected:** Subtle native indicator (Auto-selected default).
- **Notes:** Ensures the user is informed without being intrusive.

### Toast Event Design
- **Presented Options:** Native Snackbar/Toast, Custom SwiftUI/Compose overlay, Alert dialog.
- **Selected:** Native Snackbar/Toast (Auto-selected default).
- **Notes:** Keeps the experience aligned with platform conventions.

### Lifecycle Management
- **Presented Options:** Tie to View lifecycle, Tie to Application lifecycle, Global singleton.
- **Selected:** Tie to View lifecycle (Auto-selected default).
- **Notes:** Prevents memory leaks and unexpected background state updates.

## Deferred Ideas
None.