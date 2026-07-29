defmodule Crosswake.Proof.Phase153_1CacheIntegrityTest do
  @moduledoc """
  Phase 153.1 CACHE-01/CACHE-02 — structural guard on GitHub Actions cache keys.

  A wrong cache key does not fail loudly. It either produces a permanent 0% hit
  rate (which looks exactly like "caching didn't help much") or, far worse,
  restores a `_build` tree compiled by a different toolchain and the failure
  surfaces somewhere unrelated. Neither is visible in a green CI run, so the
  invariants are asserted here instead.

  A safe `_build` key pins every dimension that can change the bytes inside it:

    * `runner.os` / `runner.arch` — a BEAM file built on macOS arm64 is not
      valid on ubuntu x64. Phase 153.1 moved 13 jobs from macos-15 to
      ubuntu-latest; a key without these would have silently served the wrong
      artifacts across that move.
    * OTP and Elixir — sourced from `.tool-versions`. Without them, an OTP bump
      restores incompatible BEAM files.
    * `MIX_ENV` — dev and test `_build` trees are not interchangeable.
    * `mix.lock` hash — the actual dependency set.
  """
  use ExUnit.Case, async: true

  @workflow_dir ".github/workflows"
  @actions_dir ".github/actions"

  # Files whose caches are deliberately NOT held to the six-dimension invariant.
  #
  # release-please.yml and hex-publish.yml are the security-sensitive release
  # path (REL-05 SHA pinning, two previously armed fuses). Phase 153.1 plan 03
  # explicitly scopes them out, so their `${{ runner.os }}-<pkg>-<lock>` keys
  # stand.
  #
  # This is a real, recorded residual risk, not a clean pass: those keys carry
  # no OTP/Elixir dimension, so an OTP bump can restore a stale `_build` into a
  # PUBLISH job. Tracked as a SEED-007 follow-up. The list is asserted exactly
  # so that exempting another file is a deliberate, reviewable act rather than
  # something that quietly accumulates.
  @exempt ~w(release-please.yml hex-publish.yml)

  defp workflow_files do
    Path.wildcard("#{@workflow_dir}/*.yml") ++ Path.wildcard("#{@actions_dir}/**/action.yml")
  end

  @doc false
  # Returns the list of {key, restore_keys} pairs attached to an actions/cache
  # step. Text-scanned rather than YAML-parsed to keep the test dependency-free;
  # the shapes in this repo are uniform enough that this is unambiguous.
  def cache_entries(text) do
    lines = String.split(text, "\n")

    lines
    |> Enum.with_index()
    |> Enum.filter(fn {l, _} -> String.contains?(l, "uses: actions/cache@") end)
    |> Enum.map(fn {_, idx} ->
      window = Enum.slice(lines, idx..(idx + 12))
      key = Enum.find_value(window, &capture(&1, ~r/^\s*key:\s*(.+?)\s*$/))

      path =
        window
        |> Enum.take_while(&(not Regex.match?(~r/^\s*key:/, &1)))
        |> Enum.join("\n")

      restore =
        case Enum.find_index(window, &Regex.match?(~r/^\s*restore-keys:/, &1)) do
          nil ->
            nil

          ri ->
            Enum.find_value(Enum.slice(window, (ri + 1)..(ri + 2)), fn l ->
              capture(l, ~r/^\s{2,}([A-Za-z0-9$].*?)\s*$/)
            end) || capture(Enum.at(window, ri), ~r/^\s*restore-keys:\s*(.+?)\s*$/)
        end

      {key, restore, path}
    end)
  end

  # Only Elixir caches are held to the six-dimension invariant. A Swift SPM or
  # Gradle cache has no MIX_ENV and no mix.lock, so applying the Elixir shape to
  # it would be a category error — but os/arch still matter everywhere.
  defp elixir_cache?(path), do: path =~ ~r/(^|\/|\s)(deps|_build)(\/|\s|$)/

  defp capture(line, re) do
    case Regex.run(re, line) do
      [_, v] -> v
      _ -> nil
    end
  end

  @doc false
  # The invariant under test, exposed so the negative controls can exercise the
  # exact same code path the real assertion uses.
  def missing_dimensions(key) when is_binary(key) do
    [
      {"runner.os", ~r/runner\.os/},
      {"runner.arch", ~r/runner\.arch/},
      {"otp", ~r/otp/i},
      {"elixir", ~r/elixir/i},
      {"mix-env", ~r/mix-env|MIX_ENV/},
      {"mix.lock hash", ~r/hashFiles\([^)]*mix\.lock/}
    ]
    |> Enum.reject(fn {_, re} -> Regex.match?(re, key) end)
    |> Enum.map(&elem(&1, 0))
  end

  test "actions/cache@v3 appears nowhere (its backing service was retired Feb 2025)" do
    offenders =
      for f <- workflow_files(), String.contains?(File.read!(f), "actions/cache@v3"), do: f

    assert offenders == [],
           "actions/cache@v3 caches nothing at all. Found in: #{inspect(offenders)}"
  end

  test "every non-exempt cache key carries all six safety dimensions" do
    problems =
      for f <- workflow_files(),
          Path.basename(f) not in @exempt,
          {key, _, path} <- cache_entries(File.read!(f)),
          is_binary(key),
          elixir_cache?(path),
          missing = missing_dimensions(key),
          missing != [] do
        "#{f}\n    key: #{key}\n    missing: #{Enum.join(missing, ", ")}"
      end

    assert problems == [],
           "Cache keys missing required dimensions:\n\n" <>
             Enum.join(problems, "\n\n") <>
             "\n\nA key without os/arch/otp/elixir restores artifacts built by a " <>
             "different toolchain. Use .github/actions/setup-elixir-cache."
  end

  test "every restore-keys prefix differs from its key by exactly the lock hash" do
    problems =
      for f <- workflow_files(),
          Path.basename(f) not in @exempt,
          {key, restore, _} <- cache_entries(File.read!(f)),
          is_binary(key) and is_binary(restore) do
        # Anchored on `${{ hashFiles`, not on a leading `${{` plus a greedy gap.
        # Two earlier attempts were wrong in opposite directions: `[^}]*` stopped
        # at the inner brace of hashFiles(format('{0}/mix.lock', ...)), and a
        # greedy `.*` swallowed everything back to the FIRST `${{` in the key,
        # leaving just "deps-".
        expected = Regex.replace(~r/\$\{\{\s*hashFiles.*\}\}\s*$/, key, "")

        if String.trim(restore) == String.trim(expected) do
          nil
        else
          "#{f}\n    key:      #{key}\n    restore:  #{restore}\n    expected: #{expected}"
        end
      end
      |> Enum.reject(&is_nil/1)

    assert problems == [],
           "restore-keys must be the key minus ONLY the mix.lock hash. A looser " <>
             "prefix restores across toolchains, which is the same corruption the " <>
             "dimensions prevent:\n\n" <> Enum.join(problems, "\n\n")
  end

  test "every cache key carries runner.os and runner.arch, Elixir or not" do
    problems =
      for f <- workflow_files(),
          Path.basename(f) not in @exempt,
          {key, _, _} <- cache_entries(File.read!(f)),
          is_binary(key),
          not (key =~ ~r/runner\.os/ and key =~ ~r/runner\.arch/) do
        "#{f}\n    key: #{key}"
      end

    assert problems == [],
           "A cache restored across runner classes serves artifacts built for the " <>
             "wrong platform. Phase 153.1 moved 13 jobs macos-15 -> ubuntu-latest, " <>
             "so this is a live hazard, not a theoretical one:\n\n" <>
             Enum.join(problems, "\n\n")
  end

  test "negative control — a key missing the OTP dimension is rejected" do
    bad =
      "build-scope-${{ runner.os }}-${{ runner.arch }}-elixir1.19.5-test-" <>
        "${{ hashFiles('mix.lock') }}"

    assert "otp" in missing_dimensions(bad),
           "the dimension checker failed to reject a key with no OTP dimension — " <>
             "it would pass anything, making the real assertion above meaningless"
  end

  test "negative control — the repo's own key shape passes the checker" do
    good =
      "build-scope-${{ runner.os }}-${{ runner.arch }}-otp${{ steps.beam.outputs.otp-version }}" <>
        "-elixir${{ steps.beam.outputs.elixir-version }}-${{ inputs.mix-env }}-" <>
        "${{ hashFiles(format('{0}/mix.lock', inputs.working-directory)) }}"

    assert missing_dimensions(good) == [],
           "the checker rejects the shape produced by setup-elixir-cache, so it is " <>
             "miscalibrated and every other assertion here is suspect"
  end

  # True when a shell snippet retries something that must never be retried.
  # Exposed so the negative control below exercises the same code path the real
  # assertion uses — a predicate that matches nothing would make the assertion
  # worthless while looking green.
  def retries_a_proof?(text) do
    # Comments must be stripped first. This very file's action.yml explains, in a
    # comment, that the retry must never wrap `mix test` — and an unstripped match
    # flagged that explanation as a violation. Prose about a rule is not a breach
    # of it.
    code =
      text
      |> String.split("\n")
      |> Enum.reject(&Regex.match?(~r/^\s*#/, &1))
      |> Enum.join("\n")

    loop = ~r/for\s+\w*attempt\w*\s+in|while\s+\[\s*"?\$?\w*attempt|until\s+mix/i
    proof = ~r/\bmix\s+(test|closeout\.verify)\b|verify_[a-z_]*\.sh/

    Regex.match?(loop, code) and Regex.match?(proof, code)
  end

  test "the deps.get retry never wraps a test, proof, or gate invocation" do
    # A bounded retry around `mix deps.get` is defensible: it wraps a network call
    # to hex.pm, and a package that genuinely does not exist fails all attempts
    # identically. The same pattern around `mix test` or a proof script WOULD hide
    # a real defect behind a second attempt — the failure mode the repo's
    # no-auto-retry rule exists to prevent. This asserts the pattern stays put.
    offenders =
      for f <- workflow_files(),
          block <- String.split(File.read!(f), ~r/^\s*- /m),
          retries_a_proof?(block) do
        "#{f}\n    #{String.trim(String.slice(block, 0, 200))}"
      end

    assert offenders == [],
           "A proof/test/gate invocation appears inside a retry construct. Retrying " <>
             "a dependency fetch hides nothing; retrying a proof hides defects:\n\n" <>
             Enum.join(offenders, "\n\n")
  end

  test "negative control — the retry detector fires on a proof wrapped in a loop" do
    bad = """
    run: |
      for attempt in 1 2 3; do
        if mix test test/crosswake/proof/some_proof_test.exs; then exit 0; fi
      done
    """

    assert retries_a_proof?(bad),
           "the detector missed a `mix test` inside a retry loop, so the assertion " <>
             "above would pass no matter what anyone added"
  end

  test "negative control — the retry detector allows the deps.get retry we ship" do
    ok = """
    run: |
      for attempt in 1 2 3; do
        if mix deps.get; then exit 0; fi
      done
    """

    refute retries_a_proof?(ok),
           "the detector flags the legitimate dependency-fetch retry, so it is " <>
             "miscalibrated and would block a defensible pattern"
  end

  test "the hex registry cache is shared, not scoped, and that is deliberate" do
    action = File.read!("#{@actions_dir}/setup-elixir-cache/action.yml")

    assert action =~ ~r/key: hex-registry-\$\{\{ runner\.os \}\}/,
           "the ~/.hex cache should be keyed on os/arch only"

    refute action =~ ~r/hex-registry-\$\{\{ steps\.scope/,
           "~/.hex must NOT carry the workflow+job scope. It holds registry metadata " <>
             "and tarballs, not compiled artifacts, so sharing one entry across lanes " <>
             "is safe and keeps storage down. Scoping it would multiply a large cache " <>
             "across ~19 lanes for no safety benefit."
  end

  test "the exemption list is exactly the two security-sensitive release files" do
    assert Enum.sort(@exempt) == ["hex-publish.yml", "release-please.yml"],
           "Exemptions must stay deliberate. Adding one hides a real cache-safety " <>
             "hole; record it in SEED-007 rather than growing this list quietly."
  end

  test "setup-elixir-cache reads the toolchain from .tool-versions, not hardcoded strings" do
    action = File.read!("#{@actions_dir}/setup-elixir-cache/action.yml")

    assert action =~ "version-file: .tool-versions",
           "the composite action must source OTP/Elixir from .tool-versions"

    refute action =~ ~r/^\s*(elixir|otp)-version:\s*["']\d/m,
           "hardcoding a version here reintroduces drift against .tool-versions, and " <>
             "because the cache key is built from the setup-beam OUTPUTS, drift also " <>
             "means restoring a _build compiled by a different compiler"
  end
end
