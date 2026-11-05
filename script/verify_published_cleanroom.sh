#!/usr/bin/env bash
# verify_published_cleanroom.sh <X.Y.Z>
#
# Fail-closed clean-room proof (REL-06) that a published Crosswake version is
# consumable from nothing but the public registries. Four legs, all required:
#
#   hex    resolve crosswake == <version> from hex.pm into a fresh mix project,
#          require the mix.lock outer checksum to equal the registry checksum,
#          compile, and require Application.spec(:crosswake, :vsn) == <version>
#   maven  download the .pom, .module and .aar of
#          io.github.sztheory:crosswake-shell-core-android:<version> from Maven
#          Central, check each against its published .sha256, and require the
#          pom project groupId, artifactId, version and packaging to be
#          io.github.sztheory, crosswake-shell-core-android, <version> and aar
#   ios    find refs/tags/v<version> on the SwiftPM mirror, clone it shallowly,
#          and `swift build` it
#   docs   fetch README.md and guides/install.md at the commit CLEANROOM_DOCS_REF (40
#          lowercase hex, no clone), parse every fence in README "Integrating Crosswake"
#          and in guides/install.md (each must follow a `<!-- cleanroom:<kind> ... -->`
#          marker: run, apply, clone or show), generate a throwaway Phoenix host from a
#          pinned phx_new with assets enabled, and execute the `run` blocks verbatim
#          with `bash -e`. Steps see only an allowlisted environment (PATH, LANG, the
#          asdf variables, and HOME, MIX_HOME, HEX_HOME inside the work dir), never the
#          caller's credentials. `clone` and `show` blocks are counted, never run.
#
# Exit codes: 0 every leg passed; 1 any leg failed; 2 usage error or a refused
# override. A missing tool is a FAIL for that leg (tool_unavailable), never a
# skip. No credential is used and every registry is read unauthenticated.
# No repository clone is needed: the work happens in a throwaway directory this
# script creates and removes, and nothing is read from beside the script.
#
# Toolchain selectors (not verdict overrides): when the caller sets both
# CLEANROOM_ELIXIR_VERSION and CLEANROOM_ERLANG_VERSION, the hex leg writes
# them into a version file inside its own throwaway project so asdf shims
# resolve; otherwise it uses whatever `mix` PATH finds.
#
# CLEANROOM_DOCS_REF=<40-hex commit> is also a selector, not an override: it names which
# public commit the docs leg reads, is accepted without CLEANROOM_SELFTEST, and a value
# that is not 40 lowercase hex exits 2. CLEANROOM_DOCS_STEP_TIMEOUT=<seconds> is the same
# class (a positive integer, default 900, otherwise exit 2): every documented step and every
# host-generation command runs under that bound, because a bound can only turn a run red.
#
# Selftest overrides (honored only with CLEANROOM_SELFTEST=1; without it any
# override exits 2): CLEANROOM_LEGS, CLEANROOM_MAVEN_BASE, CLEANROOM_HEX_API,
# CLEANROOM_DOCS_BASE (docs source root, layout <base>/<ref>/README.md),
# CLEANROOM_KEEP_WORK=1 (keep the work dir and print `cleanroom: work kept <path>`).
# With the flag set the run announces itself and ends `result SELFTEST`,
# never `result PASS`.
#
# Output contract (parsed by later phases):
#   cleanroom: leg <leg> PASS <version> <detail>
#   cleanroom: FAIL <leg> <reason>
#     reasons: any leg tool_unavailable
#              hex     not_published (404 or no such release), resolve_failed (network or
#                      resolve error), parse_failed (200 response with no checksum),
#                      checksum_mismatch, compile_failed, vsn_mismatch
#              maven   not_published, fetch_failed, checksum_mismatch, pom_mismatch
#              ios     not_published (successful lookup, no tag), resolve_failed (git
#                      ls-remote failed), clone_failed, build_failed
#              docs    fetch <file>, parse <reason> (no_docs_source, unmarked_fence <file>,
#                      unterminated_fence <file>, no_fences <file>, readme_scope_missing,
#                      missing_id, bad_id, duplicate_id, unknown_attr, apply_unsupported),
#                      step <id> exit <code>, step <id> timeout <secs>, step <id> interrupted
#                      (the step's whole process group is killed; a host-generation command is
#                      step host_setup)
#   cleanroom: docs source commit <ref>
#     Network calls carry --max-time, --retry and an https-only protocol pin.
#   cleanroom: result PASS|FAIL|SELFTEST legs <list> version <version>

set -uo pipefail

DEFAULT_LEGS="hex,maven,ios,docs"
MAVEN_DEFAULT_BASE="https://repo1.maven.org/maven2"
HEX_DEFAULT_API="https://hex.pm/api"
DOCS_DEFAULT_BASE="https://raw.githubusercontent.com/szTheory/crosswake"
PHX_NEW_VERSION="1.8.13"
DOCS_STEP_TIMEOUT_DEFAULT=900
CURL_MAX_TIME=120
CURL_RETRY=2
MIRROR_URL="https://github.com/szTheory/crosswake-shell-core-ios.git"

usage() {
  echo "cleanroom: usage verify_published_cleanroom.sh <X.Y.Z>"
  exit 2
}

[ "$#" -eq 1 ] || usage
VERSION="$1"
case "$VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) usage ;;
esac
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  usage
fi

SELFTEST="${CLEANROOM_SELFTEST:-}"
LEGS="${CLEANROOM_LEGS:-$DEFAULT_LEGS}"
MAVEN_BASE="${CLEANROOM_MAVEN_BASE:-$MAVEN_DEFAULT_BASE}"
HEX_API="${CLEANROOM_HEX_API:-$HEX_DEFAULT_API}"
DOCS_BASE="${CLEANROOM_DOCS_BASE:-$DOCS_DEFAULT_BASE}"
DOCS_REF="${CLEANROOM_DOCS_REF:-}"
if [ -n "$DOCS_REF" ] && ! [[ "$DOCS_REF" =~ ^[0-9a-f]{40}$ ]]; then
  usage
fi
DOCS_STEP_TIMEOUT="${CLEANROOM_DOCS_STEP_TIMEOUT:-$DOCS_STEP_TIMEOUT_DEFAULT}"
if ! [[ "$DOCS_STEP_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  usage
fi

if [ "$SELFTEST" != "1" ]; then
  if [ "$LEGS" != "$DEFAULT_LEGS" ] || [ -n "${CLEANROOM_MAVEN_BASE:-}" ] || [ -n "${CLEANROOM_HEX_API:-}" ] || [ -n "${CLEANROOM_DOCS_BASE:-}" ] || [ -n "${CLEANROOM_KEEP_WORK:-}" ]; then
    echo "cleanroom: override refused (set CLEANROOM_SELFTEST=1 to use selftest overrides)"
    exit 2
  fi
else
  echo "cleanroom: selftest overrides active"
fi

FAILED=0
LEGS_RUN=""

# Never prompt for credentials; every registry is read anonymously.
export GIT_TERMINAL_PROMPT=0

WORK=""
cleanup() {
  [ -n "$WORK" ] || return 0
  if [ "$SELFTEST" = "1" ] && [ "${CLEANROOM_KEEP_WORK:-}" = "1" ]; then
    echo "cleanroom: work kept $WORK"
    return 0
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() { # leg reason
  echo "cleanroom: FAIL $1 $2"
  FAILED=1
}

need_tools() { # leg tool...
  local leg="$1" t
  shift
  for t in "$@"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      fail "$leg" tool_unavailable
      return 1
    fi
  done
  return 0
}

sha256_of() { # file -> hex digest
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

# fetch <url> <dest>: 0 ok, 3 not published (404 / missing file), 4 other failure.
# A file:// URL (selftest fixtures only) is answered locally first: a missing path is 3;
# a path that exists but cannot be copied (a directory, or unreadable) is 4, never 3.
# Every network URL is bounded (--max-time, --retry) and pinned to https, including after
# redirects. Retry is not widened to every error class, so a 404 stays one fast answer.
fetch() {
  local url="$1" dest="$2" code rc path
  case "$url" in
    file://*)
      path="${url#file://}"
      [ -e "$path" ] || return 3
      { [ -f "$path" ] && [ -r "$path" ]; } || return 4
      curl -sS -L -o "$dest" "$url" >/dev/null 2>&1 || return 4
      [ -f "$dest" ] && return 0
      return 4
      ;;
  esac
  code=$(curl -sS -L --max-time "$CURL_MAX_TIME" --retry "$CURL_RETRY" --proto '=https' --proto-redir '=https' -o "$dest" -w '%{http_code}' "$url" 2>/dev/null)
  rc=$?
  [ "$rc" -eq 0 ] || return 4
  case "$code" in
    200) return 0 ;;
    404) return 3 ;;
    *) return 4 ;;
  esac
}

# pom_field <pom> <element>: the value of the first project-level <element>. Blocks that
# carry their own coordinates (dependencies, dependencyManagement, parent, build, profiles,
# distributionManagement, reporting) and comments are removed first, so a dependency's
# <version> or a parent's <groupId> can never stand in for the project's. The close tag of
# each block becomes a one-byte sentinel so the delete stops at the first close (sed ERE
# has no non-greedy match).
pom_field() {
  local pom="$1" element="$2" S tag
  S=$'\001'
  local flat
  flat=$(tr '\n\r' '  ' <"$pom")
  flat=$(printf '%s' "$flat" | sed -E 's#<!--[^>]*-->##g')
  for tag in dependencyManagement profiles build parent dependencies distributionManagement reporting; do
    flat=$(printf '%s' "$flat" | sed -E -e "s#</$tag>#$S#g" -e "s#<$tag>[^$S]*$S##g")
  done
  printf '%s' "$flat" | grep -Eo "<$element>[^<]*</$element>" | head -n1 |
    sed -E -e "s#^<$element>##" -e "s#</$element>\$##" -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//'
}

mk_work() {
  if [ -z "$WORK" ]; then
    WORK=$(mktemp -d "${TMPDIR:-${RUNNER_TEMP:-/tmp}}/crosswake-cleanroom.XXXXXX") || return 1
  fi
}

leg_maven() {
  need_tools maven curl cut grep mktemp head tr sed mkdir || return
  if [ -z "$(command -v shasum 2>/dev/null)$(command -v sha256sum 2>/dev/null)" ]; then
    fail maven tool_unavailable
    return
  fi
  mk_work || { fail maven tool_unavailable; return; }
  local dir="$WORK/maven"
  mkdir -p "$dir"
  local art="crosswake-shell-core-android"
  local url_base="$MAVEN_BASE/io/github/sztheory/$art/$VERSION"
  local ext name rc published actual aar_sha=""
  for ext in pom module aar; do
    name="$art-$VERSION.$ext"
    fetch "$url_base/$name" "$dir/$name"; rc=$?
    if [ "$rc" -eq 3 ]; then fail maven not_published; return; fi
    if [ "$rc" -ne 0 ]; then fail maven fetch_failed; return; fi
    fetch "$url_base/$name.sha256" "$dir/$name.sha256"; rc=$?
    if [ "$rc" -eq 3 ]; then fail maven not_published; return; fi
    if [ "$rc" -ne 0 ]; then fail maven fetch_failed; return; fi
    published=$(tr -d '\r' <"$dir/$name.sha256" | head -n1 | cut -d' ' -f1 | tr 'A-F' 'a-f')
    actual=$(sha256_of "$dir/$name")
    if [ -z "$published" ] || [ "$published" != "$actual" ]; then
      fail maven checksum_mismatch
      return
    fi
    [ "$ext" = "aar" ] && aar_sha="$actual"
  done
  local pom="$dir/$art-$VERSION.pom"
  if [ "$(pom_field "$pom" groupId)" != "io.github.sztheory" ] ||
    [ "$(pom_field "$pom" artifactId)" != "$art" ] ||
    [ "$(pom_field "$pom" version)" != "$VERSION" ] ||
    [ "$(pom_field "$pom" packaging)" != "aar" ]; then
    fail maven pom_mismatch
    return
  fi
  echo "cleanroom: leg maven PASS $VERSION aar $(printf '%s' "$aar_sha" | cut -c1-12)"
}

leg_hex() {
  need_tools hex curl grep cut tr head tail mktemp mkdir || return
  local jsontool=""
  if command -v jq >/dev/null 2>&1; then
    jsontool="jq"
  elif command -v python3 >/dev/null 2>&1; then
    jsontool="python3"
  else
    fail hex tool_unavailable
    return
  fi
  mk_work || { fail hex tool_unavailable; return; }
  local meta="$WORK/hex-release.json" rc registry
  fetch "$HEX_API/packages/crosswake/releases/$VERSION" "$meta"; rc=$?
  if [ "$rc" -eq 3 ]; then fail hex not_published; return; fi
  if [ "$rc" -ne 0 ]; then fail hex resolve_failed; return; fi
  if [ "$jsontool" = "jq" ]; then
    registry=$(jq -r '.checksum // empty' "$meta" 2>/dev/null)
  else
    registry=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("checksum") or "")' "$meta" 2>/dev/null)
  fi
  registry=$(printf '%s' "$registry" | tr 'A-F' 'a-f')
  if [ -z "$registry" ]; then fail hex parse_failed; return; fi

  if ! command -v mix >/dev/null 2>&1; then fail hex tool_unavailable; return; fi
  local host="$WORK/cleanroom_host"
  mkdir -p "$host"
  if [ -n "${CLEANROOM_ELIXIR_VERSION:-}" ] && [ -n "${CLEANROOM_ERLANG_VERSION:-}" ]; then
    printf 'erlang %s\nelixir %s\n' "$CLEANROOM_ERLANG_VERSION" "$CLEANROOM_ELIXIR_VERSION" >"$host/.tool-versions"
    echo "cleanroom: toolchain elixir $CLEANROOM_ELIXIR_VERSION erlang $CLEANROOM_ERLANG_VERSION"
  else
    echo "cleanroom: toolchain path"
  fi
  local log="$WORK/hex.log"
  if ! (cd "$host" && mix new . --app cleanroom_host) >"$log" 2>&1; then
    fail hex tool_unavailable
    return
  fi
  printf 'defmodule CleanroomHost.MixProject do\n  use Mix.Project\n\n  def project do\n    [app: :cleanroom_host, version: "0.0.0", elixir: "~> 1.15", deps: deps()]\n  end\n\n  def application, do: [extra_applications: [:logger]]\n\n  defp deps, do: [{:crosswake, "== %s"}]\nend\n' "$VERSION" >"$host/mix.exs"
  if ! (cd "$host" && mix deps.get) >>"$log" 2>&1; then
    fail hex resolve_failed
    return
  fi
  local lock locked
  lock=$(grep -E '^[[:space:]]*"crosswake":' "$host/mix.lock" 2>/dev/null | head -n1)
  locked=$(printf '%s' "$lock" | grep -Eo '"[0-9a-fA-F]{64}"' | tail -n1 | tr -d '"' | tr 'A-F' 'a-f')
  if [ -z "$locked" ] || [ "$locked" != "$registry" ]; then
    fail hex checksum_mismatch
    return
  fi
  if ! (cd "$host" && mix compile) >>"$log" 2>&1; then
    fail hex compile_failed
    return
  fi
  local vsn
  vsn=$(cd "$host" && mix run -e 'v = Application.spec(:crosswake, :vsn) |> to_string(); IO.puts("vsn=" <> v)' 2>>"$log" | grep -E '^vsn=' | tail -n1)
  if [ "$vsn" != "vsn=$VERSION" ]; then
    fail hex vsn_mismatch
    return
  fi
  echo "cleanroom: leg hex PASS $VERSION checksum $(printf '%s' "$locked" | cut -c1-12)"
}

leg_ios() {
  need_tools ios git swift mktemp cut || return
  mk_work || { fail ios tool_unavailable; return; }
  local refs lsrc
  refs=$(git ls-remote "$MIRROR_URL" "refs/tags/v$VERSION" 2>/dev/null)
  lsrc=$?
  if [ "$lsrc" -ne 0 ]; then fail ios resolve_failed; return; fi
  if [ -z "$refs" ]; then fail ios not_published; return; fi
  local clone="$WORK/ios-mirror" log="$WORK/ios.log"
  if ! git clone --quiet --depth 1 --branch "v$VERSION" "$MIRROR_URL" "$clone" >"$log" 2>&1; then
    fail ios clone_failed
    return
  fi
  if ! swift build --package-path "$clone" >>"$log" 2>&1; then
    fail ios build_failed
    return
  fi
  echo "cleanroom: leg ios PASS $VERSION tag_commit $(git -C "$clone" rev-parse HEAD | cut -c1-12)"
}

# ---- docs leg -------------------------------------------------------------------------
#
# docs_fetch_sources: README.md and guides/install.md at CLEANROOM_DOCS_REF, through fetch
# only (never from beside this script). No ref: the leg fails; the Hex tarball default
# arrives in a later plan.
docs_fetch_sources() {
  local rc
  if [ -z "$DOCS_REF" ]; then
    fail docs "parse no_docs_source"
    return 1
  fi
  mkdir -p "$WORK/docs/body" "$WORK/docs/steps" || { fail docs tool_unavailable; return 1; }
  fetch "$DOCS_BASE/$DOCS_REF/README.md" "$WORK/docs/README.md"; rc=$?
  if [ "$rc" -ne 0 ]; then fail docs "fetch README.md"; return 1; fi
  fetch "$DOCS_BASE/$DOCS_REF/guides/install.md" "$WORK/docs/install.md"; rc=$?
  if [ "$rc" -ne 0 ]; then fail docs "fetch guides/install.md"; return 1; fi
  echo "cleanroom: docs source commit $DOCS_REF"
}

# docs_parse_file <tag> <path> <display>: one record per fence in scope appended to
# $WORK/docs/steps.tsv as tag, ordinal, kind, id, attrs, body file (tab separated, no empty
# field). Scope: for the README the lines after `### Integrating Crosswake` up to the next
# `# `, `## ` or `### ` heading; for guides/install.md the whole file. A trimmed line that
# starts with three backticks toggles a fence, the same rule as strip_fences/1 in
# check_release_doc_version_literals.exs, so headings inside a fence never count. The
# nearest preceding non-blank line outside a fence must be a cleanroom marker. A problem is
# written to parse_error as a reason and exits 1.
docs_parse_file() {
  local tag="$1" path="$2" display="$3" reason
  awk -v tag="$tag" -v display="$display" -v tsv="$WORK/docs/steps.tsv" \
    -v idsfile="$WORK/docs/ids" -v bodydir="$WORK/docs/body" -v errfile="$WORK/docs/parse_error" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
    function die(reason) { print reason > errfile; close(errfile); failed = 1; exit 1 }
    function open_fence(    m, n, parts, i, p, eq, key, val, nattr) {
      ord++
      nfence++
      if (prev !~ /^<!-- cleanroom:(run|apply|clone|show)( [a-z_]+=[^ ]+)* -->$/) {
        die("unmarked_fence " display)
      }
      m = prev
      sub(/^<!-- cleanroom:/, "", m)
      sub(/ -->$/, "", m)
      n = split(m, parts, " ")
      kind = parts[1]
      id = ""; attrs = ""
      delete seen_key
      for (i = 2; i <= n; i++) {
        p = parts[i]
        eq = index(p, "=")
        key = substr(p, 1, eq - 1)
        val = substr(p, eq + 1)
        if ((key != "id" && key != "file" && key != "mode" && key != "since") || (key in seen_key)) {
          die("unknown_attr")
        }
        seen_key[key] = 1
        if (key == "id") id = val
        else attrs = attrs (attrs == "" ? "" : ";") key "=" val
      }
      if (kind != "show" && id == "") die("missing_id")
      if (id != "") {
        if (id !~ /^[A-Za-z0-9_-]+$/) die("bad_id")
        if (id in ids) die("duplicate_id")
        ids[id] = 1
        print id >> idsfile
        close(idsfile)
      }
      body = bodydir "/" tag "-" ord
      printf "" > body
      close(body)
    }
    BEGIN {
      while ((getline l < idsfile) > 0) ids[l] = 1
      close(idsfile)
      in_fence = 0; prev = ""; ord = 0; nfence = 0
      in_scope = (tag == "install"); found_scope = in_scope
    }
    {
      line = $0
      sub(/\r$/, "", line)
      t = line
      sub(/^[ \t]+/, "", t)
      isfence = (substr(t, 1, 3) == "```")
      if (in_fence) {
        if (isfence) {
          in_fence = 0
          if (capture) {
            if (id == "") rid = "-"; else rid = id
            if (attrs == "") rattrs = "-"; else rattrs = attrs
            printf "%s\t%d\t%s\t%s\t%s\t%s\n", tag, ord, kind, rid, rattrs, body >> tsv
            close(tsv)
          }
          prev = "```"
        } else if (capture) {
          print line >> body
        }
        next
      }
      if (isfence) {
        in_fence = 1
        capture = in_scope
        if (capture) open_fence()
        next
      }
      if (tag == "readme") {
        if (line ~ /^### Integrating Crosswake[ \t]*$/) { in_scope = 1; found_scope = 1 }
        else if (in_scope && line ~ /^(# |## |### )/) in_scope = 0
      }
      if (trim(line) != "") prev = trim(line)
    }
    END {
      if (failed) exit 1
      if (in_fence) die("unterminated_fence " display)
      if (!found_scope) die("readme_scope_missing")
      if (nfence == 0) die("no_fences " display)
    }
  ' "$path"
  if [ "$?" -ne 0 ]; then
    reason=$(head -n1 "$WORK/docs/parse_error" 2>/dev/null)
    [ -n "$reason" ] || reason="awk_failed"
    fail docs "parse $reason"
    return 1
  fi
}

docs_parse() {
  : >"$WORK/docs/steps.tsv"
  : >"$WORK/docs/ids"
  : >"$WORK/docs/parse_error"
  docs_parse_file readme "$WORK/docs/README.md" "README.md" || return 1
  docs_parse_file install "$WORK/docs/install.md" "guides/install.md" || return 1
  # apply blocks parse today; running them lands in a later plan, so one fails the leg.
  if awk -F '\t' '$3 == "apply" { found = 1 } END { exit found ? 0 : 1 }' "$WORK/docs/steps.tsv"; then
    fail docs "parse apply_unsupported"
    return 1
  fi
}

# docs_env <cmd...>: run one command with an allowlisted environment only. The caller's
# credentials and every other variable never cross: PATH, LANG, the asdf variables (so
# shims resolve) and HOME, MIX_HOME, HEX_HOME inside the work dir.
docs_env() {
  local -a vars
  vars=(PATH="$PATH" LANG="${LANG:-C.UTF-8}" HOME="$WORK/home" MIX_HOME="$WORK/mix_home" HEX_HOME="$WORK/hex_home" MIX_ENV=dev)
  [ -n "${ASDF_DIR:-}" ] && vars+=(ASDF_DIR="$ASDF_DIR")
  if [ -n "${ASDF_DATA_DIR:-}" ]; then
    vars+=(ASDF_DATA_DIR="$ASDF_DATA_DIR")
  elif [ -d "$HOME/.asdf" ]; then
    vars+=(ASDF_DATA_DIR="$HOME/.asdf")
  fi
  env -i "${vars[@]}" "$@"
}

DOCS_STEP_ID=""
DOCS_STEP_PID=""
DOCS_WATCHDOG_PID=""
DOCS_BOUND_TIMEOUT=0

# INT or TERM while a bounded command runs: kill its process group, name the step, end the
# run as a failure. Never exits 0.
docs_interrupt() {
  trap '' INT TERM
  if [ -n "$DOCS_WATCHDOG_PID" ]; then
    kill -s KILL -- "-$DOCS_WATCHDOG_PID" 2>/dev/null
    wait "$DOCS_WATCHDOG_PID" 2>/dev/null
  fi
  if [ -n "$DOCS_STEP_PID" ]; then
    kill -s TERM -- "-$DOCS_STEP_PID" 2>/dev/null
    sleep 1
    kill -s KILL -- "-$DOCS_STEP_PID" 2>/dev/null
    wait "$DOCS_STEP_PID" 2>/dev/null
  fi
  fail docs "step $DOCS_STEP_ID interrupted"
  echo "cleanroom: result FAIL legs $LEGS version $VERSION"
  exit 1
}

# docs_bounded <id> <cmd...>: run one command in its own process group (job control gives
# the background job a group id equal to its pid) under the DOCS_STEP_TIMEOUT bound. A
# watchdog in its own group sends TERM then, five seconds later, KILL to the command's whole
# group. On timeout it prints `FAIL docs step <id> timeout <secs>`, sets DOCS_BOUND_TIMEOUT=1
# and returns 1 (a command that exits 124 by itself is told apart by that variable). On INT
# or TERM, docs_interrupt runs. Otherwise it returns the command's own exit status.
docs_bounded() {
  local id="$1" rc flag="$WORK/docs/timeout-$1.flag"
  shift
  DOCS_STEP_ID="$id"
  DOCS_BOUND_TIMEOUT=0
  trap docs_interrupt INT TERM
  set -m
  "$@" &
  DOCS_STEP_PID=$!
  (
    sleep "$DOCS_STEP_TIMEOUT"
    : >"$flag"
    kill -s TERM -- "-$DOCS_STEP_PID" 2>/dev/null
    sleep 5
    kill -s KILL -- "-$DOCS_STEP_PID" 2>/dev/null
  ) &
  DOCS_WATCHDOG_PID=$!
  set +m
  wait "$DOCS_STEP_PID" 2>/dev/null
  rc=$?
  kill -s KILL -- "-$DOCS_WATCHDOG_PID" 2>/dev/null
  wait "$DOCS_WATCHDOG_PID" 2>/dev/null
  if [ -e "$flag" ]; then
    kill -s KILL -- "-$DOCS_STEP_PID" 2>/dev/null
    DOCS_BOUND_TIMEOUT=1
  fi
  trap - INT TERM
  DOCS_STEP_PID=""
  DOCS_WATCHDOG_PID=""
  if [ "$DOCS_BOUND_TIMEOUT" -eq 1 ]; then
    fail docs "step $id timeout $DOCS_STEP_TIMEOUT"
    return 1
  fi
  return "$rc"
}

docs_setup_exec() { # cmd...: one host-generation command in the setup dir
  (cd "$WORK/setup" && docs_env "$@") </dev/null >>"$WORK/docs.log" 2>&1
}

# docs_setup <cmd...>: bounded host-generation command (step id host_setup). A timeout has
# already printed its FAIL line; any other failure is tool_unavailable.
docs_setup() {
  docs_bounded host_setup docs_setup_exec "$@"
  local rc=$?
  [ "$DOCS_BOUND_TIMEOUT" -eq 0 ] || return 1
  if [ "$rc" -ne 0 ]; then
    fail docs tool_unavailable
    return 1
  fi
}

# docs_make_host: a throwaway Phoenix host from a pinned phx_new (assets enabled, because
# the documented esbuild flags need them), copied to one fresh host per doc file.
docs_make_host() {
  local setup="$WORK/setup" pinned=0
  mkdir -p "$WORK/home" "$WORK/mix_home" "$WORK/hex_home" "$setup" || { fail docs tool_unavailable; return 1; }
  if [ -n "${CLEANROOM_ELIXIR_VERSION:-}" ] && [ -n "${CLEANROOM_ERLANG_VERSION:-}" ]; then
    pinned=1
    printf 'erlang %s\nelixir %s\n' "$CLEANROOM_ERLANG_VERSION" "$CLEANROOM_ELIXIR_VERSION" >"$setup/.tool-versions"
    echo "cleanroom: toolchain elixir $CLEANROOM_ELIXIR_VERSION erlang $CLEANROOM_ERLANG_VERSION"
  else
    echo "cleanroom: toolchain path"
  fi
  docs_setup mix local.hex --force || return 1
  docs_setup mix local.rebar --force || return 1
  docs_setup mix archive.install hex phx_new "$PHX_NEW_VERSION" --force || return 1
  docs_setup mix phx.new "$WORK/host-template" --app clean_room_host --module CleanRoomHost \
    --no-ecto --no-dashboard --no-mailer --no-gettext --no-install --no-version-check || return 1
  if [ "$pinned" -eq 1 ]; then
    printf 'erlang %s\nelixir %s\n' "$CLEANROOM_ERLANG_VERSION" "$CLEANROOM_ELIXIR_VERSION" >"$WORK/host-template/.tool-versions"
  fi
  cp -R "$WORK/host-template" "$WORK/host-readme" || { fail docs tool_unavailable; return 1; }
  cp -R "$WORK/host-template" "$WORK/host-install" || { fail docs tool_unavailable; return 1; }
}

# docs_run_step <id> <body file> <host dir>: the body runs verbatim under `bash -e` in the
# host, scrubbed env, stdin closed (the caller reads the step list from a file). Output is
# appended to docs.log and never echoed.
docs_step_exec() { # host step
  (cd "$1" && docs_env bash -e "$2") </dev/null >>"$WORK/docs.log" 2>&1
}

docs_run_step() {
  local id="$1" body="$2" host="$3" step rc
  step="$WORK/docs/steps/$id.sh"
  cp "$body" "$step" || { fail docs "step $id exit 1"; return 1; }
  docs_bounded "$id" docs_step_exec "$host" "$step"
  rc=$?
  [ "$DOCS_BOUND_TIMEOUT" -eq 0 ] || return 1
  if [ "$rc" -ne 0 ]; then
    fail docs "step $id exit $rc"
    return 1
  fi
}

docs_run_all() {
  local tag ord kind id attrs body failed_tags=" " executed=0 clone=0 shown=0 bad=0
  while IFS=$'\t' read -r tag ord kind id attrs body; do
    case "$kind" in
      run)
        case "$failed_tags" in *" $tag "*) continue ;; esac
        if docs_run_step "$id" "$body" "$WORK/host-$tag"; then
          executed=$((executed + 1))
        else
          bad=1
          failed_tags="$failed_tags$tag "
        fi
        ;;
      clone) clone=$((clone + 1)) ;;
      show) shown=$((shown + 1)) ;;
    esac
  done <"$WORK/docs/steps.tsv"
  [ "$bad" -eq 0 ] || return 1
  echo "cleanroom: leg docs PASS $VERSION executed=$executed not_applicable=0 clone=$clone shown=$shown source=commit:$DOCS_REF phx_new=$PHX_NEW_VERSION"
}

leg_docs() {
  need_tools docs curl awk sed grep tr head tail cut mktemp mkdir cp tar gzip mix env bash sleep || return
  mk_work || { fail docs tool_unavailable; return; }
  docs_fetch_sources || return
  docs_parse || return
  docs_make_host || return
  docs_run_all
}

IFS=',' read -r -a LEG_LIST <<<"$LEGS"
for leg in "${LEG_LIST[@]}"; do
  case "$leg" in
    hex | maven | ios | docs) ;;
    *) echo "cleanroom: override refused (unknown leg)"; exit 2 ;;
  esac
done
for leg in "${LEG_LIST[@]}"; do
  "leg_$leg"
done
LEGS_RUN="$LEGS"

if [ "$FAILED" -ne 0 ]; then
  echo "cleanroom: result FAIL legs $LEGS_RUN version $VERSION"
  exit 1
fi
if [ "$SELFTEST" = "1" ]; then
  echo "cleanroom: result SELFTEST legs $LEGS_RUN version $VERSION"
  exit 0
fi
echo "cleanroom: result PASS legs $LEGS_RUN version $VERSION"
exit 0
