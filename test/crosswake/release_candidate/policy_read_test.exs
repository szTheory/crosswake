defmodule Crosswake.ReleaseCandidate.PolicyReadTest do
  use ExUnit.Case, async: true
  alias Crosswake.ReleaseCandidate.PolicyRead
  @root "https://api.github.com/repos/szTheory/crosswake"
  @token "fixture-policy-credential"

  test "only exact policy reads receive the dedicated credential" do
    for path <- [
          "/branches/main/protection",
          "/rulesets?per_page=100",
          "/rulesets?per_page=100&page=2",
          "/rulesets/123"
        ] do
      assert PolicyRead.github_env(@root <> path, @token) == [{"GH_TOKEN", @token}]
    end
  end

  test "candidate and publication reads retain their ordinary credential" do
    for path <- [
          "/pulls/219",
          "/actions/runs/1",
          "/commits/abc",
          "/actions/artifacts",
          "/branches/main",
          "/branches/main/protection/required_status_checks",
          "/rulesets/123?redirect=1",
          "/rulesets?per_page=100&other=1"
        ] do
      assert PolicyRead.github_env(@root <> path, @token) == []
    end
  end

  test "different hosts repositories schemes ports and userinfo never receive the credential" do
    for url <- [
          "https://api.github.com/repos/other/crosswake/branches/main/protection",
          "https://example.org/repos/szTheory/crosswake/branches/main/protection",
          "http://api.github.com/repos/szTheory/crosswake/branches/main/protection",
          "https://api.github.com:444/repos/szTheory/crosswake/branches/main/protection",
          "https://user@api.github.com/repos/szTheory/crosswake/branches/main/protection",
          @root <> "/branches/main/protection#fragment"
        ] do
      assert PolicyRead.github_env(url, @token) == []
    end
  end

  test "missing dedicated credential preserves the caller's existing environment" do
    for value <- [nil, ""] do
      assert PolicyRead.github_env(@root <> "/branches/main/protection", value) == []
    end
  end
end
