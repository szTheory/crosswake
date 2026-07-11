defmodule CrosswakeExample.LearnLoop.FixturesTest do
  use ExUnit.Case, async: true

  @learn_loop Module.concat([CrosswakeExample, LearnLoop])
  @fixtures Module.concat([CrosswakeExample, LearnLoop, Fixtures])
  @route_ids [
    "learnloop-dashboard",
    "learnloop-course",
    "learnloop-pack",
    "learnloop-study-session",
    "learnloop-history",
    "learnloop-subscription"
  ]

  @tag :learnloop_fixture_density
  test "LearnLoop fixture density contract covers learners, courses, packs, progress, subscription state, and support truth" do
    module =
      assert_exported!(
        @fixtures,
        :seed,
        0,
        "LearnLoop fixture density contract D-01/D-23/D-24 requires #{@fixtures}.seed/0"
      )

    data = apply(module, :seed, [])

    assert is_map(data),
           "LearnLoop fixture density contract D-23 requires seed/0 to return deterministic lane data"

    learners =
      assert_min_list(
        data,
        :learners,
        3,
        "LearnLoop fixture density contract D-23/D-33 requires realistic learner and coach personas"
      )

    assert_id_present!(
      learners,
      "learner-iris",
      "LearnLoop fixture density contract D-01 requires stable learner-iris for the route-tour path"
    )

    courses =
      assert_min_list(
        data,
        :courses,
        3,
        "LearnLoop fixture density contract D-01/D-03 requires multiple realistic courses without broad LMS scope"
      )

    assert_id_present!(
      courses,
      "course-elixir-routing",
      "LearnLoop fixture density contract D-01 requires stable course-elixir-routing"
    )

    lessons =
      assert_min_list(
        data,
        :lessons,
        6,
        "LearnLoop fixture density contract D-01/D-32 requires lesson rows for the representative learning path"
      )

    assert_id_present!(
      lessons,
      "lesson-offline-review",
      "LearnLoop fixture density contract D-04/D-09 requires stable lesson-offline-review"
    )

    packs =
      assert_min_list(
        data,
        :content_packs,
        2,
        "LearnLoop fixture density contract D-10/D-34 requires content-pack metadata"
      )

    assert_id_present!(
      packs,
      "learnloop_daily_pack",
      "LearnLoop fixture density contract D-10 requires stable learnloop_daily_pack"
    )

    assert_min_list(
      data,
      :progress_checkpoints,
      3,
      "LearnLoop fixture density contract D-12/D-14 requires server-confirmed progress projection rows"
    )

    entitlement_states =
      assert_min_list(
        data,
        :subscription_states,
        4,
        "LearnLoop fixture density contract D-16/D-19 requires granted, pending, stale, and denied subscription states"
      )

    for state <- [:granted, :pending, :stale, :denied] do
      assert Enum.any?(entitlement_states, &(Map.get(&1, :state) == state)),
             "LearnLoop fixture density contract D-19 requires #{inspect(state)} entitlement state"
    end

    route_postures =
      assert_min_list(
        data,
        :route_postures,
        6,
        "LearnLoop fixture density contract D-08/D-10/D-41 requires route posture rows for all LearnLoop routes"
      )

    assert MapSet.new(Enum.map(route_postures, &Map.get(&1, :route_id))) ==
             MapSet.new(@route_ids),
           "LearnLoop fixture density contract D-04 requires stable LearnLoop route ids"

    assert_min_list(
      data,
      :support_findings,
      5,
      "LearnLoop fixture density contract D-41/D-45 requires support findings for unsupported storefront, native storage, and sync claims"
    )
  end

  @tag :learnloop_fixture_density
  test "LearnLoop context contract exposes dashboard, course, pack, history, and reset read models" do
    module =
      assert_exported!(
        @learn_loop,
        :dashboard_context,
        1,
        "LearnLoop fixture density contract D-27 requires #{@learn_loop}.dashboard_context/1"
      )

    assert_exported!(
      module,
      :course_context!,
      1,
      "LearnLoop fixture density contract D-27 requires course_context!/1"
    )

    assert_exported!(
      module,
      :pack_context!,
      1,
      "LearnLoop fixture density contract D-27 requires pack_context!/1"
    )

    assert_exported!(
      module,
      :history_context,
      0,
      "LearnLoop fixture density contract D-12/D-13 requires history_context/0"
    )

    assert_exported!(
      module,
      :reset_seed!,
      0,
      "LearnLoop reset digest contract D-11/D-29 requires reset_seed!/0"
    )

    dashboard = apply(module, :dashboard_context, ["learner-iris"])

    assert get_in(dashboard, [:learner, :id]) == "learner-iris"
    assert get_in(dashboard, [:active_course, :id]) == "course-elixir-routing"
    assert get_in(dashboard, [:next_pack, :id]) == "learnloop_daily_pack"
    assert inspect(dashboard) =~ "LiveView route"
    assert inspect(dashboard) =~ "Cached read-only"
    assert inspect(dashboard) =~ "Offline island"
    assert inspect(dashboard) =~ "Backend projection"

    course = apply(module, :course_context!, ["course-elixir-routing"])
    assert Enum.any?(Map.get(course, :lessons, []), &(Map.get(&1, :id) == "lesson-offline-review"))
    assert inspect(course) =~ "/learnloop/study/session"
    assert inspect(course) =~ "/learnloop/subscription"

    pack = apply(module, :pack_context!, ["learnloop_daily_pack"])
    assert inspect(pack) =~ "Local-first outbox"
    assert inspect(pack) =~ "append-only review"

    history = apply(module, :history_context, [])
    assert inspect(history) =~ "server-confirmed"
    assert inspect(history) =~ "Cached read-only"
    refute inspect(history) =~ ~r/LiveView works offline|generic sync engine|native storage/i
  end

  @tag :learnloop_reset_digest
  test "LearnLoop reset digest contract preserves browser-state honesty and lane-scoped digest components" do
    fixtures =
      assert_exported!(
        @fixtures,
        :digest_components,
        0,
        "LearnLoop reset digest contract D-29 requires #{@fixtures}.digest_components/0"
      )

    context =
      assert_exported!(
        @learn_loop,
        :reset_seed!,
        0,
        "LearnLoop reset digest contract D-11/D-29 requires #{@learn_loop}.reset_seed!/0"
      )

    reset_counts = apply(context, :reset_seed!, [])

    assert Map.has_key?(reset_counts, :learning_training),
           "LearnLoop reset digest contract D-29 requires reset count key :learning_training"

    learning_training = Map.fetch!(reset_counts, :learning_training)

    assert learning_training.browser_state_reset == false,
           "LearnLoop reset digest contract D-11 requires browser_state_reset: false"

    assert Map.take(learning_training, [
             :learners,
             :courses,
             :lessons,
             :content_packs,
             :progress_checkpoints,
             :subscription_states,
             :route_postures,
             :support_findings,
             :synced_reviews
           ])
           |> map_size() == 9,
           "LearnLoop reset digest contract D-23/D-29 requires deterministic breadth counts plus synced_reviews"

    digest_components = apply(fixtures, :digest_components, [])

    assert is_list(digest_components) and digest_components != [],
           "LearnLoop reset digest contract D-29 requires stable digest components"

    assert Enum.any?(digest_components, &String.contains?(&1, "learner-iris"))
    assert Enum.any?(digest_components, &String.contains?(&1, "course-elixir-routing"))
    assert Enum.any?(digest_components, &String.contains?(&1, "learnloop_daily_pack"))

    assert Enum.all?(
             digest_components,
             &(String.starts_with?(&1, "learn_loop.") or
                 String.starts_with?(&1, "learning_training."))
           ),
           "LearnLoop reset digest contract D-29 requires lane-scoped digest components"
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp assert_min_list(data, key, minimum, message) do
    value = Map.get(data, key, [])

    assert is_list(value), "#{message}; expected #{inspect(key)} to be a list"

    assert length(value) >= minimum,
           "#{message}; expected at least #{minimum}, got #{length(value)}"

    value
  end

  defp assert_id_present!(records, expected_id, message) do
    assert Enum.any?(records, &(Map.get(&1, :id) == expected_id)),
           message
  end
end
