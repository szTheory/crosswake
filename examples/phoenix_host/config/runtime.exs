import Config

# Bind 0.0.0.0 inside Docker; 127.0.0.1 native. Port defaults to 4700.
# Gate on an explicit env var so :test env stays on loopback.
ip =
  if System.get_env("BIND_ALL") == "true" do
    {0, 0, 0, 0}
  else
    {127, 0, 0, 1}
  end

port = String.to_integer(System.get_env("PORT") || "4700")

config :crosswake_example, CrosswakeExample.Endpoint,
  http: [ip: ip, port: port]

database_path =
  System.get_env("DATABASE_PATH") ||
    Path.expand("../crosswake_example.db", Path.dirname(__ENV__.file))

config :crosswake_example, CrosswakeExample.Repo,
  database: database_path
