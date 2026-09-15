# Resolve a phase-evidence path whether its phase directory is live or archived.
#
# `/gsd-complete-milestone` MOVES every phase directory from
# `.planning/workstreams/<ws>/phases/<phase>` to
# `.planning/workstreams/<ws>/milestones/<version>-phases/<phase>`. A script that
# hardcodes the live path passes for the whole life of a milestone and then
# breaks, all at once, the moment that milestone ships.
#
# When neither location exists this echoes the LIVE path, so the caller fails
# with a missing-file error naming the location a reader would expect rather
# than silently finding nothing to check.
crosswake_phase_evidence_path() {
  local ws="$1" rel="$2"
  local live=".planning/workstreams/${ws}/phases/${rel}"
  if [ -e "$live" ]; then
    printf '%s\n' "$live"
    return 0
  fi
  local match
  # A phase directory is only ever archived once; `sort | tail -1` just keeps
  # the choice deterministic.
  match=$(ls -d .planning/workstreams/"${ws}"/milestones/*-phases/"${rel}" 2>/dev/null | sort | tail -1)
  printf '%s\n' "${match:-$live}"
}
