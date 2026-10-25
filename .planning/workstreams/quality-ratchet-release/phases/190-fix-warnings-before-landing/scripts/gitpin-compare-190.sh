#!/bin/sh
# Phase 190 FIX-03 comparison (D-05): the shared shell git helper and the Elixir funnel
# must give the same answer under a misleading global git config, the Phase 188 helper
# must not, and the helper's lists must equal GitPins. Fixed labels only.
# env: G190_MIX_ROOT (Elixir clone with a build), G190_OLD_GATE (188 run-once-05.sh),
#      optional MIX_BUILD_PATH. usage: gitpin-compare-190.sh [--tracer]
set -u
umask 077
SD=$(cd "$(dirname "$0")" && pwd -P) || exit 2
HELPER="$SD/git-pinned-190.sh"
TRACER=0
[ "${1:-}" = "--tracer" ] && TRACER=1
[ -r "$HELPER" ] || { echo "gitpin-compare: driver error"; exit 2; }
[ -n "${G190_MIX_ROOT:-}" ] && [ -d "$G190_MIX_ROOT" ] || { echo "gitpin-compare: driver error"; exit 2; }
[ -n "${G190_OLD_GATE:-}" ] && [ -r "$G190_OLD_GATE" ] || { echo "gitpin-compare: driver error"; exit 2; }

REAL_HOME=$HOME
if [ -n "${MIX_HOME:-}" ]; then
  REAL_MIX_HOME=$MIX_HOME
else
  # resolve the real mix home while HOME is still the real one
  REAL_MIX_HOME=$(cd "$G190_MIX_ROOT" && MIX_ENV=test mix eval 'IO.puts(Mix.Utils.mix_home())' 2>/dev/null | tail -n 1)
fi
[ -n "$REAL_MIX_HOME" ] || { echo "gitpin-compare: driver error"; exit 2; }
REAL_HEX_HOME=${HEX_HOME:-$HOME/.hex}
REAL_ASDF=${ASDF_DATA_DIR:-$HOME/.asdf}

TR=$(mktemp -d /private/tmp/crosswake-gitpin-190.XXXXXX) || { echo "gitpin-compare: driver error"; exit 2; }
trap 'rm -rf "$TR"' EXIT
trap 'exit 2' INT TERM HUP

exec 3>&1
die() { echo "gitpin-compare: driver error" >&3; exit 2; }
refused() { echo "gitpin-compare: fixture refused" >&3; exit 2; }
FX=0
TOTAL=0
OK=0

# mk_fixture VARIANT -> sets T (fixture root). hostile = executable bit set; clean = untouched.
mk_fixture() {
  FX=$((FX + 1))
  T="$TR/fx$FX"
  mkdir -p "$T/repo" "$T/home" || die
  printf '[core]\n\tfileMode = false\n' > "$T/home/.gitconfig"
  (
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=fx GIT_AUTHOR_EMAIL=fx.invalid
    export GIT_COMMITTER_NAME=fx GIT_COMMITTER_EMAIL=fx.invalid
    git init -q "$T/repo" &&
      printf 'one\n' > "$T/repo/f" &&
      git -C "$T/repo" add f &&
      git -C "$T/repo" commit -q -m init &&
      { git -C "$T/repo" config --local --unset core.filemode || true; }
  ) >/dev/null 2>&1 || die
  if [ "$1" = hostile ]; then chmod +x "$T/repo/f" || die; fi
}

# shell_new MODE -> dirty|clean (stdout); non-zero on driver failure
shell_new() {
  (
    case "$1" in
      home) HOME="$T/home"; export HOME ;;
      global) GIT_CONFIG_GLOBAL="$T/home/.gitconfig"; export GIT_CONFIG_GLOBAL ;;
    esac
    . "$HELPER" || exit 2
    CAND="$T/repo"
    g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none > "$TR/st.out" 2>/dev/null || exit 2
    if [ -s "$TR/st.out" ]; then echo dirty; else echo clean; fi
  )
}

# shell_old MODE -> same, with the verbatim Phase 188 g() read from the old gate
shell_old() {
  awk '/^g\(\) \{/{p=1} p{print} p&&/^\}/{exit}' "$G190_OLD_GATE" > "$TR/oldg.sh" || return 2
  [ -s "$TR/oldg.sh" ] || return 2
  (
    case "$1" in
      home) HOME="$T/home"; export HOME ;;
      global) GIT_CONFIG_GLOBAL="$T/home/.gitconfig"; export GIT_CONFIG_GLOBAL ;;
    esac
    . "$TR/oldg.sh" || exit 2
    CAND="$T/repo"
    g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none > "$TR/st.out" 2>/dev/null || exit 2
    if [ -s "$TR/st.out" ]; then echo dirty; else echo clean; fi
  )
}

# mixrun CODE MODE -> runs Elixir code in the mix root with the same hostile setting
mixrun() {
  (
    case "$2" in
      home) HOME="$T/home"; export HOME ;;
      global) GIT_CONFIG_GLOBAL="$T/home/.gitconfig"; export GIT_CONFIG_GLOBAL ;;
    esac
    G190_PROBE_PATH="$T/repo"
    export G190_PROBE_PATH MIX_ENV=test MIX_HOME="$REAL_MIX_HOME" HEX_HOME="$REAL_HEX_HOME" ASDF_DATA_DIR="$REAL_ASDF"
    cd "$G190_MIX_ROOT" || exit 2
    mix run --no-start --no-deps-check -e "$1"
  )
}

ELIXIR_PROBE='case Crosswake.ProofLane.TwinProducers.probe_source(System.fetch_env!("G190_PROBE_PATH")) do
  {:ok, %{modified: m, flagged: f, excludes: e}} -> IO.puts(if m + f + e > 0, do: "probe: dirty", else: "probe: clean")
  _ -> IO.puts("probe: other")
end'

# elixir MODE -> dirty|clean in $TR/val
elixir() {
  mixrun "$ELIXIR_PROBE" "$1" > "$TR/mix.out" 2>"$TR/mix.err" || die
  line=$(grep '^probe: ' "$TR/mix.out" | tail -n 1)
  case "$line" in
    'probe: dirty') echo dirty ;;
    'probe: clean') echo clean ;;
    'probe: other') refused ;;
    *) die ;;
  esac
}

compare() { if [ "$1" = "$2" ]; then echo agree; else echo disagree; fi; }

# val_into_file CMD... : run, put stdout in $TR/val, driver error on failure
val() { "$@" > "$TR/val" 2>/dev/null || die; V=$(cat "$TR/val"); }

run_ctl() {
  _id=$1; _desc=$2; shift 2
  TOTAL=$((TOTAL + 1))
  if "$@"; then
    OK=$((OK + 1)); echo "$_id $_desc: as expected"
  else
    echo "$_id $_desc: NOT as expected"
  fi
}

finish() {
  if [ "$TRACER" -eq 1 ]; then _w="tracer controls"; else _w="controls"; fi
  echo "gitpin-compare: $_w $OK of $TOTAL as expected"
  [ "$OK" -eq "$TOTAL" ] && exit 0
  exit 1
}

# ---- controls ----------------------------------------------------------------
ctl_g01() { mk_fixture hostile; val shell_new home; a=$V; val elixir home; b=$V; [ "$a" = dirty ] && [ "$b" = dirty ] && [ "$(compare "$a" "$b")" = agree ]; }
ctl_g02() { mk_fixture hostile; val shell_old home; a=$V; val elixir home; b=$V; [ "$a" = clean ] && [ "$b" = dirty ] && [ "$(compare "$a" "$b")" = disagree ]; }
ctl_g03() { mk_fixture clean; val shell_new home; a=$V; val elixir home; b=$V; [ "$a" = clean ] && [ "$b" = clean ] && [ "$(compare "$a" "$b")" = agree ]; }
ctl_g04() { mk_fixture hostile; val shell_new global; a=$V; val elixir global; b=$V; [ "$a" = dirty ] && [ "$b" = dirty ] && [ "$(compare "$a" "$b")" = agree ]; }
ctl_g05() { mk_fixture hostile; val shell_old global; a=$V; val elixir global; b=$V; [ "$a" = clean ] && [ "$b" = dirty ] && [ "$(compare "$a" "$b")" = disagree ]; }
ctl_g06() {
  mk_fixture hostile
  rm -f "$T/trace"
  (
    GIT_DIR="$T/nonexistent-git-dir"; GIT_TRACE="$T/trace"; export GIT_DIR GIT_TRACE
    shell_new none
  ) > "$TR/val" 2>/dev/null || return 1
  [ "$(cat "$TR/val")" = dirty ] && [ ! -e "$T/trace" ]
}

ELIXIR_DESCRIBE='for {n, v} <- Crosswake.ProofLane.GitPins.env(), do: IO.puts("env #{n}=#{v || "<unset>"}")
for p <- Crosswake.ProofLane.GitPins.pins(), do: IO.puts("pin #{p}")'

# prints "same" or "drift" for the helper at path $1
drift_check() {
  mk_fixture clean
  mixrun "$ELIXIR_DESCRIBE" none > "$TR/d.mix" 2>/dev/null || die
  grep '^env ' "$TR/d.mix" | LC_ALL=C sort > "$TR/d.env.ex"
  grep '^pin ' "$TR/d.mix" > "$TR/d.pin.ex"
  [ -s "$TR/d.env.ex" ] && [ -s "$TR/d.pin.ex" ] || die
  ( . "$1" || exit 2; g190_describe ) > "$TR/d.sh" 2>/dev/null || die
  grep '^env ' "$TR/d.sh" | LC_ALL=C sort > "$TR/d.env.sh"
  grep '^pin ' "$TR/d.sh" > "$TR/d.pin.sh"
  if cmp -s "$TR/d.env.ex" "$TR/d.env.sh" && cmp -s "$TR/d.pin.ex" "$TR/d.pin.sh"; then echo same; else echo drift; fi
}

ctl_g07() { val drift_check "$HELPER"; [ "$V" = same ]; }
ctl_g08() {
  sed 's#core.hooksPath=/dev/null#core.hooksPath=/tmp/x#' "$HELPER" > "$TR/h08.sh" || die
  cmp -s "$HELPER" "$TR/h08.sh" && die
  val drift_check "$TR/h08.sh"; [ "$V" = drift ]
}
ctl_g09() {
  sed 's/ GIT_EXEC_PATH"/"/' "$HELPER" > "$TR/h09.sh" || die
  cmp -s "$HELPER" "$TR/h09.sh" && die
  val drift_check "$TR/h09.sh"; [ "$V" = drift ]
}
ctl_g10() {
  _f="$G190_MIX_ROOT/lib/crosswake/proof_lane/twin_producers.ex"
  _a=$(printf '\100')
  grep -qF "${_a}git_env GitPins.env()" "$_f" && grep -qF "${_a}git_pins GitPins.pins()" "$_f"
}
ctl_g11() {
  [ "$(grep -h '^g() {' "$SD"/* 2>/dev/null | wc -l | tr -d ' ')" -eq 1 ] || return 1
  [ "$(grep -l '^g() {' "$SD"/* 2>/dev/null)" = "$HELPER" ] || return 1
  grep -q 'git-pinned-190\.sh' "$SD/run-once-05-190.sh" && grep -q '^H=.*git-pinned-190\.sh.*\. "\$H"' "$SD/run-once-05-190.sh"
}

run_ctl G01 "hostile temp-HOME config, shell helper and funnel agree (dirty)" ctl_g01
run_ctl G02 "hostile temp-HOME config, Phase 188 helper reads clean and disagrees with the funnel" ctl_g02
run_ctl G03 "clean tree, shell helper and funnel both clean" ctl_g03
if [ "$TRACER" -eq 1 ]; then finish; fi
run_ctl G04 "hostile GIT_CONFIG_GLOBAL config, shell helper and funnel agree (dirty)" ctl_g04
run_ctl G05 "hostile GIT_CONFIG_GLOBAL config, Phase 188 helper disagrees with the funnel" ctl_g05
run_ctl G06 "inherited GIT_DIR and GIT_TRACE ignored by the shell helper" ctl_g06
run_ctl G07 "helper lists equal GitPins env and pins" ctl_g07
run_ctl G08 "drift control: changed pin is reported as drift" ctl_g08
run_ctl G09 "drift control: removed scrub name is reported as drift" ctl_g09
run_ctl G10 "funnel binds GitPins env and pins" ctl_g10
run_ctl G11 "exactly one g() in the phase scripts and the run gate sources it" ctl_g11
finish
