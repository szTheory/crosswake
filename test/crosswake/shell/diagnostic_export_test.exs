defmodule Crosswake.Shell.DiagnosticExportTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.DiagnosticExport
  alias Crosswake.Shell.DiagnosticExport.Envelope
  alias Crosswake.Shell.DiagnosticExport.NativeDiagnostic

  # ---------------------------------------------------------------------------
  # Task 1: Behaviour, Envelope + NativeDiagnostic structs, closed-enum accessors
  # ---------------------------------------------------------------------------

  describe "behaviour" do
    test "exports the export/1 callback" do
      callbacks = DiagnosticExport.behaviour_info(:callbacks)
      assert {:export, 1} in callbacks
    end
  end

  describe "Envelope struct" do
    test "raises when constructed without all 7 enforce-keys" do
      assert_raise ArgumentError, fn ->
        # Missing required fields — should raise
        %Envelope{}
      end
    end

    test "can be constructed with all 7 enforce-keys" do
      env = %Envelope{
        schema_version: "1",
        layer: :native,
        platform: :ios,
        native_runtime_version: "1.0.0",
        kind: :crash,
        correlation_id: "corr-001",
        observed_at: "2026-06-04T00:00:00Z"
      }

      assert env.schema_version == "1"
      assert env.layer == :native
      assert env.platform == :ios
    end

    test "has native_diagnostic as optional (non-enforced) field defaulting to nil" do
      env = %Envelope{
        schema_version: "1",
        layer: :native,
        platform: :ios,
        native_runtime_version: "1.0.0",
        kind: :crash,
        correlation_id: "corr-001",
        observed_at: "2026-06-04T00:00:00Z"
      }

      assert is_nil(env.native_diagnostic)
    end
  end

  describe "NativeDiagnostic struct" do
    test "raises when constructed without both enforce-keys" do
      assert_raise ArgumentError, fn ->
        %NativeDiagnostic{}
      end
    end

    test "has exactly source and exit_reason keys — no raw_payload, no open map" do
      nd = %NativeDiagnostic{source: :metrickit, exit_reason: :crash}
      keys = nd |> Map.from_struct() |> Map.keys()
      assert :source in keys
      assert :exit_reason in keys
      refute :raw_payload in keys
      assert length(keys) == 2
    end
  end

  describe "layers/0" do
    test "returns exactly [:native, :web, :bridge]" do
      assert DiagnosticExport.layers() == [:native, :web, :bridge]
    end
  end

  describe "platforms/0" do
    test "returns exactly [:ios, :android, :web]" do
      assert DiagnosticExport.platforms() == [:ios, :android, :web]
    end
  end

  describe "kinds/0" do
    test "covers the 6-atom locked set" do
      kinds = DiagnosticExport.kinds()
      assert :crash in kinds
      assert :termination in kinds
      assert :hang in kinds
      assert :cpu in kinds
      assert :bridge_fault in kinds
      assert :web_fault in kinds
    end
  end

  describe "sources/0" do
    test "returns [:metrickit, :app_exit_info]" do
      assert DiagnosticExport.sources() == [:metrickit, :app_exit_info]
    end
  end

  describe "exit_reasons/0" do
    test "covers the 8-atom locked set" do
      reasons = DiagnosticExport.exit_reasons()
      assert :crash in reasons
      assert :anr in reasons
      assert :low_memory in reasons
      assert :user_requested in reasons
      assert :hang in reasons
      assert :cpu_resource_limit in reasons
      assert :abnormal_exit in reasons
      assert :other in reasons
    end
  end

  # ---------------------------------------------------------------------------
  # Task 2: forbidden_keys/0, allowed_keys/0, sanitize/1, to_map/1
  # ---------------------------------------------------------------------------

  describe "forbidden_keys/0" do
    test "contains the canonical 19-key set" do
      fk = DiagnosticExport.forbidden_keys()
      assert :token in fk
      assert :raw_token in fk
      assert :device_token in fk
      assert :registration_token in fk
      assert :apns_token in fk
      assert :fcm_token in fk
      assert :provider_payload in fk
      assert :raw_payload in fk
      assert :notification_title in fk
      assert :notification_body in fk
      assert :route_params in fk
      assert :actor_id in fk
      assert :subject_ref in fk
      assert :session_ref in fk
      assert :device_id in fk
      assert :ip in fk
      assert :user_agent in fk
      assert :email in fk
      assert :provider_response_body in fk
      assert length(fk) == 19
    end
  end

  describe "allowed_keys/0" do
    test "contains all envelope fields" do
      ak = DiagnosticExport.allowed_keys()
      assert :schema_version in ak
      assert :layer in ak
      assert :platform in ak
      assert :native_runtime_version in ak
      assert :kind in ak
      assert :correlation_id in ak
      assert :observed_at in ak
    end

    test "shares no key with forbidden_keys/0 (disjoint sets)" do
      fk = DiagnosticExport.forbidden_keys()
      ak = DiagnosticExport.allowed_keys()
      assert Enum.filter(fk, &(&1 in ak)) == []
    end
  end

  describe "sanitize/1" do
    @valid_attrs %{
      schema_version: "1",
      layer: :native,
      platform: :ios,
      kind: :crash,
      native_runtime_version: "1.0.0",
      correlation_id: "corr-001",
      observed_at: "2026-06-04T00:00:00Z"
    }

    test "returns {:ok, %Envelope{}} for a valid native iOS crash attrs map" do
      assert {:ok, %Envelope{} = env} = DiagnosticExport.sanitize(@valid_attrs)
      assert env.layer == :native
      assert env.platform == :ios
      assert env.kind == :crash
    end

    test "returns {:error, :redaction_failed} when a forbidden key is present" do
      attrs = Map.put(@valid_attrs, :token, "leak")
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize(attrs)
    end

    test "returns {:error, :redaction_failed} for each of the 19 forbidden keys" do
      fk = DiagnosticExport.forbidden_keys()

      for forbidden_key <- fk do
        attrs = Map.put(@valid_attrs, forbidden_key, "injected")
        assert {:error, :redaction_failed} = DiagnosticExport.sanitize(attrs),
               "Expected :redaction_failed when #{forbidden_key} is present"
      end
    end

    test "returns {:error, :redaction_failed} when layer is out of enum" do
      attrs = Map.put(@valid_attrs, :layer, :rogue)
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize(attrs)
    end

    test "returns {:error, :redaction_failed} for an unexpected key" do
      attrs = Map.put(@valid_attrs, :unexpected_key, "value")
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize(attrs)
    end

    test "returns {:error, :redaction_failed} for non-map input" do
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize(:not_a_map)
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize("string")
      assert {:error, :redaction_failed} = DiagnosticExport.sanitize(nil)
    end
  end

  describe "to_map/1" do
    test "stringifies atom values and rejects nils" do
      {:ok, env} =
        DiagnosticExport.sanitize(%{
          schema_version: "1",
          layer: :native,
          platform: :ios,
          kind: :crash,
          native_runtime_version: "1.0.0",
          correlation_id: "corr-001",
          observed_at: "2026-06-04T00:00:00Z"
        })

      m = DiagnosticExport.to_map(env)
      assert m["layer"] == "native"
      assert m["platform"] == "ios"
      assert m["kind"] == "crash"
      assert m["schema_version"] == "1"
      refute Enum.any?(m, fn {_, v} -> is_nil(v) end)
      refute Enum.any?(m, fn {_, v} -> is_atom(v) end)
    end

    test "recurses into nested NativeDiagnostic and stringifies atoms" do
      nd = %NativeDiagnostic{source: :metrickit, exit_reason: :crash}

      env = %Envelope{
        schema_version: "1",
        layer: :native,
        platform: :ios,
        native_runtime_version: "1.0.0",
        kind: :crash,
        correlation_id: "corr-001",
        observed_at: "2026-06-04T00:00:00Z",
        native_diagnostic: nd
      }

      m = DiagnosticExport.to_map(env)
      assert is_map(m["native_diagnostic"])
      assert m["native_diagnostic"]["source"] == "metrickit"
      assert m["native_diagnostic"]["exit_reason"] == "crash"
    end
  end
end
