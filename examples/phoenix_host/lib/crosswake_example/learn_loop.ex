defmodule CrosswakeExample.LearnLoop do
  @moduledoc """
  Lane-local LearnLoop read context for the subscription learning showcase.

  Static product breadth is deterministic fixture data. Persisted workflow
  evidence stays in the existing flashcard and local-first review-event tables.
  """

  alias CrosswakeExample.Flashcards
  alias CrosswakeExample.LearnLoop.Fixtures
  alias CrosswakeExample.LocalFirst.Study

  @history_notice "server-confirmed cached read-only progress"

  def dashboard_context(learner_id) when is_binary(learner_id) do
    learner = learner!(learner_id)
    active_course = course!(learner.active_course_id)
    next_lesson = lesson!(active_course.next_lesson_id)
    active_pack = pack!(learner.active_pack_id)

    %{
      learner: learner,
      active_course: course_summary(active_course),
      next_lesson: lesson_summary(next_lesson),
      next_pack: pack_summary(active_pack),
      sync_ledger: Fixtures.sync_ledger_preview(),
      entitlement_summary: entitlement_summary(learner.subscription_state),
      entitlement_authority: "Backend projection",
      recent_server_review_events: history_events(),
      route_posture: route_posture!("learnloop-dashboard"),
      route_postures: Fixtures.route_postures(),
      support_findings: Fixtures.support_findings(),
      posture_badges: [
        "LiveView route",
        "Cached read-only",
        "Offline island",
        "Backend projection"
      ]
    }
  end

  def course_context!(course_id) when is_binary(course_id) do
    course = course!(course_id)
    lessons = lessons_for_course(course.id)
    pack = pack!(course.content_pack_id)

    %{
      course: course_summary(course),
      study_session_path: "/learnloop/study/session",
      subscription_path: "/learnloop/subscription",
      lessons: Enum.map(lessons, &lesson_summary/1),
      next_lesson: lesson_summary(lesson!(course.next_lesson_id)),
      content_pack: pack_summary(pack),
      route_posture: route_posture!("learnloop-course"),
      support_findings:
        support_findings_for([
          "learnloop-course",
          "learnloop-study-session",
          "learnloop-subscription"
        ]),
      primary_actions: [
        %{
          label: "Start offline study",
          path: "/learnloop/study/session",
          route_id: "learnloop-study-session"
        },
        %{
          label: "Review access",
          path: "/learnloop/subscription",
          route_id: "learnloop-subscription"
        }
      ],
      offline_notice:
        "Course metadata is cached read-only; local-first answers happen only in the study island."
    }
  end

  def pack_context!(pack_id) when is_binary(pack_id) do
    pack = pack!(pack_id)
    lessons = Enum.map(pack.lesson_ids, &lesson!/1)

    %{
      pack: pack_summary(pack),
      lessons: Enum.map(lessons, &lesson_summary/1),
      route_posture: route_posture!("learnloop-pack"),
      study_session: %{
        path: "/learnloop/study/session",
        route_id: "learnloop-study-session",
        support_labels: ["Offline island", "Local-first outbox"],
        sync_model: "append-only review events replay through the existing LocalFirst.Study seam"
      },
      sync_ledger: Fixtures.sync_ledger_preview(),
      support_findings: support_findings_for(["learnloop-pack", "learnloop-study-session"])
    }
  end

  def history_context do
    %{
      label: "Study history",
      notice: @history_notice,
      cached_snapshot: "Cached read-only",
      events: history_events(),
      progress_checkpoints: Fixtures.progress_checkpoints(),
      route_posture: route_posture!("learnloop-history"),
      support_findings: support_findings_for(["learnloop-history", "learnloop-study-session"]),
      sync_copy:
        "History shows server-confirmed review events and keeps reconciliation route-local."
    }
  end

  def subscription_context(learner_id) when is_binary(learner_id) do
    learner = learner!(learner_id)

    %{
      learner: learner,
      active_state: entitlement_summary(learner.subscription_state),
      entitlement_snapshots: Fixtures.entitlement_snapshots(),
      route_posture: route_posture!("learnloop-subscription"),
      support_findings: support_findings_for(["learnloop-subscription"]),
      fail_closed_copy: [
        "Access stays closed until backend projection refreshes",
        "Backend projection required",
        "Mock storefront evidence received",
        "No live StoreKit, Play Billing, or RevenueCat adapter in this demo"
      ]
    }
  end

  def reset_seed! do
    flashcard_counts = Flashcards.reset_seed!()

    %{
      learning_training: %{
        browser_state_reset: Map.fetch!(flashcard_counts, :browser_state_reset),
        learners: length(Fixtures.learners()),
        courses: length(Fixtures.courses()),
        lessons: length(Fixtures.lessons()),
        content_packs: length(Fixtures.packs()),
        progress_checkpoints: length(Fixtures.progress_checkpoints()),
        subscription_states: length(Fixtures.entitlement_snapshots()),
        route_postures: length(Fixtures.route_postures()),
        support_findings: length(Fixtures.support_findings()),
        synced_reviews: Map.fetch!(flashcard_counts, :synced_reviews)
      }
    }
  end

  def digest_components do
    [
      Fixtures.digest_components(),
      Flashcards.seed_digest_components()
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  defp learner!(learner_id) do
    Fixtures.learners()
    |> Enum.find(&(&1.id == learner_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop learner: #{inspect(learner_id)}"
      learner -> learner
    end
  end

  defp course!(course_id) do
    Fixtures.courses()
    |> Enum.find(&(&1.id == course_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop course: #{inspect(course_id)}"
      course -> course
    end
  end

  defp lesson!(lesson_id) do
    Fixtures.lessons()
    |> Enum.find(&(&1.id == lesson_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop lesson: #{inspect(lesson_id)}"
      lesson -> lesson
    end
  end

  defp pack!(pack_id) do
    Fixtures.packs()
    |> Enum.find(&(&1.id == pack_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop pack: #{inspect(pack_id)}"
      pack -> pack
    end
  end

  defp route_posture!(route_id) do
    Fixtures.route_postures()
    |> Enum.find(&(&1.route_id == route_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop route posture: #{inspect(route_id)}"
      posture -> posture
    end
  end

  defp lessons_for_course(course_id) do
    Fixtures.lessons()
    |> Enum.filter(&(&1.course_id == course_id))
  end

  defp course_summary(course) do
    Map.take(course, [
      :id,
      :title,
      :subtitle,
      :status,
      :level,
      :progress_percent,
      :next_lesson_id,
      :content_pack_id,
      :route_id
    ])
  end

  defp lesson_summary(lesson) do
    lesson
    |> Map.take([
      :id,
      :course_id,
      :title,
      :status,
      :duration_minutes,
      :route_id,
      :access_state,
      :support_labels,
      :gate_copy
    ])
    |> Map.put_new(:gate_copy, nil)
  end

  defp pack_summary(pack) do
    Map.take(pack, [
      :id,
      :title,
      :version,
      :status,
      :course_id,
      :lesson_ids,
      :card_count,
      :route_id,
      :offline_posture,
      :storage_owner,
      :support_labels,
      :summary
    ])
  end

  defp entitlement_summary(state) do
    Fixtures.entitlement_snapshots()
    |> Enum.find(&(&1.state == state))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop subscription state: #{inspect(state)}"
      snapshot -> snapshot
    end
  end

  defp support_findings_for(route_ids) do
    Fixtures.support_findings()
    |> Enum.filter(&(&1.route_id in route_ids))
  end

  defp history_events do
    Study.list_events()
    |> Enum.map(fn event ->
      %{
        id: event.id,
        client_mutation_id: event.client_mutation_id,
        card_id: event.card_id,
        rating: event.rating,
        status: event.status,
        status_label: "server-confirmed",
        cached_snapshot: "Cached read-only",
        inserted_at: event.inserted_at
      }
    end)
  end
end
