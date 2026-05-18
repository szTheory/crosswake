import Config

config :phoenix, :json_library, Jason

config :crosswake_example,
  ecto_repos: [CrosswakeExample.Repo]

config :crosswake_example, CrosswakeExample.Repo,
  database: Path.expand("../crosswake_example.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :crosswake_example, CrosswakeExample.Router,
  url: [host: "example.crosswake.invalid", scheme: "https", port: 443]
