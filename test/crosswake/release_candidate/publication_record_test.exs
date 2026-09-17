defmodule Crosswake.ReleaseCandidate.PublicationRecordTest do
  @moduledoc """
  Behavioral proof for the shared post-publish publication-record pair
  (XPUB-04 / XPUB-05, Phase 173 plan 01).

  Both lanes -- the ordinary `publish-hex` job in `release-please.yml` and the
  `operation: recovery` `publish` job in `hex-publish.yml` -- write their
  post-publish receipt through ONE emitter, and the shared
  `exact-public-proof` reusable workflow makes its record-presence decision
  through ONE assertion script. These tests invoke both real scripts through
  `System.cmd/3` against files in a temp directory; they deliberately do NOT
  read the scripts' source text, because a source-grep cannot tell a script
  that rejects a bad record from one that merely mentions the word "reject".

  Every failing case asserts BOTH a non-zero exit AND the specific result
  token. An exit-code-only assertion cannot distinguish a deliberate
  rejection from a syntax error in the script, which would let the script rot
  into always-failing while this file stayed green.
  """

  use ExUnit.Case, async: true

  @emitter "script/write_publication_record.sh"
  @asserter "script/assert_publication_record.sh"

  @verified_token "PUBLICATION_RECORD_VERIFIED"
  @missing_token "PUBLICATION_RECORD_MISSING"
  @mismatch_token "PUBLICATION_RECORD_MISMATCH"
  @unreadable_token "PUBLICATION_RECORD_UNREADABLE"

  @package "crosswake"
  @version "0.2.1"
  @head String.duplicate("a", 40)
  @other_head String.duplicate("b", 40)
  @ref "refs/tags/v0.2.1"
  @run_id "1234567890"

  @record_keys ~w(
    approved_head
    package
    path
    published_at
    ref
    run_id
    schema_version
    version
  )

  defp tmp_dir!(name) do
    dir =
      Path.join([
        System.tmp_dir!(),
        "crosswake-publication-record",
        "#{name}-#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp emit(args) do
    System.cmd("bash", [@emitter | args], stderr_to_stdout: true)
  end

  defp emit_args(out, overrides \\ %{}) do
    fields =
      Map.merge(
        %{
          package: @package,
          version: @version,
          approved_head: @head,
          ref: @ref,
          lane: "ordinary",
          run_id: @run_id
        },
        overrides
      )

    [
      "--package",
      fields.package,
      "--version",
      fields.version,
      "--approved-head",
      fields.approved_head,
      "--ref",
      fields.ref,
      "--lane",
      fields.lane,
      "--run-id",
      fields.run_id,
      "--output",
      out
    ]
  end

  defp assert_record(record, overrides \\ %{}) do
    fields =
      Map.merge(
        %{package: @package, version: @version, approved_head: @head},
        overrides
      )

    System.cmd(
      "bash",
      [
        @asserter,
        "--package",
        fields.package,
        "--version",
        fields.version,
        "--approved-head",
        fields.approved_head,
        "--record",
        record
      ],
      stderr_to_stdout: true
    )
  end

  describe "write_publication_record.sh" do
    test "writes exactly the declared key set and nothing else" do
      dir = tmp_dir!("emit-keys")
      out = Path.join(dir, "publication-record.json")

      assert {output, 0} = emit(emit_args(out))
      assert output =~ "OK"

      decoded = out |> File.read!() |> Jason.decode!()

      assert Enum.sort(Map.keys(decoded)) == @record_keys

      assert decoded["schema_version"] == "1.0.0"
      assert decoded["package"] == @package
      assert decoded["version"] == @version
      assert decoded["approved_head"] == @head
      assert decoded["ref"] == @ref
      assert decoded["path"] == "ordinary"
      assert decoded["run_id"] == @run_id
      assert decoded["published_at"] =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
    end

    test "accepts the recovery lane name" do
      dir = tmp_dir!("emit-recovery")
      out = Path.join(dir, "publication-record.json")

      assert {_output, 0} = emit(emit_args(out, %{lane: "recovery"}))
      assert out |> File.read!() |> Jason.decode!() |> Map.fetch!("path") == "recovery"
    end

    test "rejects an approved head that is not 40 lowercase hex characters" do
      dir = tmp_dir!("emit-bad-head")
      out = Path.join(dir, "publication-record.json")

      for bad <- [String.upcase(@head), String.duplicate("a", 39), "not-a-sha", ""] do
        assert {output, code} = emit(emit_args(out, %{approved_head: bad}))
        assert code != 0
        assert output =~ "approved_head"
        refute File.exists?(out)
      end
    end

    test "rejects a version that is not semver" do
      dir = tmp_dir!("emit-bad-version")
      out = Path.join(dir, "publication-record.json")

      for bad <- ["v0.2.1", "0.2", "0.2.1.4", "latest", ""] do
        assert {output, code} = emit(emit_args(out, %{version: bad}))
        assert code != 0
        assert output =~ "version"
        refute File.exists?(out)
      end
    end

    test "rejects a lane name outside the two declared lanes" do
      dir = tmp_dir!("emit-bad-lane")
      out = Path.join(dir, "publication-record.json")

      for bad <- ["Ordinary", "manual", "recovery-lane", ""] do
        assert {output, code} = emit(emit_args(out, %{lane: bad}))
        assert code != 0
        assert output =~ "lane"
        refute File.exists?(out)
      end
    end

    test "the three rejection classes carry distinct exit codes" do
      dir = tmp_dir!("emit-exit-codes")
      out = Path.join(dir, "publication-record.json")

      {_, head_code} = emit(emit_args(out, %{approved_head: "nope"}))
      {_, version_code} = emit(emit_args(out, %{version: "nope"}))
      {_, lane_code} = emit(emit_args(out, %{lane: "nope"}))

      codes = [head_code, version_code, lane_code]

      # Pins the collection's cardinality before the all?/2 below: on an empty list
      # `Enum.all?/2` is vacuously true, so without this line the assertion would pass
      # on a collection that was never built (VAC-02).
      assert length(codes) == 3
      assert Enum.all?(codes, &(&1 != 0))
      assert Enum.uniq(codes) == codes
    end
  end

  describe "assert_publication_record.sh" do
    setup do
      dir = tmp_dir!("assert")
      record = Path.join(dir, "publication-record.json")
      {:ok, dir: dir, record: record}
    end

    defp write_record(path, overrides) do
      base = %{
        "schema_version" => "1.0.0",
        "package" => @package,
        "version" => @version,
        "approved_head" => @head,
        "ref" => @ref,
        "path" => "ordinary",
        "run_id" => @run_id,
        "published_at" => "2026-09-17T00:00:00Z"
      }

      File.write!(path, Jason.encode!(Map.merge(base, overrides)))
      path
    end

    test "verifies a record matching the expected triple", %{record: record} do
      write_record(record, %{})

      assert {output, 0} = assert_record(record)
      assert output =~ @verified_token
    end

    test "reports record-missing when no record file exists at all", %{record: record} do
      refute File.exists?(record)

      assert {output, code} = assert_record(record)
      assert code != 0
      assert output =~ @missing_token
      refute output =~ @verified_token

      # The operator has to know WHICH coordinate went unrecorded.
      assert output =~ @package
      assert output =~ @version
      assert output =~ @head
    end

    test "reports mismatch when only the version differs", %{record: record} do
      write_record(record, %{"version" => "0.9.9"})

      assert {output, code} = assert_record(record)
      assert code != 0
      assert output =~ @mismatch_token
      refute output =~ @verified_token
      assert output =~ "0.9.9"
      assert output =~ @version
    end

    test "reports mismatch when only the approved head differs", %{record: record} do
      write_record(record, %{"approved_head" => @other_head})

      assert {output, code} = assert_record(record)
      assert code != 0
      assert output =~ @mismatch_token
      refute output =~ @verified_token
      assert output =~ @other_head
      assert output =~ @head
    end

    test "reports mismatch when only the package differs", %{record: record} do
      write_record(record, %{"package" => "crosswake_sigra"})

      assert {output, code} = assert_record(record)
      assert code != 0
      assert output =~ @mismatch_token
      refute output =~ @verified_token
      assert output =~ "crosswake_sigra"
    end

    test "reports unreadable -- not missing -- on a record that is not valid JSON", %{
      record: record
    } do
      File.write!(record, "{not json at all")

      assert {output, code} = assert_record(record)
      assert code != 0
      assert output =~ @unreadable_token
      refute output =~ @missing_token
      refute output =~ @verified_token
    end

    test "reports unreadable -- not missing -- on a record missing a required key", %{
      record: record
    } do
      for key <- @record_keys do
        body =
          record
          |> write_record(%{})
          |> File.read!()
          |> Jason.decode!()
          |> Map.delete(key)

        File.write!(record, Jason.encode!(body))

        assert {output, code} = assert_record(record)
        assert code != 0, "expected a non-zero exit with #{key} removed"
        assert output =~ @unreadable_token
        refute output =~ @missing_token
        refute output =~ @verified_token
        assert output =~ key
      end
    end

    test "the missing, mismatch and unreadable outcomes carry distinct exit codes", %{
      dir: dir,
      record: record
    } do
      {_, missing_code} = assert_record(Path.join(dir, "absent.json"))

      write_record(record, %{"version" => "0.9.9"})
      {_, mismatch_code} = assert_record(record)

      File.write!(record, "{not json at all")
      {_, unreadable_code} = assert_record(record)

      codes = [missing_code, mismatch_code, unreadable_code]

      # Pins the collection's cardinality before the all?/2 below: on an empty list
      # `Enum.all?/2` is vacuously true, so without this line the assertion would pass
      # on a collection that was never built (VAC-02).
      assert length(codes) == 3
      assert Enum.all?(codes, &(&1 != 0))
      assert Enum.uniq(codes) == codes
    end
  end

  describe "round trip" do
    test "the emitter's real output verifies against the same triple" do
      dir = tmp_dir!("round-trip")
      out = Path.join(dir, "publication-record.json")

      assert {_output, 0} = emit(emit_args(out))
      assert {output, 0} = assert_record(out)
      assert output =~ @verified_token
    end

    test "the emitter's real output from the recovery lane verifies identically" do
      dir = tmp_dir!("round-trip-recovery")
      out = Path.join(dir, "publication-record.json")

      assert {_output, 0} = emit(emit_args(out, %{lane: "recovery"}))
      assert {output, 0} = assert_record(out)
      assert output =~ @verified_token
    end

    test "the emitter's real output fails against a different version" do
      dir = tmp_dir!("round-trip-mismatch")
      out = Path.join(dir, "publication-record.json")

      assert {_output, 0} = emit(emit_args(out))
      assert {output, code} = assert_record(out, %{version: "0.9.9"})
      assert code != 0
      assert output =~ @mismatch_token
    end
  end
end
