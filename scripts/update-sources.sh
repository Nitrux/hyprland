#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 <Nitrux Latinoamericana S.C. <hello@nxos.org>>

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
package_filter=""
tag_override=""
update_all=false

usage() {
    cat <<\EOF
Usage:
  ./scripts/update-sources.sh --all
  ./scripts/update-sources.sh --package PACKAGE [--tag TAG]

Update package source submodules to upstream release tags. Builds do not run
this updater, so source revisions remain pinned and reproducible.

Options:
  --all              Update every stable-build source with a release tag.
  --package NAME    Update one package source.
  --tag TAG         Use an explicit tag for --package.
  -h, --help        Show this help.
EOF
}

while (($# > 0)); do
    case "$1" in
        --all)
            update_all=true
            ;;
        --package)
            (($# >= 2)) || { printf "%s\n" "--package requires a value." >&2; usage >&2; exit 2; }
            package_filter="$2"
            shift
            ;;
        --tag)
            (($# >= 2)) || { printf "%s\n" "--tag requires a value." >&2; usage >&2; exit 2; }
            tag_override="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf "Unknown option: %s\n" "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ "$update_all" == true && -n "$package_filter" ]]; then
    printf "%s\n" "--all and --package cannot be used together." >&2
    exit 2
fi
if [[ -n "$tag_override" && -z "$package_filter" ]]; then
    printf "%s\n" "--tag requires --package." >&2
    exit 2
fi
if [[ "$update_all" == false && -z "$package_filter" ]]; then
    usage >&2
    exit 2
fi

source_path_for_package() {
    local package="$1"
    local key
    local path

    while read -r key path; do
        if [[ "$path" == "$package/source" ]]; then
            printf "%s\n" "$path"
            return 0
        fi
    done < <(git -C "$repo_root" config --file .gitmodules --get-regexp "^submodule\..*\.path$")

    return 1
}

latest_stable_tag() {
    local source_dir="$1"
    local tag
    local version
    local latest=""

    while IFS= read -r tag; do
        version="${tag#v}"
        if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ || "$tag" =~ ^[[:alnum:]][[:alnum:]._-]*-[v]?[0-9]+(\.[0-9]+)*$ ]]; then
            latest="$tag"
        fi
    done < <(git -C "$source_dir" tag --list | sort -V)

    printf "%s\n" "$latest"
}

requires_explicit_tag() {
    case "$1" in
        hyprland|hyprland-plugins) return 0 ;;
        *) return 1 ;;
    esac
}

update_package() {
    local package="$1"

    case "$package" in
        iio-hyprland|hyprspace|hyprsplit)
            printf "Package %s is excluded from the stable build.\n" "$package" >&2
            return 1
            ;;
    esac
    local source_path
    local source_dir
    local target_tag
    local current_revision
    local target_revision

    if ! source_path="$(source_path_for_package "$package")"; then
        printf "No source submodule is defined for package: %s\n" "$package" >&2
        return 1
    fi

    source_dir="$repo_root/$source_path"
    if [[ ! -d "$source_dir" ]] || ! git -C "$source_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
        printf "The %s source is not initialized.\n" "$package" >&2
        return 1
    fi
    if [[ -n "$(git -C "$source_dir" status --porcelain)" ]]; then
        printf "The %s source has local changes; refusing to update it.\n" "$package" >&2
        return 1
    fi

    printf "Fetching release tags for %s...\n" "$package"
    git -C "$source_dir" fetch --tags origin

    if [[ -z "$tag_override" ]] && requires_explicit_tag "$package"; then
        if [[ "$update_all" == true ]]; then
            printf "Skipping %s: use an explicit compatible release tag for this package.\n" "$package"
            return 0
        fi
        printf "Package %s requires an explicit --tag for stable updates.\n" "$package" >&2
        return 1
    fi

    if [[ -n "$tag_override" ]]; then
        target_tag="$tag_override"
    else
        target_tag="$(latest_stable_tag "$source_dir")"
        if [[ -z "$target_tag" ]]; then
            if [[ "$update_all" == true ]]; then
                printf "Skipping %s: no stable-looking release tag was found; use --package with --tag to update it.\n" "$package"
                return 0
            fi
            printf "No stable-looking release tag was found for %s; use --tag explicitly.\n" "$package" >&2
            return 1
        fi
    fi

    if ! target_revision="$(git -C "$source_dir" rev-parse --verify "refs/tags/$target_tag^{commit}")"; then
        printf "Tag %s was not found for %s.\n" "$target_tag" "$package" >&2
        return 1
    fi

    current_revision="$(git -C "$source_dir" rev-parse HEAD)"
    if [[ "$current_revision" == "$target_revision" ]]; then
        printf "%s is already pinned to %s.\n" "$package" "$target_tag"
        return 0
    fi

    git -C "$source_dir" checkout --detach "$target_tag"
    git -C "$source_dir" submodule update --init --recursive
    printf "%s: %s -> %s\n" "$package" "${current_revision:0:12}" "$target_tag"
}

if git -C "$repo_root" submodule status --recursive | grep -q "^-"; then
    printf "Initializing missing package sources...\n"
    git -C "$repo_root" submodule update --init --recursive
fi

if [[ "$update_all" == true ]]; then
    source_paths=()
    while read -r key source_path; do
        if [[ "$source_path" == */source ]]; then
            source_paths+=( "$source_path" )
        fi
    done < <(git -C "$repo_root" config --file .gitmodules --get-regexp "^submodule\..*\.path$")

    ((${#source_paths[@]} > 0)) || {
        printf "%s\n" "No package source submodules were found." >&2
        exit 1
    }

    for source_path in "${source_paths[@]}"; do
        package="${source_path%/source}"
        case "$package" in
            iio-hyprland|hyprspace|hyprsplit) continue ;;
        esac
        update_package "$package"
    done
else
    update_package "$package_filter"
fi

cat <<\EOF

Source updates are now present as submodule pointer changes.
Review them with git submodule status and commit the tested pointers together
with the matching VERSION and Debian changelog updates.
EOF
