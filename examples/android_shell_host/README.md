# Crosswake ANDROID Shell Baseline

This generated project is `host-owned`. Crosswake uses a scaffold once posture so your
team can review, ship, and patch the native shell as an application artifact.
Do not treat this directory as library-owned or safely regeneratable over host
edits.

## Included Baseline

- Real Android Studio project files that match the class of artifact adopters ship
- Bundled canonical manifest, activation, denial, and pack inventory fixtures
- Thin native seams for app boot, manifest loading, and route-unavailable handling

## Boundary

- The generated shell is intentionally thin and manifest-first.
- Crosswake does not claim offline journals, pack managers, or broad plugin registries here.
- Upgrade this shell with patch-or-doc guidance after generation instead of expecting safe re-ownership.
