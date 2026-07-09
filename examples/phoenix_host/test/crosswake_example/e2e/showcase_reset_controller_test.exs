defmodule CrosswakeExample.E2E.ShowcaseResetControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  test "create returns deterministic showcase reset counts, digest, and browser non-claim" do
    conn =
      build_conn(:post, "/_e2e/showcase-reset", %{})
      |> CrosswakeExample.E2E.ShowcaseResetController.create(%{})

    body = Jason.decode!(conn.resp_body)

    assert body["browser_state_reset"] == false
    assert is_binary(body["digest"])
    assert String.length(body["digest"]) == 64

    assert body["counts"]["saas_admin"] == %{
             "accounts" => 1,
             "approvals" => 3,
             "users" => 2
           }

    assert body["counts"]["field_service_native_pressure"] == %{
             "claims" => 2,
             "submissions" => 0
           }

    assert body["counts"]["learning_training"] == %{
             "browser_state_reset" => false,
             "cards" => 3,
             "decks" => 1,
             "progress" => 0,
             "synced_reviews" => 0
           }
  end

  test "create ignores arbitrary reset scopes and always runs the fixed reset contract" do
    conn =
      build_conn(:post, "/_e2e/showcase-reset", %{
        "table" => "users",
        "scope" => "all",
        "browser_state_reset" => true
      })
      |> CrosswakeExample.E2E.ShowcaseResetController.create(%{
        "table" => "users",
        "scope" => "all",
        "browser_state_reset" => true
      })

    body = Jason.decode!(conn.resp_body)

    refute Map.has_key?(body, "table")
    refute Map.has_key?(body, "scope")
    assert body["browser_state_reset"] == false
    assert body["counts"]["field_service_native_pressure"]["claims"] == 2
  end
end
