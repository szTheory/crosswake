defmodule Crosswake.ReleaseCandidate.Workflow do
  @moduledoc false

  @children ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a
  @public_children ~w(hex ios_mirror android)a
  @statuses ~w(success failed skipped)
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @dependencies %{
    hex: [],
    ios_mirror: [],
    android: [],
    ios_public_proof: ~w(hex ios_mirror)a,
    android_public_proof: ~w(hex android)a,
    exact_public: @children -- [:exact_public]
  }

  @spec rollup!(map()) :: map()
  def rollup!(input) do
    unless exact_map?(input, ~w(approved_ref candidate_receipt children version)a),
      do: invalid!()

    approved_ref = exact_hex!(input.approved_ref, 40)
    candidate_receipt = exact_hex!(input.candidate_receipt, 64)
    children = children!(input.children)
    version = version!(input.version)

    Enum.each(@children, fn child ->
      if children[child] == "success" and
           not Enum.all?(@dependencies[child], &(children[&1] == "success")),
         do: invalid!()
    end)

    coordinates = coordinates(version)

    successful_coordinates =
      @public_children
      |> Enum.filter(&(children[&1] == "success"))
      |> Enum.map(&Map.fetch!(coordinates, &1))
      |> Enum.sort()

    failed_child = Enum.find(@children, &(children[&1] != "success"))

    state =
      cond do
        is_nil(failed_child) -> "COMPLETE"
        successful_coordinates == [] -> "BLOCKED"
        true -> "PARTIAL"
      end

    %{
      schema_version: "1.1.0",
      approved_ref: approved_ref,
      candidate_receipt: candidate_receipt,
      version: version,
      child_states: children,
      successful_coordinates: successful_coordinates,
      failed_step: if(failed_child, do: Atom.to_string(failed_child)),
      failed_ref: if(failed_child, do: approved_ref),
      state: state,
      next_action:
        if(state == "COMPLETE",
          do: "no_action_required",
          else: "retry_failed_step_from_exact_ref_or_publish_forward_fix"
        ),
      receipt_external_state: receipt_external_state(state, successful_coordinates, failed_child)
    }
  rescue
    KeyError -> invalid!()
  end

  @spec validate!(map()) :: map()
  def validate!(result) do
    unless exact_map?(
             result,
             ~w(schema_version approved_ref candidate_receipt version child_states successful_coordinates failed_step failed_ref state next_action receipt_external_state)a
           ),
           do: invalid!()

    rebuilt =
      rollup!(%{
        approved_ref: result.approved_ref,
        candidate_receipt: result.candidate_receipt,
        children: result.child_states,
        version: result.version
      })

    if rebuilt == result, do: result, else: invalid!()
  rescue
    KeyError -> invalid!()
  end

  @doc false
  def evaluate_cli! do
    approved_head = exact_hex!(System.fetch_env!("APPROVED_HEAD"), 40)
    approved_tree = exact_hex!(System.fetch_env!("APPROVED_TREE"), 40)
    merge_oid = exact_hex!(System.fetch_env!("APPROVED_REF"), 40)

    output =
      rollup!(%{
        approved_ref: merge_oid,
        candidate_receipt: System.fetch_env!("CANDIDATE_RECEIPT"),
        version: System.fetch_env!("APPROVED_VERSION"),
        children: %{
          hex: workflow_status!(System.fetch_env!("HEX_STATE")),
          ios_mirror: workflow_status!(System.fetch_env!("IOS_STATE")),
          android: workflow_status!(System.fetch_env!("ANDROID_STATE")),
          ios_public_proof: workflow_status!(System.fetch_env!("IOS_PROOF_STATE")),
          android_public_proof: workflow_status!(System.fetch_env!("ANDROID_PROOF_STATE")),
          exact_public: workflow_status!(System.fetch_env!("EXACT_PUBLIC_STATE"))
        }
      })

    persisted =
      Map.merge(output, %{
        approved_head: approved_head,
        approved_tree: approved_tree,
        merge_oid: merge_oid
      })

    File.write!(
      System.get_env("LINKED_RELEASE_STATUS", "linked-release-status.json"),
      Jason.encode!(persisted)
    )

    if output.state != "COMPLETE", do: System.halt(1)
    output
  end

  defp children!(children) do
    unless exact_map?(children, @children), do: invalid!()
    Map.new(@children, &{&1, enum!(Map.fetch!(children, &1), @statuses)})
  end

  defp version!(version) when is_binary(version) do
    if Regex.match?(@version_pattern, version), do: version, else: invalid!()
  end

  defp version!(_version), do: invalid!()

  defp coordinates(version) do
    %{
      hex: "hex:crosswake@#{version}",
      ios_mirror: "swift:crosswake-shell-core-ios@#{version}",
      android: "maven:io.crosswake:crosswake-shell-core@#{version}"
    }
  end

  defp workflow_status!("success"), do: "success"
  defp workflow_status!("skipped"), do: "skipped"
  defp workflow_status!(status) when status in ~w(failure cancelled), do: "failed"
  defp workflow_status!(_status), do: invalid!()

  defp receipt_external_state("COMPLETE", coordinates, _failed_child) do
    %{
      publication: "COMPLETE",
      successful_coordinates: coordinates,
      failed_step: nil,
      changed: true,
      all_linked_proven: true
    }
  end

  defp receipt_external_state("PARTIAL", coordinates, failed_child) do
    %{
      publication: "PARTIAL",
      successful_coordinates: coordinates,
      failed_step: Atom.to_string(failed_child),
      changed: true,
      all_linked_proven: false
    }
  end

  defp receipt_external_state("BLOCKED", _coordinates, _failed_child) do
    %{
      publication: "NONE",
      successful_coordinates: [],
      failed_step: nil,
      changed: false,
      all_linked_proven: false
    }
  end

  defp exact_hex!(value, size) when is_binary(value) and byte_size(value) == size do
    if Regex.match?(~r/\A[0-9a-f]+\z/, value), do: value, else: invalid!()
  end

  defp exact_hex!(_value, _size), do: invalid!()
  defp enum!(value, allowed), do: if(value in allowed, do: value, else: invalid!())

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false
  defp invalid!, do: raise(ArgumentError, "release workflow observation is invalid")
end
