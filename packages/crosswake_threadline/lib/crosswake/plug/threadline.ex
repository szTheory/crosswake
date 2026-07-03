if Code.ensure_loaded?(Plug.Conn) do
  defmodule Crosswake.Plug.Threadline do
    @moduledoc """
    HTTP thread_id read/mint Plug with telemetry triplet.

    > #### Optional dependency {: .info}
    > This module is only available when `{:plug, "~> 1.0"}` is declared as a dependency.
    > After adding `:plug` to your deps, run `mix deps.compile --force crosswake_threadline`
    > (stale-BEAM caveat: optional deps are not compiled by default until forced).
    """
    @behaviour Plug

    alias Plug.Conn
    alias Crosswake.Threadline.Id
    alias Crosswake.Threadline.Telemetry

    @schema NimbleOptions.new!(
      header_name: [
        type: :string,
        default: "x-crosswake-thread-id"
      ],
      logger_metadata_key: [
        type: :atom,
        default: :crosswake_thread_id
      ],
      telemetry_prefix: [
        type: {:list, :atom},
        default: [:crosswake, :threadline, :request]
      ]
    )

    @impl Plug
    def init(opts) do
      NimbleOptions.validate!(opts, @schema)
    end

    @impl Plug
    def call(conn, opts) do
      start_time = System.monotonic_time()

      try do
        header_name = opts[:header_name]

        {id, source} =
          case Conn.get_req_header(conn, header_name) do
            [id | _] -> {id, :inbound}
            [] -> {Id.generate(), :minted}
          end

        logger_key = opts[:logger_metadata_key]
        Logger.metadata([{logger_key, id}])

        conn = Conn.put_resp_header(conn, header_name, id)

        prefix = opts[:telemetry_prefix]
        meta = [thread_id: id, source: source]

        Telemetry.execute(
          prefix ++ [:start],
          %{system_time: System.system_time()},
          meta
        )

        Conn.register_before_send(conn, fn conn ->
          duration = System.monotonic_time() - start_time
          Telemetry.execute(prefix ++ [:stop], %{duration: duration}, meta)
          conn
        end)
      rescue
        e ->
          # The :exception scope is OWN-plug-work-only
          prefix = opts[:telemetry_prefix] || [:crosswake, :threadline, :request]
          duration = System.monotonic_time() - start_time

          Telemetry.execute(
            prefix ++ [:exception],
            %{duration: duration},
            %{kind: :error, reason: e}
          )

          reraise e, __STACKTRACE__
      end
    end
  end
end
