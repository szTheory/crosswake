#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: verify_ios_release_host.sh --version VERSION --host-root DIR --target DIR" >&2
  exit 2
}

version=""
host_root=""
target=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) [ "$#" -ge 2 ] || usage; version="$2"; shift 2 ;;
    --host-root) [ "$#" -ge 2 ] || usage; host_root="$2"; shift 2 ;;
    --target) [ "$#" -ge 2 ] || usage; target="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || usage
[ -n "$host_root" ] && [ -n "$target" ] || usage
[ ! -e "$host_root" ] && [ ! -e "$target" ] || {
  echo "consumer host and target paths must not already exist" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$(dirname "$host_root")" "$(dirname "$target")"
mix new "$host_root" --app crosswake_release_proof >/dev/null
cp "$repo_root/.tool-versions" "$host_root/.tool-versions"
mkdir -p "$target"

cat > "$host_root/mix.exs" <<'ELIXIR'
defmodule CrosswakeReleaseProof.MixProject do
  use Mix.Project

  def project do
    [app: :crosswake_release_proof, version: "0.1.0", elixir: "~> 1.19", deps: deps()]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    version = System.fetch_env!("CROSSWAKE_VERSION")
    [{:crosswake, "== #{version}"}]
  end
end
ELIXIR

(
  cd "$host_root"
  export CROSSWAKE_VERSION="$version"
  mix deps.get
  deps_report="$(mix deps)"
  printf '%s\n' "$deps_report"
  printf '%s\n' "$deps_report" | grep -F "* crosswake (Hex package)" >/dev/null
  printf '%s\n' "$deps_report" | grep -F "  locked at $version (crosswake)" >/dev/null
  mix crosswake.gen.shell ios --target "$target"
)

manifest="$target/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json"
jq -e '.crosswake_version | type == "string" and length > 0' "$manifest" >/dev/null
echo "external Hex consumer generated iOS shell for Crosswake $version"
