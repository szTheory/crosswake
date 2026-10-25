# Phase 190 shared pinned git helper (FIX-03, D-05). POSIX sh; meant to be sourced.
# Loading it only assigns variables and defines functions. Mirrors the Elixir funnel
# (git_scrub_names, git_fixed_env, git_pins in twin_producers.ex). Fixed labels only.
G190_EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
G190_SCRUB="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH"
G190_FIXED="GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 GIT_ATTR_NOSYSTEM=1 GIT_OPTIONAL_LOCKS=0 GIT_TERMINAL_PROMPT=0 LC_ALL=C"
G190_PINS="--no-optional-locks --no-replace-objects --attr-source=$G190_EMPTY_TREE -c core.fsmonitor=false -c core.filemode=true -c core.excludesFile=/dev/null -c core.attributesFile=/dev/null -c core.quotePath=false -c core.ignoreStat=false -c status.showUntrackedFiles=all -c core.autocrlf=false -c core.hooksPath=/dev/null -c core.ignorecase=false"

g() {
  (
    for _n in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$_n"; done
    for _n in $G190_SCRUB; do unset "$_n"; done
    for _p in $G190_FIXED; do export "$_p"; done
    # shellcheck disable=SC2086
    exec git $G190_PINS -C "$CAND" "$@"
  )
}

g190_describe() {
  {
    for _n in $G190_SCRUB; do printf 'env %s=<unset>\n' "$_n"; done
    for _p in $G190_FIXED; do printf 'env %s\n' "$_p"; done
  } | LC_ALL=C sort
  for _p in $G190_PINS; do printf 'pin %s\n' "$_p"; done
}
