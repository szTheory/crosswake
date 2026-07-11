defmodule CrosswakeExample.LearnLoop.StudyController do
  use Phoenix.Controller, formats: [:html]

  alias Crosswake.Offline.Contracts
  alias CrosswakeExample.LearnLoop, as: LearnLoopContext
  alias CrosswakeExample.PageTitle

  @pack_id "learnloop_daily_pack"

  def index(conn, _params) do
    island =
      Contracts.new_study_session_island(
        "learnloop_study_session_contract",
        route_id: "learnloop-study-session",
        sync_seam: "learnloop_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    pack_context = LearnLoopContext.pack_context!(@pack_id)

    conn
    |> put_view(CrosswakeExample.LearnLoopStudyHTML)
    |> put_root_layout(false)
    |> render(:index,
      page_title: PageTitle.learn("Offline Study"),
      island: island,
      pack: pack_context.pack,
      support_findings: pack_context.support_findings,
      sync_ledger: pack_context.sync_ledger
    )
  end
end
