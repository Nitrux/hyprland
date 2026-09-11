#!/bin/bash

# shellcheck disable=SC2154
# sourcefolder, buildfolder, and debianfolder are supplied by the package builder.
set -xe
cd "$sourcefolder"

: Hardcode version from git in patch
cat "$debianfolder/patches/00-version" |
  while IFS= read -r line; do
    case "$line" in
      +##*)
        cmd="${line#+## }"
        echo "$line"
        IFS= read -r line
        result="$(eval "$cmd" | sed 's/ \+$//')"
        prefix="${line%%<result>*}"
        suffix="${line##*<result>}"
        printf '%s%s%s\n' "$prefix" "$result" "$suffix"
        ;;
      *)
        echo "$line"
        ;;
    esac
  done > "$buildfolder/debian/patches/00-version"
