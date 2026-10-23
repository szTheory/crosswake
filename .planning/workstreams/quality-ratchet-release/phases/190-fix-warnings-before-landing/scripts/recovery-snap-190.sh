#!/bin/sh
# Digest-only snapshot of a .git folder, read as files. Input: REC_GIT.
set -u
export LC_ALL=C
G=${REC_GIT:?}
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
