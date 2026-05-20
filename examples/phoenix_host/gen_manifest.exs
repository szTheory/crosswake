{:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(CrosswakeExample.Router)
json = Crosswake.Manifest.Serializer.render(manifest)

File.write!("../../examples/ios_shell_host/Fixtures/crosswake_manifest.json", json)
File.write!("../../examples/android_shell_host/app/src/main/assets/crosswake_manifest.json", json)
IO.puts("Manifests generated")
