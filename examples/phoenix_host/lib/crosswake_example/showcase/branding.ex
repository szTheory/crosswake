defmodule CrosswakeExample.Showcase.Branding do
  @moduledoc """
  Internal brand direction for the example-host showcase.

  These names and fixture briefs make the demo lanes feel like realistic apps.
  They are not public Crosswake library API.
  """

  @brand_ids [:saas_admin, :field_service, :learning_training]

  @root %{
    name: "Crosswake Showcase",
    eyebrow: "Demo apps powered by Crosswake",
    logo_path: "/brand/crosswake-lockup-horizontal.svg",
    logo_dark_path: "/brand/crosswake-lockup-horizontal-dark.svg",
    headline: "Phoenix routes, native where it matters.",
    deck:
      "Three realistic demo apps show which runtime owns each route: LiveView, offline island, or native-pressure path."
  }

  @brands %{
    saas_admin: %{
      id: :saas_admin,
      name: "AdminPilot",
      category: "SaaS/Admin",
      tagline: "Approvals, roles, and account health for teams that run on Phoenix.",
      tone: "Refined enterprise control room",
      theme_class: "showcase-brand-adminpilot",
      mark: "AP",
      style_identifier: "ledger-green-ops",
      fixture_brief: %{
        organization: "Northwind Workspace",
        people: ["Marta Member", "Alex Approver", "Priya Owner"],
        records: [
          "Quarterly spend increase",
          "Vendor access renewal",
          "Contract archive export"
        ],
        activity: ["2 approvals pending", "14-day renewal window", "1 role change staged"],
        pressure: "Auth-sensitive admin posture stays Phoenix-owned."
      }
    },
    field_service: %{
      id: :field_service,
      name: "Fieldserv",
      category: "Field Service",
      tagline: "Dispatch, inspection, and evidence capture under jobsite pressure.",
      tone: "High-visibility dispatch and device pressure",
      theme_class: "showcase-brand-fieldserv",
      mark: "FS",
      style_identifier: "signal-orange-field",
      fixture_brief: %{
        organization: "Ridgeway Mutual Field Ops",
        people: ["Noor Dispatcher", "Sam Inspector", "Inez Adjuster"],
        records: ["Broken windshield", "Hail damage", "Roof moisture scan"],
        activity: [
          "2 claims pending capture",
          "1 technician en route",
          "Camera permission gap visible"
        ],
        pressure:
          "Capture/scanning remains future native-control evidence until route-specific proof backs it."
      }
    },
    learning_training: %{
      id: :learning_training,
      name: "LearnLoop",
      category: "Subscription Learning",
      tagline: "Courses, progress, subscriptions, and offline study loops in one lane.",
      tone: "Polished course progress and offline study",
      theme_class: "showcase-brand-learnloop",
      mark: "LL",
      style_identifier: "violet-teal-learning",
      fixture_brief: %{
        organization: "Brightpath Academy",
        people: ["Iris Learner", "Theo Coach", "Mina Admin"],
        records: ["Daily Elixir Pack", "Offline Review Queue", "Subscription renewal check"],
        activity: [
          "3 seeded cards",
          "1 replayable outbox path",
          "Grace-period entitlement pressure"
        ],
        pressure: "Offline study state is browser-owned; server reset does not clear IndexedDB."
      }
    }
  }

  @spec root() :: map()
  def root, do: @root

  @spec brand_ids() :: [atom()]
  def brand_ids, do: @brand_ids

  @spec app_brands() :: [map()]
  def app_brands do
    Enum.map(@brand_ids, &brand_for!/1)
  end

  @spec brand_for!(atom()) :: map()
  def brand_for!(id), do: Map.fetch!(@brands, id)
end
