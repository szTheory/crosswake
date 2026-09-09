#!/usr/bin/env bash
set -euo pipefail

# Materialize the declared repository-evidence toolchain beneath one owned root.
# No credential, global package manager, or user cache participates.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOCK_PATH="$ROOT_DIR/script/repository_evidence_toolchain.json"
EXPECTED_IDS=(erlang elixir node java)
BOOTSTRAP_NODE_SHIM="$(command -v node 2>/dev/null || true)"
BOOTSTRAP_NODE="$(${BOOTSTRAP_NODE_SHIM:-/nonexistent} -p 'process.execPath' 2>/dev/null || true)"
[[ -n "$BOOTSTRAP_NODE" && -x "$BOOTSTRAP_NODE" && "$($BOOTSTRAP_NODE --version 2>/dev/null)" = "v22.14.0" ]] || {
  printf '%s\n' '[crosswake] FAIL repository-evidence-environment; corrective-command=Use the declared Node 22.14.0 bootstrap' >&2
  exit 1
}

fail() {
  printf '%s\n' "[crosswake] FAIL repository-evidence-environment; corrective-command=$1" >&2
  exit 1
}

current_shell_pid() {
  printf '%s\n' "$$"
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi
}

validate_lock() {
  local lock="$1" fixture_mode="${2:-production}"
  "$BOOTSTRAP_NODE" -e '
const fs = require("node:fs");
const lockPath = process.argv[1];
const fixtureMode = process.argv[2] === "fixture";
const ids = ["erlang","elixir","node","java"];
const expected = {
  erlang: ["27.3","https://github.com/erlef/otp_builds/releases/download/OTP-27.3/OTP-27.3-macos-arm64.tar.gz","erlef/otp_builds","OTP-27.3","OTP-27.3-macos-arm64.tar.gz","a76eb513202c7131bcd62ee516f8498098b8adadd417bd90e30ae3a2e3f6762d"],
  elixir: ["1.19.5-otp-27","https://github.com/elixir-lang/elixir/releases/download/v1.19.5/elixir-otp-27.zip","elixir-lang/elixir","v1.19.5","elixir-otp-27.zip","1ab3154ec19adcd4b764cf96badecbe44df5ec6f358dc0fbe29c3749ff6c08de"],
  node: ["22.14.0","https://nodejs.org/dist/v22.14.0/node-v22.14.0-darwin-arm64.tar.gz","nodejs/node","v22.14.0","node-v22.14.0-darwin-arm64.tar.gz","e9404633bc02a5162c5c573b1e2490f5fb44648345d64a958b17e325729a5e42"],
  java: ["17.0.20.1+1","https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.20.1_1.tar.gz","adoptium/temurin17-binaries","jdk-17.0.20.1+1","OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.20.1_1.tar.gz","196d13ba5f10414bef7f6a05a9b3f00edacb18ebacef2b99485db9e2ee18f0e8"]
};
const topKeys = ["architecture","artifacts","os","python_packages","schema_version"];
const artifactKeys = ["archive_format","archive_root","asset","authority_repository","authority_tag","executable_relative_path","id","sha256","url","version","version_probe","version_regex"];
const pythonPackageKeys = ["asset","authority_project","id","import_name","sha256","url","version"];
const sameKeys = (value, keys) => value && typeof value === "object" && !Array.isArray(value) && Object.keys(value).sort().join("\0") === [...keys].sort().join("\0");
let lock;
try { lock = JSON.parse(fs.readFileSync(lockPath, "utf8")); } catch { process.exit(1); }
if (!sameKeys(lock, topKeys) || lock.schema_version !== 1 || lock.os !== "Darwin" || lock.architecture !== "arm64" || !Array.isArray(lock.artifacts) || lock.artifacts.length !== 4 || !Array.isArray(lock.python_packages) || lock.python_packages.length !== 1) process.exit(1);
const pythonPackage = lock.python_packages[0];
if (!sameKeys(pythonPackage, pythonPackageKeys) || pythonPackage.id !== "pyyaml" || pythonPackage.import_name !== "yaml" || !/^[0-9a-f]{64}$/.test(pythonPackage.sha256)) process.exit(1);
const expectedPythonPackage = ["6.0.3","https://files.pythonhosted.org/packages/ae/92/861f152ce87c452b11b9d0977952259aa7df792d71c1053365cc7b09cc08/pyyaml-6.0.3-cp39-cp39-macosx_11_0_arm64.whl","PyYAML","pyyaml-6.0.3-cp39-cp39-macosx_11_0_arm64.whl","c3355370a2c156cffb25e876646f149d5d68f5e0a3ce86a5084dd0b64a994917"];
if (!fixtureMode && (!/^https:\/\/files\.pythonhosted\.org\//.test(pythonPackage.url) || JSON.stringify([pythonPackage.version,pythonPackage.url,pythonPackage.authority_project,pythonPackage.asset,pythonPackage.sha256]) !== JSON.stringify(expectedPythonPackage))) process.exit(1);
if (fixtureMode && !pythonPackage.url.startsWith("https://fixtures.invalid/")) process.exit(1);
for (let index = 0; index < ids.length; index += 1) {
  const record = lock.artifacts[index];
  if (!sameKeys(record, artifactKeys) || record.id !== ids[index] || !["tar.gz","zip"].includes(record.archive_format)) process.exit(1);
  for (const field of ["version","url","authority_repository","authority_tag","asset","sha256","archive_root","executable_relative_path","version_regex"]) if (typeof record[field] !== "string" || record[field] === "") process.exit(1);
  if (!/^https:\/\//.test(record.url) || /(?:^|[\/_-])latest(?:[\/_-]|$)/i.test(record.url) || !/^[0-9a-f]{64}$/.test(record.sha256)) process.exit(1);
  if (record.archive_root.startsWith("/") || record.executable_relative_path.startsWith("/") || [record.archive_root, record.executable_relative_path].some(value => value.split(/[\\/]/).includes(".."))) process.exit(1);
  if (!Array.isArray(record.version_probe) || record.version_probe.length < 2 || record.version_probe[0] !== record.executable_relative_path || record.version_probe.some(value => typeof value !== "string" || value === "")) process.exit(1);
  try { new RegExp(record.version_regex); } catch { process.exit(1); }
  if (!fixtureMode) {
    const fields = [record.version,record.url,record.authority_repository,record.authority_tag,record.asset,record.sha256];
    if (JSON.stringify(fields) !== JSON.stringify(expected[record.id])) process.exit(1);
  } else if (!record.url.startsWith("https://fixtures.invalid/")) process.exit(1);
}
' "$lock" "$fixture_mode"
}

emit_lock_records() {
  local lock="$1"
  "$BOOTSTRAP_NODE" -e '
const lock = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
for (const value of lock.artifacts) console.log([value.id,value.version,value.url,value.authority_repository,value.authority_tag,value.asset,value.sha256,value.archive_format,value.archive_root,value.executable_relative_path,JSON.stringify(value.version_probe),value.version_regex].join("\t"));
' "$lock"
}

emit_python_package_records() {
  local lock="$1"
  "$BOOTSTRAP_NODE" -e '
const lock = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
for (const value of lock.python_packages) console.log([value.id,value.version,value.url,value.authority_project,value.asset,value.sha256,value.import_name].join("\t"));
' "$lock"
}

validate_archive_entries() {
  local entries="$1"
  "$BOOTSTRAP_NODE" -e '
const fs = require("node:fs");
const entries = fs.readFileSync(process.argv[1], "utf8").split(/\n/).filter(Boolean);
if (entries.length === 0) process.exit(1);
for (const entry of entries) {
  if (entry.startsWith("/") || entry.includes("\\") || entry.split("/").includes("..") || entry.includes("\0")) process.exit(1);
}
' "$entries"
}

validate_owned_root() {
  local candidate="$1" temp_parent="${TMPDIR:-/tmp}" parent_real
  [[ "$candidate" = "$temp_parent"/crosswake-repository-evidence-tools.* && -d "$candidate" && ! -L "$candidate" ]] || return 1
  parent_real="$(cd "$(dirname "$candidate")" && pwd -P)" || return 1
  [[ "$parent_real" = "$(cd "$temp_parent" && pwd -P)" ]]
}

host_identity() {
  if [[ "${CROSSWAKE_EVIDENCE_TEST_GUARD:-}" = "isolated-fixture" ]]; then
    printf '%s\n' "${CROSSWAKE_EVIDENCE_TEST_HOST_IDENTITY:-Darwin/arm64}"
  else
    printf '%s/%s\n' "$(uname -s)" "$(uname -m)"
  fi
}

system_path() {
  if [[ "${CROSSWAKE_EVIDENCE_TEST_GUARD:-}" = "isolated-fixture" ]]; then
    printf '%s\n' "${CROSSWAKE_EVIDENCE_TEST_SYSTEM_PATH:-/usr/bin:/bin:/usr/sbin:/sbin}"
  else
    printf '%s\n' "/usr/bin:/bin:/usr/sbin:/sbin"
  fi
}

validate_apple_tools() {
  local safe_path="$1" xcode swift output
  xcode="$(PATH="$safe_path" command -v xcodebuild 2>/dev/null)" || return 1
  swift="$(PATH="$safe_path" command -v swift 2>/dev/null)" || return 1
  case ":$safe_path:" in *":$(dirname "$xcode"):"*) ;; *) return 1 ;; esac
  case ":$safe_path:" in *":$(dirname "$swift"):"*) ;; *) return 1 ;; esac
  output="$(PATH="$safe_path" xcodebuild -version 2>&1)" || return 1
  grep -Eq '^Xcode (1[5-9]|[2-9][0-9])\.' <<<"$output" || return 1
  output="$(PATH="$safe_path" swift --version 2>&1)" || return 1
  grep -Eq 'Swift version (5\.9|6\.)' <<<"$output"
}

provision() {
  local lock="${CROSSWAKE_EVIDENCE_TEST_LOCK:-$LOCK_PATH}" mode=production safe_system_path tool_root records
  local id version url authority_repository authority_tag asset digest format archive_root executable probe_json version_regex
  local archive extract_root prefix executable actual path_prefixes="" java_home="" python_records python_root import_name
  if [[ "${CROSSWAKE_EVIDENCE_TEST_GUARD:-}" = "isolated-fixture" ]]; then mode=fixture; fi
  validate_lock "$lock" "$mode" || fail "node --test --test-name-pattern=environment test/js/repository_verification.test.mjs"
  [[ "$(host_identity)" = "Darwin/arm64" ]] || fail "Run repository evidence on Darwin/arm64"
  safe_system_path="$(system_path)"
  validate_apple_tools "$safe_system_path" || fail "Install and select Xcode command-line tools"

  tool_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-repository-evidence-tools.XXXXXX")"
  chmod 700 "$tool_root"
  EVIDENCE_TOOL_OWNER_PID="$(current_shell_pid)"
  EVIDENCE_TOOL_ROOT="$tool_root"
  cleanup_tools() {
    [[ "$(current_shell_pid)" = "$EVIDENCE_TOOL_OWNER_PID" ]] || return 0
    case "$EVIDENCE_TOOL_ROOT" in "${TMPDIR:-/tmp}"/crosswake-repository-evidence-tools.*) rm -rf -- "$EVIDENCE_TOOL_ROOT" ;; *) return 1 ;; esac
  }
  trap cleanup_tools EXIT HUP INT TERM
  validate_owned_root "$tool_root" || fail "Use the invocation-owned repository evidence tool root"
  mkdir -p "$tool_root/downloads" "$tool_root/extracted" "$tool_root/home" "$tool_root/cache"
  records="$tool_root/records.tsv"
  emit_lock_records "$lock" >"$records"

  while IFS=$'\t' read -r id version url authority_repository authority_tag asset digest format archive_root executable probe_json version_regex; do
    archive="$tool_root/downloads/$asset"
    extract_root="$tool_root/extracted/$id"
    mkdir -p "$extract_root"
    curl --proto '=https' --tlsv1.2 --fail --location --retry 3 --retry-delay 2 --retry-all-errors "$url" -o "$archive" >"$tool_root/downloads/$id.log" 2>&1 || fail "Retry the pinned $id artifact download"
    [[ "$(sha256_file "$archive")" = "$digest" ]] || fail "Verify the tracked $id SHA-256 pin"
    if [[ "$format" = "tar.gz" ]]; then
      tar -tzf "$archive" >"$tool_root/$id.entries" || fail "Inspect the pinned $id archive"
    else
      unzip -Z1 "$archive" >"$tool_root/$id.entries" || fail "Inspect the pinned $id archive"
    fi
    validate_archive_entries "$tool_root/$id.entries" || fail "Reject unsafe $id archive entries"
    if [[ "$format" = "tar.gz" ]]; then tar -xzf "$archive" -C "$extract_root"; else unzip -q "$archive" -d "$extract_root"; fi
    if [[ "$archive_root" = "." ]]; then prefix="$extract_root"; else prefix="$extract_root/$archive_root"; fi
    [[ -d "$prefix" && ! -L "$prefix" ]] || fail "Verify the pinned $id archive layout"
    executable="$prefix/$executable"
    [[ -x "$executable" && ! -L "$executable" ]] || fail "Verify the pinned $id executable layout"
    actual="$(PATH="${path_prefixes:+$path_prefixes:}$safe_system_path" "$BOOTSTRAP_NODE" -e '
const {spawnSync} = require("node:child_process");
const executable = process.argv[1];
const relative = process.argv[2];
const argv = JSON.parse(process.argv[3]);
const pathValue = process.argv[4];
argv[0] = executable;
const result = spawnSync(argv[0], argv.slice(1), {encoding:"utf8", env:{...process.env, PATH:pathValue}});
if (result.error || result.status !== 0) process.exit(1);
process.stdout.write(`${result.stdout || ""}${result.stderr || ""}`.trim());
' "$executable" "$executable" "$probe_json" "${path_prefixes:+$path_prefixes:}$safe_system_path")" || fail "Run the pinned $id version probe"
    grep -Eq "$version_regex" <<<"$actual" || fail "Match the pinned $id version"
    if [[ "$id" = "elixir" ]]; then grep -Fq 'Erlang/OTP 27' <<<"$actual" || fail "Compose Elixir with pinned OTP 27"; fi
    path_prefixes="${path_prefixes:+$path_prefixes:}$(dirname "$executable")"
    if [[ "$id" = "java" ]]; then java_home="$prefix"; fi
  done <"$records"

  python_root="$tool_root/python"
  python_records="$tool_root/python-records.tsv"
  mkdir -p "$python_root"
  emit_python_package_records "$lock" >"$python_records"
  while IFS=$'\t' read -r id version url authority_project asset digest import_name; do
    archive="$tool_root/downloads/$asset"
    curl --proto '=https' --tlsv1.2 --fail --location --retry 3 --retry-delay 2 --retry-all-errors "$url" -o "$archive" >"$tool_root/downloads/$id.log" 2>&1 || fail "Retry the pinned $id package download"
    [[ "$(sha256_file "$archive")" = "$digest" ]] || fail "Verify the tracked $id SHA-256 pin"
    unzip -Z1 "$archive" >"$tool_root/$id.entries" || fail "Inspect the pinned $id package"
    validate_archive_entries "$tool_root/$id.entries" || fail "Reject unsafe $id package entries"
    unzip -q "$archive" -d "$python_root" || fail "Extract the pinned $id package"
    PYTHONPATH="$python_root" PYTHONNOUSERSITE=1 PATH="$safe_system_path" python3 -c "import $import_name; assert $import_name.__version__ == '$version'" || fail "Import the pinned $id package"
  done <"$python_records"

  PATH="$path_prefixes:$safe_system_path"
  export PATH JAVA_HOME="$java_home" HOME="$tool_root/home" MIX_HOME="$tool_root/cache/mix" HEX_HOME="$tool_root/cache/hex" \
    NPM_CONFIG_CACHE="$tool_root/cache/npm" GRADLE_USER_HOME="$tool_root/cache/gradle" SWIFTPM_MODULECACHE_OVERRIDE="$tool_root/cache/swift" \
    PLAYWRIGHT_BROWSERS_PATH="$tool_root/cache/playwright" PYTHONPATH="$python_root" PYTHONNOUSERSITE=1 CROSSWAKE_REPOSITORY_EVIDENCE_ENVIRONMENT=1 \
    CROSSWAKE_REPOSITORY_EVIDENCE_TOOL_ROOT="$tool_root"
  mkdir -p "$MIX_HOME" "$HEX_HOME" "$NPM_CONFIG_CACHE" "$GRADLE_USER_HOME" "$SWIFTPM_MODULECACHE_OVERRIDE" "$PLAYWRIGHT_BROWSERS_PATH"
  [[ "$(command -v erl)" = "$tool_root"/* && "$(command -v elixir)" = "$tool_root"/* && "$(command -v node)" = "$tool_root"/* && "$(command -v java)" = "$tool_root"/* ]] || fail "Keep evidence tools inside the invocation root"
  python3 -c 'import yaml; assert yaml.__version__ == "6.0.3"' || fail "Use the pinned invocation-local PyYAML package"
  PROVISIONED_TOOL_ROOT="$tool_root"
}

prepare_preflight() {
  local source_repository="$1" commit="$2" source_root resolved tool_root checkout status=0
  source_root="$(git -C "$source_repository" rev-parse --show-toplevel 2>/dev/null)" || fail "Provide a Git source repository"
  [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || fail "Provide an exact commit SHA"
  resolved="$(git -C "$source_root" rev-parse --verify "$commit^{commit}" 2>/dev/null)" || fail "Provide a tracked commit SHA"
  [[ "$resolved" = "$commit" && -n "$(git -C "$source_root" for-each-ref --contains "$resolved" --format='%(refname)' refs/heads refs/tags refs/remotes)" ]] || fail "Provide a tracked commit SHA"
  provision
  tool_root="$PROVISIONED_TOOL_ROOT"
  checkout="$tool_root/preflight-checkout"
  git clone --quiet --no-local "$source_root" "$checkout" >"$tool_root/preflight-clone.log" 2>&1 || status=$?
  [[ "$status" -eq 0 ]] || fail "Clone the explicit repository commit"
  git -C "$checkout" checkout --quiet --detach "$resolved" || fail "Check out the explicit repository commit"
  (cd "$checkout" && mix local.hex --force && mix local.rebar --force && MIX_ENV=test mix deps.get && packages/crosswake-shell-core-android/gradlew --no-daemon --version) >"$tool_root/preflight-bootstrap.log" 2>&1 || fail "Bootstrap lock-governed preflight dependencies"
  (cd "$checkout" && script/verify_repository.sh --stage repository-preflight) >"$tool_root/preflight.log" 2>&1 || fail "Run the production repository preflight"
  grep -Fxq 'PASS repository-preflight' "$tool_root/preflight.log" || fail "Run the production repository preflight"
  grep -Fxq 'PASS repository-cleanliness' "$tool_root/preflight.log" || fail "Run the production repository preflight"
  [[ -z "$(git -C "$checkout" status --porcelain=v1 --untracked-files=all)" ]] || fail "Keep the preflight checkout clean"
  trap - EXIT HUP INT TERM
  cleanup_tools
  printf '%s\n' '[crosswake] PASS repository-evidence-environment preflight'
}

run_capture() {
  local source_repository="$1" commit="$2" output_dir="$3" tool_root
  provision
  tool_root="$PROVISIONED_TOOL_ROOT"
  "$ROOT_DIR/script/capture_repository_verification_evidence.sh" --source-repository "$source_repository" --commit "$commit" --output-dir "$output_dir"
  trap - EXIT HUP INT TERM
  cleanup_tools
}

self_test() {
  local self_root bad_lock entries outside candidate status source_text fixture_artifacts fixture_sources fixture_bin fixture_lock id version archive_root executable version_regex digest
  self_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-repository-evidence-self-test.XXXXXX")"
  chmod 700 "$self_root"
  EVIDENCE_SELF_TEST_OWNER_PID="$(current_shell_pid)"
  EVIDENCE_SELF_TEST_ROOT="$self_root"
  cleanup_self_test() {
    [[ "$(current_shell_pid)" = "$EVIDENCE_SELF_TEST_OWNER_PID" ]] || return 0
    case "$EVIDENCE_SELF_TEST_ROOT" in "${TMPDIR:-/tmp}"/crosswake-repository-evidence-self-test.*) rm -rf -- "$EVIDENCE_SELF_TEST_ROOT" ;; *) return 1 ;; esac
  }
  trap cleanup_self_test EXIT HUP INT TERM

  validate_lock "$LOCK_PATH"
  fixture_artifacts="$self_root/artifacts"
  fixture_sources="$self_root/sources"
  fixture_bin="$self_root/system-bin"
  fixture_lock="$self_root/fixture-lock.json"
  mkdir -p "$fixture_artifacts" "$fixture_sources" "$fixture_bin"
  printf '%s\n' '#!/bin/bash' 'printf "Xcode 26.6\\nBuild version fixture\\n"' >"$fixture_bin/xcodebuild"
  printf '%s\n' '#!/bin/bash' 'printf "Apple Swift version 6.3.3\\n"' >"$fixture_bin/swift"
  printf '%s\n' '#!/bin/bash' 'set -euo pipefail' 'url=""; output=""' 'while [[ "$#" -gt 0 ]]; do case "$1" in -o) output="$2"; shift 2 ;; https://*) url="$1"; shift ;; *) shift ;; esac; done' 'cp "$CROSSWAKE_EVIDENCE_FIXTURE_ARTIFACTS/${url##*/}" "$output"' >"$fixture_bin/curl"
  chmod +x "$fixture_bin/xcodebuild" "$fixture_bin/swift" "$fixture_bin/curl"
  for id in "${EXPECTED_IDS[@]}"; do
    mkdir -p "$fixture_sources/$id/bin"
    case "$id" in
      erlang) version=27.3; executable=bin/erl; version_regex='^27$'; printf '%s\n' '#!/bin/bash' 'printf 27' >"$fixture_sources/$id/$executable" ;;
      elixir) version=1.19.5-otp-27; executable=bin/elixir; version_regex='Elixir 1\.19\.5'; printf '%s\n' '#!/bin/bash' 'printf "Erlang/OTP 27 fixture\\nElixir 1.19.5\\n"' >"$fixture_sources/$id/$executable" ;;
      node) version=22.14.0; executable=bin/node; version_regex='^v22\.14\.0$'; printf '%s\n' '#!/bin/bash' 'printf v22.14.0' >"$fixture_sources/$id/$executable" ;;
      java) version=17.0.20.1+1; executable=bin/java; version_regex='version "17\.0\.20\.1"'; printf '%s\n' '#!/bin/bash' "echo 'openjdk version \"17.0.20.1\"' >&2" >"$fixture_sources/$id/$executable" ;;
    esac
    chmod +x "$fixture_sources/$id/$executable"
    tar -czf "$fixture_artifacts/$id.tar.gz" -C "$fixture_sources/$id" .
  done
  mkdir -p "$fixture_sources/pyyaml/yaml"
  printf '%s\n' '__version__ = "6.0.3"' >"$fixture_sources/pyyaml/yaml/__init__.py"
  (cd "$fixture_sources/pyyaml" && zip -qr "$fixture_artifacts/pyyaml.whl" .)
  "$BOOTSTRAP_NODE" -e '
const fs=require("node:fs"), cp=require("node:child_process"), path=require("node:path");
const root=process.argv[1];
const records=[
  ["erlang","27.3","^27$"],["elixir","1.19.5-otp-27","Elixir 1\\.19\\.5"],
  ["node","22.14.0","^v22\\.14\\.0$"],["java","17.0.20.1+1","version \\\"17\\.0\\.20\\.1\\\""]
].map(([id,version,version_regex]) => {
  const asset=`${id}.tar.gz`;
  const sha256=cp.execFileSync("shasum",["-a","256",path.join(root,asset)],{encoding:"utf8"}).split(/\s/)[0];
  const executable_relative_path=`bin/${id === "erlang" ? "erl" : id === "java" ? "java" : id}`;
  return {id,version,url:`https://fixtures.invalid/${asset}`,authority_repository:"fixtures/repository-evidence",authority_tag:`${id}-${version}`,asset,sha256,archive_format:"tar.gz",archive_root:".",executable_relative_path,version_probe:[executable_relative_path,id === "erlang" ? "-noshell" : "--version"],version_regex};
});
const python_packages=[{id:"pyyaml",version:"6.0.3",url:"https://fixtures.invalid/pyyaml.whl",authority_project:"fixtures/repository-evidence",asset:"pyyaml.whl",sha256:cp.execFileSync("shasum",["-a","256",path.join(root,"pyyaml.whl")],{encoding:"utf8"}).split(/\s/)[0],import_name:"yaml"}];
fs.writeFileSync(process.argv[2],JSON.stringify({schema_version:1,os:"Darwin",architecture:"arm64",python_packages,artifacts:records},null,2)+"\n");
' "$fixture_artifacts" "$fixture_lock"
  (
    trap - EXIT HUP INT TERM
    export CROSSWAKE_EVIDENCE_TEST_GUARD=isolated-fixture CROSSWAKE_EVIDENCE_TEST_LOCK="$fixture_lock" CROSSWAKE_EVIDENCE_TEST_SYSTEM_PATH="$fixture_bin:/usr/bin:/bin:/usr/sbin:/sbin" CROSSWAKE_EVIDENCE_FIXTURE_ARTIFACTS="$fixture_artifacts"
    export PATH="$fixture_bin:$PATH"
    provision
    [[ "$(command -v erl)" = "$PROVISIONED_TOOL_ROOT"/* && "$(command -v elixir)" = "$PROVISIONED_TOOL_ROOT"/* && "$(command -v node)" = "$PROVISIONED_TOOL_ROOT"/* && "$(command -v java)" = "$PROVISIONED_TOOL_ROOT"/* ]]
    python3 -c 'import yaml; assert yaml.__version__ == "6.0.3"'
  )
  printf '%s\n' 'PASS evidence-environment-self-test pinned-python-package'
  bad_lock="$self_root/bad-lock.json"
  "$BOOTSTRAP_NODE" -e 'const fs=require("node:fs"); const value=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); value.artifacts[2].version_regex="^v0$"; fs.writeFileSync(process.argv[2],JSON.stringify(value));' "$fixture_lock" "$bad_lock"
  status=0
  (
    trap - EXIT HUP INT TERM
    export CROSSWAKE_EVIDENCE_TEST_GUARD=isolated-fixture CROSSWAKE_EVIDENCE_TEST_LOCK="$bad_lock" CROSSWAKE_EVIDENCE_TEST_SYSTEM_PATH="$fixture_bin:/usr/bin:/bin:/usr/sbin:/sbin" CROSSWAKE_EVIDENCE_FIXTURE_ARTIFACTS="$fixture_artifacts"
    export PATH="$fixture_bin:$PATH"
    provision
  ) >/dev/null 2>&1 || status=$?
  [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test exact-version-selection'

  "$BOOTSTRAP_NODE" -e 'const fs=require("node:fs"); const value=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); value.artifacts[0].sha256="0".repeat(64); fs.writeFileSync(process.argv[2],JSON.stringify(value));' "$LOCK_PATH" "$bad_lock"
  status=0; validate_lock "$bad_lock" >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test checksum-rejection'

  "$BOOTSTRAP_NODE" -e 'const fs=require("node:fs"); const value=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); value.artifacts[0].url="https://github.com/erlef/otp_builds/releases/latest/download/OTP.tar.gz"; fs.writeFileSync(process.argv[2],JSON.stringify(value));' "$LOCK_PATH" "$bad_lock"
  status=0; validate_lock "$bad_lock" >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test source-pin-rejection'

  entries="$self_root/entries"
  printf '%s\n' '../escape' >"$entries"
  status=0; validate_archive_entries "$entries" >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test archive-entry-escape'

  outside="$self_root/not-owned"
  mkdir "$outside"
  status=0; validate_owned_root "$outside" >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test path-containment'

  candidate="$self_root/crosswake-repository-evidence-tools.fixture"
  mkdir "$candidate"
  EVIDENCE_TOOL_OWNER_PID="$(current_shell_pid)"
  EVIDENCE_TOOL_ROOT="$candidate"
  cleanup_tools() { case "$EVIDENCE_TOOL_ROOT" in "$self_root"/crosswake-repository-evidence-tools.*) rm -rf -- "$EVIDENCE_TOOL_ROOT" ;; *) return 1 ;; esac; }
  cleanup_tools
  [[ ! -e "$candidate" ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test failure-cleanup'

  source_text="$(sed -n '1,/^self_test()/p' "$ROOT_DIR/script/run_repository_evidence_environment.sh")"
  ! grep -Eq '(^|[[:space:]])(sudo|brew|asdf)([[:space:]]|$)|npm install -g|(^|[^A-Z_])HOME/' <<<"$source_text" || return 1
  printf '%s\n' 'PASS evidence-environment-self-test forbidden-global-write'

  status=0; CROSSWAKE_EVIDENCE_TEST_GUARD=isolated-fixture CROSSWAKE_EVIDENCE_TEST_SYSTEM_PATH="$self_root/empty-path" validate_apple_tools "$self_root/empty-path" >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test missing-apple-tool'

  EVIDENCE_TOOL_ROOT="$outside"
  status=0; cleanup_tools >/dev/null 2>&1 || status=$?; [[ "$status" -ne 0 && -d "$outside" ]] || return 1
  printf '%s\n' 'PASS evidence-environment-self-test cleanup-escape'
  printf '%s\n' 'PASS evidence-environment-self-test complete cases=10'
  trap - EXIT HUP INT TERM
  cleanup_self_test
}

if [[ "${1:-}" = "--self-test" && "$#" -eq 1 ]]; then
  self_test
elif [[ "${1:-}" = "--prepare-and-preflight" ]]; then
  shift
  source_repository=""; commit=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in --source-repository) source_repository="${2:-}"; shift 2 ;; --commit) commit="${2:-}"; shift 2 ;; *) fail "Use --prepare-and-preflight with --source-repository and --commit" ;; esac
  done
  [[ -n "$source_repository" && -n "$commit" ]] || fail "Use --prepare-and-preflight with --source-repository and --commit"
  prepare_preflight "$source_repository" "$commit"
else
  source_repository=""; commit=""; output_dir=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in --source-repository) source_repository="${2:-}"; shift 2 ;; --commit) commit="${2:-}"; shift 2 ;; --output-dir) output_dir="${2:-}"; shift 2 ;; *) fail "Use --source-repository, --commit, and --output-dir" ;; esac
  done
  [[ -n "$source_repository" && -n "$commit" && -n "$output_dir" ]] || fail "Use --source-repository, --commit, and --output-dir"
  run_capture "$source_repository" "$commit" "$output_dir"
fi
