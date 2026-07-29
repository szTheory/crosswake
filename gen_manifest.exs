paths = [
  "examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex",
  "examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/on_mount.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/submission.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/claims.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/submissions.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/claim_live.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/claim_capture_live.ex",
  "examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex",
  "examples/phoenix_host/lib/crosswake_example/router.ex"
]

for path <- paths do
  Code.require_file(Path.expand(path, File.cwd!()))
end

{:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(CrosswakeExample.Router)
json = Crosswake.Manifest.render(manifest)

File.write!("examples/ios_shell_host/Fixtures/crosswake_manifest.json", json)
File.write!("examples/android_shell_host/app/src/main/assets/crosswake_manifest.json", json)
IO.puts("Manifests generated")
