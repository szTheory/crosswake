# Crosswake Token Distribution

This guide documents the single distribution mechanism for Crosswake's design tokens:
where they come from, how to regenerate them, what ships in the Hex package, and how
consumers receive them.

## Source

`crosswake.tokens.json` — W3C DTCG 2025.10 format, frozen v9.0 brand contract.

This file is the authoritative origin of every `--cw-*` CSS custom property. All
edits to the brand token values happen here and nowhere else.

## Generate

Run one Node command from the repository root:

```
node brandbook/tools/compile-tokens.js
```

This produces two outputs:

- `brandbook/tokens/tokens.css` — brand book reference copy, linked by `brandbook/index.html`
- `priv/static/crosswake/tokens.css` — distributable copy that ships in the Hex package

Both files are byte-identical. Diff them to verify parity:

```
diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css
```

No output means the copies are in sync. A non-zero exit or any diff output means one
of the files was edited by hand or a regeneration was only partially applied.

No toolchain beyond Node is required. There is no build system, bundler, or separate
CSS preprocessor involved in generating the token file.

## What ships in the package

`priv/static/crosswake/tokens.css` is in the `priv/` directory tree, which is
explicitly included in the Hex `files:` whitelist in `mix.exs`:

```elixir
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)
```

The `brandbook/` tree is excluded from the package. The brand book reference copy
(`brandbook/tokens/tokens.css`) is a development and documentation artifact only
and is never published to Hex.

## How consumers receive tokens.css

### Via `mix crosswake.gen.offline_ui`

Running the generator task copies `priv/static/crosswake/tokens.css` into the host's
`priv/static/assets/tokens.css` (no-clobber: if that file already exists the generator
logs "reused" and skips the write, preserving any host customizations).

The generated `offline_root.html.heex` template links `tokens.css` before `app.css`:

```html
<link rel="stylesheet" href="/assets/tokens.css" />
<link rel="stylesheet" href="/assets/app.css" />
```

This ensures all `--cw-*` custom properties are defined before any rule that
consumes them.

### Direct Phoenix host

Copy `priv/static/crosswake/tokens.css` from the installed Crosswake dependency into
your host's static CSS directory:

```
cp deps/crosswake/priv/static/crosswake/tokens.css priv/static/css/tokens.css
```

Then link it in your layout before `app.css`:

```html
<link rel="stylesheet" href="/css/tokens.css" />
<link rel="stylesheet" href="/css/app.css" />
```

`tokens.css` must load before `app.css` so that `--cw-*` custom properties are
defined before any rules that reference them via `var(--cw-*)`.

## Contract

- **Never hand-edit `tokens.css` in any consumer.** Edit `crosswake.tokens.json` and
  regenerate with `node brandbook/tools/compile-tokens.js`. Hand-edited copies will
  drift from the source of truth and break on the next regeneration.
- **Both generated copies must remain byte-identical.** `brandbook/tokens/tokens.css`
  and `priv/static/crosswake/tokens.css` are both outputs of the same compile step.
  Diff them to confirm parity before committing a regeneration.
- **All `--cw-*` custom properties are defined in `tokens.css`.** Consuming rules
  reference them via `var(--cw-*)` and must not duplicate or redefine these values
  in host stylesheets.
- Phase 109 adds a CI gate that asserts byte-identical parity with `diff` on every
  pull request. Until that gate lands, parity is enforced by convention and the
  diff command above.
