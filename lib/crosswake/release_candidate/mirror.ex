defmodule Crosswake.ReleaseCandidate.Mirror do
  @moduledoc """
  Evaluates bounded iOS mirror observations without owning Git credentials or mutation.

  The shell adapter refreshes refs, computes the subtree split, and performs any authorized
  porcelain probe. This module keeps the four mirror modes closed and turns incomplete, raced, or
  conflicting observations into a single safe correction.
  """

  @baseline_version "0.2.0"
  @candidate_version "0.2.1"
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @common_input_keys ~w(
    mode version source_ref split_sha recorded_split_sha remote atomic_supported authorization
    dry_run external_state_changed
  )a
  @publication_input_keys @common_input_keys ++ ~w(ancestry approval)a
  @remote_keys ~w(status main tag)a
  @authorization_keys ~w(checked result)a
  @dry_run_keys ~w(status before_main before_tag after_main after_tag)a
  @remote_statuses ~w(PASS UNREACHABLE AMBIGUOUS)
  @authorization_results ["PROVEN", "NOT CHECKED", "DENIED"]
  @dry_run_statuses ["PASS", "APPLIED", "NOT RUN", "REJECTED", "UNPARSEABLE"]
  @ancestry_states ["ANCESTOR", "EQUAL", "DIVERGED", "NOT CHECKED"]
  @approval_keys ~w(status receipt_digest expected_old_ref expected_new_ref)a

  @spec evaluate!(map()) :: map()
  def evaluate!(input) do
    mode = Map.get(input, :mode)

    expected_keys =
      if mode in ["publish", "recovery"], do: @publication_input_keys, else: @common_input_keys

    unless exact_map?(input, expected_keys), do: invalid!()
    unless mode in ["baseline", "candidate", "publish", "recovery"], do: invalid!()
    unless exact_map?(input.remote, @remote_keys), do: invalid!()
    unless exact_map?(input.authorization, @authorization_keys), do: invalid!()
    unless exact_map?(input.dry_run, @dry_run_keys), do: invalid!()

    remote = normalize_remote!(input.remote)
    authorization = normalize_authorization!(input.authorization)
    dry_run = normalize_dry_run!(input.dry_run)
    atomic_supported = boolean!(input.atomic_supported)
    observed_changed = boolean!(input.external_state_changed) or refs_changed?(dry_run)

    normalized =
      %{
        mode: input.mode,
        version: bounded_string(input.version),
        source_ref: bounded_ref(input.source_ref),
        split_sha: sha_or_nil(input.split_sha),
        recorded_split_sha: sha_or_nil(input.recorded_split_sha),
        remote: remote,
        atomic_supported: atomic_supported,
        authorization: authorization,
        dry_run: dry_run,
        external_state_changed: observed_changed
      }
      |> maybe_add_publication_fields(input)

    {state, correction, operation, push_arguments} = disposition(normalized)

    %{
      state: state,
      mode: normalized.mode,
      source_ref: normalized.source_ref,
      split_sha: normalized.split_sha,
      remote_main: reported_ref(normalized, :main),
      remote_tag: reported_ref(normalized, :tag),
      atomic_supported: normalized.atomic_supported,
      authorization_checked: normalized.authorization.checked,
      authorization_result: normalized.authorization.result,
      dry_run_result: normalized.dry_run.status,
      external_state_changed: normalized.external_state_changed,
      correction: correction,
      operation: operation,
      push_arguments: push_arguments
    }
  rescue
    KeyError -> invalid!()
  end

  @spec publication_plan!(map()) :: map()
  def publication_plan!(%{mode: mode} = input) when mode in ["publish", "recovery"],
    do: evaluate!(input)

  def publication_plan!(_input), do: invalid!()

  @doc false
  @spec evaluate_cli!([String.t()]) :: :ok
  def evaluate_cli!(args) when length(args) == 22 do
    [
      mode,
      version,
      source_ref,
      split_sha,
      recorded_split_sha,
      remote_status,
      remote_main,
      remote_tag,
      atomic_supported,
      authorization_checked,
      authorization_result,
      dry_run_status,
      before_main,
      before_tag,
      after_main,
      after_tag,
      external_state_changed,
      ancestry,
      approval_status,
      approval_digest,
      expected_old_ref,
      expected_new_ref
    ] = args

    input = %{
      mode: mode,
      version: version,
      source_ref: source_ref,
      split_sha: nullable(split_sha),
      recorded_split_sha: nullable(recorded_split_sha),
      remote: %{
        status: remote_status,
        main: nullable(remote_main),
        tag: nullable(remote_tag)
      },
      atomic_supported: parse_boolean!(atomic_supported),
      authorization: %{
        checked: parse_boolean!(authorization_checked),
        result: authorization_result
      },
      dry_run: %{
        status: dry_run_status,
        before_main: nullable(before_main),
        before_tag: nullable(before_tag),
        after_main: nullable(after_main),
        after_tag: nullable(after_tag)
      },
      external_state_changed: parse_boolean!(external_state_changed)
    }

    input =
      if mode in ["publish", "recovery"] do
        Map.merge(input, %{
          ancestry: ancestry,
          approval: %{
            status: approval_status,
            receipt_digest: nullable(approval_digest),
            expected_old_ref: nullable(expected_old_ref),
            expected_new_ref: nullable(expected_new_ref)
          }
        })
      else
        input
      end

    result = evaluate!(input)

    IO.puts(Jason.encode!(result))
    :ok
  end

  def evaluate_cli!(_args), do: invalid!()

  defp disposition(%{mode: "baseline"} = input) do
    cond do
      baseline_pass?(input) -> {"PASS", "none", "INSPECT_BASELINE", []}
      input.remote.status != "PASS" -> blocked("refresh_mirror_baseline")
      input.remote.tag != input.split_sha -> blocked("resolve_immutable_tag_conflict")
      true -> blocked("restore_recorded_mirror_baseline")
    end
  end

  defp disposition(%{mode: "candidate"} = input) do
    cond do
      not input.authorization.checked or input.authorization.result == "NOT CHECKED" ->
        blocked("WRITE AUTHORITY NOT CHECKED", "REHEARSE_ATOMIC")

      input.authorization.result == "DENIED" ->
        blocked("restore_mirror_write_authority", "REHEARSE_ATOMIC")

      candidate_pass?(input) ->
        {"PASS", "none", "REHEARSE_ATOMIC", candidate_push_arguments(input)}

      true ->
        blocked("rerun_candidate_mirror_rehearsal", "REHEARSE_ATOMIC")
    end
  end

  defp disposition(%{mode: "publish"} = input) do
    cond do
      publish_applied?(input) ->
        {"PASS", "none", "PUBLISHED", []}

      publish_noop?(input) ->
        {"PASS", "none", "NOOP", []}

      publish_ready?(input) ->
        {"PASS", "none", "PUBLISH_ATOMIC", publish_push_arguments(input)}

      input.remote.tag not in [nil, input.split_sha] ->
        blocked("resolve_immutable_tag_conflict")

      input.ancestry == "DIVERGED" ->
        blocked("resolve_mirror_main_divergence")

      not input.atomic_supported ->
        blocked("require_atomic_mirror_push")

      true ->
        blocked("refresh_publish_observations")
    end
  end

  defp disposition(%{mode: "recovery"} = input) do
    cond do
      recovery_applied?(input) ->
        {"PASS", "none", "RECOVERED", []}

      recovery_ready?(input) ->
        {"PASS", "none", "RECOVER_EXACT_MAIN", recovery_push_arguments(input)}

      true ->
        blocked("obtain_exact_recovery_approval")
    end
  end

  defp baseline_pass?(input) do
    input.version == @baseline_version and
      input.source_ref == "refs/tags/ios-core-v#{@baseline_version}" and
      valid_sha?(input.split_sha) and input.recorded_split_sha == input.split_sha and
      input.remote == %{status: "PASS", main: input.split_sha, tag: input.split_sha} and
      input.authorization == %{checked: false, result: "NOT CHECKED"} and
      input.dry_run == %{
        status: "NOT RUN",
        before_main: input.split_sha,
        before_tag: input.split_sha,
        after_main: input.split_sha,
        after_tag: input.split_sha
      } and not input.external_state_changed
  end

  defp candidate_pass?(input) do
    input.version == @candidate_version and valid_sha?(input.source_ref) and
      valid_sha?(input.split_sha) and input.recorded_split_sha == input.split_sha and
      input.remote.status == "PASS" and valid_sha?(input.remote.main) and
      optional_sha?(input.remote.tag) and input.atomic_supported and
      input.authorization == %{checked: true, result: "PROVEN"} and
      input.dry_run.status == "PASS" and
      input.dry_run.before_main == input.remote.main and
      input.dry_run.before_tag == input.remote.tag and
      input.dry_run.after_main == input.remote.main and
      input.dry_run.after_tag == input.remote.tag and not input.external_state_changed
  end

  defp publish_ready?(input) do
    publication_common?(input, "APPROVED") and input.dry_run.status == "PASS" and
      not input.external_state_changed and input.ancestry in ["ANCESTOR", "EQUAL"] and
      input.remote.tag in [nil, input.split_sha]
  end

  defp publish_noop?(input) do
    publish_ready?(input) and input.ancestry == "EQUAL" and
      input.remote.main == input.split_sha and input.remote.tag == input.split_sha
  end

  defp publish_applied?(input) do
    publication_identity?(input, "APPROVED") and input.remote.status == "PASS" and
      input.atomic_supported and input.authorization == %{checked: true, result: "PROVEN"} and
      input.ancestry in ["ANCESTOR", "EQUAL"] and
      input.dry_run.before_main == input.remote.main and
      input.dry_run.before_tag == input.remote.tag and input.dry_run.status == "APPLIED" and
      input.external_state_changed and input.dry_run.after_main == input.split_sha and
      input.dry_run.after_tag == input.split_sha
  end

  defp recovery_ready?(input) do
    recovery_common?(input) and input.dry_run.status == "PASS" and
      not input.external_state_changed and input.ancestry == "DIVERGED"
  end

  defp recovery_applied?(input) do
    publication_identity?(input, "RECOVERY APPROVED") and input.remote.status == "PASS" and
      input.authorization == %{checked: true, result: "PROVEN"} and
      input.dry_run.before_main == input.remote.main and
      input.dry_run.before_tag == input.remote.tag and input.dry_run.status == "APPLIED" and
      input.external_state_changed and input.dry_run.after_main == input.split_sha and
      input.dry_run.after_tag == input.dry_run.before_tag
  end

  defp recovery_common?(input) do
    publication_identity?(input, "RECOVERY APPROVED") and input.remote.status == "PASS" and
      input.authorization == %{checked: true, result: "PROVEN"} and
      input.dry_run.before_main == input.remote.main and
      input.dry_run.before_tag == input.remote.tag and
      input.dry_run.after_main == input.remote.main and
      input.dry_run.after_tag == input.remote.tag
  end

  defp publication_common?(input, approval_status) do
    publication_identity?(input, approval_status) and input.remote.status == "PASS" and
      input.atomic_supported and input.authorization == %{checked: true, result: "PROVEN"} and
      input.dry_run.before_main == input.remote.main and
      input.dry_run.before_tag == input.remote.tag and
      input.dry_run.after_main == input.remote.main and
      input.dry_run.after_tag == input.remote.tag
  end

  defp publication_identity?(input, approval_status) do
    input.version == @candidate_version and valid_sha?(input.source_ref) and
      valid_sha?(input.split_sha) and input.recorded_split_sha == input.split_sha and
      valid_sha?(input.remote.main) and optional_sha?(input.remote.tag) and
      input.approval.status == approval_status and valid_digest?(input.approval.receipt_digest) and
      input.approval.expected_old_ref == input.remote.main and
      input.approval.expected_new_ref == input.split_sha
  end

  defp candidate_push_arguments(input),
    do: [
      "--dry-run",
      "--porcelain",
      "--atomic",
      "#{input.split_sha}:refs/heads/main",
      "#{input.split_sha}:refs/tags/v#{@candidate_version}"
    ]

  defp publish_push_arguments(input),
    do: [
      "--atomic",
      "#{input.split_sha}:refs/heads/main",
      "#{input.split_sha}:refs/tags/v#{@candidate_version}"
    ]

  defp recovery_push_arguments(input),
    do: [
      "--force-with-lease=refs/heads/main:#{input.approval.expected_old_ref}",
      "#{input.approval.expected_new_ref}:refs/heads/main"
    ]

  defp reported_ref(%{dry_run: %{status: "APPLIED", after_main: value}}, :main), do: value
  defp reported_ref(%{dry_run: %{status: "APPLIED", after_tag: value}}, :tag), do: value

  defp reported_ref(input, key), do: Map.fetch!(input.remote, key)

  defp blocked(correction, operation \\ "NONE"), do: {"BLOCKED", correction, operation, []}

  defp maybe_add_publication_fields(normalized, %{mode: mode} = input)
       when mode in ["publish", "recovery"] do
    Map.merge(normalized, %{
      ancestry: enum!(input.ancestry, @ancestry_states),
      approval: normalize_approval!(input.approval)
    })
  end

  defp maybe_add_publication_fields(normalized, _input), do: normalized

  defp normalize_approval!(approval) do
    unless exact_map?(approval, @approval_keys), do: invalid!()

    %{
      status: bounded_string(approval.status),
      receipt_digest: digest_or_nil(approval.receipt_digest),
      expected_old_ref: sha_or_nil(approval.expected_old_ref),
      expected_new_ref: sha_or_nil(approval.expected_new_ref)
    }
  end

  defp normalize_remote!(remote) do
    status = enum!(remote.status, @remote_statuses)
    %{status: status, main: sha_or_nil(remote.main), tag: sha_or_nil(remote.tag)}
  end

  defp normalize_authorization!(authorization) do
    checked = boolean!(authorization.checked)
    result = enum!(authorization.result, @authorization_results)

    unless (checked and result in ["PROVEN", "DENIED"]) or
             (not checked and result == "NOT CHECKED"),
           do: invalid!()

    %{checked: checked, result: result}
  end

  defp normalize_dry_run!(dry_run) do
    %{
      status: enum!(dry_run.status, @dry_run_statuses),
      before_main: sha_or_nil(dry_run.before_main),
      before_tag: sha_or_nil(dry_run.before_tag),
      after_main: sha_or_nil(dry_run.after_main),
      after_tag: sha_or_nil(dry_run.after_tag)
    }
  end

  defp refs_changed?(dry_run),
    do: dry_run.before_main != dry_run.after_main or dry_run.before_tag != dry_run.after_tag

  defp nullable("-"), do: nil
  defp nullable(value), do: value

  defp parse_boolean!("true"), do: true
  defp parse_boolean!("false"), do: false
  defp parse_boolean!(_value), do: invalid!()

  defp bounded_string(value) when is_binary(value) and byte_size(value) in 1..80, do: value
  defp bounded_string(_value), do: nil

  defp bounded_ref(value) when is_binary(value) and byte_size(value) in 1..100, do: value
  defp bounded_ref(_value), do: nil

  defp sha_or_nil(nil), do: nil
  defp sha_or_nil(value), do: if(valid_sha?(value), do: value, else: nil)
  defp optional_sha?(nil), do: true
  defp optional_sha?(value), do: valid_sha?(value)

  defp digest_or_nil(nil), do: nil
  defp digest_or_nil(value), do: if(valid_digest?(value), do: value, else: nil)

  defp valid_digest?(value) when is_binary(value),
    do: byte_size(value) == 64 and Regex.match?(~r/\A[0-9a-f]+\z/, value)

  defp valid_digest?(_value), do: false

  defp valid_sha?(value) when is_binary(value), do: Regex.match?(@sha_pattern, value)
  defp valid_sha?(_value), do: false

  defp enum!(value, allowed), do: if(value in allowed, do: value, else: invalid!())
  defp boolean!(value) when is_boolean(value), do: value
  defp boolean!(_value), do: invalid!()

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp invalid!, do: raise(ArgumentError, "candidate mirror input is invalid")
end
