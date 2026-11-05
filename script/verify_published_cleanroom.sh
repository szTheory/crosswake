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
#   docs   read README.md and guides/install.md from the Hex tarball of the version under
#          test (default) or, when CLEANROOM_DOCS_REF is set, from that commit (40
#          lowercase hex, no clone); parse every fence in README "Integrating Crosswake"
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
# public commit the docs leg reads instead of the Hex tarball, is accepted without
# CLEANROOM_SELFTEST, and a value that is not 40 lowercase hex exits 2. Without it the docs
# come from $HEX_REPO/tarballs/crosswake-<version>.tar (https://repo.hex.pm), so docs and code
# are one artifact; only README.md and guides/install.md are extracted. A default run against a
# version whose shipped docs carry no markers fails `parse unmarked_fence` (true for 0.2.11 and
# earlier); the Phase 197 evidence run therefore uses CLEANROOM_DOCS_REF. CLEANROOM_DOCS_STEP_TIMEOUT=<seconds> is the same
# class (a positive integer, default 900, otherwise exit 2): every documented step and every
# host-generation command runs under that bound, because a bound can only turn a run red.
#
# Selftest overrides (honored only with CLEANROOM_SELFTEST=1; without it any
# override exits 2): CLEANROOM_LEGS, CLEANROOM_MAVEN_BASE, CLEANROOM_HEX_API,
# CLEANROOM_DOCS_BASE (docs source root, layout <base>/<ref>/README.md),
# CLEANROOM_HEX_REPO (tarball repo root, layout <repo>/tarballs/crosswake-<v>.tar),
# CLEANROOM_KEEP_WORK=1 (keep the work dir and print `cleanroom: work kept <path>`).
# With the flag set the run announces itself and ends `result SELFTEST`,
# never `result PASS`.
#
# Output contract (parsed by later phases):
#   cleanroom: leg <leg> PASS <version> <detail>
#   cleanroom: docs deferred ios_host <file> since=0.2.12 version=<v>
#     (below 0.2.12 only; the docs PASS line then names `deferred=ios_host`, otherwise
#     `deferred=none`, right after `not_applicable=<m>`, and the block is not in `executed`)
#   cleanroom: FAIL <leg> <reason>
#     reasons: any leg tool_unavailable
#              hex     not_published (404 or no such release), resolve_failed (network or
#                      resolve error), parse_failed (200 response with no checksum),
#                      checksum_mismatch, compile_failed, vsn_mismatch
#              maven   not_published, fetch_failed, checksum_mismatch, pom_mismatch
#              ios     not_published (successful lookup, no tag), resolve_failed (git
#                      ls-remote failed), clone_failed, build_failed
#              docs    fetch <file>, fetch tarball, parse <reason> (unmarked_fence <file>,
#                      unterminated_fence <file>, no_fences <file>, readme_scope_missing,
#                      missing_id, bad_id, duplicate_id, unknown_attr, missing_mode,
#                      unknown_mode, missing_file, bad_path, bad_since),
#                      apply <id> <reason> (target_missing, anchor_missing, exists,
#                      empty_body, write_failed), compile_warning <path>,
#                      required_step doctor <file>, required_step bridge_hook|esbuild_external|
#                      esbuild_esm|attach <file> (the file's executed blocks lack the step; a block
#                      whose `since=` is above the version under test is NOT_APPLICABLE, skipped
#                      and counted in `not_applicable=`, and never satisfies a step),
#                      required_step ios_host <file> (absent, or NOT_APPLICABLE from 0.2.12 on, or a
#                      `since=` other than 0.2.12 below it), required_step ios_host_unread <file>
#                      (below 0.2.12 a block carrying :ios_host without since=0.2.12),
#                      executed_below_floor <n> <floor>,
#                      step <id> exit <code>, step <id> timeout <secs>, step <id> interrupted
#                      (the step's whole process group is killed; a host-generation command is
#                      step host_setup; step compile is the harness `mix compile` before a
#                      file's doctor block)
#   cleanroom: docs source commit <ref> | docs source tarball crosswake-<version>.tar
#     Network calls carry --max-time, --retry and an https-only protocol pin.
#   cleanroom: result PASS|FAIL|SELFTEST legs <list> version <version>

set -uo pipefail

DEFAULT_LEGS="hex,maven,ios,docs"
MAVEN_DEFAULT_BASE="https://repo1.maven.org/maven2"
HEX_DEFAULT_API="https://hex.pm/api"
HEX_REPO_DEFAULT="https://repo.hex.pm"
DOCS_DEFAULT_BASE="https://raw.githubusercontent.com/szTheory/crosswake"
PHX_NEW_VERSION="1.8.13"
DOCS_STEP_TIMEOUT_DEFAULT=900
# D-04 amendment (2026-10-29): `config :crosswake, :ios_host` is read only by crosswake versions
# from this one on (it landed after 0.2.11). Below it the `:ios_host` step is the single named
# deferral; at or above it there is no exemption (Phase 199 runs against 0.2.12 with none).
DOCS_IOS_HOST_SINCE="0.2.12"
# Executed-step floor (D-04). Pinned to the measured executed count of the marked docs: the run
# and apply blocks without since= in README.md and guides/install.md plus one harness compile per
# file (8 + 8 + 2 = 18; the since-marked :ios_host blocks are deferred against 0.2.11 and are not
# counted). test/crosswake/guides/cleanroom_doc_markers_test.exs asserts this equals that count,
# and it equals the executed= value of the docs-leg selftest evidence. It is a minimum: at 0.2.12
# the ios-host blocks execute and executed exceeds it.
DOCS_EXECUTED_FLOOR=18
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
HEX_REPO="${CLEANROOM_HEX_REPO:-$HEX_REPO_DEFAULT}"
DOCS_REF="${CLEANROOM_DOCS_REF:-}"
if [ -n "$DOCS_REF" ] && ! [[ "$DOCS_REF" =~ ^[0-9a-f]{40}$ ]]; then
  usage
fi
DOCS_STEP_TIMEOUT="${CLEANROOM_DOCS_STEP_TIMEOUT:-$DOCS_STEP_TIMEOUT_DEFAULT}"
if ! [[ "$DOCS_STEP_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  usage
fi

if [ "$SELFTEST" != "1" ]; then
  if [ "$LEGS" != "$DEFAULT_LEGS" ] || [ -n "${CLEANROOM_MAVEN_BASE:-}" ] || [ -n "${CLEANROOM_HEX_API:-}" ] || [ -n "${CLEANROOM_DOCS_BASE:-}" ] || [ -n "${CLEANROOM_HEX_REPO:-}" ] || [ -n "${CLEANROOM_KEEP_WORK:-}" ]; then
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
# docs_fetch_sources: README.md and guides/install.md, through fetch only (never from beside
# this script). With CLEANROOM_DOCS_REF they come from that commit; without it from the Hex
# tarball of the version under test (D-03), so docs and code are one artifact. DOCS_SOURCE
# records which, for the PASS line.
DOCS_SOURCE=""
docs_fetch_sources() {
  local rc
  mkdir -p "$WORK/docs/body" "$WORK/docs/steps" || { fail docs tool_unavailable; return 1; }
  if [ -z "$DOCS_REF" ]; then
    docs_fetch_tarball
    return
  fi
  fetch "$DOCS_BASE/$DOCS_REF/README.md" "$WORK/docs/README.md"; rc=$?
  if [ "$rc" -ne 0 ]; then fail docs "fetch README.md"; return 1; fi
  fetch "$DOCS_BASE/$DOCS_REF/guides/install.md" "$WORK/docs/install.md"; rc=$?
  if [ "$rc" -ne 0 ]; then fail docs "fetch guides/install.md"; return 1; fi
  DOCS_SOURCE="commit:$DOCS_REF"
  echo "cleanroom: docs source commit $DOCS_REF"
}

# docs_fetch_tarball: the Hex tarball is an outer tar holding contents.tar.gz. Only the two
# named members are extracted, into a directory inside the work dir (removed with it), and each
# must be a regular file that is not a symlink. A fetch failure (404 or otherwise) is
# `fetch tarball`; a missing member is `fetch <member>`.
docs_fetch_tarball() {
  local name="crosswake-$VERSION.tar" tarball="$WORK/docs/crosswake-$VERSION.tar"
  local ex="$WORK/docs/extract" member rc
  fetch "$HEX_REPO/tarballs/$name" "$tarball"; rc=$?
  if [ "$rc" -ne 0 ]; then fail docs "fetch tarball"; return 1; fi
  mkdir -p "$ex" || { fail docs tool_unavailable; return 1; }
  if ! tar -xf "$tarball" -C "$ex" contents.tar.gz >/dev/null 2>&1 || [ ! -f "$ex/contents.tar.gz" ]; then
    fail docs "fetch tarball"
    return 1
  fi
  for member in README.md guides/install.md; do
    if ! tar -xzf "$ex/contents.tar.gz" -C "$ex" "$member" >/dev/null 2>&1 ||
      [ -L "$ex/$member" ] || [ -L "$ex/guides" ] || [ ! -f "$ex/$member" ]; then
      fail docs "fetch $member"
      return 1
    fi
  done
  cp "$ex/README.md" "$WORK/docs/README.md" || { fail docs "fetch README.md"; return 1; }
  cp "$ex/guides/install.md" "$WORK/docs/install.md" || { fail docs "fetch guides/install.md"; return 1; }
  DOCS_SOURCE="tarball"
  echo "cleanroom: docs source tarball $name"
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
  docs_validate || return 1
}

# docs_version_ge <a> <b>: success when a >= b, comparing three numeric components
# (0.2.9 < 0.2.10; a leading zero is never read as octal).
docs_version_ge() {
  local a="$1" b="$2" i x y
  local -a av bv
  IFS=. read -r -a av <<<"$a"
  IFS=. read -r -a bv <<<"$b"
  for i in 0 1 2; do
    x=$((10#${av[$i]:-0}))
    y=$((10#${bv[$i]:-0}))
    if [ "$x" -gt "$y" ]; then return 0; fi
    if [ "$x" -lt "$y" ]; then return 1; fi
  done
  return 0
}

# docs_attr <attrs> <key>: print the value of one `key=value` attribute of a steps.tsv attrs
# field (`;`-joined, `-` when empty); nothing when the key is absent.
docs_attr() {
  local rest="$1" kv
  while [ -n "$rest" ] && [ "$rest" != "-" ]; do
    kv="${rest%%;*}"
    if [ "$rest" = "$kv" ]; then rest=""; else rest="${rest#*;}"; fi
    case "$kv" in
      "$2="*) printf '%s' "${kv#"$2="}"; return 0 ;;
    esac
  done
  return 0
}

# docs_applicable <attrs>: success when the block has no `since=` or the version under test is
# at least it. A block above it is NOT_APPLICABLE: skipped, counted, never executed (D-04).
docs_applicable() {
  local since
  since=$(docs_attr "$1" since)
  [ -z "$since" ] || docs_version_ge "$VERSION" "$since"
}

# docs_display <tag>: the doc path as fetched, used in reasons.
docs_display() {
  if [ "$1" = readme ]; then printf 'README.md'; else printf 'guides/install.md'; fi
}

# docs_path_ok <file>: a `file=` path is relative, non-empty and has no `..` segment, so no
# documented fragment can be written outside the throwaway host (T-197-14).
docs_path_ok() {
  case "$1" in
    "" | /* | .. | ../* | */.. | */../*) return 1 ;;
  esac
  return 0
}

# docs_validate: structural rules checked before any host is built. Every apply block names
# a known `mode=` and a safe `file=` (parse missing_mode, unknown_mode, missing_file,
# bad_path), and each doc file carries a doctor run block (required_step doctor <file>,
# D-02): the doctor is the one documented step that reads the whole install.
docs_validate() {
  local tag ord kind id attrs body mode file kv rest bad=0 since
  local doctor_readme=0 doctor_install=0
  while IFS=$'\t' read -r tag ord kind id attrs body; do
    since=$(docs_attr "$attrs" since)
    if [ -n "$since" ] && ! [[ "$since" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      fail docs "parse bad_since"
      return 1
    fi
    case "$kind" in
      run)
        # a doctor block whose `since=` is above the version under test is NOT_APPLICABLE and
        # does not satisfy the requirement
        if grep -qF 'mix crosswake.doctor' "$body" && docs_applicable "$attrs"; then
          if [ "$tag" = readme ]; then doctor_readme=1; else doctor_install=1; fi
        fi
        ;;
      apply)
        mode=""
        file=""
        rest="$attrs"
        while [ -n "$rest" ] && [ "$rest" != "-" ]; do
          kv="${rest%%;*}"
          if [ "$rest" = "$kv" ]; then rest=""; else rest="${rest#*;}"; fi
          case "$kv" in
            mode=*) mode="${kv#mode=}" ;;
            file=*) file="${kv#file=}" ;;
          esac
        done
        if [ -z "$mode" ]; then fail docs "parse missing_mode"; return 1; fi
        case "$mode" in
          create | append | deps | esbuild-args | js-hook | router-route) ;;
          *) fail docs "parse unknown_mode"; return 1 ;;
        esac
        if [ -z "$file" ]; then fail docs "parse missing_file"; return 1; fi
        if ! docs_path_ok "$file"; then fail docs "parse bad_path"; return 1; fi
        ;;
    esac
  done <"$WORK/docs/steps.tsv"
  if [ "$doctor_readme" -eq 0 ]; then fail docs "required_step doctor README.md"; bad=1; fi
  if [ "$doctor_install" -eq 0 ]; then fail docs "required_step doctor guides/install.md"; bad=1; fi
  [ "$bad" -eq 0 ] || return 1
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
  : >"$flag"
  trap docs_interrupt INT TERM
  set -m
  "$@" &
  DOCS_STEP_PID=$!
  (
    sleep "$DOCS_STEP_TIMEOUT"
    echo 1 >"$flag"
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
  if [ -s "$flag" ]; then
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

# docs_subst: stdin to stdout through the fixed substitution table (D-01), longest key first,
# applied to apply bodies and `file=` values only; run blocks stay verbatim. The documented
# `{:crosswake, "~> 0.2"}` requirement becomes an exact pin to the version under test.
docs_subst() {
  sed -e 's/my_app_web/clean_room_host_web/g' \
    -e 's/MyAppWeb/CleanRoomHostWeb/g' \
    -e 's/my_app/clean_room_host/g' \
    -e 's/MyApp/CleanRoomHost/g' \
    -e 's/{:crosswake, "~> 0\.2"}/{:crosswake, "== '"$VERSION"'"}/g'
}

# docs_apply_deps <target> <body>: add each `{:name, ...}` tuple of the body that the host's
# deps list lacks, as the first elements after the `defp deps do` line and its `[` line.
# Exit 3: no such anchor.
docs_apply_deps() {
  awk -v tgt="$1" -v bodyfile="$2" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
    function tname(l,    s) { s = l; sub(/^[ \t]*[{]:/, "", s); sub(/,.*$/, "", s); return s }
    BEGIN {
      while ((getline l < tgt) > 0) if (l ~ /^[ \t]*[{]:[A-Za-z0-9_]+,/) have[tname(l)] = 1
      close(tgt)
      while ((getline l < bodyfile) > 0) {
        if (l !~ /^[ \t]*[{]:[A-Za-z0-9_]+,/) continue
        nm = tname(l)
        if (nm in have) continue
        have[nm] = 1
        t = trim(l)
        sub(/,$/, "", t)
        tuples[++nt] = t
      }
      close(bodyfile)
    }
    {
      if (prev_def && !anchor && trim($0) == "[") {
        print
        for (i = 1; i <= nt; i++) print "      " tuples[i] ","
        anchor = 1
        prev_def = 0
        next
      }
      print
      prev_def = (index($0, "defp deps do") > 0)
    }
    END { exit (anchor ? 0 : 3) }
  ' "$1" >"$WORK/docs/edit.tmp" || return $?
  cp "$WORK/docs/edit.tmp" "$1"
}

# docs_apply_create <target> <body>: write the body as a new host file (parent directories
# inside the host). An existing file with identical content is a no-op; a different one is
# exit 5 (`exists`). No anchor.
docs_apply_create() {
  if [ -e "$1" ]; then
    cmp -s "$2" "$1" && return 0
    return 5
  fi
  mkdir -p "${1%/*}" && cp "$2" "$1"
}

# docs_apply_append <target> <body>: append the body to an existing file unless that exact
# body text is already in it. No anchor.
docs_apply_append() {
  local content body
  content=$(<"$1")
  body=$(<"$2")
  case "$content" in *"$body"*) return 0 ;; esac
  if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then printf '\n' >>"$1" || return 1; fi
  cat "$2" >>"$1"
}

# docs_apply_esbuild <target> <body>: inside the first `~w(js/app.js ...)` sigil add every
# `--` token of the body that is absent. A `--name=value` token is skipped when `--name=`
# is already there; any other token (`--external:<v>`, `--flag`) compares whole.
# Exit 3: no such sigil on one line.
docs_apply_esbuild() {
  awk -v bodyfile="$2" '
    BEGIN {
      while ((getline l < bodyfile) > 0) {
        m = split(l, parts, /[ \t]+/)
        for (i = 1; i <= m; i++) {
          sub(/[)]+$/, "", parts[i])
          if (substr(parts[i], 1, 2) == "--" && !(parts[i] in want)) { want[parts[i]] = 1; order[++n] = parts[i] }
        }
      }
      close(bodyfile)
    }
    {
      p = index($0, "~w(js/app.js")
      if (!done && p > 0) {
        head = substr($0, 1, p + 2)
        rest = substr($0, p + 3)
        q = index(rest, ")")
        if (q > 0) {
          inner = substr(rest, 1, q - 1)
          tail_part = substr(rest, q)
          k = split(inner, toks, /[ \t]+/)
          for (i = 1; i <= n; i++) {
            t = order[i]
            eq = index(t, "=")
            pre = (t ~ /^--[A-Za-z0-9_-]+=/) ? substr(t, 1, eq) : ""
            present = 0
            for (j = 1; j <= k; j++) {
              if (pre != "") { if (substr(toks[j], 1, length(pre)) == pre) present = 1 }
              else if (toks[j] == t) present = 1
            }
            if (!present) { inner = inner " " t; toks[++k] = t }
          }
          print head inner tail_part
          done = 1
          next
        }
      }
      print
    }
    END { exit (done ? 0 : 3) }
  ' "$1" >"$WORK/docs/edit.tmp" || return $?
  cp "$WORK/docs/edit.tmp" "$1"
}

# docs_apply_jshook <target> <body>: prepend each `import` line of the body that is absent,
# and put `CrosswakeBridge, ` right after the first `hooks: {` unless that object already
# names it. Exit 3: no `hooks: {`.
docs_apply_jshook() {
  awk -v tgt="$1" -v bodyfile="$2" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
    BEGIN {
      while ((getline l < tgt) > 0) have[trim(l)] = 1
      close(tgt)
      while ((getline l < bodyfile) > 0) {
        t = trim(l)
        if (t ~ /^import[ \t]/ && !(t in have)) { have[t] = 1; print t }
      }
      close(bodyfile)
    }
    {
      p = index($0, "hooks: {")
      if (!done && p > 0) {
        head = substr($0, 1, p + 7)
        rest = substr($0, p + 8)
        q = index(rest, "}")
        obj = (q > 0) ? substr(rest, 1, q - 1) : rest
        if (index(obj, "CrosswakeBridge") == 0) print head "CrosswakeBridge, " rest
        else print
        done = 1
        next
      }
      print
    }
    END { exit (done ? 0 : 3) }
  ' "$1" >"$WORK/docs/edit.tmp" || return $?
  cp "$WORK/docs/edit.tmp" "$1"
}

# docs_apply_route <target> <body>: insert each body line that the router lacks after the
# first `pipe_through :browser` line inside the first `scope "/", ` block, indented like that
# line. The block ends at the first `end` at the scope line indentation.
# Exit 3: no such line in that block.
docs_apply_route() {
  awk -v tgt="$1" -v bodyfile="$2" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
    BEGIN {
      while ((getline l < tgt) > 0) have[trim(l)] = 1
      close(tgt)
      while ((getline l < bodyfile) > 0) {
        t = trim(l)
        if (t == "" || (t in have)) continue
        have[t] = 1
        lines[++n] = t
        raw[n] = l
      }
      close(bodyfile)
    }
    {
      print
      if (!anchor && !scope_done) {
        if (!inscope) {
          if (substr(trim($0), 1, 10) == "scope \"/\",") { inscope = 1; match($0, /^[ \t]*/); sind = RLENGTH }
        } else if ($0 ~ /pipe_through :browser/) {
          match($0, /^[ \t]*/)
          ind = substr($0, 1, RLENGTH)
          for (i = 1; i <= n; i++) print ind raw[i]
          anchor = 1
        } else {
          match($0, /^[ \t]*/)
          if (RLENGTH == sind && trim($0) == "end") scope_done = 1
        }
      }
    }
    END { exit (anchor ? 0 : 3) }
  ' "$1" >"$WORK/docs/edit.tmp" || return $?
  cp "$WORK/docs/edit.tmp" "$1"
}

# docs_apply_step <tag> <id> <attrs> <body file> <host dir>: one apply block. The target
# rule is checked once here from the per-mode table: every mode but `create` needs its file
# to exist (`target_missing`); `create` needs it absent or identical (`exists`); the anchored
# modes report `anchor_missing`. Writes stay inside the per-file host dir (the `file=` path
# was checked by docs_validate and is checked again here).
docs_apply_step() {
  local tag="$1" id="$2" attrs="$3" body="$4" host="$5"
  local mode="" file="" kv rest sbody target rc
  rest="$attrs"
  while [ -n "$rest" ] && [ "$rest" != "-" ]; do
    kv="${rest%%;*}"
    if [ "$rest" = "$kv" ]; then rest=""; else rest="${rest#*;}"; fi
    case "$kv" in
      mode=*) mode="${kv#mode=}" ;;
      file=*) file="${kv#file=}" ;;
    esac
  done
  if ! docs_path_ok "$file"; then fail docs "parse bad_path"; return 1; fi
  file=$(printf '%s\n' "$file" | docs_subst)
  if ! docs_path_ok "$file"; then fail docs "parse bad_path"; return 1; fi
  sbody="$WORK/docs/steps/$id.apply"
  target="$host/$file"
  if ! docs_subst <"$body" >"$sbody"; then fail docs "apply $id subst_failed"; return 1; fi
  if ! grep -q '[^[:space:]]' "$sbody"; then fail docs "apply $id empty_body"; return 1; fi
  case "$mode" in
    create) ;;
    append | deps | esbuild-args | js-hook | router-route)
      if [ ! -f "$target" ]; then fail docs "apply $id target_missing"; return 1; fi
      ;;
  esac
  case "$mode" in
    create) docs_apply_create "$target" "$sbody"; rc=$? ;;
    append) docs_apply_append "$target" "$sbody"; rc=$? ;;
    deps) docs_apply_deps "$target" "$sbody"; rc=$? ;;
    esbuild-args) docs_apply_esbuild "$target" "$sbody"; rc=$? ;;
    js-hook) docs_apply_jshook "$target" "$sbody"; rc=$? ;;
    router-route) docs_apply_route "$target" "$sbody"; rc=$? ;;
    *) fail docs "apply $id write_failed"; return 1 ;;
  esac
  case "$rc" in
    0) ;;
    3) fail docs "apply $id anchor_missing"; return 1 ;;
    5) fail docs "apply $id exists"; return 1 ;;
    *) fail docs "apply $id write_failed"; return 1 ;;
  esac
  printf '%s\n' "$file" >>"$WORK/docs/written-$tag"
}

# docs_compile_warning <log> <written list>: print the first leg-written path named inside a
# `warning:` block of the compile log (a block runs to the next blank line). Warnings in
# Phoenix's own generated files are not named by any written path and are ignored.
docs_compile_warning() {
  [ -s "$2" ] || return 0
  awk -v wfile="$2" '
    BEGIN { while ((getline l < wfile) > 0) if (l != "") w[++n] = l }
    /^[ \t]*$/ { inw = 0; next }
    /warning:/ { inw = 1 }
    inw {
      for (i = 1; i <= n; i++) {
        p = index($0, w[i] ":")
        if (p > 0 && (p == 1 || substr($0, p - 1, 1) !~ /[A-Za-z0-9_.\/-]/)) { print w[i]; exit }
      }
    }
  ' "$1"
}

docs_compile_exec() { # host log
  (cd "$1" && docs_env mix compile) </dev/null >"$2" 2>&1
}

# docs_compile <tag>: harness step `compile` before the first doctor run block of a file
# (D-02). Non-zero exit, or a warning located in a file an apply block wrote, fails.
docs_compile() {
  local tag="$1" log="$WORK/docs-compile-$1.log" rc bad
  docs_bounded compile docs_compile_exec "$WORK/host-$tag" "$log"
  rc=$?
  [ "$DOCS_BOUND_TIMEOUT" -eq 0 ] || return 1
  if [ "$rc" -ne 0 ]; then
    fail docs "step compile exit $rc"
    return 1
  fi
  bad=$(docs_compile_warning "$log" "$WORK/docs/written-$tag")
  if [ -n "$bad" ]; then
    fail docs "compile_warning $bad"
    return 1
  fi
}

DOCS_IOS_HOST_TOKEN=":ios_host"
DOCS_DEFERRED=""

# docs_required_token <name>: the literal a required wiring step must contain (D-04).
docs_required_token() {
  case "$1" in
    bridge_hook) printf '%s' 'CrosswakeBridge' ;;
    esbuild_external) printf '%s' '--external:/crosswake/*' ;;
    esbuild_esm) printf '%s' '--format=esm' ;;
    attach) printf '%s' 'Crosswake.Bridge.attach()' ;;
  esac
}

# docs_classify <tag> <attrs> <body>: decide one run or apply block before it is executed.
# Returns 0 to execute it, 1 when it is NOT_APPLICABLE (`since=` above the version under test:
# skipped, counted, never executed), 2 when it is the deferred `:ios_host` block (the same, and
# named on a `docs deferred` line and in `deferred=`), 3 when it already failed (reported).
# The `:ios_host` step is the only one with an exemption and it is version-conditional (D-04
# amendment): below DOCS_IOS_HOST_SINCE a block carrying it must be marked exactly
# `since=$DOCS_IOS_HOST_SINCE`; an unmarked one would run against a version that never reads the
# key (ios_host_unread), any other `since=` is a plain miss. From that version on the ordinary
# rules apply, with no exemption.
docs_classify() {
  local tag="$1" attrs="$2" body="$3" since file
  since=$(docs_attr "$attrs" since)
  file=$(docs_display "$tag")
  if grep -qF -- "$DOCS_IOS_HOST_TOKEN" "$body"; then
    : >"$WORK/docs/ios-seen-$tag"
    if ! docs_version_ge "$VERSION" "$DOCS_IOS_HOST_SINCE"; then
      if [ "$since" = "$DOCS_IOS_HOST_SINCE" ]; then
        echo "cleanroom: docs deferred ios_host $file since=$since version=$VERSION"
        case ",$DOCS_DEFERRED," in
          *,ios_host,*) ;;
          *) DOCS_DEFERRED="${DOCS_DEFERRED:+$DOCS_DEFERRED,}ios_host" ;;
        esac
        return 2
      fi
      if [ -z "$since" ]; then
        fail docs "required_step ios_host_unread $file"
      else
        fail docs "required_step ios_host $file"
      fi
      return 3
    fi
  fi
  docs_applicable "$attrs" || return 1
  return 0
}

# docs_required_steps <tag>: the per-file required-step check (D-04) over the bodies that
# actually executed, after substitution. A NOT_APPLICABLE block never reaches that file, so it
# cannot satisfy a step. Returns 1 after reporting every missing step.
docs_required_steps() {
  local tag="$1" file name tok bad=0 ex="$WORK/docs/executed-$1"
  file=$(docs_display "$tag")
  : >>"$ex"
  for name in bridge_hook esbuild_external esbuild_esm attach; do
    tok=$(docs_required_token "$name")
    if ! grep -qF -- "$tok" "$ex"; then
      fail docs "required_step $name $file"
      bad=1
    fi
  done
  # `:ios_host`: from DOCS_IOS_HOST_SINCE on it must be in an executed block like the others;
  # below it any block carrying it (deferred, or already failed above) is enough, none is a miss
  if docs_version_ge "$VERSION" "$DOCS_IOS_HOST_SINCE"; then
    if ! grep -qF -- "$DOCS_IOS_HOST_TOKEN" "$ex"; then
      fail docs "required_step ios_host $file"
      bad=1
    fi
  elif [ ! -e "$WORK/docs/ios-seen-$tag" ]; then
    fail docs "required_step ios_host $file"
    bad=1
  fi
  [ "$bad" -eq 0 ]
}

docs_run_all() {
  local tag ord kind id attrs body failed_tags=" " compiled_tags=" " executed=0 not_applicable=0 clone=0 shown=0 bad=0 rc
  while IFS=$'\t' read -r tag ord kind id attrs body; do
    case "$kind" in
      run)
        case "$failed_tags" in *" $tag "*) continue ;; esac
        docs_classify "$tag" "$attrs" "$body"
        rc=$?
        case "$rc" in
          1 | 2) not_applicable=$((not_applicable + 1)); continue ;;
          3) bad=1; failed_tags="$failed_tags$tag "; continue ;;
        esac
        case "$compiled_tags" in
          *" $tag "*) ;;
          *)
            if grep -qF 'mix crosswake.doctor' "$body"; then
              compiled_tags="$compiled_tags$tag "
              if docs_compile "$tag"; then
                executed=$((executed + 1))
              else
                bad=1
                failed_tags="$failed_tags$tag "
                continue
              fi
            fi
            ;;
        esac
        if docs_run_step "$id" "$body" "$WORK/host-$tag"; then
          executed=$((executed + 1))
          cat "$body" >>"$WORK/docs/executed-$tag"
        else
          bad=1
          failed_tags="$failed_tags$tag "
        fi
        ;;
      apply)
        case "$failed_tags" in *" $tag "*) continue ;; esac
        docs_classify "$tag" "$attrs" "$body"
        rc=$?
        case "$rc" in
          1 | 2) not_applicable=$((not_applicable + 1)); continue ;;
          3) bad=1; failed_tags="$failed_tags$tag "; continue ;;
        esac
        if docs_apply_step "$tag" "$id" "$attrs" "$body" "$WORK/host-$tag"; then
          executed=$((executed + 1))
          cat "$WORK/docs/steps/$id.apply" >>"$WORK/docs/executed-$tag"
        else
          bad=1
          failed_tags="$failed_tags$tag "
        fi
        ;;
      clone) clone=$((clone + 1)) ;;
      show) shown=$((shown + 1)) ;;
    esac
  done <"$WORK/docs/steps.tsv"
  # the required-step check runs only for a file whose steps all ran: a file that already
  # failed is red, and its missing steps would only repeat that failure
  for tag in readme install; do
    case "$failed_tags" in *" $tag "*) continue ;; esac
    docs_required_steps "$tag" || bad=1
  done
  if [ "$executed" -lt "$DOCS_EXECUTED_FLOOR" ]; then
    fail docs "executed_below_floor $executed $DOCS_EXECUTED_FLOOR"
    bad=1
  fi
  [ "$bad" -eq 0 ] || return 1
  echo "cleanroom: leg docs PASS $VERSION executed=$executed not_applicable=$not_applicable deferred=${DOCS_DEFERRED:-none} clone=$clone shown=$shown source=$DOCS_SOURCE phx_new=$PHX_NEW_VERSION"
}

leg_docs() {
  need_tools docs curl awk sed grep tr head tail cut mktemp mkdir cp tar gzip mix env bash sleep cat cmp || return
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
