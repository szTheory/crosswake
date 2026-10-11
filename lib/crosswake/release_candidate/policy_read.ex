defmodule Crosswake.ReleaseCandidate.PolicyRead do
  @moduledoc false

  # Use the policy credential only for the fixed repository's policy reads.
  # Candidate, check, run, artifact and commit reads keep the workflow token.
  def github_env(url, token) when is_binary(url) and is_binary(token) and byte_size(token) > 0 do
    case URI.parse(url) do
      %URI{
        scheme: "https",
        host: "api.github.com",
        port: 443,
        userinfo: nil,
        path: path,
        query: query,
        fragment: nil
      } ->
        if policy_path?(path, query), do: [{"GH_TOKEN", token}], else: []

      _ ->
        []
    end
  end

  def github_env(_, _), do: []

  defp policy_path?("/repos/szTheory/crosswake/branches/main/protection", nil), do: true

  defp policy_path?("/repos/szTheory/crosswake/rulesets", query) when is_binary(query),
    do: Regex.match?(~r{\Aper_page=100(?:&page=[1-9][0-9]*)?\z}, query)

  defp policy_path?(path, nil) when is_binary(path),
    do: Regex.match?(~r{\A/repos/szTheory/crosswake/rulesets/[1-9][0-9]*\z}, path)

  defp policy_path?(_, _), do: false
end
