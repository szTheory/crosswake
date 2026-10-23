#!/usr/bin/env bash
# Resolve package ownership independently of artifact manifests.
set -euo pipefail
[ "$#" -eq 4 ] || [ "$#" -eq 5 ] || exit 2
repo=$1 package=$2 version=$3 candidate=$4 mode=${5:-candidate}
case "$mode" in candidate|public) ;; *) exit 2 ;; esac
printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
printf '%s' "$candidate" | grep -Eq '^[0-9a-f]{40}$'
case "$package" in
  crosswake) git -C "$repo" cat-file -e "$candidate^{commit}"; printf '%s\n' "$candidate"; exit 0 ;;
  crosswake_rulestead|crosswake_rindle|crosswake_sigra|crosswake_chimeway|crosswake_threadline) ;;
  *) exit 2 ;;
esac
tag="refs/tags/$package-v$version"
# A failed provider read is fatal; only a successful empty read denotes an unpublished version.
refs=$(git -C "$repo" ls-remote --tags https://github.com/szTheory/crosswake.git "$tag" "$tag^{}")
if [ -z "$refs" ]; then
  [ "$mode" = candidate ] || exit 1
  git -C "$repo" cat-file -e "$candidate^{commit}"
  printf '%s\n' "$candidate"
else
  object=$(printf '%s\n' "$refs" | awk -v tag="$tag" '$2 == tag { print $1 }')
  printf '%s' "$object" | grep -Eq '^[0-9a-f]{40}$'
  # Checkout fetch-depth:0 supplies the object. Missing objects fail closed.
  git -C "$repo" rev-parse --verify "$object^{commit}"
fi
