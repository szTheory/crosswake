# Reviewed declared production runtime surface. Deliberate edits only; never refreshed.
[
  {"mix.exs", "crosswake",
   [
     {"jason", false, "Encode and decode contract JSON."},
     {"nimble_options", false, "Validate route and bridge declarations."},
     {"phoenix", false, "Integrate host routing and endpoints."},
     {"phoenix_live_view", false, "Provide the LiveView bridge surface."},
     {"telemetry", false, "Emit bounded operational events."}
   ]},
  {"packages/crosswake_chimeway/mix.exs", "crosswake_chimeway",
   [{"crosswake", false, "Integrate core notification contracts."}]},
  {"packages/crosswake_rindle/mix.exs", "crosswake_rindle",
   [
     {"crosswake", false, "Integrate core media contracts."},
     {"rindle", true, "Enable the optional media engine."}
   ]},
  {"packages/crosswake_rulestead/mix.exs", "crosswake_rulestead",
   [
     {"crosswake", false, "Integrate core feature contracts."},
     {"rulestead", true, "Enable the optional feature engine."}
   ]},
  {"packages/crosswake_sigra/mix.exs", "crosswake_sigra",
   [{"crosswake", false, "Integrate core authorization contracts."}]},
  {"packages/crosswake_threadline/mix.exs", "crosswake_threadline",
   [
     {"crosswake", false, "Integrate core thread contracts."},
     {"nimble_options", false, "Validate thread integration options."},
     {"phoenix_live_view", true, "Enable the optional LiveView thread surface."},
     {"plug", true, "Enable the optional Plug thread surface."},
     {"telemetry", false, "Observe bounded thread events."}
   ]}
]
