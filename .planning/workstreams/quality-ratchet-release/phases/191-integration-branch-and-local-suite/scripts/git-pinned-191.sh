# Phase 191 shared pinned git helper (D-01, D-17b). POSIX sh; meant to be sourced.
# Loading it only assigns variables and defines functions. g() takes the repository
# as its first argument. Fixed labels only.
G191_EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
G191_SCRUB="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH"
G191_FIXED="GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 GIT_ATTR_NOSYSTEM=1 GIT_OPTIONAL_LOCKS=0 GIT_TERMINAL_PROMPT=0 LC_ALL=C"
G191_PINS="--no-optional-locks --no-replace-objects --attr-source=$G191_EMPTY_TREE -c core.fsmonitor=false -c core.filemode=true -c core.excludesFile=/dev/null -c core.attributesFile=/dev/null -c core.quotePath=false -c core.ignoreStat=false -c status.showUntrackedFiles=all -c core.autocrlf=false -c core.hooksPath=/dev/null -c core.ignorecase=false"

g() {
  if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then echo "g: repo missing"; return 2; fi
  _g191_repo=$1
  shift
  (
    for _n in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$_n"; done
    for _n in $(printf '%s\n' "$G191_SCRUB"); do unset "$_n"; done
    for _p in $(printf '%s\n' "$G191_FIXED"); do export "$_p"; done
    # word splitting via command substitution works in sh, bash and zsh
    exec git $(printf '%s\n' "$G191_PINS") -C "$_g191_repo" "$@"
  )
}

g191_describe() {
  {
    for _n in $(printf '%s\n' "$G191_SCRUB"); do printf 'env %s=<unset>\n' "$_n"; done
    for _p in $(printf '%s\n' "$G191_FIXED"); do printf 'env %s\n' "$_p"; done
  } | LC_ALL=C sort
  for _p in $(printf '%s\n' "$G191_PINS"); do printf 'pin %s\n' "$_p"; done
}
