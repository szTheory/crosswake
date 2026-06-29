defmodule Crosswake.Proof.Phase134TemplateVersionDriftTest do
  @moduledoc """
  Merge-blocking drift test for LIFE-02a.

  Asserts that the SHA-256 hash of all `.eex` shell templates (sorted, bytewise)
  matches the `@checked_in_hash` module attribute. Any change to a template without
  running `mix crosswake.bump_template_version` causes this test to fail.

  Also asserts non-vacuity: at least one iOS and at least one Android `.eex` template
  must be present so the glob never silently produces a vacuous pass on an empty set.

  Untagged. `async: true` — read-only filesystem access; no Application state mutation.

  Stable ids (LIFE-02a):
    - proof.life_02a.template_version_drift
    - proof.life_02a.non_vacuity.ios
    - proof.life_02a.non_vacuity.android
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "shell"])

  @checked_in_hash "0000000000000000000000000000000000000000000000000000000000000000"

  # ---------------------------------------------------------------------------
  # SC#1 — drift guard: live template hash must match the checked-in hash.
  # This test is EXPECTED RED on the all-zero placeholder hash.
  # Plan 01 (bump_template_version) turns it GREEN by stamping the real hash.
  # ---------------------------------------------------------------------------

  test "template hash matches checked-in hash (drift guard)" do
    live = live_template_hash()

    assert live == @checked_in_hash,
           ProofAssertions.stable_id_message(
             "proof.life_02a.template_version_drift",
             "shell templates must not change without bumping @template_version",
             "priv/templates/crosswake/shell/**/*.eex (sorted, SHA-256)",
             "live hash #{live} != checked-in hash #{@checked_in_hash}",
             "priv/templates/crosswake/shell/",
             "run `mix crosswake.bump_template_version` to increment @template_version and update the hash",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC#2 — non-vacuity (iOS): the glob must find at least one iOS template,
  # so a platform directory removal does not silently pass the drift test.
  # ---------------------------------------------------------------------------

  test "at least 1 iOS template present (non-vacuity guard)" do
    ios_templates = Path.wildcard(Path.join([@template_dir, "ios", "**", "*.eex"]))
    count = length(ios_templates)

    assert count >= 1,
           ProofAssertions.stable_id_message(
             "proof.life_02a.non_vacuity.ios",
             "at least one iOS .eex template must exist under priv/templates/crosswake/shell/ios/",
             "Path.wildcard(priv/templates/crosswake/shell/ios/**/*.eex)",
             "found #{count} iOS .eex template(s) — the drift test would pass vacuously on an empty glob",
             "priv/templates/crosswake/shell/ios/",
             "confirm ios templates exist under priv/templates/crosswake/shell/ios/",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC#3 — non-vacuity (Android): same guard for the Android platform.
  # ---------------------------------------------------------------------------

  test "at least 1 Android template present (non-vacuity guard)" do
    android_templates = Path.wildcard(Path.join([@template_dir, "android", "**", "*.eex"]))
    count = length(android_templates)

    assert count >= 1,
           ProofAssertions.stable_id_message(
             "proof.life_02a.non_vacuity.android",
             "at least one Android .eex template must exist under priv/templates/crosswake/shell/android/",
             "Path.wildcard(priv/templates/crosswake/shell/android/**/*.eex)",
             "found #{count} Android .eex template(s) — the drift test would pass vacuously on an empty glob",
             "priv/templates/crosswake/shell/android/",
             "confirm android templates exist under priv/templates/crosswake/shell/android/",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Private helper — glob all .eex templates, sort deterministically (bytewise),
  # concatenate bytes, and SHA-256 hash. Must match crosswake.bump_template_version
  # exactly (same glob, same sort, same concat, same hash algorithm).
  # ---------------------------------------------------------------------------

  defp live_template_hash do
    @template_dir
    |> Path.join("**/*.eex")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&File.read!/1)
    |> Enum.join()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
