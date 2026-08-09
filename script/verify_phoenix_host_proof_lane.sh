#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_host="${repo_root}/examples/phoenix_host"
adapter_fixture="${repo_root}/test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts"
isolated_root="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/crosswake-proof-lane.XXXXXX")" && pwd -P)"
workspace_root="${isolated_root}/crosswake"
host_root="${workspace_root}/examples/phoenix_host"
config_path="${isolated_root}/proof_lane.exs"

cleanup() {
  rm -rf "${isolated_root}"
}
trap cleanup EXIT INT TERM

for required_file in \
  "${adapter_fixture}" \
  "${source_host}/playwright.config.ts" \
  "${source_host}/tsconfig.offline_route_proof.json"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "missing Phoenix proof input" >&2
    exit 1
  fi
done

for executable in tsc playwright; do
  if [[ ! -x "${source_host}/node_modules/.bin/${executable}" ]]; then
    echo "missing existing Phoenix-host Node dependency: ${executable}" >&2
    exit 1
  fi
done

rsync -a \
  --exclude '.git' \
  --exclude 'examples' \
  --exclude 'deps' \
  --exclude '_build' \
  "${repo_root}/" "${workspace_root}/"
ln -s "${repo_root}/deps" "${workspace_root}/deps"
ln -s "${repo_root}/_build" "${workspace_root}/_build"
mkdir -p "${workspace_root}/examples"
ln -s "${repo_root}/packages" "${workspace_root}/packages"

rsync -a \
  --exclude 'node_modules' \
  --exclude 'playwright-report' \
  --exclude 'test-results' \
  --exclude 'e2e/crosswake_proof_lane/proof_lane.spec.ts' \
  --exclude 'e2e/crosswake_proof_lane/support/proof_lane.ts' \
  "${source_host}/" "${host_root}/"
ln -s "${source_host}/node_modules" "${host_root}/node_modules"

generated_spec="${host_root}/e2e/crosswake_proof_lane/proof_lane.spec.ts"
generated_support="${host_root}/e2e/crosswake_proof_lane/support/proof_lane.ts"
generated_adapter="${host_root}/e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts"

if [[ -e "${generated_spec}" || -e "${generated_support}" ]]; then
  echo "isolated host retained the checked-in proof surrogate" >&2
  exit 1
fi

mkdir -p "$(dirname "${generated_adapter}")"
cp "${adapter_fixture}" "${generated_adapter}"
adapter_sha_before="$(shasum -a 256 "${generated_adapter}" | awk '{print $1}')"

printf '%s\n' \
  'import Config' \
  'config :crosswake, :proof_lane,' \
  '  route_id: "route-0123456789abcdef",' \
  '  route_path: "/offline",' \
  '  indexed_db_database: "crosswake_offline_study",' \
  '  indexed_db_store: "mutations",' \
  '  mutation_id_path: "client_mutation_id",' \
  '  sync_path: "/study/sync",' \
  '  evidence_path: "/_proof/evidence",' \
  '  router: CrosswakeWeb.Router,' \
  "  ios_shell_root: \"${host_root}/native/ios\"" > "${config_path}"

generation_output="$(cd "${repo_root}" && MIX_ENV=test mix crosswake.gen.proof_lane ios --config "${config_path}")"
if ! grep -Fqx 'reused e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts' <<<"${generation_output}"; then
  echo "generator did not reuse the pre-supplied host adapter" >&2
  exit 1
fi

if ! grep -Fqx 'created e2e/crosswake_proof_lane/proof_lane.spec.ts' <<<"${generation_output}" ||
  ! grep -Fqx 'created e2e/crosswake_proof_lane/support/proof_lane.ts' <<<"${generation_output}"; then
  echo "generator did not create the isolated rendered proof files" >&2
  exit 1
fi

if [[ "${adapter_sha_before}" != "$(shasum -a 256 "${generated_adapter}" | awk '{print $1}')" ]]; then
  echo "generator changed the host-owned adapter" >&2
  exit 1
fi

node -e '
  const fs = require("node:fs");
  const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const adapter = "e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts";
  if (manifest.schema_version !== 1 || manifest.template_version !== 2 ||
      manifest.provenance !== "crosswake:proof-lane" || !manifest.paths.includes(adapter)) process.exit(1);
' "${host_root}/.crosswake/proof_lane.json" || {
  echo "isolated manifest has invalid proof provenance" >&2
  exit 1
}

(cd "${host_root}" && npm run typecheck:offline-route-proof)
(
  cd "${host_root}"
  ./node_modules/.bin/playwright test --config playwright.config.ts e2e/crosswake_proof_lane/proof_lane.spec.ts
)
