defmodule Phase175SafeCapture do
  @drop ~w(user owner actor triggering_actor author committer authors owners assignee assignees requested_reviewers requested_teams body email avatar_url gravatar_id node_id login)
  def digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  def clean(value) when is_list(value), do: Enum.map(value, &clean/1)
  def clean(value) when is_map(value) do
    if Map.has_key?(value, "login") do
      %{"login" => "redacted_account"}
    else
      value |> Enum.reject(fn {k, _} -> k in @drop end) |> Map.new(fn
        {"message", text} when is_binary(text) -> {"message", text |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "REL17-AUTHORIZATION: ")) |> Enum.join("\n")}
        {k, v} -> {k, clean(v)}
      end)
    end
  end
  def clean(value), do: value
  def bounded(program, args, ms) do
    task = Task.async(fn -> System.cmd(program, args, stderr_to_stdout: true) end)
    case Task.yield(task, ms) do
      {:ok, result} -> result
      nil -> Task.shutdown(task, :brutal_kill); {"", 124}
    end
  end
  def fetch(url) do
    allowed = String.starts_with?(url, "https://api.github.com/repos/szTheory/crosswake/") or url in ["https://hex.pm/api/packages/crosswake", "https://hex.pm/api/packages/crosswake_chimeway"]
    if not allowed, do: raise("unapproved read route")
    response = if String.starts_with?(url, "https://hex.pm/") do
      case bounded("curl", ["--silent", "--show-error", "--max-time", "20", "--max-filesize", "2097152", "--write-out", "\n__STATUS__%{http_code}", url], 25000) do
        {output, 0} -> [body, status] = String.split(output, "\n__STATUS__", parts: 2); {:ok, %{status: String.to_integer(String.trim(status)), body: body, headers: []}}
        _ -> {:error, "api_request_failed"}
      end
    else
      case bounded("gh", ["api", "--include", url], 20000) do
        {text, 0} ->
          case Regex.run(~r/\AHTTP\/[^\s]+\s+(\d{3})[^\r\n]*\r?\n(.*?)(?:\r?\n\r?\n)(.*)\z/s, text) do
            [_, status, headers, body] ->
              links = headers |> String.split(~r/\r?\n/) |> Enum.flat_map(fn line ->
                case String.split(line, ":", parts: 2) do
                  [key, v] -> if String.downcase(key) == "link", do: [{key, String.trim(v)}], else: []
                  _ -> []
                end
              end)
              {:ok, %{status: String.to_integer(status), headers: links, body: body}}
            _ -> {:error, "api_response_invalid"}
          end
        _ -> {:error, "api_request_failed"}
      end
    end
    case response do
      {:ok, %{body: body} = response} when byte_size(body) in 1..2097152 ->
        case Jason.decode(body) do
          {:ok, value} ->
            cleaned = clean(value)
            bytes = if cleaned == value, do: body, else: Jason.encode!(cleaned, maps: :strict)
            {:ok, %{response | body: bytes}}
          _ -> {:error, "api_response_invalid"}
        end
      _ -> {:error, "api_request_failed"}
    end
  end
  def get(url) do
    {:ok, %{status: 200, body: body}} = fetch(url)
    {Jason.decode!(body), body}
  end
  def policy do
    {protection, raw} = get("https://api.github.com/repos/szTheory/crosswake/branches/main/protection")
    {rulesets, _} = get("https://api.github.com/repos/szTheory/crosswake/rulesets?per_page=100")
    ids = rulesets |> Enum.filter(&(&1["enforcement"] in ["active", "evaluate"])) |> Enum.map(& &1["id"])
    details = Enum.map(ids, fn id -> {detail, bytes} = get("https://api.github.com/repos/szTheory/crosswake/rulesets/#{id}"); {id, detail, bytes} end)
    checks = protection["required_status_checks"]
    app_ids = Map.new(List.wrap(checks["checks"]), &{&1["context"], &1["app_id"]})
    branch = Enum.map(List.wrap(checks["contexts"]), &%{"context" => &1, "app_id" => app_ids[&1]}) ++ Enum.map(List.wrap(checks["checks"]), &%{"context" => &1["context"], "app_id" => &1["app_id"]})
    from_rules = Enum.flat_map(details, fn {_, d, _} ->
      Enum.flat_map(d["rules"] || [], fn rule ->
        if rule["type"] == "required_status_checks" do
          checks = rule["parameters"]["required_status_checks"] || rule["parameters"]["checks"] || []
          Enum.map(checks, &Map.put_new(&1, "app_id", &1["integration_id"]))
        else
          []
        end
      end)
    end)
    required = Enum.uniq_by(branch ++ from_rules, & &1["context"]) |> Enum.sort_by(& &1["context"])
    true = protection["enforce_admins"]["enabled"] == true
    true = Enum.all?(details, fn {_, d, _} -> d["bypass_actors"] in [nil, []] end)
    true = Enum.any?(required, &(&1["context"] == "Crosswake CI"))
    facts = %{"required_checks" => required, "ruleset_ids" => Enum.sort(ids), "branch_protection_sha256" => digest(raw), "rulesets" => Enum.map(details, fn {id, _, b} -> %{"id" => id, "sha256" => digest(b)} end) |> Enum.sort_by(& &1["id"]), "enforce_admins" => true, "bypass_actors" => []}
    %{sha256: facts |> Jason.encode!(maps: :strict) |> digest(), facts: facts}
  end
end
case Enum.reject(System.argv(), &(&1 == "--")) do
  ["policy"] -> IO.puts(Jason.encode!(Phase175SafeCapture.policy()))
  ["capture", options_file, ancestry_root] ->
    data = options_file |> File.read!() |> Jason.decode!()
    opts = Enum.map(data, fn {key, value} -> {String.to_existing_atom(key), value} end)
    git = fn from, to -> case Phase175SafeCapture.bounded("git", ["-C", ancestry_root, "merge-base", "--is-ancestor", from, to], 10000) do {_, 0} -> true; _ -> false end end
    case Crosswake.ReleaseCandidate.EvidenceLive.capture(opts ++ [http: &Phase175SafeCapture.fetch/1, git_ancestor: git]) do
      {:ok, result} ->
        File.write!(Path.join(result.source_dir, "envelope.json"), Jason.encode!(result.envelope), [:sync])
        case Crosswake.ReleaseCandidate.EvidenceGate.validate(result.envelope, result.sources) do
          {:ok, verdict} -> IO.puts(Jason.encode!(%{status: "PASS", verdict: verdict}))
          {:error, reason} -> IO.puts(Jason.encode!(%{status: "BLOCKED", reason: reason})); System.halt(1)
        end
      {:error, reason} -> IO.puts(Jason.encode!(%{status: "BLOCKED", reason: reason})); System.halt(1)
    end
  [] -> :ok
end
