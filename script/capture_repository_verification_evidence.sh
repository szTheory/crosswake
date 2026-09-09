#!/usr/bin/env bash
set -euo pipefail

# Exact-commit repository evidence transaction. Full child output stays inside
# the invocation root; only the closed projection is eligible for retention.
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
STAGE_IDS=(repository-preflight root-proof example-host-proof browser-proof ios-package-proof android-package-proof format-proof warnings-proof repository-cleanliness)

fail() {
  printf '%s\n' "[crosswake] FAIL repository-evidence-capture; corrective-command=$1" >&2
  exit 1
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

validate_evidence() {
  local evidence="$1"
  node -e '
const fs = require("node:fs");
const path = require("node:path");
const evidencePath = path.resolve(process.argv[1]);
const ids = ["repository-preflight","root-proof","example-host-proof","browser-proof","ios-package-proof","android-package-proof","format-proof","warnings-proof","repository-cleanliness"];
const sameKeys = (value, expected) => value && typeof value === "object" && !Array.isArray(value) && Object.keys(value).sort().join("\0") === [...expected].sort().join("\0");
let value;
try { value = JSON.parse(fs.readFileSync(evidencePath, "utf8")); } catch { process.exit(1); }
if (!sameKeys(value, ["cleanup","repository_state","schema_version","stages","supported_code_sha","tool_policy"])) process.exit(1);
if (value.schema_version !== 1 || !/^[0-9a-f]{40}$/.test(value.supported_code_sha)) process.exit(1);
if (!Array.isArray(value.stages) || value.stages.length !== ids.length) process.exit(1);
for (let index = 0; index < ids.length; index += 1) {
  const stage = value.stages[index];
  if (!sameKeys(stage, ["result","stage_id"]) || stage.stage_id !== ids[index] || stage.result !== "PASS") process.exit(1);
}
if (!sameKeys(value.repository_state, ["baseline_empty","final_empty","index_unchanged","snapshots_equal"]) ||
    Object.values(value.repository_state).some(item => item !== true)) process.exit(1);
if (!sameKeys(value.cleanup, ["status"]) || value.cleanup.status !== "PASS") process.exit(1);
if (!sameKeys(value.tool_policy, ["apple","elixir","erlang","java","node"]) ||
    value.tool_policy.erlang !== "27.3" || value.tool_policy.elixir !== "1.19.5-otp-27" ||
    value.tool_policy.node !== "22.14.0" || value.tool_policy.java !== "17" || value.tool_policy.apple !== "host-validated") process.exit(1);
const forbidden = new Set(["account_identifier","credential","device_identifier","environment","log","media","payload","raw_answer","secret","stable_device_identifier","token","transcript","url"]);
const visit = item => {
  if (Array.isArray(item)) return item.every(visit);
  if (!item || typeof item !== "object") return true;
  return Object.entries(item).every(([key, child]) => !forbidden.has(key) && visit(child));
};
if (!visit(value)) process.exit(1);
const markdown = [
  "# Clean-checkout repository verification",
  "",
  `- Supported code: \`${value.supported_code_sha}\``,
  "- Repository baseline: empty",
  "- Repository final state: empty",
  "- Git index: unchanged",
  "- Invocation-owned cleanup: PASS",
  "",
  "## Supported stages",
  "",
  ...value.stages.map(stage => `- ${stage.result} \`${stage.stage_id}\``),
  ""
].join("\n");
const markdownPath = evidencePath.replace(/\.json$/, ".md");
if (markdownPath === evidencePath || !fs.existsSync(markdownPath) || fs.readFileSync(markdownPath, "utf8") !== markdown) process.exit(1);
' "$evidence"
}

resolve_output_dir() {
  local source_root="$1" requested="$2" candidate parent parent_real
  if [[ "$requested" = /* ]]; then candidate="$requested"; else candidate="$PWD/$requested"; fi
  while [[ "$candidate" == *'/./'* ]]; do candidate="${candidate//\/\.\//\/}"; done
  [[ "$candidate" != *'/../'* && "$candidate" != */.. && "$candidate" != *$'\n'* ]] || return 1
  [[ ! -L "$candidate" ]] || return 1
  parent="$(dirname "$candidate")"
  while [[ ! -e "$parent" ]]; do
    [[ ! -L "$parent" ]] || return 1
    [[ "$parent" != "/" ]] || return 1
    parent="$(dirname "$parent")"
  done
  [[ -d "$parent" && ! -L "$parent" ]] || return 1
  parent_real="$(cd "$parent" && pwd -P)" || return 1
  [[ "$parent_real" = "$source_root" || "$parent_real" = "$source_root/"* ]] || return 1
  printf '%s\n' "$candidate"
}

capture() {
  local source_repository="$1" commit="$2" requested_output="$3"
  local source_root resolved output_dir output_created=0 run_root checkout status=0
  local baseline_snapshot final_snapshot index_before index_after stage

  [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || fail "git rev-parse <commit>^{commit}"
  [[ -d "$source_repository" && ! -L "$source_repository" ]] || fail "git -C <source-repository> rev-parse --show-toplevel"
  source_root="$(git -C "$source_repository" rev-parse --show-toplevel 2>/dev/null)" || fail "git -C <source-repository> rev-parse --show-toplevel"
  source_root="$(cd "$source_root" && pwd -P)"
  resolved="$(git -C "$source_root" rev-parse --verify "$commit^{commit}" 2>/dev/null)" || fail "git -C <source-repository> rev-parse <commit>^{commit}"
  [[ "$resolved" = "$commit" ]] || fail "git -C <source-repository> rev-parse <commit>^{commit}"
  [[ -n "$(git -C "$source_root" for-each-ref --contains "$resolved" --format='%(refname)' refs/heads refs/tags refs/remotes)" ]] || fail "git -C <source-repository> branch --contains <commit>"
  output_dir="$(resolve_output_dir "$source_root" "$requested_output")" || fail "Use a non-symlink output directory inside the source repository"
  if [[ ! -e "$output_dir" ]]; then mkdir -p "$output_dir"; output_created=1; fi
  [[ -d "$output_dir" && ! -L "$output_dir" ]] || fail "Use a non-symlink output directory inside the source repository"
  [[ ! -e "$output_dir/clean-checkout-run.json" && ! -e "$output_dir/clean-checkout-run.md" ]] || fail "Remove the existing clean-checkout evidence files"

  run_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-repository-capture.XXXXXX")"
  chmod 700 "$run_root"
  checkout="$run_root/checkout"
  CAPTURE_OWNER_PID="$BASHPID"
  CAPTURE_RUN_ROOT="$run_root"
  CAPTURE_OUTPUT_DIR="$output_dir"
  CAPTURE_OUTPUT_CREATED="$output_created"
  CAPTURE_SUCCEEDED=0
  cleanup_capture() {
    [[ "$BASHPID" = "$CAPTURE_OWNER_PID" ]] || return 0
    case "$CAPTURE_RUN_ROOT" in
      "${TMPDIR:-/tmp}"/crosswake-repository-capture.*) rm -rf -- "$CAPTURE_RUN_ROOT" ;;
      *) return 1 ;;
    esac
    if [[ "$CAPTURE_SUCCEEDED" -ne 1 ]]; then
      rm -f -- "$CAPTURE_OUTPUT_DIR/clean-checkout-run.json" "$CAPTURE_OUTPUT_DIR/clean-checkout-run.md" \
        "$CAPTURE_OUTPUT_DIR/clean-checkout-run.json.tmp" "$CAPTURE_OUTPUT_DIR/clean-checkout-run.md.tmp"
      if [[ "$CAPTURE_OUTPUT_CREATED" -eq 1 ]]; then rmdir "$CAPTURE_OUTPUT_DIR" 2>/dev/null || true; fi
    fi
  }
  trap cleanup_capture EXIT HUP INT TERM

  git clone --quiet --no-local "$source_root" "$checkout" >"$run_root/clone.log" 2>&1 || status=$?
  [[ "$status" -eq 0 ]] || return "$status"
  git -C "$checkout" checkout --quiet --detach "$resolved" >"$run_root/checkout.log" 2>&1 || status=$?
  [[ "$status" -eq 0 ]] || return "$status"
  [[ "$(git -C "$checkout" rev-parse HEAD)" = "$resolved" ]] || return 1

  baseline_snapshot="$run_root/git-before.z"
  final_snapshot="$run_root/git-final.z"
  git -C "$checkout" status --porcelain=v1 -z --untracked-files=all >"$baseline_snapshot"
  [[ ! -s "$baseline_snapshot" ]] || return 1
  index_before="$(sha256_file "$checkout/.git/index")"

  (cd "$checkout" && script/verify_repository.sh --all) >"$run_root/verify.stdout" 2>"$run_root/verify.stderr" || status=$?
  git -C "$checkout" status --porcelain=v1 -z --untracked-files=all >"$final_snapshot" || status=1
  index_after="$(sha256_file "$checkout/.git/index")" || status=1
  [[ "$status" -eq 0 && ! -s "$final_snapshot" && "$index_before" = "$index_after" ]] || return 1
  cmp -s "$baseline_snapshot" "$final_snapshot" || return 1
  [[ "$(wc -l <"$run_root/verify.stdout" | tr -d ' ')" = "${#STAGE_IDS[@]}" ]] || return 1
  for stage in "${STAGE_IDS[@]}"; do grep -Fxq "PASS $stage" "$run_root/verify.stdout" || return 1; done
  ! grep -Eq '^(FAIL|BLOCKED) ' "$run_root/verify.stdout" || return 1

  node -e '
const fs = require("node:fs");
const sha = process.argv[1];
const jsonPath = process.argv[2];
const mdPath = process.argv[3];
const ids = process.argv.slice(4);
const value = {
  schema_version: 1,
  supported_code_sha: sha,
  stages: ids.map(stage_id => ({stage_id, result: "PASS"})),
  repository_state: {baseline_empty: true, final_empty: true, snapshots_equal: true, index_unchanged: true},
  cleanup: {status: "PASS"},
  tool_policy: {erlang: "27.3", elixir: "1.19.5-otp-27", node: "22.14.0", java: "17", apple: "host-validated"}
};
const markdown = [
  "# Clean-checkout repository verification", "", `- Supported code: \`${sha}\``,
  "- Repository baseline: empty", "- Repository final state: empty", "- Git index: unchanged",
  "- Invocation-owned cleanup: PASS", "", "## Supported stages", "",
  ...value.stages.map(stage => `- ${stage.result} \`${stage.stage_id}\``), ""
].join("\n");
fs.writeFileSync(jsonPath + ".tmp", JSON.stringify(value, null, 2) + "\n", {mode: 0o600, flag: "wx"});
fs.writeFileSync(mdPath + ".tmp", markdown, {mode: 0o600, flag: "wx"});
fs.renameSync(jsonPath + ".tmp", jsonPath);
fs.renameSync(mdPath + ".tmp", mdPath);
' "$resolved" "$output_dir/clean-checkout-run.json" "$output_dir/clean-checkout-run.md" "${STAGE_IDS[@]}" || return 1
  validate_evidence "$output_dir/clean-checkout-run.json" || return 1
  CAPTURE_SUCCEEDED=1
  trap - EXIT HUP INT TERM
  cleanup_capture
  printf '%s\n' "[crosswake] PASS repository-evidence-capture commit=$resolved"
}

self_test() {
  local self_root fixture outside commit unreachable case_sha case_dir status
  self_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-repository-capture-self-test.XXXXXX")"
  chmod 700 "$self_root"
  SELF_TEST_OWNER_PID="$BASHPID"
  SELF_TEST_ROOT="$self_root"
  cleanup_self_test() {
    [[ "$BASHPID" = "$SELF_TEST_OWNER_PID" ]] || return 0
    case "$SELF_TEST_ROOT" in "${TMPDIR:-/tmp}"/crosswake-repository-capture-self-test.*) rm -rf -- "$SELF_TEST_ROOT" ;; *) return 1 ;; esac
  }
  trap cleanup_self_test EXIT HUP INT TERM
  fixture="$self_root/source"
  outside="$self_root/outside"
  mkdir -p "$fixture/script" "$outside"
  git -C "$fixture" init --quiet
  git -C "$fixture" config user.email capture@example.invalid
  git -C "$fixture" config user.name "Repository Capture Test"
  printf '%s\n' tracked >"$fixture/tracked.txt"
  printf '%s\n' success >"$fixture/.capture-case"
  apply_patch_fixture="$fixture/script/verify_repository.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'case "$(cat .capture-case)" in' '  failing-child) exit 7 ;;' '  altered-index) printf changed >> tracked.txt; git add tracked.txt ;;' '  residue) printf residue > leaked-output ;;' 'esac' 'for id in repository-preflight root-proof example-host-proof browser-proof ios-package-proof android-package-proof format-proof warnings-proof repository-cleanliness; do printf "PASS %s\\n" "$id"; done' >"$apply_patch_fixture"
  chmod +x "$apply_patch_fixture"
  git -C "$fixture" add .capture-case script/verify_repository.sh tracked.txt
  git -C "$fixture" commit --quiet -m fixture
  commit="$(git -C "$fixture" rev-parse HEAD)"

  status=0; TMPDIR="$self_root" "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --source-repository "$fixture" --commit 0000000000000000000000000000000000000000 --output-dir "$fixture/wrong" >/dev/null 2>&1 || status=$?
  [[ "$status" -ne 0 && ! -e "$fixture/wrong/clean-checkout-run.json" ]] || return 1
  printf '%s\n' "PASS capture-self-test wrong-sha"

  unreachable="$(printf unreachable | git -C "$fixture" commit-tree "$(git -C "$fixture" write-tree)" -p "$commit")"
  status=0; TMPDIR="$self_root" "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --source-repository "$fixture" --commit "$unreachable" --output-dir "$fixture/untracked" >/dev/null 2>&1 || status=$?
  [[ "$status" -ne 0 && ! -e "$fixture/untracked/clean-checkout-run.json" ]] || return 1
  printf '%s\n' "PASS capture-self-test untracked-object"

  for case_sha in failing-child altered-index residue; do
    printf '%s\n' "$case_sha" >"$fixture/.capture-case"
    git -C "$fixture" add .capture-case
    git -C "$fixture" commit --quiet -m "$case_sha"
    commit="$(git -C "$fixture" rev-parse HEAD)"
    case_dir="$fixture/$case_sha"
    status=0; TMPDIR="$self_root" "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --source-repository "$fixture" --commit "$commit" --output-dir "$case_dir" >/dev/null 2>&1 || status=$?
    [[ "$status" -ne 0 && ! -e "$case_dir/clean-checkout-run.json" ]] || return 1
    [[ -z "$(find "$self_root" -maxdepth 1 -name 'crosswake-repository-capture.*' -print -quit)" ]] || return 1
    printf '%s\n' "PASS capture-self-test $case_sha"
  done

  mkdir -p "$fixture/forbidden"
  printf '%s\n' '{"schema_version":1,"token":"forbidden"}' >"$fixture/forbidden/clean-checkout-run.json"
  printf '%s\n' forbidden >"$fixture/forbidden/clean-checkout-run.md"
  status=0; "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --verify "$fixture/forbidden/clean-checkout-run.json" >/dev/null 2>&1 || status=$?
  [[ "$status" -ne 0 ]] || return 1
  printf '%s\n' "PASS capture-self-test forbidden-evidence-key"

  ln -s "$outside" "$fixture/symlink-output"
  status=0; TMPDIR="$self_root" "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --source-repository "$fixture" --commit "$commit" --output-dir "$fixture/symlink-output" >/dev/null 2>&1 || status=$?
  [[ "$status" -ne 0 && -z "$(find "$outside" -mindepth 1 -print -quit)" ]] || return 1
  printf '%s\n' "PASS capture-self-test symlink-escape"

  printf '%s\n' success >"$fixture/.capture-case"
  git -C "$fixture" add .capture-case
  git -C "$fixture" commit --quiet -m success
  commit="$(git -C "$fixture" rev-parse HEAD)"
  printf '%s\n' dirty-source-sentinel >"$fixture/dirty-untracked"
  printf '%s\n' dirty-source-sentinel >>"$fixture/tracked.txt"
  TMPDIR="$self_root" "$SCRIPT_ROOT/script/capture_repository_verification_evidence.sh" --source-repository "$fixture" --commit "$commit" --output-dir "$fixture/success" >/dev/null
  validate_evidence "$fixture/success/clean-checkout-run.json"
  ! grep -R -Fq dirty-source-sentinel "$fixture/success" || return 1
  [[ -z "$(find "$self_root" -maxdepth 1 -name 'crosswake-repository-capture.*' -print -quit)" ]] || return 1
  printf '%s\n' "PASS capture-self-test dirty-source-success"
  printf '%s\n' "PASS capture-self-test complete cases=8"
  trap - EXIT HUP INT TERM
  cleanup_self_test
}

if [[ "${1:-}" = "--self-test" && "$#" -eq 1 ]]; then
  self_test
elif [[ "${1:-}" = "--verify" && "$#" -eq 2 ]]; then
  validate_evidence "$2" || fail "script/capture_repository_verification_evidence.sh --verify <evidence.json>"
  printf '%s\n' "[crosswake] PASS repository-evidence-verify"
else
  source_repository=""
  commit=""
  output_dir=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --source-repository) [[ "$#" -ge 2 ]] || fail "Provide --source-repository"; source_repository="$2"; shift 2 ;;
      --commit) [[ "$#" -ge 2 ]] || fail "Provide --commit"; commit="$2"; shift 2 ;;
      --output-dir) [[ "$#" -ge 2 ]] || fail "Provide --output-dir"; output_dir="$2"; shift 2 ;;
      *) fail "Use --source-repository, --commit, and --output-dir" ;;
    esac
  done
  [[ -n "$source_repository" && -n "$commit" && -n "$output_dir" ]] || fail "Use --source-repository, --commit, and --output-dir"
  capture "$source_repository" "$commit" "$output_dir"
fi
