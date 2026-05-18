defmodule CrosswakeExample.Repo do
  use Ecto.Repo,
    otp_app: :crosswake_example,
    adapter: Ecto.Adapters.SQLite3
end
