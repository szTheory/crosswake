defmodule Crosswake.Bridge.CatalogGuardTest do
  @moduledoc """
  Predicate-level unit coverage for `Crosswake.Bridge.CatalogGuard`.

  Every mechanical sub-assertion gets a synthetic violating source AND a
  synthetic clean source, so a predicate that always returns `:ok` (or always
  returns a violation) fails here rather than passing silently in the proof
  lane. The proof lane (`test/crosswake/proof/phase154_catalog_guard_test.exs`)
  is the merge-blocking gate; this file is the microscope.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Bridge.CatalogGuard

  # ---------------------------------------------------------------------------
  # (d) semantically bounded — the command list must be a literal
  # ---------------------------------------------------------------------------

  describe "check_command_list_literal/1" do
    test "a ~w sigil command list is a literal — clean" do
      assert :ok =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 @commands ~w(app.info.get haptics.impact)
               end
               """)
    end

    test "a plain list of string literals is a literal — clean" do
      assert :ok =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 @commands ["app.info.get", "haptics.impact"]
               end
               """)
    end

    test "a command list built with ++ is a violation" do
      assert {:violation, [{:command_list_not_literal, _} | _]} =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 @commands ~w(app.info.get) ++ ["haptics.impact"]
               end
               """)
    end

    test "a command list built with a comprehension is a violation" do
      assert {:violation, [{:command_list_not_literal, _} | _]} =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 @commands for n <- ~w(app haptics), do: n <> ".invoke"
               end
               """)
    end

    test "a command list built with string interpolation is a violation" do
      assert {:violation, [{:command_list_not_literal, _} | _]} =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 @prefix "app"
                 @commands ["#{"\#{@prefix}"}.info.get"]
               end
               """)
    end

    test "a source with no @commands attribute is clean — not every file declares a vocabulary" do
      assert :ok =
               CatalogGuard.check_command_list_literal("""
               defmodule Fake do
                 def hello, do: :world
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (d) semantically bounded — no dynamic registration seam
  # ---------------------------------------------------------------------------

  describe "check_no_dynamic_registration/1" do
    test "a register_-prefixed function definition is a violation" do
      assert {:violation, [{:dynamic_registration, _} | _]} =
               CatalogGuard.check_no_dynamic_registration("""
               defmodule Fake do
                 def register_command(name), do: name
               end
               """)
    end

    test "a private register_-prefixed function definition is a violation" do
      assert {:violation, [{:dynamic_registration, _} | _]} =
               CatalogGuard.check_no_dynamic_registration("""
               defmodule Fake do
                 defp register_handler(name), do: name
               end
               """)
    end

    test "a function merely NAMED registry_lookup is clean — prefix match, not substring" do
      assert :ok =
               CatalogGuard.check_no_dynamic_registration("""
               defmodule Fake do
                 def registry_lookup(name), do: name
                 def unregistered?(name), do: name
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (d) semantically bounded — no runtime function application
  # ---------------------------------------------------------------------------

  describe "check_no_runtime_apply/1" do
    test "a bare apply/3 call is a violation" do
      assert {:violation, [{:runtime_apply, _} | _]} =
               CatalogGuard.check_no_runtime_apply("""
               defmodule Fake do
                 def go(m, f, a), do: apply(m, f, a)
               end
               """)
    end

    test "a Kernel.apply/3 call is a violation" do
      assert {:violation, [{:runtime_apply, _} | _]} =
               CatalogGuard.check_no_runtime_apply("""
               defmodule Fake do
                 def go(m, f, a), do: Kernel.apply(m, f, a)
               end
               """)
    end

    test "a direct static call is clean" do
      assert :ok =
               CatalogGuard.check_no_runtime_apply("""
               defmodule Fake do
                 def go(a), do: Enum.map(a, & &1)
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (d) semantically bounded — no atom minting
  # ---------------------------------------------------------------------------

  describe "check_no_atom_minting/1" do
    test "String.to_atom/1 is a violation" do
      assert {:violation, [{:atom_minting, _} | _]} =
               CatalogGuard.check_no_atom_minting("""
               defmodule Fake do
                 def go(s), do: String.to_atom(s)
               end
               """)
    end

    test "List.to_atom/1 is a violation" do
      assert {:violation, [{:atom_minting, _} | _]} =
               CatalogGuard.check_no_atom_minting("""
               defmodule Fake do
                 def go(s), do: List.to_atom(s)
               end
               """)
    end

    test "String.to_existing_atom/1 is clean — the frozen allowlist permits it" do
      assert :ok =
               CatalogGuard.check_no_atom_minting("""
               defmodule Fake do
                 def go(s), do: String.to_existing_atom(s)
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (c) zero external SDK — AST allowlist walk over dependency declarations
  # ---------------------------------------------------------------------------

  describe "check_no_external_sdk/1" do
    test "aliasing a non-allowlisted top-level namespace is a violation" do
      assert {:violation, [{:external_sdk, _} | _]} =
               CatalogGuard.check_no_external_sdk("""
               defmodule Fake do
                 alias FirebaseMessaging.Client
               end
               """)
    end

    test "importing a non-allowlisted top-level namespace is a violation" do
      assert {:violation, [{:external_sdk, _} | _]} =
               CatalogGuard.check_no_external_sdk("""
               defmodule Fake do
                 import StripeSDK
               end
               """)
    end

    test "aliasing a Crosswake namespace is clean" do
      assert :ok =
               CatalogGuard.check_no_external_sdk("""
               defmodule Fake do
                 alias Crosswake.Bridge.Contract
                 alias Crosswake.Manifest.Types
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (b) low-frequency — MECHANICAL ONLY IN THE NEGATIVE
  # ---------------------------------------------------------------------------

  describe "check_no_streaming_seam/1" do
    test "a Stream.* reference is a violation" do
      assert {:violation, [{:streaming_seam, _} | _]} =
               CatalogGuard.check_no_streaming_seam("""
               defmodule Fake do
                 def go(f), do: Stream.resource(f, f, f)
               end
               """)
    end

    test "a GenStage reference is a violation" do
      assert {:violation, [{:streaming_seam, _} | _]} =
               CatalogGuard.check_no_streaming_seam("""
               defmodule Fake do
                 use GenStage
               end
               """)
    end

    test "an Enum.* reference is clean — eager traversal is not a streaming seam" do
      assert :ok =
               CatalogGuard.check_no_streaming_seam("""
               defmodule Fake do
                 def go(a), do: Enum.map(a, & &1)
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # check_source/1 — the union. A report, not a short-circuit (D-46).
  # ---------------------------------------------------------------------------

  describe "check_source/1" do
    test "a source violating six criteria at once reports ALL SIX — the guard is a report, not a short-circuit (D-46)" do
      violating = """
      defmodule Fake do
        alias FirebaseMessaging.Client

        @commands ~w(app.info.get) ++ ["haptics.impact"]

        def register_command(name), do: String.to_atom(name)
        def go(m, f, a), do: apply(m, f, a)
        def stream(f), do: Stream.resource(f, f, f)
      end
      """

      assert {:violation, violations} = CatalogGuard.check_source(violating)

      observed = violations |> Enum.map(&elem(&1, 0)) |> MapSet.new()

      expected =
        MapSet.new([
          :command_list_not_literal,
          :dynamic_registration,
          :runtime_apply,
          :atom_minting,
          :external_sdk,
          :streaming_seam
        ])

      assert MapSet.equal?(observed, expected),
             "check_source/1 must report the COMPLETE SET of violated criteria, not the first. " <>
               "expected=#{inspect(Enum.sort(expected))} observed=#{inspect(Enum.sort(observed))}"
    end

    test "an empty source returns clean without raising" do
      assert :ok = CatalogGuard.check_source("")
    end

    test "a trivially small source returns clean without raising" do
      assert :ok = CatalogGuard.check_source("defmodule Fake do\nend\n")
    end

    test "an unparseable source FAILS closed rather than passing vacuously" do
      assert {:violation, [{:unparseable_source, _} | _]} =
               CatalogGuard.check_source("defmodule Fake do\n  def (((\n")
    end

    test "a clean source with none of the six violations returns :ok" do
      assert :ok =
               CatalogGuard.check_source("""
               defmodule Fake do
                 alias Crosswake.Bridge.Contract

                 @commands ~w(app.info.get haptics.impact)

                 def commands, do: @commands
                 def supported?(c), do: c in @commands and Contract.protocol() != nil
               end
               """)
    end
  end

  # ---------------------------------------------------------------------------
  # (d) native command enum parity — bidirectional, unlocatable block FAILS
  # ---------------------------------------------------------------------------

  describe "extract_native_command_enum/1" do
    test "extracts the Swift BridgeCommand enum wire values" do
      swift = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
          case hapticsImpact = "haptics.impact"
      }
      """

      assert {:ok, ["app.info.get", "haptics.impact"]} =
               CatalogGuard.extract_native_command_enum(swift)
    end

    test "extracts the Kotlin BridgeCommand enum wire values" do
      kotlin = """
      enum class BridgeCommand(val wireValue: String) {
          APP_INFO_GET("app.info.get"),
          HAPTICS_IMPACT("haptics.impact");
      }
      """

      assert {:ok, ["app.info.get", "haptics.impact"]} =
               CatalogGuard.extract_native_command_enum(kotlin)
    end

    test "an unlocatable enum block is :error, NOT an empty success — job not found is a failure (Phase 134, D-46)" do
      assert :error = CatalogGuard.extract_native_command_enum("// no enum here at all\n")
    end
  end

  describe "check_native_enum_parity/2" do
    test "a command present in Elixir but in neither native enum is a GAP violation" do
      swift = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
      }
      """

      assert {:violation, violations} =
               CatalogGuard.check_native_enum_parity(swift, ["app.info.get", "haptics.impact"])

      assert Enum.any?(violations, &match?({:native_enum_gap, "haptics.impact"}, &1))
    end

    test "a native enum case with no Elixir command is an ORPHAN violation" do
      swift = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
          case secretBackdoor = "secret.backdoor"
      }
      """

      assert {:violation, violations} =
               CatalogGuard.check_native_enum_parity(swift, ["app.info.get"])

      assert Enum.any?(violations, &match?({:native_enum_orphan, "secret.backdoor"}, &1))
    end

    test "a documented outbound-only native case is NOT an orphan" do
      swift = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
          case serverEventPush = "server.event.push"
      }
      """

      assert :ok = CatalogGuard.check_native_enum_parity(swift, ["app.info.get"])
    end

    test "an unlocatable enum block FAILS the parity check rather than passing vacuously" do
      assert {:violation, [{:native_enum_unlocatable, _} | _]} =
               CatalogGuard.check_native_enum_parity("// nothing\n", ["app.info.get"])
    end

    test "exact bidirectional agreement is clean" do
      swift = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
          case hapticsImpact = "haptics.impact"
      }
      """

      assert :ok =
               CatalogGuard.check_native_enum_parity(swift, ["app.info.get", "haptics.impact"])
    end
  end

  # ---------------------------------------------------------------------------
  # native denial-reason vocabulary (D-16 as resolved by Task 1: option-b)
  # ---------------------------------------------------------------------------

  describe "extract_native_denial_reasons/1" do
    test "extracts a Swift labelled-argument reason literal" do
      swift = ~S|completion(deny(request, reason: "origin_denied", message: "Nope.", hint: "Retry."))|

      assert ["origin_denied"] = CatalogGuard.extract_native_denial_reasons(swift)
    end

    test "extracts a Kotlin positional reason literal" do
      kotlin = """
      return deny(
          request,
          "invalid_payload",
          "Missing 'name' in payload.",
          "Provide an event name."
      )
      """

      assert ["invalid_payload"] = CatalogGuard.extract_native_denial_reasons(kotlin)
    end

    test "extracts both branches of a ternary reason assignment" do
      swift = """
      let reason = registrationState == "unconfigured"
          ? "notification_setup_missing"
          : "notification_token_unavailable"
      """

      reasons = CatalogGuard.extract_native_denial_reasons(swift)

      assert "notification_setup_missing" in reasons
      assert "notification_token_unavailable" in reasons
      refute "unconfigured" in reasons
    end

    test "a variable-valued reason extracts NOTHING — the host-supplied seam is not statically bounded" do
      swift = ~S|completion(deny(request, reason: reason, message: "m", hint: "h"))|

      assert [] = CatalogGuard.extract_native_denial_reasons(swift)
    end
  end

  describe "check_native_denial_reasons/1" do
    test "an in-vocabulary reason is clean" do
      assert :ok =
               CatalogGuard.check_native_denial_reasons(
                 ~S|deny(request, reason: "origin_denied", message: "m", hint: "h")|
               )
    end

    test "a seeded allowlist entry is clean" do
      assert :ok =
               CatalogGuard.check_native_denial_reasons(
                 ~S|deny(request, reason: "invalid_payload", message: "m", hint: "h")|
               )
    end

    test "a NINTH out-of-vocabulary reason is a violation — the allowlist is enumerated, not open" do
      assert {:violation, [{:out_of_vocabulary_denial_reason, "wallet_locked"} | _]} =
               CatalogGuard.check_native_denial_reasons(
                 ~S|deny(request, reason: "wallet_locked", message: "m", hint: "h")|
               )
    end
  end

  describe "out_of_vocabulary_denial_allowlist/0" do
    test "enumerates exactly eight strings, each with a justification, sites, and the SEED-008 id" do
      allowlist = CatalogGuard.out_of_vocabulary_denial_allowlist()

      assert length(allowlist) == 8

      for entry <- allowlist do
        assert is_binary(entry.reason)
        assert entry.justification != ""
        assert entry.seed == "SEED-008"
        assert entry.sites != []
      end
    end

    test "no allowlist entry is already in the closed vocabulary — a redundant entry is rot" do
      vocabulary = Enum.map(Crosswake.Shell.Denial.reasons(), &Atom.to_string/1)

      for entry <- CatalogGuard.out_of_vocabulary_denial_allowlist() do
        refute entry.reason in vocabulary,
               "#{entry.reason} is in the closed vocabulary — remove it from the allowlist"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # attestation — gaps AND orphans (D-46)
  # ---------------------------------------------------------------------------

  describe "check_attestation/3" do
    test "exact agreement is clean" do
      assert :ok =
               CatalogGuard.check_attestation(
                 ["app.info.get"],
                 %{"app.info.get" => "app_info"},
                 ["app_info"]
               )
    end

    test "a catalog entry with no shipped command is a GAP" do
      assert {:violation, violations} =
               CatalogGuard.check_attestation(
                 ["app.info.get"],
                 %{"app.info.get" => "app_info"},
                 ["app_info", "orphaned_capability"]
               )

      assert Enum.any?(violations, &match?({:attestation_gap, "orphaned_capability"}, &1))
    end

    test "a shipped command with no catalog entry is an ORPHAN" do
      assert {:violation, violations} =
               CatalogGuard.check_attestation(
                 ["app.info.get", "secret.backdoor"],
                 %{"app.info.get" => "app_info"},
                 ["app_info"]
               )

      assert Enum.any?(violations, &match?({:attestation_orphan, "secret.backdoor"}, &1))
    end

    test "a mapped command absent from the shipped command list is an ORPHAN" do
      assert {:violation, violations} =
               CatalogGuard.check_attestation(
                 ["app.info.get"],
                 %{"app.info.get" => "app_info", "ghost.command" => "ghost"},
                 ["app_info", "ghost"]
               )

      assert Enum.any?(violations, &match?({:attestation_orphan, "ghost.command"}, &1))
    end
  end

  # ---------------------------------------------------------------------------
  # real shipped source — positive control (no false positives)
  # ---------------------------------------------------------------------------

  describe "positive control on real shipped source" do
    test "lib/crosswake/manifest/builder.ex returns clean" do
      source = File.read!(Path.join(File.cwd!(), "lib/crosswake/manifest/builder.ex"))

      assert :ok = CatalogGuard.check_source(source)
    end

    test "every file in the bridge tree returns clean" do
      for path <- CatalogGuard.bridge_sources() do
        assert :ok = CatalogGuard.check_source(File.read!(path)),
               "#{path} is flagged by CatalogGuard.check_source/1"
      end
    end

    test "assert_catalog_closed!/0 does not raise on the shipped tree" do
      assert :ok = CatalogGuard.assert_catalog_closed!()
    end
  end
end
