defmodule Crosswake.ReleaseCandidate.Projection do
  @moduledoc false

  alias Crosswake.ReleaseCandidate.Receipt

  @spec markdown(map()) :: String.t()
  def markdown(receipt) do
    receipt = Receipt.validate!(receipt)

    """
    #{receipt.state}

    - checks: #{passed_checks(receipt)}/#{length(receipt.checks)} passed
    - credentials exercised: #{yes_no(receipt.credentials.exercised)}
    - external state changed: #{yes_no(receipt.external_state.changed)}
    - next action: #{receipt.next_action}
    """
  end

  @spec github_summary(map()) :: String.t()
  def github_summary(receipt) do
    receipt = Receipt.validate!(receipt)

    """
    #{receipt.state}
    checks: #{passed_checks(receipt)}/#{length(receipt.checks)} passed
    credentials exercised: #{yes_no(receipt.credentials.exercised)}
    external state changed: #{yes_no(receipt.external_state.changed)}
    next action: #{receipt.next_action}
    """
  end

  @spec terminal(map(), keyword()) :: String.t()
  def terminal(receipt, opts \\ []) do
    receipt = Receipt.validate!(receipt)
    _no_color? = Keyword.get(opts, :no_color, System.get_env("NO_COLOR") not in [nil, ""])

    """
    #{receipt.state}
    checks: #{passed_checks(receipt)}/#{length(receipt.checks)} passed
    credentials exercised: #{yes_no(receipt.credentials.exercised)}
    external state changed: #{yes_no(receipt.external_state.changed)}
    next action: #{receipt.next_action}
    """
  end

  defp passed_checks(receipt), do: Enum.count(receipt.checks, &(&1.status == "PASS"))
  defp yes_no(true), do: "yes"
  defp yes_no(false), do: "no"
end
