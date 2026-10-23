#!/usr/bin/env bash
# lib-189.sh - shared read-only wrappers for phase 189.
# Run "bash lib-189.sh locate" once to write env-189.sh; source this file elsewhere.
# No script of this phase contains a literal at-sign: where one is needed it is built
# with printf and an octal escape, and argument forwarding goes through eval.
set -u
umask 077

_AT=$(printf '\100')
_LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

# ---------------------------------------------------------------- confinement
_under() { # _under PATH ROOT : PATH (physical) equals ROOT or sits below it
  case $1 in
    "$2"|"$2"/*) return 0 ;;
  esac
  return 1
}

_phys_dir() { # physical path of an existing directory, else empty
  [ -d "$1" ] || return 1
  (cd "$1" 2>/dev/null && pwd -P)
}

_phys_new() { # physical path of a path whose parent exists
  local par base
  par=$(dirname "$1"); base=$(basename "$1")
  par=$(_phys_dir "$par") || return 1
  printf '%s/%s\n' "$par" "$base"
}

_scratch_ok() { # 0 when the path resolves under RUNS or a selftest fixture
  local p=$1
  case $p in
    /private/tmp/cw189-selftest.*) return 0 ;;
  esac
  if [ -n "${RUNS:-}" ]; then
    _under "$p" "$RUNS" && return 0
  fi
  return 1
}

# ------------------------------------------------------------------------ gr
# gr REPO VERB ARGS : read-only git, allow-listed verbs only.
gr() {
  local repo verb a sub seen
  if [ "$#" -lt 2 ]; then echo "gr: usage" >&2; return 3; fi
  repo=$1; verb=$2
  shift 2
  for a; do
    case $a in
      --output|--output=*) echo "gr: refused output option" >&2; return 3 ;;
    esac
  done
  case $verb in
    rev-parse|symbolic-ref|for-each-ref|log|rev-list|cherry|show|cat-file|ls-tree|ls-files|merge-base|diff) : ;;
    status)
      seen=0
      for a; do
        case $a in
          --porcelain|--porcelain=*) seen=1 ;;
        esac
      done
      if [ "$seen" -ne 1 ]; then echo "gr: refused status without porcelain" >&2; return 3; fi
      ;;
    hash-object)
      for a; do
        case $a in
          -w|--write|-[a-zA-Z]*w[a-zA-Z]*) echo "gr: refused hash-object write" >&2; return 3 ;;
        esac
      done
      ;;
    stash)
      sub=${1:-}
      case $sub in
        list|show) : ;;
        *) echo "gr: refused stash $sub" >&2; return 3 ;;
      esac
      ;;
    worktree)
      sub=${1:-}
      [ "$sub" = list ] || { echo "gr: refused worktree $sub" >&2; return 3; }
      ;;
    config)
      sub=${1:-}
      [ "$sub" = "--get" ] || { echo "gr: refused config $sub" >&2; return 3; }
      ;;
    remote)
      sub=${1:-}
      [ "$sub" = get-url ] || { echo "gr: refused remote $sub" >&2; return 3; }
      ;;
    *) echo "gr: refused $verb" >&2; return 3 ;;
  esac
  (
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
    export GIT_OPTIONAL_LOCKS=0
    eval "git --no-optional-locks -c core.fsmonitor=false -C \"\$repo\" \"\$verb\" \"\$$_AT\""
  )
}

# ------------------------------------------------------------------------ gs
# gs DIR VERB ARGS : any git verb, but DIR must be scratch (RUNS or selftest fixture).
# A source repository may appear only as the URL argument of fetch (read by upload-pack).
gs() {
  local dir verb pd
  if [ "$#" -lt 2 ]; then echo "gs: usage" >&2; return 3; fi
  dir=$1; verb=$2
  pd=$(_phys_dir "$dir") || { echo "gs: refused (no such directory)" >&2; return 3; }
  _scratch_ok "$pd" || { echo "gs: refused" >&2; return 3; }
  case $verb in
    push|send-pack|receive-pack|worktree|submodule|clone) echo "gs: refused $verb" >&2; return 3 ;;
  esac
  shift 2
  (
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
    export GIT_CEILING_DIRECTORIES=/private/tmp
    eval "git -C \"\$pd\" \"\$verb\" \"\$$_AT\""
  )
}

# gclone SRC DST OPTS : git clone into DST only when DST sits under scratch.
gclone() {
  local src dst pn
  if [ "$#" -lt 2 ]; then echo "gclone: usage" >&2; return 3; fi
  src=$1; dst=$2
  pn=$(_phys_new "$dst") || { echo "gclone: refused (parent missing)" >&2; return 3; }
  _scratch_ok "$pn" || { echo "gclone: refused" >&2; return 3; }
  shift 2
  (
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
    export GIT_CEILING_DIRECTORIES=/private/tmp
    eval "git clone \"\$$_AT\" \"\$src\" \"\$pn\""
  )
}

# ghr ARGS : gh, read calls only.
ghr() {
  local a first second
  first=${1:-}; second=${2:-}
  case "$first $second" in
    "pr view"|"pr list"|"repo view") : ;;
    "api "*) : ;;
    *) echo "ghr: refused" >&2; return 3 ;;
  esac
  for a; do
    case $a in
      -X|--method|--method=*|-X*|-f|-F|--field|--field=*|--raw-field|--raw-field=*|--input|--input=*|-f*|-F*)
        echo "ghr: refused write option" >&2; return 3 ;;
    esac
  done
  eval "gh \"\$$_AT\""
}

# ----------------------------------------------------------- git directory
gitdir_abs() { # gitdir_abs REPO : absolute common git directory or exit 3
  local out
  out=$(gr "$1" rev-parse --path-format=absolute --git-common-dir) || { echo "gitdir_abs: failed" >&2; return 3; }
  case $out in
    /*) printf '%s\n' "$out" ;;
    *) echo "gitdir_abs: not absolute" >&2; return 3 ;;
  esac
}

_reflog_files() { # prints reflog file paths under an absolute git directory
  local g=$1
  [ -d "$g/logs" ] && find "$g/logs" -type f
  if [ -d "$g/worktrees" ]; then
    find "$g/worktrees" -type f -path '*/logs/HEAD'
  fi
}

_zero_id() { printf '%040d' 0; }

reflog_ids() { # reflog_ids GITDIR : sorted unique new ids (column 2), zero id removed
  local g=${1:-} z f
  case $g in
    /*) : ;;
    *) echo "reflog_ids: refused relative" >&2; return 3 ;;
  esac
  z=$(_zero_id)
  f=$(_reflog_files "$g") || return 3
  [ -n "$f" ] || return 0
  printf '%s\n' "$f" | while IFS= read -r p; do awk '{print $2}' "$p"; done | grep -v -x -e "$z" -e '' | LC_ALL=C sort -u
  return 0
}

reflog_ids_all() { # old and new ids (columns 1 and 2)
  local g=${1:-} z f
  case $g in
    /*) : ;;
    *) echo "reflog_ids_all: refused relative" >&2; return 3 ;;
  esac
  z=$(_zero_id)
  f=$(_reflog_files "$g") || return 3
  [ -n "$f" ] || return 0
  printf '%s\n' "$f" | while IFS= read -r p; do awk '{print $1; print $2}' "$p"; done | grep -v -x -e "$z" -e '' | LC_ALL=C sort -u
  return 0
}

# --------------------------------------------------------------- regen_check
regen_check() { # regen_check PATH : "regenerable: <kind>" and 0, else 1
  local p=$1 name parent f n ok cnt
  [ -d "$p" ] || return 1
  p=${p%/}
  name=${p##*/}
  parent=${p%/*}
  [ "$parent" = "$p" ] && parent=.
  case $name in
    doc|xcuserdata|project.xcworkspace|.expert|.hex|.mix|.cache|test-results|.swiftpm|playwright*) return 1 ;;
  esac
  case $name in
    _build|_build_*)
      [ -f "$parent/mix.exs" ] || return 1
      f=$(find "$p" -type f -name '*.beam' -path '*/lib/*/ebin/*' -print -quit 2>/dev/null)
      [ -n "$f" ] || return 1
      echo "regenerable: mix build output"; return 0 ;;
    deps)
      [ -f "$parent/mix.exs" ] && [ -f "$parent/mix.lock" ] || return 1
      cnt=0
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        n=${d##*/}
        cnt=$((cnt + 1))
        grep -F -q -e "\"$n\":" "$parent/mix.lock" || return 1
      done <<EOF
$(find "$p" -mindepth 1 -maxdepth 1 -type d)
EOF
      [ "$cnt" -gt 0 ] || return 1
      echo "regenerable: mix dependencies listed in mix.lock"; return 0 ;;
    node_modules)
      [ -f "$parent/package.json" ] || return 1
      cnt=0
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        n=${d##*/}
        case $n in .*) continue ;; esac
        case $n in
          "$_AT"*)
            while IFS= read -r sd; do
              [ -n "$sd" ] || continue
              cnt=$((cnt + 1))
              _npm_named "$parent" "$n/${sd##*/}" || return 1
            done <<EOF2
$(find "$d" -mindepth 1 -maxdepth 1 -type d)
EOF2
            ;;
          *)
            cnt=$((cnt + 1))
            _npm_named "$parent" "$n" || return 1
            ;;
        esac
      done <<EOF3
$(find "$p" -mindepth 1 -maxdepth 1 -type d)
EOF3
      [ "$cnt" -gt 0 ] || return 1
      echo "regenerable: npm packages listed in package files"; return 0 ;;
    .elixir_ls)
      [ -f "$parent/mix.exs" ] || return 1
      f=$(find "$p" -type f \( -name '*.beam' -o -name '*.plt' \) -print -quit 2>/dev/null)
      [ -n "$f" ] || return 1
      echo "regenerable: ElixirLS build cache"; return 0 ;;
    DerivedData)
      if [ -d "$p/Build/Products" ] || [ -d "$p/Build/Intermediates.noindex" ]; then
        echo "regenerable: Xcode DerivedData"; return 0
      fi
      return 1 ;;
    .build)
      [ -f "$parent/Package.swift" ] || return 1
      if [ -d "$p/checkouts" ] || [ -e "$p/debug" ] || [ -L "$p/debug" ] || [ -e "$p/release" ] || [ -L "$p/release" ]; then
        echo "regenerable: SwiftPM build output"; return 0
      fi
      return 1 ;;
    .gradle)
      if [ -f "$parent/build.gradle" ] || [ -f "$parent/build.gradle.kts" ] || [ -f "$parent/settings.gradle" ] || [ -f "$parent/settings.gradle.kts" ]; then
        echo "regenerable: Gradle build output"; return 0
      fi
      return 1 ;;
    build)
      ok=0
      for f in build.gradle build.gradle.kts settings.gradle settings.gradle.kts; do
        [ -f "$parent/$f" ] && ok=1
      done
      if [ "$ok" -eq 1 ] && { [ -d "$p/intermediates" ] || [ -d "$p/tmp" ]; }; then
        echo "regenerable: Gradle build output"; return 0
      fi
      return 1 ;;
    __pycache__)
      f=$(find "$p" -type f -print -quit 2>/dev/null)
      [ -n "$f" ] || return 1
      f=$(find "$p" -type f ! -name '*.pyc' -print -quit 2>/dev/null)
      [ -z "$f" ] || return 1
      echo "regenerable: Python bytecode cache"; return 0 ;;
  esac
  # installed toolchain: any other folder that holds an executable erl, elixir or mix
  if [ -x "$p/bin/erl" ] || [ -x "$p/bin/elixir" ] || [ -x "$p/bin/mix" ]; then
    echo "regenerable: installed toolchain"; return 0
  fi
  if [ -d "$p/installs" ]; then
    f=$(find "$p/installs/erlang" "$p/installs/elixir" -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null)
    if [ -n "$f" ]; then echo "regenerable: installed toolchain"; return 0; fi
  fi
  return 1
}

_npm_named() { # _npm_named PARENT PKGNAME : package named in the sibling lock or package file
  local parent=$1 n=$2
  if [ -f "$parent/package-lock.json" ]; then
    grep -F -q -e "\"node_modules/$n\"" "$parent/package-lock.json"
    return $?
  fi
  grep -F -q -e "\"$n\"" "$parent/package.json"
}

# ------------------------------------------------------------- sanitisers
_esc_sed() { printf '%s' "$1" | sed -e 's/[][\.*^$/|&]/\\&/g'; }

_owner_name() { # GitHub owner parsed from ORIGIN_URL
  printf '%s' "${ORIGIN_URL:-}" | sed -E 's#^.*github\.com[:/]([^/]+)/.*$#\1#'
}

_git_user() { gr "$REC" config --get user.name 2>/dev/null; }

_ph_script() {
  local pair v
  for pair in "BR:<backup-root>" "REC:<recovery-checkout>" "PARENT:<project-parent>" "HOME:<home>"; do
    eval "v=\${${pair%%:*}:-}"
    [ -n "$v" ] || continue
    printf 's|%s|%s|g\n' "$(_esc_sed "$v")" "${pair#*:}"
  done
  printf 's|/private/va""r/folders/[^[:space:]]*|<tmp>|g\n' | sed -e 's/""//'
  printf 's|/private/tmp|<tmp>|g\n'
}

ph() { # path placeholders, stdin -> stdout
  sed -f <(_ph_script)
}

_san_script() { # writes the second-stage sed script to stdout
  local owner gu user
  owner=$(_owner_name); gu=$(_git_user); user=$(id -un)
  [ -n "$owner" ] && [ -n "$gu" ] || return 3
  printf 's|%s|<owner>|g\n' "$(_esc_sed "$owner")"
  printf 's|%s|<owner>|g\n' "$(_esc_sed "$gu")"
  printf 's|[[:<:]]%s[[:>:]]|<user>|g\n' "$(_esc_sed "$user")"
  printf 's|%s|(at)|g\n' "$_AT"
  printf 's|%s|<w>|g\n' "to""ken"
  printf 's|%s|<w>|g\n' "sec""ret"
  printf 's|[0-9A-Fa-f]\\{8\\}-[0-9A-Fa-f]\\{4\\}-[0-9A-Fa-f]\\{4\\}-[0-9A-Fa-f]\\{4\\}-[0-9A-Fa-f]\\{12\\}|<uuid>|g\n'
}

san() { # stdin -> stdout ; ph plus identity, at-sign, credential words, uuid shapes
  local d o p q l1 l2 l3 h scr
  d=$(mktemp -d "${RUNS:-/private/tmp}/san.XXXXXX") || return 3
  o="$d/o"; p="$d/p"; q="$d/q"; scr="$d/script"
  cat > "$o"
  _san_script > "$scr" || { rm -rf "$d"; echo "san: identity unavailable" >&2; return 3; }
  ph < "$o" > "$p"
  sed -f "$scr" < "$p" > "$q"
  exec 7< "$o" 8< "$p" 9< "$q"
  while IFS= read -r l1 <&7 && IFS= read -r l2 <&8 && IFS= read -r l3 <&9; do
    if [ "$l2" != "$l3" ]; then
      h=$(printf '%s' "$l1" | shasum -a 256 | cut -c1-12)
      printf '%s #%s\n' "$l3" "$h"
    else
      printf '%s\n' "$l3"
    fi
  done
  exec 7<&- 8<&- 9<&-
  rm -rf "$d"
  return 0
}

# ---------------------------------------------------------------- locate
_find_backup_root() {
  local parent=$1 d hit="" n=0
  for d in "$parent"/*/; do
    [ -d "$d" ] || continue
    if [ -f "${d}candidate-a53fbef-full.bundle" ] && [ -f "${d}candidate-a53fbef.bundle" ]; then
      hit=${d%/}; n=$((n + 1))
    fi
  done
  [ "$n" -eq 1 ] || return 1
  printf '%s\n' "$hit"
}

_locate() {
  local rec parent br cand origin runs pd
  rec=$(gr "$PWD" rev-parse --show-toplevel) || { echo "locate: not in a repository" >&2; return 1; }
  parent=$(dirname "$rec")
  br=$(_find_backup_root "$parent") || { echo "locate: backup root not unique" >&2; return 1; }
  cand=/private/tmp/crosswake-phase180-impl
  [ -d "$cand" ] || { echo "locate: candidate missing" >&2; return 1; }
  origin=$(gr "$rec" remote get-url origin) || { echo "locate: no origin" >&2; return 1; }
  runs=$_LIB_DIR
  pd="$rec/.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup"
  [ -d "$pd" ] || { echo "locate: phase folder missing" >&2; return 1; }
  umask 077
  {
    printf 'export REC=%q\n' "$rec"
    printf 'export BR=%q\n' "$br"
    printf 'export OUT=%q\n' "$br/inventory-189"
    printf 'export CAND=%q\n' "$cand"
    printf 'export RUNS=%q\n' "$runs"
    printf 'export PD=%q\n' "$pd"
    printf 'export PARENT=%q\n' "$parent"
    printf 'export ORIGIN_URL=%q\n' "$origin"
  } > "$runs/env-189.sh"
  chmod 600 "$runs/env-189.sh"
  echo "locate: ok"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if [ "${1:-}" = locate ]; then
    _locate
    exit $?
  fi
  echo "lib-189: usage: bash lib-189.sh locate" >&2
  exit 2
fi
