defmodule Crosswake.ProofLane.TwinRuntimeCheckTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.TwinRuntime

  @head String.duplicate("a", 40)
  @tree String.duplicate("b", 40)

  setup do
    base =
      Path.join(
        System.tmp_dir!(),
        "twin-check-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
      )

    File.mkdir_p!(base)
    File.chmod!(base, 0o700)
    on_exit(fn -> File.rm_rf(base) end)

    candidate = Path.join(base, "candidate")
    File.mkdir_p!(candidate)
    File.write!(Path.join(candidate, "mix.lock"), "%{}\n")
    run_root = Path.join(base, "run")
    File.mkdir!(run_root)
    File.chmod!(run_root, 0o700)
    {:ok, base: base, candidate: candidate, run_root: run_root}
  end

  defp free_port do
    {:ok, l} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
    {:ok, port} = :inet.port(l)
    :gen_tcp.close(l)
    port
  end

  defp record(ctx, port \\ nil, mode \\ 0o600, origin \\ nil) do
    path = Path.join(ctx.base, "candidate-record-#{System.unique_integer([:positive])}.json")

    File.write!(
      path,
      Jason.encode!(%{
        candidate_path: ctx.candidate,
        expected_head: @head,
        expected_tree: @tree,
        origin: origin || "http://127.0.0.1:#{port || free_port()}",
        resource_digests: [String.duplicate("d", 64)],
        fixture_digests: [String.duplicate("e", 64)]
      })
    )

    File.chmod!(path, mode)
    path
  end

  # Run fun with TMPDIR pointing at an empty absolute 0700 sandbox; restore after.
  defp with_sandbox(ctx, fun) do
    sandbox = Path.join(ctx.base, "sandbox-#{System.unique_integer([:positive])}")
    File.mkdir!(sandbox)
    File.chmod!(sandbox, 0o700)
    old = System.get_env("TMPDIR")
    System.put_env("TMPDIR", sandbox)

    try do
      fun.(sandbox)
    after
      if old, do: System.put_env("TMPDIR", old), else: System.delete_env("TMPDIR")
    end
  end

  test "a refused prepare without a run root leaves nothing in the temp dir", ctx do
    with_sandbox(ctx, fn sandbox ->
      bad_record = Path.join(ctx.base, "missing-record.json")

      assert {:error, %{cause: :prerequisite_missing}} =
               TwinRuntime.prepare(candidate: bad_record)

      assert File.ls!(sandbox) == []

      malformed = record(ctx, nil, 0o600, "http://localhost:80")
      assert {:error, %{cause: :prerequisite_missing}} = TwinRuntime.prepare(candidate: malformed)
      assert File.ls!(sandbox) == []

      {:ok, held} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
      {:ok, port} = :inet.port(held)

      try do
        occupied = record(ctx, port)

        assert {:error, %{cause: :origin_port_occupied}} =
                 TwinRuntime.prepare(candidate: occupied)

        assert File.ls!(sandbox) == []
      after
        :gen_tcp.close(held)
      end
    end)
  end

  test "check/1 creates nothing and holds no port", ctx do
    port = free_port()
    rec = record(ctx, port)

    with_sandbox(ctx, fn sandbox ->
      assert {:ok, checked} = TwinRuntime.check(candidate: rec)
      assert checked.root.create? == true
      assert File.ls!(sandbox) == []
    end)

    before_listing = File.ls!(ctx.run_root)
    assert {:ok, _} = TwinRuntime.check(candidate: rec, run_root: ctx.run_root)
    assert File.ls!(ctx.run_root) == before_listing
    refute File.exists?(Path.join(ctx.run_root, "receipt.json"))

    assert {:ok, l} = :gen_tcp.listen(port, ip: {127, 0, 0, 1}, reuseaddr: false)
    :gen_tcp.close(l)
  end

  test "commit/1 creates the root and holds the origin until stop_all", ctx do
    port = free_port()
    rec = record(ctx, port)

    with_sandbox(ctx, fn sandbox ->
      assert {:ok, checked} = TwinRuntime.check(candidate: rec)
      assert File.ls!(sandbox) == []
      assert {:ok, runtime} = TwinRuntime.commit(checked)

      [created] = File.ls!(sandbox)
      assert String.starts_with?(created, "crosswake-twin-")
      assert Bitwise.band(File.lstat!(Path.join(sandbox, created)).mode, 0o777) == 0o700

      assert {:error, :eaddrinuse} = :gen_tcp.listen(port, ip: {127, 0, 0, 1}, reuseaddr: false)
      assert :ok = TwinRuntime.stop_all(runtime)
      assert {:ok, l} = :gen_tcp.listen(port, ip: {127, 0, 0, 1}, reuseaddr: false)
      :gen_tcp.close(l)
    end)
  end

  test "commit/1 never removes a run root path it did not create", ctx do
    existing = Path.join(ctx.base, "planted-root")
    File.mkdir!(existing)
    sentinel = Path.join(existing, "sentinel.txt")
    File.write!(sentinel, "keep")

    checked = %{
      root: %{path: existing, create?: true},
      record: %{},
      db: Path.join(existing, "twin.sqlite3"),
      port: free_port(),
      run_deadline_ms: nil
    }

    assert {:error, %{cause: :prerequisite_missing}} = TwinRuntime.commit(checked)
    assert File.dir?(existing)
    assert File.read!(sentinel) == "keep"
  end

  test "a run root owned by another user is refused", ctx do
    rec = record(ctx)
    uid = File.lstat!(ctx.run_root).uid

    assert {:ok, _} = TwinRuntime.check(candidate: rec, run_root: ctx.run_root)
    assert {:ok, runtime} = TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root)
    TwinRuntime.stop_all(runtime)

    expected =
      {:error,
       %{
         cause: :prerequisite_missing,
         action: "Create a private run root directory (mode 0700) and run again with it"
       }}

    opts = [candidate: record(ctx), run_root: ctx.run_root, current_uid: uid + 1]
    assert TwinRuntime.check(opts) == expected
    assert TwinRuntime.prepare(opts) == expected
  end

  test "an unreadable current uid is refused", ctx do
    opts = [candidate: record(ctx), run_root: ctx.run_root, current_uid: "501"]
    assert {:error, %{cause: :prerequisite_missing}} = TwinRuntime.check(opts)
    assert {:error, %{cause: :prerequisite_missing}} = TwinRuntime.prepare(opts)
  end

  test "check/1 and prepare/1 give the same first cause", ctx do
    uid = File.lstat!(ctx.run_root).uid

    loose = Path.join(ctx.base, "loose")
    File.mkdir!(loose)
    File.chmod!(loose, 0o755)

    link = Path.join(ctx.base, "link")
    File.ln_s!(ctx.run_root, link)

    reused = Path.join(ctx.base, "reused")
    File.mkdir!(reused)
    File.chmod!(reused, 0o700)
    File.write!(Path.join(reused, "receipt.json"), "{}")

    inside = Path.join(ctx.candidate, "inner-run")
    File.mkdir!(inside)
    File.chmod!(inside, 0o700)

    {:ok, held} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
    {:ok, held_port} = :inet.port(held)
    on_exit(fn -> :gen_tcp.close(held) end)

    rows = [
      {"root option not a path", fn -> [candidate: record(ctx), run_root: 42] end,
       :prerequisite_missing},
      {"0755 root", fn -> [candidate: record(ctx), run_root: loose] end, :prerequisite_missing},
      {"symlink root", fn -> [candidate: record(ctx), run_root: link] end, :prerequisite_missing},
      {"reused root", fn -> [candidate: record(ctx), run_root: reused] end, :run_root_reused},
      {"foreign-owned root",
       fn -> [candidate: record(ctx), run_root: ctx.run_root, current_uid: uid + 1] end,
       :prerequisite_missing},
      {"missing record",
       fn -> [candidate: Path.join(ctx.base, "nope.json"), run_root: ctx.run_root] end,
       :prerequisite_missing},
      {"0644 record", fn -> [candidate: record(ctx, nil, 0o644), run_root: ctx.run_root] end,
       :prerequisite_missing},
      {"root inside candidate", fn -> [candidate: record(ctx), run_root: inside] end,
       :prerequisite_missing},
      {"database path outside root",
       fn ->
         [
           candidate: record(ctx),
           run_root: ctx.run_root,
           database_path: Path.join(ctx.base, "outside.sqlite3")
         ]
       end, :database_path_rejected},
      {"malformed origin",
       fn ->
         [candidate: record(ctx, nil, 0o600, "http://localhost:80"), run_root: ctx.run_root]
       end, :prerequisite_missing},
      {"occupied port", fn -> [candidate: record(ctx, held_port), run_root: ctx.run_root] end,
       :origin_port_occupied}
    ]

    assert length(rows) == 11

    for {label, opts_fun, expected} <- rows do
      assert {:error, %{cause: ^expected}} = TwinRuntime.check(opts_fun.()), label
      assert {:error, %{cause: ^expected}} = TwinRuntime.prepare(opts_fun.()), label
    end
  end

  test "an occupied origin port is blocked by check/1", ctx do
    {:ok, held} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
    {:ok, port} = :inet.port(held)

    try do
      assert {:error, %{cause: :origin_port_occupied}} =
               TwinRuntime.check(candidate: record(ctx, port), run_root: ctx.run_root)
    after
      :gen_tcp.close(held)
    end
  end
end
