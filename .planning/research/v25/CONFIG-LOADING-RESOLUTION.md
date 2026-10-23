# Config Loading Resolution

**Decision:** Supersede the earlier `@requirements ["app.config"]` recommendation. Declare the generator's requirement as `@requirements ["compile"]`, read the host's ordinary build-time application config, and do not evaluate `config/runtime.exs` or start the Phoenix application.

## Evidence and tradeoffs

Elixir 1.19 documents `config/config.exs` and environment imports as build-time config loaded whenever a Mix command runs, and `config/runtime.exs` as runtime config, commonly used for environment variables unavailable at build time. Under `MIX_ENV=prod`, `import_config "#{config_env()}.exs"` selects `config/prod.exs` without evaluating `runtime.exs`. Put public bundle inputs (router, deployment origin, bundle IDs, signing mode/team selector) in ordinary build-time config; leave DB URLs, secret keys, and other runtime-only settings in runtime config. [Elixir 1.19.5 Mix configuration docs](https://mix.hexdocs.pm/1.19.5/Mix.html#module-configuration) and [Elixir 1.19.5's config lifecycle](https://hexdocs.pm/elixir/config-and-distribution.html#compile-vs-runtime-configuration) define this split.

The Mix task choices differ materially:

| Requirement | What it provides | Decision |
|---|---|---|
| `"compile"` | Compiles current host code/router; Mix has already loaded build-time config. Does not ask Mix to evaluate `runtime.exs` or start the host application. | **Use.** The generator needs a compiled router and public build inputs. |
| `"app.config"` | Configures apps and evaluates `runtime.exs` in addition to making configuration available. It may therefore require server-only credentials before generation can run. | **Do not use.** Parent's Elixir 1.19.5 fixture proves failure on a deliberately missing runtime-only variable. |
| Pure explicit config passing | A separate CLI/file config can avoid loading host runtime config, but duplicates the host's router/origin/identity declaration and introduces precedence and maintenance burden. Manually invoking `Config.Reader` on host files also duplicates Mix's environment/import behavior. | **Do not introduce.** The ordinary build-time config path already solves it. |

The `Mix.Task` API documentation recommends `app.config` as the minimum requirement when a task must interact with user application configuration, but it does not account for this generator's need to avoid unrelated runtime config. The more specific behavior is established by Elixir's config lifecycle and the fixture. Use `@requirements ["compile"]`; read the already-loaded declaration with `Application.fetch_env!(:crosswake, :ios_host)` and fail with a key-specific remediation if missing. Do not manually call `Mix.Task.run("app.config")` or `app.start`. Sources: [Mix.Task requirements](https://mix.hexdocs.pm/main/Mix.Task.html), [`mix app.config`](https://mix.hexdocs.pm/Mix.Tasks.App.Config.html), [`mix compile`](https://mix.hexdocs.pm/1.19.5/Mix.Tasks.Compile.html).

The parent-run fixture used a minimal Mix project with `MIX_ENV=prod`, `config/config.exs` build input, and `runtime.exs` containing `System.fetch_env!` for a deliberately unset synthetic variable. The `app.config`-required task exited 1 while evaluating runtime config; the compile-only task exited 0, observed the build config, and confirmed the app was not started. This confirms the material concern without using real credentials. Artifact: [`build-config-experiment.json`](build-config-experiment.json). It is a Mix lifecycle experiment, not proof of full Phoenix router/Xcode generation.

## Recommended API and boundary

Keep the previously chosen consumer path, with this loading correction:

```elixir
# config/config.exs imports the ordinary environment file
import_config "#{config_env()}.exs"

# config/prod.exs — public bundle/generation inputs only
config :crosswake, :ios_host,
  router: MyAppWeb.Router,
  origin: "https://study.example.org",
  bundle_id: "org.example.study"
```

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --check
MIX_ENV=prod mix crosswake.gen.shell ios
```

`MIX_ENV` is the one config selector; do not add a second `--config` file or mirror these inputs in CLI flags. `compile` ensures router code is available while the host app remains stopped. The deployment origin must be a public, build-time host input because generation serializes it into the bundled production manifest. If a server injects a runtime origin, the host may compare it to the bundled origin at its own startup, but generation must neither require that runtime config nor substitute an example origin.

Generated activation remains static route/runtime data only. It cannot infer session, identity, account, scope, or replay authority from host build config. Those are established by the running host against its actual request/session authority; absence denies the operation.

**Implementation check:** retain one narrow test on supported Elixir 1.19 that sets a marker in build config and a distinct unset-required variable in `runtime.exs`; assert `--check` sees the marker, exits successfully, and leaves the Phoenix app stopped. If router compilation or tests accidentally evaluate runtime config through an alias, remove that alias dependency rather than adding a credential workaround.
