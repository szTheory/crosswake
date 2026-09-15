---
id: TODO-008
title: Generated iOS shell letterboxes on every modern iPhone — no UILaunchScreen, synthesis disabled
status: open
created: 2026-09-15
severity: high
surfaced_by: First B2C Adopter launch-screen report (CW-REQ-M7), verified against this repo
relates_to: TODO-003, TODO-006, TODO-007, SEED-013, SEED-015
---

# Generated iOS shell runs in iOS legacy compatibility mode

## Outcome

`mix crosswake.gen.shell ios` produces an app that lays out at the device's true screen size on
every modern iPhone, without the adopter editing a generated file.

## The defect (verified in this repo, 2026-09-15)

Without `UILaunchScreen` or `UILaunchStoryboardName`, iOS lays the app out at an older, shorter
logical screen and scales the result in, padding with black bars top and bottom. Both halves of the
cause are in the templates:

- `priv/templates/crosswake/shell/ios/Info.plist.eex` — neither key is present. Confirmed: the
  plist carries `CFBundle*`, `LSRequiresIPhoneOS`, `UIApplicationSceneManifest` and
  `WKAppBoundDomains`, and no launch key at all.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex:319` (Release)
  and `:343` (Debug) — `GENERATE_INFOPLIST_FILE = NO;` on the **app** target (both configs also
  carry `INFOPLIST_FILE = CrosswakeShell/Info.plist;`, which is how the target was identified).
  The two `GENERATE_INFOPLIST_FILE = YES` entries at `:365`/`:387` are the test targets, not the app.

`grep -rn "UILaunchScreen\|UILaunchStoryboardName\|INFOPLIST_KEY_UILaunchScreen" priv/ lib/ test/`
returns **zero matches** repo-wide.

The second half is what makes it unrecoverable by the adopter: Xcode only synthesizes a launch
screen for a target that generates its own Info.plist. This target supplies its own, so the key is
absent from the template *and* cannot be supplied by the toolchain.

## Why an adopter will not diagnose this

The obvious fix is already present and is wrong. `CrosswakeShellApp.swift` applies
`.ignoresSafeArea()` correctly — but the app has already been scaled into a smaller logical screen
before SwiftUI lays out anything, so there is nothing inside the view hierarchy left to reclaim. An
adopter reaches for safe-area handling, finds it correct, and has no next move.

This is another **simulator-green / device-red**-shaped defect in the weak sense: it reproduces on
the Simulator, but a developer reads the bars there as a window-size artefact rather than a bug.

## The ask

Add to `Info.plist.eex`:

```xml
<key>UILaunchScreen</key>
<dict/>
```

An empty dict is correct and sufficient for a modern app: it opts into the native launch-screen
system and inherits a default background, which is exactly what a webview shell wants. It is not a
placeholder needing adopter configuration, so this needs **no new generator flag and no adopter
input** — unlike TODO-006 and TODO-007, this one is a pure template fix with no blocking dependency.

Rejected alternative, recorded so it is not re-litigated: `GENERATE_INFOPLIST_FILE = YES` plus
`INFOPLIST_KEY_UILaunchScreen_Generation = YES` also works, but it moves Info.plist ownership to
Xcode and breaks the "host-owned Info.plist is the single source" property the template header
already asserts. Prefer the empty dict.

## Suggested doctor check

`shell_launch_screen_missing` — assert the host-owned `Info.plist` carries one of the two launch
keys. This is the shape doctor already handles well: a structural fact about the generated shell
that an adopter cannot see. It would have caught this at generation time rather than on hardware.

Per SEED-013's CHANGELOG discipline, adding a doctor finding is upgrade-impacting (adopters pin
finding registers) and belongs under Upgrade Impact.

## Verification bar to copy from the adopter

The adopter verified the key survives into the **built** `CrosswakeShell.app/Info.plist`, not just
into source, on the grounds that a key can be correct in source and lost in packaging. Any fix here
should assert against the built product, not the template output.

## Provenance

Reported against the published hex `0.2.1` package templates under `deps/crosswake/`, not a working
copy. Physical iPhone 16 Pro Max. Every claim above was re-verified against this repo on 2026-09-15
and all three template facts matched exactly.
