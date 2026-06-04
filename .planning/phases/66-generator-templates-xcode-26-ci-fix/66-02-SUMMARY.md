---
requirements-completed: []
---
# Plan 02 Summary

- Created `CrosswakeShell.entitlements.eex` and `PrivacyInfo.xcprivacy.eex` in `priv/templates/crosswake/shell/ios/` with `ADOPT: CROSSWAKE` scaffolds conditionally populated based on `@capabilities`.
- Updated `Info.plist.eex` and `AndroidManifest.xml.eex` to conditionally emit required usage descriptions and permissions with `ADOPT: CROSSWAKE` markers based on `@capabilities`.
- Updated `lib/mix/tasks/crosswake.gen.shell.ex` to extract `--router` argument, retrieve capabilities from the compiled manifest (defaulting to the public capability list), and pass them to the templates.
