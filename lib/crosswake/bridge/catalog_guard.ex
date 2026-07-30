defmodule Crosswake.Bridge.CatalogGuard do
  @moduledoc """
  Merge-blocking structural guard for the Phase 154 catalog line (CTRL-04, PROOF-04).

  This module is a plain support module (NO `use ExUnit.Case`) callable from the
  proof lane and from `mix crosswake.doctor`. It lives in `lib/`, not `test/`,
  for the reason D-43 gives: deleting the test does not delete the rule, and
  doctor can call the same predicates a developer's CI run does. The guard
  travels with the code.

  It reads the attestation file that already exists — `Manifest.Builder`'s
  capability catalog — rather than minting a second one. A second catalog would
  recreate exactly the drift problem it claims to solve, and here it would be
  five-way drift: new file, catalog, command list, capability-command map, and
  two native enums (D-42).

  ## The six criteria, labelled honestly (D-44)

  This labelling is not decoration. D-45 records that PROOF-04 does **not** stop
  a maintainer adding forty controls one string at a time. Stating which criteria
  are mechanical, which is mechanical only in the negative, and which is hybrid
  with a later phase is what keeps the requirement from quietly overclaiming.

    * **(a) route-local and declarable — MECHANICAL.** Universally quantified over
      every command in the vocabulary, never spot-checked: every shipped command
      resolves to a declared capability family, and every bounded-bridge catalog
      entry resolves back to a shipped command (`check_attestation/3`).
    * **(b) low-frequency — MECHANICAL ONLY IN THE NEGATIVE.** The guard can prove
      no streaming seam exists in the bridge tree (`check_no_streaming_seam/1`).
      It cannot prove nobody calls a control in a loop. Absence of a seam is
      provable; discipline in calling is not.
    * **(c) zero external SDK — MECHANICAL.** An AST allowlist walk over every
      `alias`/`import`/`require`/`use` declaration in the bridge tree
      (`check_no_external_sdk/1`).
    * **(d) semantically bounded — MECHANICAL.** Six sub-assertions: the command
      list is a literal, no dynamic-registration function, no runtime function
      application, no atom minting outside the frozen allowlist, and native
      command enum parity against BOTH native sources in BOTH directions.
    * **(e) fails closed — HYBRID.** This phase asserts the *declaration*. Phase
      155's PROOF-01 route tour asserts it *renders*. Nothing here proves the
      denial surface actually appears to a user.
    * **(f) backend-authoritative — MECHANICAL BY PROXY.** `Crosswake.Bridge.Reply`'s
      field set is frozen (Plan 03), so a reply has nowhere to put an
      authority-carrying key. The guard does not re-derive this; it inherits it.

  ## Non-mechanical exclusion — the unbounded host-supplied denial reason

  Separately labelled, because it is NOT one of the six and it is NOT covered by
  the mechanical set above. Five delegate seams accept a **bare `String`** denial
  reason from an adopter host, so no static enumeration can bound them:

    1. `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/CrosswakeDelegates.kt:39`
       — `data class Denied(val reason: String, ...)` on the notification-token delegate.
    2. `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/FilesPickResult.kt:7`
       — `data class Denied(val reason: String, ...)` on the files-pick result.
    3. `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:128`
       — `case unavailable(reason: String, detail: [String: String])`.
    4. `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:133`
       — `case deny(reason: String, message: String, hint: String)`.
    5. `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/CrosswakeDelegates.kt:39`
       — the duplicated example-host copy of seam 1.

  Any adopter host can mint an arbitrary reason at any of those five seams. This
  sub-assertion is **NOT mechanically enforceable** and is carried by
  `.planning/seeds/SEED-008-native-denial-vocabulary.md`, not by this guard. Do
  not read the six-criteria block above as covering it. The runtime answer
  already shipped: `Crosswake.Bridge`'s reply decoder resolves an unknown reason
  string to `:unavailable_capability` and preserves the raw value at
  `details.raw_reason`, so an unbounded reason can neither crash the server nor
  launder itself into the closed vocabulary.

  ## Known extractor limitation

  `extract_native_denial_reasons/1` recognises a reason literal only when it is
  lowercase **and contains at least one underscore**. Every one of the 14 closed
  vocabulary reasons and all 8 seeded allowlist entries have that shape, and the
  underscore requirement is what keeps neighbouring prose and detail-key literals
  (`"unconfigured"`, `"connecting"`) from being mistaken for reasons. A
  single-word reason literal would slip past. Named here rather than hidden.

  ## AST mechanism

  `Code.string_to_quoted/2` + `Macro.prewalk/3` only — stdlib, no new dependency,
  no cross-reference tooling. Mirrors `Crosswake.CompanionGuard` exactly, including
  its documented child-module prefix-match pitfall when matching alias node parts.

  ## The injection seam, and why it is not a loophole

  `assert_catalog_closed!/1` accepts an optional `root:` plus the three compiled
  inputs it would otherwise read from `Contract`, `Registry`, and
  `Manifest.Builder`. Every default is the real shipped value, so the zero-argument
  call — the one CI and `mix crosswake.doctor` make — is byte-for-byte the gate it
  was before the seam existed. Nothing is relaxed and no violation is skippable.

  The seam exists so
  `test/crosswake/proof/phase154_recipe_followable_test.exs` can EXECUTE the
  six-step recipe this module's failure message prints, against a synthetic control
  in a temp tree, and prove the gate goes red-to-green across the steps and red
  again when any single step is omitted. Before the seam, that test could only
  re-compose the individual predicates and hope the composition matched the
  raiser's; now it drives the raiser itself. A gate whose documented path to yes is
  never executed is a gate nobody has checked the exit door on.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest.Builder
  alias Crosswake.Shell.Denial, as: ShellDenial

  @registration_prefix "register_"

  # Frozen top-level namespaces a bridge-tree file may depend on. Anything else
  # is an external SDK reaching into the bounded bridge — criterion (c).
  @allowed_dependency_roots [:Crosswake, :Phoenix, :Logger, :Jason, :Kernel]

  # Criterion (b), in the negative only: these roots are streaming/back-pressure
  # seams. Their ABSENCE is provable; call-site discipline is not.
  @streaming_roots [:Stream, :GenStage, :Flow, :Broadway]

  # Native enum cases with no inbound Elixir request command, by construction:
  # these are server -> shell outbound pushes, not bounded-bridge requests, so
  # they are exempt from orphan detection. Enumerated, not pattern-matched.
  @outbound_only_native_commands [
    # iOS: connection-state fan-out to the shell chrome
    "connection.state.update",
    # both natives: server-originated event delivery
    "server.event.push",
    # Android: the Kotlin spelling of the connection-state fan-out
    "server.state.update"
  ]

  # ---------------------------------------------------------------------------
  # D-16 disposition: option-b with amendment. Eight strings, enumerated, each
  # individually justified, each carrying the SEED-008 id. The guard goes red on
  # a NINTH. This is a DEFERRAL WITH A NAME, not a permanent exemption — the
  # retirement path is in SEED-008.
  # ---------------------------------------------------------------------------
  @out_of_vocabulary_denial_allowlist [
    %{
      reason: "notification_status_unavailable",
      seed: "SEED-008",
      sites: [
        "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:286"
      ],
      justification:
        "Core iOS: the shell cannot resolve notification authorization status without prompting, " <>
          "and notification_token is contractually prompt-free. No closed-vocabulary reason " <>
          "distinguishes 'cannot answer without prompting' from 'capability unavailable'."
    },
    %{
      reason: "notification_authorization_required",
      seed: "SEED-008",
      sites: [
        "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:292"
      ],
      justification:
        "Core iOS: authorization must be resolved before a token snapshot lookup. Distinct from " <>
          "step_up_required, which is an auth-level escalation, not an OS permission grant."
    },
    %{
      reason: "invalid_payload",
      seed: "SEED-008",
      sites: [
        "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:273",
        "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:284"
      ],
      justification:
        "Core Android: a malformed server-push payload (missing 'name' / missing 'state'). The " <>
          "closed vocabulary has no malformed-request reason at all — every entry describes a " <>
          "policy outcome, not a parse failure."
    },
    %{
      reason: "notification_setup_missing",
      seed: "SEED-008",
      sites: ["examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift:113"],
      justification:
        "Example iOS host: the app delegate reports registration state 'unconfigured'. " <>
          "Host-authored, but committed and shipping in this repo, so it is on the wire in " <>
          "every example-host run and in the adopter-facing sample."
    },
    %{
      reason: "notification_token_unavailable",
      seed: "SEED-008",
      sites: ["examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift:114"],
      justification:
        "Example iOS host: registration is configured but no provider-tagged token snapshot " <>
          "exists yet. The sibling branch of the same ternary as notification_setup_missing."
    },
    %{
      reason: "picker_unavailable",
      seed: "SEED-008",
      sites: [
        "examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift:58",
        "examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift:78"
      ],
      justification:
        "Example iOS host: the file-picker coordinator is not attached to a presented view " <>
          "controller. A host wiring state, not a manifest declaration state, so " <>
          "undeclared_capability would be an actively misleading answer."
    },
    %{
      reason: "picker_in_progress",
      seed: "SEED-008",
      sites: ["examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift:67"],
      justification:
        "Example iOS host: a second files.pick arrived while one is already presented. A " <>
          "concurrency-refusal that the closed vocabulary does not model at all."
    },
    %{
      reason: "file_staging_failed",
      seed: "SEED-008",
      sites: ["examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift:185"],
      justification:
        "Example iOS host: copy-first staging of the picked file threw. An I/O failure, not a " <>
          "policy denial — the closed vocabulary carries no I/O-failure reason."
    }
  ]

  @doc """
  The `lib/` sources the catalog line is enforced over.

  `root` defaults to `File.cwd!()` — the shipped tree. It is parameterised only so
  the recipe-followability proof can point the same walk at a temp fixture tree.
  """
  @spec bridge_sources(String.t()) :: [String.t()]
  def bridge_sources(root \\ File.cwd!()) do
    Path.wildcard(Path.join(root, "lib/crosswake/bridge/**/*.ex")) ++
      [Path.join(root, "lib/crosswake/bridge.ex")]
  end

  @doc """
  The native sources whose emitted denial reason strings are checked against the
  closed vocabulary. Enumerated, not globbed: a source that has moved must be
  noticed, not silently skipped.
  """
  @spec native_denial_sources(String.t()) :: [String.t()]
  def native_denial_sources(root \\ File.cwd!()) do
    Enum.map(
      [
        "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift",
        "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt",
        "examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift",
        "examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift"
      ],
      &Path.join(root, &1)
    )
  end

  @doc """
  The two native command-enum sources checked for bidirectional parity.
  """
  @spec native_command_enum_sources(String.t()) :: [String.t()]
  def native_command_enum_sources(root \\ File.cwd!()) do
    Enum.map(
      [
        "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift",
        "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt"
      ],
      &Path.join(root, &1)
    )
  end

  @doc """
  The eight enumerated out-of-vocabulary native denial reason strings, each with
  its shipping sites, an individual justification, and the SEED-008 id (D-16,
  resolved as option-b with amendment).

  A NINTH string turns `check_native_denial_reasons/1` red. Padding this list is
  the failure mode the individual justifications exist to make visible: adding an
  entry means writing down, in review, why the closed vocabulary could not answer.
  """
  @spec out_of_vocabulary_denial_allowlist() :: [map()]
  def out_of_vocabulary_denial_allowlist, do: @out_of_vocabulary_denial_allowlist

  @doc """
  Native enum cases exempt from orphan detection because they are outbound
  server -> shell pushes with no inbound bounded-bridge request seam.
  """
  @spec outbound_only_native_commands() :: [String.t()]
  def outbound_only_native_commands, do: @outbound_only_native_commands

  # ---------------------------------------------------------------------------
  # check_source/1 — the union. A REPORT, not a short-circuit (D-46).
  # ---------------------------------------------------------------------------

  @doc """
  Runs every source-level mechanical sub-assertion over `source_string` and
  returns the COMPLETE SET of violations.

  A source violating five criteria reports all five. Short-circuiting on the
  first would make a five-violation control look like a one-violation control,
  and the fix-one-rerun loop is exactly how a structural gate degrades into a
  nuisance.

  Returns `:ok`, or `{:violation, [{criterion_atom, node_or_detail}]}`. An empty
  or trivially small source is clean. An UNPARSEABLE source is a violation, not
  a pass — the guard fails closed.
  """
  @spec check_source(String.t()) :: :ok | {:violation, list()}
  def check_source(source_string) when is_binary(source_string) do
    case Code.string_to_quoted(source_string, []) do
      {:ok, ast} ->
        violations =
          Enum.flat_map(
            [
              &command_list_violations/1,
              &dynamic_registration_violations/1,
              &runtime_apply_violations/1,
              &atom_minting_violations/1,
              &external_sdk_violations/1,
              &streaming_seam_violations/1
            ],
            fn checker -> checker.(ast) end
          )

        wrap(violations)

      {:error, detail} ->
        {:violation, [{:unparseable_source, detail}]}
    end
  end

  @doc """
  Criterion (d): the command vocabulary must be a compile-time literal.

  A `~w` sigil or a plain list of string literals is a literal. A list built with
  `++`, a comprehension, an `Enum` call, or string interpolation is not — that is
  a runtime-constructed vocabulary, which is the plugin-catalog road under a
  different name. A source with no `@commands` attribute is clean; not every file
  declares a vocabulary.
  """
  @spec check_command_list_literal(String.t()) :: :ok | {:violation, list()}
  def check_command_list_literal(source), do: parse_then(source, &command_list_violations/1)

  @doc """
  Criterion (d): no dynamic-registration seam.

  Any `def`/`defp`/`defmacro` whose name starts with `#{@registration_prefix}` is
  a violation. Prefix match, not substring: `registry_lookup/1` is fine.
  """
  @spec check_no_dynamic_registration(String.t()) :: :ok | {:violation, list()}
  def check_no_dynamic_registration(source),
    do: parse_then(source, &dynamic_registration_violations/1)

  @doc """
  Criterion (d): no runtime function application. `apply/2`, `apply/3`, and
  `Kernel.apply/3` all let a command name become a call target.
  """
  @spec check_no_runtime_apply(String.t()) :: :ok | {:violation, list()}
  def check_no_runtime_apply(source), do: parse_then(source, &runtime_apply_violations/1)

  @doc """
  Criterion (d): no atom minting. `String.to_atom/1` and `List.to_atom/1` grow the
  atom table from wire input. `String.to_existing_atom/1` is on the frozen
  allowlist — it cannot mint, only resolve.
  """
  @spec check_no_atom_minting(String.t()) :: :ok | {:violation, list()}
  def check_no_atom_minting(source), do: parse_then(source, &atom_minting_violations/1)

  @doc """
  Criterion (c): zero external SDK. An allowlist walk over every
  `alias`/`import`/`require`/`use` declaration; anything rooted outside
  `#{inspect(@allowed_dependency_roots)}` is an external SDK reaching into the
  bounded bridge.
  """
  @spec check_no_external_sdk(String.t()) :: :ok | {:violation, list()}
  def check_no_external_sdk(source), do: parse_then(source, &external_sdk_violations/1)

  @doc """
  Criterion (b), in the negative only: no streaming or back-pressure seam
  (`#{inspect(@streaming_roots)}`) in the bridge tree.

  This proves no streaming seam EXISTS. It does not prove nobody calls a control
  in a loop — see the moduledoc's honest labelling.
  """
  @spec check_no_streaming_seam(String.t()) :: :ok | {:violation, list()}
  def check_no_streaming_seam(source), do: parse_then(source, &streaming_seam_violations/1)

  # ---------------------------------------------------------------------------
  # Native command enum parity — bidirectional (D-46)
  # ---------------------------------------------------------------------------

  @doc """
  Extracts the wire values from a native `BridgeCommand` enum block.

  Returns `{:ok, wire_values}` or `:error`. `:error` when the enum block cannot
  be located at all — carrying forward Phase 134's guard that a job not found is
  a FAILURE, not a pass. An extractor that silently returns `[]` for a renamed
  enum turns the parity check green at exactly the moment it should be red.
  """
  @spec extract_native_command_enum(String.t()) :: {:ok, [String.t()]} | :error
  def extract_native_command_enum(source) when is_binary(source) do
    cond do
      block = capture_block(source, ~r/enum\s+BridgeCommand\s*:\s*String[^\{]*\{/) ->
        {:ok, scan_wire_values(block, ~r/case\s+\w+\s*=\s*"([^"]+)"/)}

      block = capture_block(source, ~r/enum\s+class\s+BridgeCommand\s*\([^\)]*\)\s*\{/) ->
        {:ok, scan_wire_values(block, ~r/\w+\s*\(\s*"([^"]+)"\s*\)/)}

      true ->
        :error
    end
  end

  @doc """
  Criterion (d): native command enum parity, asserted in BOTH directions.

  A GAP is an Elixir command absent from the native enum. An ORPHAN is a native
  enum case with no Elixir command, excluding the enumerated outbound-only
  pushes. Checking one direction only would let a native shell ship a command the
  server has never heard of — which is the same hole as a dynamic registration
  seam, opened from the other end.

  An unlocatable enum block is a violation, never a vacuous pass.
  """
  @spec check_native_enum_parity(String.t(), [String.t()]) :: :ok | {:violation, list()}
  def check_native_enum_parity(native_source, commands)
      when is_binary(native_source) and is_list(commands) do
    case extract_native_command_enum(native_source) do
      :error ->
        {:violation,
         [{:native_enum_unlocatable, "BridgeCommand enum block not found in native source"}]}

      {:ok, wire_values} ->
        gaps = Enum.map(commands -- wire_values, &{:native_enum_gap, &1})

        orphans =
          wire_values
          |> Kernel.--(commands)
          |> Kernel.--(@outbound_only_native_commands)
          |> Enum.map(&{:native_enum_orphan, &1})

        wrap(gaps ++ orphans)
    end
  end

  # ---------------------------------------------------------------------------
  # Native denial vocabulary (D-16 -> option-b + amendment)
  # ---------------------------------------------------------------------------

  @doc """
  Extracts denial reason string literals from native (Swift/Kotlin) source.

  Recognises three emission shapes, each anchored on a real call site rather than
  a bare regex over every literal in the file:

    1. The FIRST reason-shaped literal inside a balanced `deny(` / `Denied(` /
       `unavailable(` call — covers both the Swift labelled-argument form
       (`reason: "x"`) and the Kotlin positional form.
    2. Every reason-shaped literal in a `let`/`val`/`var reason =` assignment
       expression — covers ternary-assigned reasons.
    3. Nothing at all when the reason argument is a VARIABLE. That is not a miss;
       it is the unbounded host-supplied seam, which is not statically bounded
       and is carried by SEED-008 (see the moduledoc's non-mechanical exclusion).

  "Reason-shaped" means lowercase with at least one underscore — see the
  moduledoc's known extractor limitation.
  """
  @spec extract_native_denial_reasons(String.t()) :: [String.t()]
  def extract_native_denial_reasons(source) when is_binary(source) do
    from_calls =
      ["deny(", "Denied(", "unavailable("]
      |> Enum.flat_map(&opener_offsets(source, &1))
      |> Enum.flat_map(fn offset ->
        case Regex.run(reason_literal_regex(), balanced_call(source, offset)) do
          [_, literal] -> [literal]
          _ -> []
        end
      end)

    from_assignments =
      ~r/(?:let|val|var)\s+reason\s*=\s*((?:[^\n]*\n){0,4})/
      |> Regex.scan(source)
      |> Enum.flat_map(fn [_full, window] ->
        reason_literal_regex()
        |> Regex.scan(window)
        |> Enum.map(&Enum.at(&1, 1))
      end)

    Enum.uniq(from_calls ++ from_assignments)
  end

  @doc """
  Asserts every statically extractable native denial reason is either in the
  closed `Crosswake.Shell.Denial` vocabulary or on the eight-entry seeded
  allowlist. A NINTH out-of-vocabulary string is a violation.
  """
  @spec check_native_denial_reasons(String.t()) :: :ok | {:violation, list()}
  def check_native_denial_reasons(source) when is_binary(source) do
    known = closed_vocabulary() ++ Enum.map(@out_of_vocabulary_denial_allowlist, & &1.reason)

    source
    |> extract_native_denial_reasons()
    |> Enum.reject(&(&1 in known))
    |> Enum.map(&{:out_of_vocabulary_denial_reason, &1})
    |> wrap()
  end

  @doc """
  Asserts every allowlist entry is still emitted by at least one of its declared
  sites. An entry whose string has been fixed or deleted is rot: it makes the
  allowlist look larger than the real debt and quietly widens the gate.
  """
  @spec check_denial_allowlist_liveness(String.t()) :: :ok | {:violation, list()}
  def check_denial_allowlist_liveness(root \\ File.cwd!()) do
    sources = Map.new(native_denial_sources(root), &{&1, read_or_nil(&1)})

    @out_of_vocabulary_denial_allowlist
    |> Enum.flat_map(fn entry ->
      live? =
        Enum.any?(entry.sites, fn site ->
          path = Path.join(root, site |> String.split(":") |> hd())

          case Map.get(sources, path) do
            nil -> false
            body -> String.contains?(body, "\"" <> entry.reason <> "\"")
          end
        end)

      if live?, do: [], else: [{:stale_denial_allowlist_entry, entry.reason}]
    end)
    |> wrap()
  end

  # ---------------------------------------------------------------------------
  # Attestation — gaps AND orphans (D-46)
  # ---------------------------------------------------------------------------

  @doc """
  Criterion (a): every catalog entry maps to a shipped command and every shipped
  command maps to a catalog entry.

  Rejecting only gaps would let a command ship with no owner, no rebuild cost,
  and no declared denial — an undeclared control wearing a declared one's badge.
  Rejecting only orphans would let a catalog entry claim a control that does not
  exist. Both directions or neither.
  """
  @spec check_attestation([String.t()], %{String.t() => String.t() | nil}, [String.t()]) ::
          :ok | {:violation, list()}
  def check_attestation(commands, command_capability_map, catalog_capability_ids)
      when is_list(commands) and is_map(command_capability_map) and
             is_list(catalog_capability_ids) do
    mapped_capabilities =
      command_capability_map |> Map.values() |> Enum.reject(&is_nil/1) |> Enum.uniq()

    gaps =
      (catalog_capability_ids -- mapped_capabilities)
      |> Enum.map(&{:attestation_gap, &1})

    unmapped_commands =
      commands
      |> Enum.filter(&is_nil(Map.get(command_capability_map, &1)))
      |> Enum.map(&{:attestation_orphan, &1})

    unshipped_commands =
      (Map.keys(command_capability_map) -- commands)
      |> Enum.map(&{:attestation_orphan, &1})

    wrap(gaps ++ unmapped_commands ++ unshipped_commands)
  end

  # ---------------------------------------------------------------------------
  # The raiser
  # ---------------------------------------------------------------------------

  @doc """
  Walks the real shipped sources and raises on the first violated criterion,
  with the six-step recipe for legitimately adding the next control.

  Returns `:ok` when the catalog line holds.

  ## Options — all defaulting to the real shipped values

    * `:root` — the tree the source, native-enum, and native-denial walks read
      from. Defaults to `File.cwd!()`.
    * `:commands` — defaults to `Crosswake.Bridge.Contract.commands/0`.
    * `:command_capability_map` — defaults to `shipped_command_capability_map/0`.
    * `:catalog_capability_ids` — defaults to `bounded_bridge_capability_ids/0`.

  `assert_catalog_closed!()` with no options is the merge-blocking gate, unchanged.
  See the moduledoc's "injection seam" section for why the options exist.
  """
  @spec assert_catalog_closed!(keyword()) :: :ok
  def assert_catalog_closed!(opts \\ []) do
    root = Keyword.get(opts, :root, File.cwd!())
    commands = Keyword.get(opts, :commands, Contract.commands())

    command_capability_map =
      Keyword.get_lazy(opts, :command_capability_map, &shipped_command_capability_map/0)

    catalog_capability_ids =
      Keyword.get_lazy(opts, :catalog_capability_ids, &bounded_bridge_capability_ids/0)

    source_violations =
      Enum.flat_map(bridge_sources(root), fn path ->
        case check_source(File.read!(path)) do
          :ok -> []
          {:violation, list} -> Enum.map(list, fn v -> {path, v} end)
        end
      end)

    parity_violations =
      Enum.flat_map(native_command_enum_sources(root), fn path ->
        case check_native_enum_parity(read_or_missing(path), commands) do
          :ok -> []
          {:violation, list} -> Enum.map(list, fn v -> {path, v} end)
        end
      end)

    denial_violations =
      Enum.flat_map(native_denial_sources(root), fn path ->
        case check_native_denial_reasons(read_or_missing(path)) do
          :ok -> []
          {:violation, list} -> Enum.map(list, fn v -> {path, v} end)
        end
      end)

    liveness_violations =
      case check_denial_allowlist_liveness(root) do
        :ok -> []
        {:violation, list} -> Enum.map(list, fn v -> {"(allowlist)", v} end)
      end

    attestation_violations =
      case check_attestation(commands, command_capability_map, catalog_capability_ids) do
        :ok -> []
        {:violation, list} -> Enum.map(list, fn v -> {"(attestation)", v} end)
      end

    all =
      source_violations ++
        parity_violations ++ denial_violations ++ liveness_violations ++ attestation_violations

    case all do
      [] ->
        :ok

      violations ->
        raise catalog_failure_message(violations)
    end
  end

  @doc """
  The bounded-bridge capability families declared in `Manifest.Builder`'s
  capability catalog — the attestation file that already exists (D-42).
  """
  @spec bounded_bridge_capability_ids() :: [String.t()]
  def bounded_bridge_capability_ids do
    []
    |> Builder.capability_registry()
    |> Enum.filter(fn {_id, capability} -> capability.owner == :bounded_bridge end)
    |> Enum.map(fn {id, _capability} -> id end)
    |> Enum.sort()
  end

  @doc """
  The shipped command -> capability family map, read from `Crosswake.Bridge.Registry`.
  """
  @spec shipped_command_capability_map() :: %{String.t() => String.t() | nil}
  def shipped_command_capability_map do
    Map.new(Registry.allowed_commands(), &{&1, Registry.command_capability(&1)})
  end

  @doc """
  The closed denial vocabulary as wire strings.
  """
  @spec closed_vocabulary() :: [String.t()]
  def closed_vocabulary, do: Enum.map(ShellDenial.reasons(), &Atom.to_string/1)

  # ---------------------------------------------------------------------------
  # Failure message: stable id on line 1, then the path to yes (D-48)
  # ---------------------------------------------------------------------------

  defp catalog_failure_message(violations) do
    [{path, {criterion, detail}} | _] = violations

    header =
      "[proof.ctrl_04.catalog_closed.#{criterion}] " <>
        "subject=the bounded bridge command vocabulary must stay a closed, declared, literal catalog " <>
        "source=CatalogGuard.assert_catalog_closed!/0 " <>
        "observed=#{inspect(detail)} " <>
        "path=#{path} " <>
        "hint=see the recipe below — this gate has a documented path to yes " <>
        "posture=merge_blocking"

    all_lines =
      violations
      |> Enum.map(fn {p, {c, d}} -> "  - #{c} at #{p}: #{inspect(d)}" end)
      |> Enum.join("\n")

    """
    #{header}

    Every violated criterion, not just the first:
    #{all_lines}

    WHY THE VOCABULARY IS CLOSED

    Cordova shipped a plugin catalog. It began as a short list of obviously-native
    things and ended as a directory nobody could audit, where the answer to "what
    can this app do?" was "whatever is installed." Crosswake's bounded bridge is a
    closed vocabulary precisely so that question keeps a short, readable answer.
    A dynamically-registered command is not a smaller version of that outcome. It
    is the first step of it.

    Note what this gate does NOT do (D-45): it closes the mechanical
    plugin-catalog road. It does not stop a maintainer adding forty controls one
    string at a time. The inoculation against that is the attestation criteria and
    CTRL-05 making each control's rebuild cost publicly named.

    THE SIX-STEP RECIPE FOR ADDING THE NEXT CONTROL

      1. Add the capability to `Manifest.Builder`'s capability catalog with its
         owner, package class, proof class, rebuild cost, interaction, denial,
         fallback, guide, and prerequisites. No entry, no control.
      2. Add the wire command string to `Crosswake.Bridge.Contract`'s `@commands`
         as a LITERAL. Not concatenated, not interpolated, not comprehended.
      3. Add the command -> capability mapping to `Crosswake.Bridge.Registry`.
      4. Add the matching case to BOTH native command enums, in the same PR, with
         the same wire string. One-sided parity is drift with a delay.
      5. Regenerate the contract vectors: `mix crosswake.contract.gen`. Commit the
         regenerated files alongside the change, not in a follow-up.
      6. Write the denial and the fallback surface before the happy path. A
         control whose failure is undesigned fails open by default.

    A NOTE ON THE HOST-SUPPLIED DENIAL SEAM

    Five delegate seams accept a bare `String` denial reason from an adopter host
    rather than a bounded enum, so a host can mint an arbitrary unvalidated reason
    onto the wire:

      - crosswake-shell-core-android .../core/CrosswakeDelegates.kt:39
          data class Denied(val reason: String, ...)   (notification-token delegate)
      - crosswake-shell-core-android .../core/FilesPickResult.kt:7
          data class Denied(val reason: String, ...)   (files-pick result)
      - crosswake-shell-core-ios .../BridgeChannel.swift:128
          case unavailable(reason: String, detail: [String: String])
      - crosswake-shell-core-ios .../BridgeChannel.swift:133
          case deny(reason: String, message: String, hint: String)
      - examples/android_shell_host .../shell/CrosswakeDelegates.kt:39
          the duplicated example-host copy of the first seam

    This guard CANNOT close that seam — no static enumeration bounds a public
    `String` field an adopter fills in. It is carried by SEED-008, whose retirement
    path is converting all five to bounded enums (a BREAKING change to public
    adopter-implemented types on both platforms, gated on the Phase 153 mirror
    train). The runtime answer already shipped: the reply decoder resolves an
    unknown reason to :unavailable_capability and preserves the raw value at
    details.raw_reason.

    This gate does not exist to stop the next control. It exists to make the next
    control look exactly like the existing ones.
    """
  end

  # ---------------------------------------------------------------------------
  # AST predicates
  # ---------------------------------------------------------------------------

  defp parse_then(source, checker) when is_binary(source) do
    case Code.string_to_quoted(source, []) do
      {:ok, ast} -> wrap(checker.(ast))
      {:error, detail} -> {:violation, [{:unparseable_source, detail}]}
    end
  end

  defp command_list_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:@, _meta, [{:commands, _, [value]}]} = node, acc ->
          if literal_command_list?(value),
            do: {node, acc},
            else: {node, [{:command_list_not_literal, value} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  # A ~w sigil over a plain (non-interpolated) binary is a literal.
  defp literal_command_list?({:sigil_w, _meta, [{:<<>>, _, parts}, _mods]}),
    do: Enum.all?(parts, &is_binary/1)

  # A plain list of string literals is a literal.
  defp literal_command_list?(list) when is_list(list), do: Enum.all?(list, &is_binary/1)

  defp literal_command_list?(_other), do: false

  defp dynamic_registration_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {kind, _meta, [{name, _, _} | _]} = node, acc
        when kind in [:def, :defp, :defmacro] and is_atom(name) ->
          if String.starts_with?(Atom.to_string(name), @registration_prefix) do
            {node, [{:dynamic_registration, name} | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp runtime_apply_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {{:., _, [{:__aliases__, _, [:Kernel]}, :apply]}, _, args} = node, acc
        when length(args) in [2, 3] ->
          {node, [{:runtime_apply, :"Kernel.apply"} | acc]}

        {:apply, _meta, args} = node, acc when is_list(args) and length(args) in [2, 3] ->
          {node, [{:runtime_apply, :apply} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp atom_minting_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {{:., _, [{:__aliases__, _, [mod]}, fun]}, _, _args} = node, acc
        when {mod, fun} in [{:String, :to_atom}, {:List, :to_atom}, {:Atom, :to_atom}] ->
          {node, [{:atom_minting, :"#{mod}.#{fun}"} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp external_sdk_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {kind, _meta, [{:__aliases__, _, [root | _]} | _]} = node, acc
        when kind in [:alias, :import, :require, :use] and is_atom(root) ->
          if root in @allowed_dependency_roots do
            {node, acc}
          else
            {node, [{:external_sdk, root} | acc]}
          end

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp streaming_seam_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:__aliases__, _meta, [root | _]} = node, acc when is_atom(root) ->
          if root in @streaming_roots do
            {node, [{:streaming_seam, root} | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    violations
  end

  # ---------------------------------------------------------------------------
  # Native source scanning helpers
  # ---------------------------------------------------------------------------

  defp reason_literal_regex, do: ~r/"([a-z][a-z0-9]*(?:_[a-z0-9]+)+)"/

  defp capture_block(source, header_regex) do
    case Regex.run(header_regex, source, return: :index) do
      [{start, len} | _] -> balanced_braces(source, start + len - 1)
      _ -> nil
    end
  end

  defp scan_wire_values(block, regex) do
    regex |> Regex.scan(block) |> Enum.map(&Enum.at(&1, 1)) |> Enum.uniq()
  end

  # Offsets of the "(" that closes each opener occurrence.
  defp opener_offsets(source, opener), do: do_opener_offsets(source, opener, 0, [])

  defp do_opener_offsets(source, opener, from, acc) do
    case :binary.match(source, opener, scope: {from, byte_size(source) - from}) do
      :nomatch -> Enum.reverse(acc)
      {pos, len} -> do_opener_offsets(source, opener, pos + len, [pos + len - 1 | acc])
    end
  end

  defp balanced_call(source, offset) do
    balanced(binary_part(source, offset, byte_size(source) - offset), ?\(, ?\), 0, false, "")
  end

  defp balanced_braces(source, offset) do
    balanced(binary_part(source, offset, byte_size(source) - offset), ?{, ?}, 0, false, "")
  end

  defp balanced(<<>>, _open, _close, _depth, _in_string?, acc), do: acc

  defp balanced(<<?\\, _skipped, rest::binary>>, open, close, depth, true, acc),
    do: balanced(rest, open, close, depth, true, acc)

  defp balanced(<<?", rest::binary>>, open, close, depth, in_string?, acc),
    do: balanced(rest, open, close, depth, not in_string?, acc <> "\"")

  defp balanced(<<char::utf8, rest::binary>>, open, close, depth, false, acc)
       when char == open,
       do: balanced(rest, open, close, depth + 1, false, acc <> <<char::utf8>>)

  defp balanced(<<char::utf8, rest::binary>>, open, close, depth, false, acc)
       when char == close do
    if depth <= 1 do
      acc <> <<char::utf8>>
    else
      balanced(rest, open, close, depth - 1, false, acc <> <<char::utf8>>)
    end
  end

  defp balanced(<<char::utf8, rest::binary>>, open, close, depth, in_string?, acc),
    do: balanced(rest, open, close, depth, in_string?, acc <> <<char::utf8>>)

  defp read_or_nil(path), do: if(File.exists?(path), do: File.read!(path), else: nil)

  defp read_or_missing(path) do
    # A native source that has MOVED must fail the guard, not skip it. Returning
    # an empty string here makes extract_native_command_enum/1 return :error,
    # which the parity check reports as a violation (D-46).
    read_or_nil(path) || ""
  end

  defp wrap([]), do: :ok
  defp wrap(violations), do: {:violation, violations}
end
