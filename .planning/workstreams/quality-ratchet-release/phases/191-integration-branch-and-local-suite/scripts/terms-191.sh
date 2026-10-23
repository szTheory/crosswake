# Phase 191 denylist term loader (D-18, A-13). POSIX sh; meant to be sourced:  . terms-191.sh
# Needs DENY (and REC, IC, D) from env-191.sh. Exports CROSSWAKE_PRIVATE_ADOPTER_TERMS into the
# current shell only. Prints one fixed label and never a term, a path or a hash.
# Returns 0 when at least one term loaded, 2 otherwise.
# TERMS191_TMP overrides the temp folder prefix (self-test only).

terms191_load() {
  _t191_f=${DENY:-}
  _t191_tmp=${TERMS191_TMP:-/private/tmp}
  if [ -z "$_t191_f" ]; then echo "terms: denylist missing"; return 2; fi
  if [ ! -e "$_t191_f" ] && [ ! -L "$_t191_f" ]; then echo "terms: denylist missing"; return 2; fi
  if [ -L "$_t191_f" ] || [ ! -f "$_t191_f" ]; then echo "terms: denylist unsafe"; return 2; fi
  _t191_uid=$(id -u)
  _t191_own=$(stat -f %u "$_t191_f" 2>/dev/null)
  _t191_mode=$(stat -f %Lp "$_t191_f" 2>/dev/null)
  if [ "$_t191_own" != "$_t191_uid" ] || [ "$_t191_mode" != "600" ]; then echo "terms: denylist unsafe"; return 2; fi
  _t191_dir=$(cd "$(dirname "$_t191_f")" 2>/dev/null && pwd -P)
  if [ -z "$_t191_dir" ]; then echo "terms: denylist missing"; return 2; fi
  _t191_abs="$_t191_dir/$(basename "$_t191_f")"
  _t191_tmp2=/tmp
  [ -z "${TERMS191_TMP:-}" ] || _t191_tmp2=
  for _t191_x in "${REC:-}" "${IC:-}" "${D:-}" "$_t191_tmp" "$_t191_tmp2"; do
    [ -n "$_t191_x" ] || continue
    _t191_xp=$(cd "$_t191_x" 2>/dev/null && pwd -P) || _t191_xp=$_t191_x
    case "$_t191_abs" in
      "$_t191_xp"|"$_t191_xp"/*) echo "terms: denylist inside repo or tmp"; return 2 ;;
    esac
  done
  _t191_terms=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$_t191_f" | awk 'NF')
  if [ -z "$_t191_terms" ]; then echo "terms: none"; return 2; fi
  case "$_t191_terms" in *,*) echo "terms: comma in term"; return 2 ;; esac
  _t191_n=$(printf '%s\n' "$_t191_terms" | wc -l | tr -d ' ')
  CROSSWAKE_PRIVATE_ADOPTER_TERMS=$(printf '%s\n' "$_t191_terms" | paste -sd, -)
  export CROSSWAKE_PRIVATE_ADOPTER_TERMS
  echo "terms: loaded $_t191_n"
  return 0
}
terms191_load
_t191_rc=$?
unset _t191_tmp2 _t191_f _t191_tmp _t191_uid _t191_own _t191_mode _t191_dir _t191_abs _t191_x _t191_xp _t191_terms _t191_n
return $_t191_rc
