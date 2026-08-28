defmodule CrosswakeExample.PageTitleTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Flashcards
  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.Router
  alias CrosswakeExample.SelectiveNative.Claims
  alias CrosswakeExample.SelectiveNative.Fixtures, as: NativeFixtures
  alias CrosswakeExample.Showcase.Reset

  @endpoint CrosswakeExample.Endpoint

  @expected_route_titles %{
    "bridge-proof" => PageTitle.crosswake("Bridge Proof"),
    "commerce-paywall-entry" => PageTitle.crosswake("Paywall Proof"),
    "decks-index" => PageTitle.learn("Decks"),
    "decks-show" => PageTitle.learn("Deck"),
    "fieldserv-evidence-review" => PageTitle.field("Evidence Review"),
    "fieldserv-inspection" => PageTitle.field("Inspection"),
    "fieldserv-job" => PageTitle.field("Job"),
    "fieldserv-job-capture" => PageTitle.field("Capture"),
    "fieldserv-jobs" => PageTitle.field("Jobs"),
    "gating-beta-feature" => PageTitle.crosswake("Beta Feature Gate"),
    "library" => PageTitle.crosswake("Lesson Library"),
    "learnloop-course" => PageTitle.learn("Course"),
    "learnloop-dashboard" => PageTitle.learn("Dashboard"),
    "learnloop-history" => PageTitle.learn("History"),
    "learnloop-pack" => PageTitle.learn("Content Pack"),
    "learnloop-study-session" => PageTitle.learn("Offline Study"),
    "learnloop-subscription" => PageTitle.learn("Subscription access"),
    "local-first-study-history" => PageTitle.learn("Study History"),
    "local-first-study-session" => PageTitle.learn("Study Session"),
    "media-proof-lane" => PageTitle.crosswake("Media Proof"),
    "offline-study" => PageTitle.learn("Offline Study"),
    "saas-account" => PageTitle.admin("Account Health"),
    "saas-admin-member-access" => PageTitle.admin("Admin Member Access"),
    "saas-approval" => PageTitle.admin("Approval Detail"),
    "saas-approvals" => PageTitle.admin("Approvals"),
    "saas-dashboard" => PageTitle.admin("Dashboard"),
    "saas-profile-settings" => PageTitle.admin("Profile Settings"),
    "selective-native-claim" => PageTitle.field("Claim Detail"),
    "selective-native-claim-capture" => PageTitle.field("Capture Evidence"),
    "selective-native-claims" => PageTitle.field("Claims"),
    "selective-native-submission-review" => PageTitle.field("Review Evidence"),
    "showcase-hub" => PageTitle.crosswake("Showcase"),
    "sigra-step-up" => PageTitle.admin("Step-up Challenge")
  }

  setup do
    Reset.reset!()
    NativeFixtures.seed()
    :ok
  end

  test "representative HTML routes render browser titles" do
    claim = Claims.list_claims() |> List.first()
    deck = Flashcards.list_decks() |> List.first()

    assert_title("/", PageTitle.crosswake("Showcase"))
    assert_title("/offline", PageTitle.learn("Offline Study"))
    assert_title("/bridge-proof", PageTitle.crosswake("Bridge Proof"))
    assert_title("/saas/dashboard", PageTitle.admin("Dashboard"))
    assert_title("/saas/accounts/acct-north", PageTitle.admin("Northwind Workspace"))
    assert_title("/saas/approvals/approval-1", PageTitle.admin("Quarterly spend increase"))
    assert_title("/fieldserv/jobs", PageTitle.field("Jobs"))
    assert_title("/fieldserv/jobs/job-1", PageTitle.field("Broken windshield"))

    assert_title(
      "/fieldserv/jobs/job-1/inspection",
      PageTitle.field("Broken windshield Inspection")
    )

    assert_title("/fieldserv/jobs/job-1/capture", PageTitle.field("Broken windshield Capture"))

    assert_title(
      "/fieldserv/jobs/job-1/evidence/evidence-1/review",
      PageTitle.field("Windshield crack overview Review")
    )

    assert_title("/native/claims/#{claim.id}/capture", PageTitle.field("Capture Evidence"))
    assert_title("/decks/#{deck.id}", PageTitle.learn(deck.title))
  end

  test "all browser-visible Crosswake routes have planned titles" do
    expected_ids = @expected_route_titles |> Map.keys() |> MapSet.new()

    actual_ids =
      Router
      |> Phoenix.Router.routes()
      |> Enum.filter(&browser_get_route?/1)
      |> Enum.map(&route_id!/1)
      |> MapSet.new()

    assert actual_ids == expected_ids
  end

  defp assert_title(path, title) do
    html =
      build_conn()
      |> get(path)
      |> html_response(200)

    assert html =~ ~r/<title[^>]*>#{Regex.escape(title)}<\/title>/
    refute html =~ ~r/<title[^>]*>localhost/i
  end

  defp browser_get_route?(%{verb: :get, path: "/_e2e/" <> _}), do: false
  defp browser_get_route?(%{verb: :get}), do: true
  defp browser_get_route?(_route), do: false

  defp route_id!(route) do
    case RouterMetadata.fetch(route.metadata) do
      {:ok, policy} -> policy.id
      :error -> raise "browser route #{route.path} is missing Crosswake metadata"
    end
  end
end
