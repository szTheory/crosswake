defmodule Crosswake.Proof.RescueBoundaryRatchetTest do
  use ExUnit.Case, async: false

  @root Path.expand("../../..", __DIR__)
  @script Path.join(@root, "script/check_rescue_boundaries.exs")
  @records Path.join(@root, "script/fixtures/rescue_boundary_exceptions.exs")
  @boundary "lib/crosswake/compatibility/route_gate.ex"
  @phase ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet"
  @families ~w(bridge policy router offline manifest compatibility)

  test "repository enforcement uses both exact tool blobs measured on actual main" do
    receipt =
      @root
      |> Path.join(@phase <> "/196-EVIDENCE/main-rescue.json")
      |> File.read!()
      |> Jason.decode!()

    assert receipt["guard"] == "rescue"
    assert receipt["main_ref"] == "origin/main"
    assert receipt["main_sha"] =~ ~r/\A[0-9a-f]{40}\z/
    assert receipt["candidate_sha"] =~ ~r/\A[0-9a-f]{40}\z/
    assert receipt["process_exit"] == 1
    assert receipt["subject_count"] > 0
    assert receipt["subject_count"] == length(receipt["subjects"])
    assert receipt["counts"]["files"] == receipt["subject_count"]
    assert receipt["counts"]["exceptions"] == 0
    assert receipt["privacy_before"]["exit"] == 0
    assert receipt["privacy_after"]["exit"] == 0
    assert receipt["restoration"]["head"] == receipt["candidate_sha"]
    assert receipt["restoration"]["branch"] == "fix/spec-structure-ratchet"
    assert length(receipt["tools"]) == 2

    assert Enum.map(receipt["tools"], & &1["path"]) == [
             "script/check_rescue_boundaries.exs",
             "script/fixtures/rescue_boundary_exceptions.exs"
           ]

    for tool <- receipt["tools"] do
      bytes = File.read!(Path.join(@root, tool["path"]))
      assert hash(:sha256, bytes) == tool["sha256"]
      assert hash(:sha, "blob #{byte_size(bytes)}\0" <> bytes) == tool["blob"]
    end

    for subject <- receipt["subjects"] do
      {bytes, 0} =
        System.cmd("git", ["show", receipt["main_sha"] <> ":" <> subject["path"]], cd: @root)

      assert hash(:sha256, bytes) == subject["sha256"]
    end

    assert Enum.count(receipt["findings"], &(&1["category"] == "broad_rescue")) == 5
    assert Enum.count(receipt["findings"], &(&1["category"] == "rescue_exception_mismatch")) == 2
    {report, code} = run(@root)
    assert code == 0
    assert report["counts"]["files"] > 0
    assert report["counts"]["exceptions"] == 2
    assert report["findings"] == []
  end

  @tag :tmp_dir
  test "finite classes, reraise and string data pass with directory-only families", %{
    tmp_dir: root
  } do
    fixture(root)

    put(root, "lib/crosswake/bridge/control.ex", """
    defmodule Fixture do
      def finite do
        :ok
      rescue
        error in [ArgumentError, RuntimeError] -> {:error, error.__struct__}
      end
      def class_only do
        :ok
      rescue
        RuntimeError -> :closed
      end
      def class_list do
        :ok
      rescue
        [RuntimeError, ArgumentError] -> :closed
      end
      def named_singleton do
        :ok
      rescue
        error in RuntimeError -> {:closed, error.__struct__}
      end
      def preserve do
        :ok
      rescue
        error -> reraise error, __STACKTRACE__
      end
      def data, do: "rescue _ -> synthetic_data"
    end
    """)

    {report, code} = run(root)
    assert code == 0
    assert report["counts"] == %{"files" => 8, "rescues" => 7, "exceptions" => 2}
  end

  for {label, pattern} <- [
        {"wildcard", "_"},
        {"renamed whole exception", "renamed"},
        {"dynamic classes", "error in classes"},
        {"empty classes", "error in []"}
      ] do
    @tag :tmp_dir
    test "#{label} outside the exact records is rejected", %{tmp_dir: root} do
      fixture(root)

      put(
        root,
        "lib/crosswake/offline/nested/extra.ex",
        "defmodule Extra do\ndef value do\n:ok\nrescue\n#{unquote(pattern)} -> :closed\nend\nend"
      )

      assert_red(root, "broad_rescue")
    end
  end

  for family <- @families do
    @tag :tmp_dir
    test "#{family} descendants and root files are both enforced", %{tmp_dir: root} do
      fixture(root)

      put(
        root,
        "lib/crosswake/#{unquote(family)}.ex",
        "defmodule Added do\ndef value do\n:ok\nrescue\nrenamed -> :closed\nend\nend"
      )

      assert_red(root, "broad_rescue")
    end
  end

  for {label, mutation} <- [
        {"missing", :missing},
        {"malformed", :malformed},
        {"duplicate", :duplicate},
        {"stale clause", :stale},
        {"wrong function", :function},
        {"wrong call", :call},
        {"nonliteral data", :executable}
      ] do
    @tag :tmp_dir
    test "#{label} exception records fail closed", %{tmp_dir: root} do
      fixture(root)
      file = Path.join(root, "records.exs")
      {records, _} = Code.eval_file(@records)

      case unquote(mutation) do
        :missing ->
          :ok

        :malformed ->
          File.write!(file, "[")

        :duplicate ->
          File.write!(file, inspect([hd(records), hd(records)], limit: :infinity))

        :stale ->
          File.write!(
            file,
            inspect(
              [Map.put(hd(records), :clause, "_extension_error -> :closed"), List.last(records)],
              limit: :infinity
            )
          )

        :function ->
          File.write!(
            file,
            inspect([Map.put(hd(records), :function, "another/2"), List.last(records)],
              limit: :infinity
            )
          )

        :call ->
          File.write!(
            file,
            inspect(
              [Map.put(hd(records), :call, "another.validate_dependency()"), List.last(records)],
              limit: :infinity
            )
          )

        :executable ->
          File.write!(file, "raise \"synthetic_private_record\"")
      end

      assert_red(root, "rescue_exception_mismatch", ["--exceptions", file])
    end
  end

  for {label, original, replacement} <- [
        {"same clause in wrong function", "defp check_dependencies(companions, route)",
         "defp another_dependencies(companions, route)"},
        {"same clause with wrong protected call", "case companion.validate_dependency() do",
         "case companion.other_dependency() do"},
        {"changed exact denial clause", "result = {{:error, nil}, :adapter_unloadable}",
         "result = {{:error, nil}, :engine_unvalidated}"},
        {"wrong module", "defmodule Crosswake.Compatibility.RouteGate do",
         "defmodule Crosswake.Compatibility.OtherGate do"}
      ] do
    @tag :tmp_dir
    test "#{label} cannot borrow a containment record", %{tmp_dir: root} do
      fixture(root)
      file = Path.join(root, @boundary)
      before = File.read!(file)
      after_source = String.replace(before, unquote(original), unquote(replacement))
      assert after_source != before
      File.write!(file, after_source)
      assert_red(root, "broad_rescue")
    end
  end

  @tag :tmp_dir
  test "a duplicated exact semantic site fails multiplicity", %{tmp_dir: root} do
    fixture(root)
    file = Path.join(root, @boundary)
    File.write!(file, File.read!(file) <> File.read!(file))
    assert_red(root, "rescue_exception_mismatch")
  end

  @tag :tmp_dir
  test "malformed source cannot count as clean", %{tmp_dir: root} do
    fixture(root)
    put(root, "lib/crosswake/bridge/invalid.ex", "defmodule SyntheticPrivateParse do (")
    assert_red(root, "parse_error")
  end

  @tag :tmp_dir
  test "invalid UTF8 is a closed parse failure", %{tmp_dir: root} do
    fixture(root)
    put(root, "lib/crosswake/bridge/invalid.ex", <<255>>)
    assert_red(root, "parse_error")
  end

  @tag :tmp_dir
  test "regular unreadable source is a closed read failure", %{tmp_dir: root} do
    fixture(root)
    file = Path.join(root, "lib/crosswake/bridge/unreadable.ex")
    File.write!(file, "defmodule Unreadable do\nend")
    File.chmod!(file, 0o000)
    on_exit(fn -> File.chmod(file, 0o600) end)
    assert_red(root, "read_error")
  end

  @tag :tmp_dir
  test "unreadable symlink source and independent scope mismatch fail", %{tmp_dir: root} do
    fixture(root)
    File.ln_s!(Path.join(root, "absent"), Path.join(root, "lib/crosswake/bridge/broken.ex"))
    assert_red(root, "read_error")
  end

  @tag :tmp_dir
  test "missing family cannot narrow the scan silently", %{tmp_dir: root} do
    fixture(root)
    File.rm_rf!(Path.join(root, "lib/crosswake/offline"))
    assert_red(root, "scope_mismatch")
  end

  @tag :tmp_dir
  test "empty overall discovery fails", %{tmp_dir: root} do
    File.mkdir_p!(Path.join(root, "lib/crosswake"))
    assert_red(root, "scope_empty")
  end

  defp fixture(root) do
    for family <- @families do
      put(
        root,
        "lib/crosswake/#{family}/leaf.ex",
        "defmodule Fixture.#{String.capitalize(family)} do\ndef value, do: :ok\nend"
      )
    end

    put(root, @boundary, File.read!(Path.join(@root, @boundary)))
  end

  defp put(root, file, bytes) do
    path = Path.join(root, file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, bytes)
  end

  defp assert_red(root, category, args \\ []) do
    {report, code} = run(root, args)
    assert code == 1
    assert Enum.any?(report["findings"], &(&1["category"] == category))
  end

  defp run(root, args \\ []) do
    {output, code} =
      System.cmd("elixir", [@script, "--root", root, "--mode", "enforce"] ++ args,
        stderr_to_stdout: true
      )

    refute output =~ "synthetic_private_record"
    refute output =~ "SyntheticPrivateParse"
    refute output =~ root

    lines =
      String.split(output, "\n") |> Enum.filter(&String.starts_with?(&1, "PHASE196_REPORT "))

    assert length(lines) == 1, output
    {lines |> hd() |> String.replace_prefix("PHASE196_REPORT ", "") |> Jason.decode!(), code}
  end

  defp hash(algorithm, bytes), do: :crypto.hash(algorithm, bytes) |> Base.encode16(case: :lower)
end
