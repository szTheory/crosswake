import Config

config :crosswake_example, CrosswakeExample.Endpoint,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"lib/.+\.ex(s)?$",
      ~r"priv/static/.+\.(css|js)$"
    ],
    interval: 1500
  ]

config :crosswake_example, CrosswakeExample.Repo,
  show_sensitive_data_on_connection_error: true

# Force the polling file-system watcher so live-reload works on Docker bind-mounts
# — notably macOS, where inotify events do not cross the VM boundary — without
# requiring inotify-tools in the image. FSPoll is the only backend usable on every
# platform, so it keeps native dev and the container on the same code path.
config :phoenix_live_reload, :backend, :fs_poll
config :phoenix_live_reload, :backend_opts, interval: 1500
