# Phase 30: Hex Page Polish And Tarball Dry-Run - Validation

## Goal Verification
The goal is to confirm `README.md`, `mix docs` output, and the published tarball are clean and adopter-ready before the publish phase can be triggered.

## Success Criteria Checks

1. **README.md URLs are absolute for internal files**
   - Run: `grep -E '\[.*\]\((examples/|AGENTS.md|prompts/|script/)' README.md`
   - Expected: Command exits with 1 (no matches).
   - Ensure all internal references to non-packaged repo-only files use absolute URLs anchored to `@source_url` (e.g., `https://github.com/szTheory/crosswake/blob/main/`).
   - Run: `grep -E '\[.*\]\(guides/' README.md`
   - Expected: Matches relative links to guides.

2. **Hex tarball contains exactly the allowlist and no banned paths**
   - Run: `mix hex.build --unpack` and inspect the output directory `crosswake-*/`.
   - Run: `./script/verify_hex_tarball.sh`
   - Expected: Script exits 0, confirming expected paths exist (`lib/`, `priv/`, `.formatter.exs`, `mix.exs`, `README.md`, `LICENSE`, `CHANGELOG.md`, `guides/`) and banned paths (`.planning/`, `prompts/`, `test/`, `.github/`, `examples/`, `native/`) DO NOT exist.

3. **Mix docs render correctly with no warnings**
   - Run: `mix docs`
   - Expected: Command completes with zero warnings.
   - Run `open doc/index.html` locally and verify the index page redirects to the README landing page, and that every file in `guides/` is navigable.

4. **Hex publish dry-run succeeds**
   - Run: `mix hex.publish --dry-run`
   - Expected: Command exits 0 against the audited `mix.exs`, reporting correct metadata, license, files allowlist, and version preflight checks.
