#!/bin/sh
# Digest-only snapshot of a .git folder, read as files (D-23, WR-10). Input: REC_GIT.
# Optional: RECOVERY_SNAP_INDEX_OUT (a file inside the run folder) receives the raw ls-files -s output.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/git-pinned-191.sh"
G=${REC_GIT:-}
if [ -z "$G" ] || [ ! -d "$G" ]; then echo "recovery-snap: git folder missing"; exit 2; fi
if [ ! -f "$G/HEAD" ]; then echo "recovery-snap: HEAD missing"; exit 2; fi
if [ ! -f "$G/config" ]; then echo "recovery-snap: config missing"; exit 2; fi
sha() { shasum -a 256 | awk '{print $1}'; }
printf 'head_file_sha256 %s\n' "$(sha < "$G/HEAD")"
if [ -f "$G/packed-refs" ]; then printf 'packed_refs_sha256 %s\n' "$(sha < "$G/packed-refs")"; else echo "packed_refs absent"; fi
cnt=$(cd "$G" && find refs -type f | awk 'END{print NR+0}')
printf 'loose_refs_count %s\n' "$cnt"
printf 'loose_refs_sha256 %s\n' "$(cd "$G" && find refs -type f | sort | while IFS= read -r f; do shasum -a 256 "$f"; done | sha)"
if [ -f "$G/logs/refs/stash" ]; then printf 'stash_log_lines %s\n' "$(awk 'END{print NR+0}' "$G/logs/refs/stash")"; else echo "stash_log_lines 0"; fi
if [ -d "$G/worktrees" ]; then
  printf 'worktrees_count %s\n' "$(ls -1 "$G/worktrees" | awk 'END{print NR+0}')"
  printf 'worktrees_sha256 %s\n' "$(ls -1 "$G/worktrees" | sort | sha)"
else echo "worktrees absent"; fi
printf 'config_sha256 %s\n' "$(sha < "$G/config")"
TOP=$(dirname "$G")
TMPI=$(mktemp "${TMPDIR:-/private/tmp}/recovery-snap-index.XXXXXX") || exit 2
g "$TOP" ls-files -s > "$TMPI" 2>/dev/null
rc=$?
if [ "$rc" -ne 0 ]; then rm -f "$TMPI"; echo "recovery-snap: index read failed"; exit 2; fi
printf 'index_content_sha256 %s\n' "$(sha < "$TMPI")"
if [ -n "${RECOVERY_SNAP_INDEX_OUT:-}" ]; then cp "$TMPI" "$RECOVERY_SNAP_INDEX_OUT"; fi
rm -f "$TMPI"
if [ -f "$G/logs/HEAD" ]; then printf 'logs_head_sha256 %s\n' "$(sha < "$G/logs/HEAD")"; else echo "logs_head absent"; fi
printf 'object_files_count %s\n' "$(find "$G/objects" -type f | awk 'END{print NR+0}')"
