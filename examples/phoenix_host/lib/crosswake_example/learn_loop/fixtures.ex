defmodule CrosswakeExample.LearnLoop.Fixtures do
  @moduledoc """
  Deterministic LearnLoop fixtures for the subscription learning showcase lane.

  These maps provide product-shaped read context without adding broad LMS
  persistence. Server-owned mutable proof remains the existing flashcard review
  and progress tables.
  """

  @learners [
    %{
      id: "learner-iris",
      name: "Iris Learner",
      role: :learner,
      organization: "Brightpath Academy",
      headline: "Building a reliable offline review habit",
      status: :active,
      streak_days: 12,
      active_course_id: "course-elixir-routing",
      active_pack_id: "learnloop_daily_pack",
      subscription_state: :pending
    },
    %{
      id: "coach-theo",
      name: "Theo Coach",
      role: :coach,
      organization: "Brightpath Academy",
      headline: "Watching replay evidence and practice momentum",
      status: :reviewing,
      cohort: "Phoenix mobile foundations"
    },
    %{
      id: "admin-mina",
      name: "Mina Admin",
      role: :admin,
      organization: "Brightpath Academy",
      headline: "Entitlement and storefront evidence reviewer",
      status: :monitoring,
      support_focus: "Backend projection required"
    }
  ]

  @courses [
    %{
      id: "course-elixir-routing",
      title: "Phoenix Route Ownership",
      subtitle: "Route policy, cached read-only screens, and offline islands",
      status: :active,
      level: :intermediate,
      progress_percent: 64,
      lesson_ids: [
        "lesson-route-policy",
        "lesson-offline-review",
        "lesson-entitlement-gate"
      ],
      next_lesson_id: "lesson-offline-review",
      content_pack_id: "learnloop_daily_pack",
      route_id: "learnloop-course"
    },
    %{
      id: "course-offline-study",
      title: "Offline Study Loops",
      subtitle: "IndexedDB queues, append-only reviews, and sync visibility",
      status: :available,
      level: :intermediate,
      progress_percent: 28,
      lesson_ids: ["lesson-local-outbox", "lesson-replay-proof"],
      next_lesson_id: "lesson-local-outbox",
      content_pack_id: "learnloop_sync_pack",
      route_id: "learnloop-course"
    },
    %{
      id: "course-subscription-access",
      title: "Subscription Access Pressure",
      subtitle: "Backend-owned entitlement projection without live storefront support",
      status: :gated,
      level: :advanced,
      progress_percent: 10,
      lesson_ids: ["lesson-backend-projection"],
      next_lesson_id: "lesson-backend-projection",
      content_pack_id: "learnloop_sync_pack",
      route_id: "learnloop-subscription"
    }
  ]

  @lessons [
    %{
      id: "lesson-route-policy",
      course_id: "course-elixir-routing",
      title: "Map a LiveView route to cached read-only posture",
      status: :complete,
      duration_minutes: 11,
      route_id: "learnloop-course",
      access_state: :granted,
      support_labels: ["LiveView route", "Cached read-only"]
    },
    %{
      id: "lesson-offline-review",
      course_id: "course-elixir-routing",
      title: "Start the offline review island",
      status: :next,
      duration_minutes: 8,
      route_id: "learnloop-study-session",
      access_state: :granted,
      support_labels: ["Offline island", "Local-first outbox"]
    },
    %{
      id: "lesson-entitlement-gate",
      course_id: "course-elixir-routing",
      title: "Handle a gated advanced lesson",
      status: :gated,
      duration_minutes: 14,
      route_id: "learnloop-subscription",
      access_state: :pending,
      gate_copy: "Access stays closed until backend projection refreshes",
      support_labels: ["Backend projection", "Mocked storefront evidence"]
    },
    %{
      id: "lesson-local-outbox",
      course_id: "course-offline-study",
      title: "Queue review events locally",
      status: :available,
      duration_minutes: 9,
      route_id: "learnloop-pack",
      access_state: :granted,
      support_labels: ["Cached read-only", "Local-first outbox"]
    },
    %{
      id: "lesson-replay-proof",
      course_id: "course-offline-study",
      title: "Replay and reconcile accepted reviews",
      status: :available,
      duration_minutes: 12,
      route_id: "learnloop-history",
      access_state: :granted,
      support_labels: ["Cached read-only", "Backend projection"]
    },
    %{
      id: "lesson-backend-projection",
      course_id: "course-subscription-access",
      title: "Read backend entitlement projection",
      status: :gated,
      duration_minutes: 10,
      route_id: "learnloop-subscription",
      access_state: :stale,
      gate_copy: "Backend projection required",
      support_labels: ["Backend projection", "Mocked storefront evidence"]
    }
  ]

  @content_packs [
    %{
      id: "learnloop_daily_pack",
      title: "Daily Elixir Pack",
      version: "2026.07.11",
      status: :offline_ready,
      course_id: "course-elixir-routing",
      lesson_ids: ["lesson-route-policy", "lesson-offline-review"],
      card_count: 3,
      route_id: "learnloop-pack",
      offline_posture: :local_first,
      storage_owner: :browser_indexed_db,
      support_labels: ["Offline island", "Local-first outbox"],
      summary: "Connect once to load today's pack, then review from the socketless island."
    },
    %{
      id: "learnloop_sync_pack",
      title: "Sync Visibility Pack",
      version: "2026.07.11-sync",
      status: :cached_read_only,
      course_id: "course-offline-study",
      lesson_ids: ["lesson-local-outbox", "lesson-replay-proof"],
      card_count: 2,
      route_id: "learnloop-pack",
      offline_posture: :cached_read_only,
      storage_owner: :server_snapshot,
      support_labels: ["LiveView route", "Cached read-only"],
      summary:
        "Pack manifest is visible as cached read-only route context until the study island opens."
    }
  ]

  @progress_checkpoints [
    %{
      id: "progress-iris-route-policy",
      learner_id: "learner-iris",
      course_id: "course-elixir-routing",
      lesson_id: "lesson-route-policy",
      status: :server_confirmed,
      label: "Server-confirmed progress",
      reviewed_at: "2026-07-11T14:10:00Z",
      route_id: "learnloop-history"
    },
    %{
      id: "progress-iris-offline-review",
      learner_id: "learner-iris",
      course_id: "course-elixir-routing",
      lesson_id: "lesson-offline-review",
      status: :queued_for_replay,
      label: "Queued for replay",
      reviewed_at: "2026-07-11T14:18:00Z",
      route_id: "learnloop-study-session"
    },
    %{
      id: "progress-iris-entitlement-gate",
      learner_id: "learner-iris",
      course_id: "course-elixir-routing",
      lesson_id: "lesson-entitlement-gate",
      status: :blocked_by_backend_projection,
      label: "Backend projection required",
      reviewed_at: "2026-07-11T14:21:00Z",
      route_id: "learnloop-subscription"
    }
  ]

  @sync_ledger_preview [
    %{
      id: "sync-saved-local",
      label: "Saved locally",
      status: :saved_locally,
      route_id: "learnloop-study-session",
      copy: "Answer is stored in this browser's IndexedDB outbox."
    },
    %{
      id: "sync-queued-replay",
      label: "Queued for replay",
      status: :queued_for_replay,
      route_id: "learnloop-study-session",
      copy: "Replay waits for the existing append-only review-event sync endpoint."
    },
    %{
      id: "sync-server-confirmed",
      label: "Synced 1 - queued 0",
      status: :server_confirmed,
      route_id: "learnloop-history",
      copy: "History is server-confirmed cached read-only progress."
    },
    %{
      id: "sync-server-rejected",
      label: "Rejected by server - review needed",
      status: :server_rejected,
      route_id: "learnloop-history",
      copy: "Rejected rows stay evidence for reconciliation, not a generic sync engine."
    }
  ]

  @subscription_states [
    %{
      id: "subscription-granted",
      state: :granted,
      learner_id: "learner-iris",
      label: "Backend projection granted",
      access_copy: "Access is open because backend projection is granted.",
      storefront_evidence: :mocked,
      route_id: "learnloop-subscription"
    },
    %{
      id: "subscription-pending",
      state: :pending,
      learner_id: "learner-iris",
      label: "Mock storefront evidence received",
      access_copy: "Access stays closed until backend projection refreshes.",
      storefront_evidence: :mocked,
      route_id: "learnloop-subscription"
    },
    %{
      id: "subscription-stale",
      state: :stale,
      learner_id: "learner-iris",
      label: "Backend projection required",
      access_copy: "Access stays closed until backend projection refreshes.",
      storefront_evidence: :mocked,
      route_id: "learnloop-subscription"
    },
    %{
      id: "subscription-denied",
      state: :denied,
      learner_id: "learner-iris",
      label: "No live StoreKit, Play Billing, or RevenueCat adapter in this demo",
      access_copy: "Access remains closed; storefront evidence does not grant access.",
      storefront_evidence: :none,
      route_id: "learnloop-subscription"
    }
  ]

  @route_postures [
    %{
      route_id: "learnloop-dashboard",
      path: "/learnloop",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "LiveView route",
      badge_label: "Cached read-only",
      rough_edge: "Course momentum is a Phoenix-owned cached read-only route."
    },
    %{
      route_id: "learnloop-course",
      path: "/learnloop/courses/:id",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "LiveView route",
      badge_label: "Cached read-only",
      rough_edge: "Course and lesson metadata do not mutate while offline."
    },
    %{
      route_id: "learnloop-pack",
      path: "/learnloop/packs/:id",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Cached read-only",
      badge_label: "LiveView route",
      rough_edge:
        "Pack manifest is read context; actual local writes happen only in the study island."
    },
    %{
      route_id: "learnloop-study-session",
      path: "/learnloop/study/session",
      runtime_owner: :offline_island,
      offline_posture: :local_first,
      security_posture: :standard,
      support_label: "Offline island",
      badge_label: "Local-first outbox",
      rough_edge: "IndexedDB and the outbox are browser-owned; server reset does not clear them."
    },
    %{
      route_id: "learnloop-history",
      path: "/learnloop/history",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Cached read-only",
      badge_label: "Backend projection",
      rough_edge: "History shows server-confirmed review events only."
    },
    %{
      route_id: "learnloop-subscription",
      path: "/learnloop/subscription",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Backend projection",
      badge_label: "Mocked storefront evidence",
      rough_edge: "Mock storefront evidence never grants access without backend projection."
    }
  ]

  @support_findings [
    %{
      id: "support-liveview-dashboard",
      label: "LiveView route",
      route_id: "learnloop-dashboard",
      finding: "Dashboard, course, pack, history, and subscription shells are Phoenix-owned."
    },
    %{
      id: "support-cached-read",
      label: "Cached read-only",
      route_id: "learnloop-course",
      finding:
        "Course and pack routes can show cached snapshots but do not accept offline mutation."
    },
    %{
      id: "support-offline-island",
      label: "Offline island",
      route_id: "learnloop-study-session",
      finding: "The study session must remain socketless and browser-owned for local-first proof."
    },
    %{
      id: "support-local-outbox",
      label: "Local-first outbox",
      route_id: "learnloop-study-session",
      finding:
        "Review answers queue locally, replay through the existing append-only sync seam, and reconcile visibly."
    },
    %{
      id: "support-backend-projection",
      label: "Backend projection",
      route_id: "learnloop-subscription",
      finding:
        "Backend entitlement projection is required before gated lessons open; mocked storefront evidence never grants access."
    }
  ]

  @capability_pressure [
    %{
      id: "pressure-content-pack",
      capability: :content_pack,
      route_id: "learnloop-pack",
      posture: :demoed_fixture,
      support_label: "Cached read-only",
      summary: "Content-pack manifests are deterministic read data for the product lane."
    },
    %{
      id: "pressure-local-first-study",
      capability: :offline_study,
      route_id: "learnloop-study-session",
      posture: :proof_backed_island,
      support_label: "Local-first outbox",
      summary: "The offline study island uses browser IndexedDB and existing review-event replay."
    },
    %{
      id: "pressure-native-storage",
      capability: :native_storage,
      route_id: "learnloop-study-session",
      posture: :future_gap,
      support_label: "Offline island",
      summary:
        "Native storage, eviction policy, and media downloads remain future capability-map pressure."
    },
    %{
      id: "pressure-commerce-paywall",
      capability: :commerce_paywall,
      route_id: "learnloop-subscription",
      posture: :mocked_backend_projection,
      support_label: "Mocked storefront evidence",
      summary: "Subscription pressure is mocked backend evidence, not live storefront support."
    }
  ]

  @digest_fields %{
    learner: [:id, :name, :role, :status],
    course: [:id, :title, :status],
    lesson: [:id, :title, :status, :access_state],
    content_pack: [:id, :title, :status],
    progress_checkpoint: [:id, :status, :route_id],
    sync_ledger_preview: [:id, :status, :route_id],
    subscription_state: [:id, :state, :label],
    route_posture: [:route_id, :runtime_owner, :offline_posture],
    support_finding: [:id, :label, :route_id],
    capability_pressure: [:id, :capability, :posture]
  }

  def seed do
    %{
      learners: @learners,
      courses: @courses,
      lessons: @lessons,
      content_packs: @content_packs,
      packs: @content_packs,
      progress_checkpoints: @progress_checkpoints,
      sync_ledger_preview: @sync_ledger_preview,
      subscription_states: @subscription_states,
      entitlement_snapshots: @subscription_states,
      route_postures: @route_postures,
      support_findings: @support_findings,
      capability_pressure: @capability_pressure
    }
  end

  def learners, do: @learners
  def courses, do: @courses
  def lessons, do: @lessons
  def packs, do: @content_packs
  def content_packs, do: @content_packs
  def progress_checkpoints, do: @progress_checkpoints
  def sync_ledger_preview, do: @sync_ledger_preview
  def subscription_states, do: @subscription_states
  def entitlement_snapshots, do: @subscription_states
  def route_postures, do: @route_postures
  def support_findings, do: @support_findings
  def capability_pressure, do: @capability_pressure

  def digest_components do
    [
      Enum.map(@learners, &digest_component(:learner, &1)),
      Enum.map(@courses, &digest_component(:course, &1)),
      Enum.map(@lessons, &digest_component(:lesson, &1)),
      Enum.map(@content_packs, &digest_component(:content_pack, &1)),
      Enum.map(@progress_checkpoints, &digest_component(:progress_checkpoint, &1)),
      Enum.map(@sync_ledger_preview, &digest_component(:sync_ledger_preview, &1)),
      Enum.map(@subscription_states, &digest_component(:subscription_state, &1)),
      Enum.map(@route_postures, &digest_component(:route_posture, &1)),
      Enum.map(@support_findings, &digest_component(:support_finding, &1)),
      Enum.map(@capability_pressure, &digest_component(:capability_pressure, &1))
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  defp digest_component(type, record) do
    fields =
      @digest_fields
      |> Map.fetch!(type)
      |> Enum.map(&Map.fetch!(record, &1))
      |> Enum.join(":")

    "learning_training.#{type}:#{fields}"
  end
end
