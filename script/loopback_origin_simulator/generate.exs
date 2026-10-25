# Test-owned generation for the loopback Simulator harness (Phase 182, D-17.7).
# Declares the :ios_host path in Application env and calls the real generator.
# Run only under MIX_ENV=test (production refuses origin_mode :local_loopback).
[run_dir, port] = System.argv()

Application.put_env(:crosswake, :ios_host,
  router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
  origin: "http://127.0.0.1:#{port}",
  origin_mode: :local_loopback,
  entry_route_id: "study-session",
  app_bundle_id: "org.crosswake.loopbackprobe",
  proof_app_bundle_id: "org.crosswake.loopbackprobe.proof",
  device_signing: [mode: :automatic, team_id: "ABCDE12345"]
)

Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", run_dir])
