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
             "activity_events" => 3,
             "admin_pressure" => 1,
             "approval_activity_events" => 3,
             "approval_policies" => 3,
             "approvals" => 3,
             "operational_records" => 3,
             "roles" => 3,
             "settings" => 1,
             "teams" => 1,
             "users" => 3
           }

    assert body["counts"]["field_service"] == %{
             "adjuster" => 1,
             "assets" => 3,
             "dispatcher" => 1,
             "evidence_events" => 4,
             "evidence_items" => 4,
             "inspection_templates" => 1,
             "jobs" => 3,
             "notes" => 4,
             "permission_pressure" => 7,
             "route_postures" => 5,
             "support_findings" => 4,
             "technician_job_states" => 3,
             "technicians" => 3
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
    assert body["counts"]["field_service"]["jobs"] == 3
  end
end
