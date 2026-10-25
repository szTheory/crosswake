#!/usr/bin/env bash
# manifest-189.sh NAME FILE... - writes OUT/NAME with sha256 lines; names relative to OUT
# (../ names are allowed for the two existing candidate bundles). Refuses an empty file list.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
MOUT=${MANIFEST_OUT:-$OUT}
[ "$#" -ge 2 ] || { echo "manifest: refused empty file list" >&2; exit 2; }
NAME=$1
shift
case $NAME in
  */*|'') echo "manifest: bad name" >&2; exit 2 ;;
esac
[ -d "$MOUT" ] || { echo "manifest: output folder missing" >&2; exit 1; }
TMPM=$(mktemp "$MOUT/.manifest.XXXXXX") || exit 1
for f; do
  if [ ! -f "$MOUT/$f" ]; then
    rm -f "$TMPM"
    echo "manifest: file missing" >&2
    exit 1
  fi
  line=$(cd "$MOUT" && shasum -a 256 "$f") || { rm -f "$TMPM"; echo "manifest: hash failed" >&2; exit 1; }
  printf '%s\n' "$line" >> "$TMPM"
done
mv "$TMPM" "$MOUT/$NAME" || { rm -f "$TMPM"; exit 1; }
n=$(awk 'END{print NR}' "$MOUT/$NAME")
echo "manifest $NAME: $n lines"
exit 0
