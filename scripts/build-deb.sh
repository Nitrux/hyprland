#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 <Nitrux Latinoamericana S.C. <hello@nxos.org>>

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_root="$repo_root/build"
target_arch="${TARGET_ARCH:-$(dpkg --print-architecture)}"
version_file="$repo_root/VERSION"

if [ ! -f "$version_file" ]; then
    printf 'The repository VERSION file is missing.\n' >&2
    exit 1
fi

repository_version="$(tr -d '[:space:]' < "$version_file")"
if [ -z "$repository_version" ]; then
    printf 'The repository VERSION file is empty.\n' >&2
    exit 1
fi

packages=(
    hyprland-data
    hyprutils
    hyprwayland-scanner
    hyprland-protocols
    hyprlang
    hyprcursor
    hyprgraphics
    aquamarine
    libxcb-errors
    sdbus-cpp
    udis86
    hyprwire
    glaze
    hyprtoolkit
    hyprland-qt-support
    hyprland-guiutils
    hyprland
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprpolkitagent
    hyprlauncher
    hyprpwcenter
    hyprshutdown
    hyprsunset
    hyprsysteminfo
    xdg-desktop-portal-hyprland
    hyprland-plugin-deps
    hyprland-plugins
)

work_root="$(mktemp -d)"
trap 'rm -rf "$work_root"' EXIT

mkdir -p "$build_root"
find "$build_root" -maxdepth 1 -type f -name '*.deb' -delete
shopt -s nullglob

declare -A existing_debs=()

archive_source_tree() {
    local source_path="$1"
    local destination_path="$2"
    local submodule_path
    local submodule_mode

    git -C "$source_path" archive --format=tar HEAD | tar -xf - -C "$destination_path"

    if [ -f "$source_path/.gitmodules" ]; then
        while read -r _ submodule_path; do
            [ -n "$submodule_path" ] || continue
            submodule_mode="$(git -C "$source_path" ls-tree HEAD -- "$submodule_path")"
            if [ "${submodule_mode%% *}" != 160000 ]; then
                continue
            fi
            if [ ! -d "$source_path/$submodule_path" ]; then
                printf "%s\n" "The nested source submodule is not initialized: $source_path/$submodule_path" >&2
                exit 1
            fi
            mkdir -p "$destination_path/$submodule_path"
            archive_source_tree "$source_path/$submodule_path" "$destination_path/$submodule_path"
        done < <(git -C "$source_path" config --file .gitmodules --get-regexp path)
    fi
}

stage_package() {
    local package="$1"
    local source_dir="$repo_root/$package/source"
    local package_dir="$work_root/$package"
    local source_mode

    mkdir -p "$package_dir"
    if [ ! -d "$source_dir" ] || [ -z "$(find "$source_dir" -mindepth 1 -print -quit)" ]; then
        if [ "$package" = hyprland-plugin-deps ]; then
            cp -a "$repo_root/$package/debian" "$package_dir/"
            return
        fi
        printf 'The %s source is missing or empty. Initialize all submodules first.\n' "$package" >&2
        exit 1
    fi

    source_mode="$(git -C "$repo_root" ls-files --stage -- "$package/source" | awk 'NR == 1 {print $1}')"
    if [ "$source_mode" = 160000 ]; then
        if ! git -C "$source_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
            printf 'The %s source submodule is not initialized.\n' "$package" >&2
            exit 1
        fi
        archive_source_tree "$source_dir" "$package_dir"
    else
        cp -a "$source_dir"/. "$package_dir/"
    fi
    cp -a "$repo_root/$package/debian" "$package_dir/"
}

prepare_package() {
    local package="$1"

    if [ -f "$repo_root/$package/prepare.sh" ]; then
        # shellcheck disable=SC2034
        (
            sourcefolder="$repo_root/$package/source"
            buildfolder="$work_root/$package"
            debianfolder="$repo_root/$package/debian"
            # shellcheck source=hyprland/prepare.sh
            # shellcheck disable=SC1091
            . "$repo_root/$package/prepare.sh"
        )
    fi
}

set_package_version() {
    local package="$1"
    local package_dir="$work_root/$package"
    local source_package
    local package_version

    source_package="$(awk -F': ' '$1 == "Source" {print $2; exit}' "$package_dir/debian/control")"
    package_version="$repository_version"

    if [ -z "$source_package" ] || [ -z "$package_version" ]; then
        printf 'Unable to determine the package name or version for %s.\n' "$package" >&2
        exit 1
    fi

    sed -i -E "1s|^.*$|$source_package ($package_version) nitrux; urgency=medium|" \
        "$package_dir/debian/changelog"
}

for package in "${packages[@]}"; do
    stage_package "$package"
done

for package in "${packages[@]}"; do
    prepare_package "$package"
    set_package_version "$package"
done

install_built_packages() {
    local package="$1"
    local deb
    local -a new_debs=()
    local -a dpkg_command=(dpkg --install)
    local -a apt_command=(apt-get)

    for deb in "$work_root"/*.deb; do
        if [ -z "${existing_debs[$deb]+present}" ]; then
            new_debs+=("$deb")
            existing_debs["$deb"]=present
        fi
    done

    if [ "${#new_debs[@]}" -eq 0 ]; then
        printf 'The %s build did not produce a Debian package.\n' "$package" >&2
        exit 1
    fi

    if [ "$EUID" -ne 0 ]; then
        dpkg_command=(sudo dpkg --install)
        apt_command=(sudo apt-get)
    fi

    if ! "${dpkg_command[@]}" "${new_debs[@]}"; then
        "${apt_command[@]}" --fix-broken install -y
    fi
}

for package in "${packages[@]}"; do
    (
        cd "$work_root/$package"
        dpkg-buildpackage \
            -b \
            -a "$target_arch" \
            -us \
            -uc \
            -d \
            -j"$(nproc)"
    )
    install_built_packages "$package"
done

find "$work_root" -maxdepth 1 -type f -name '*.deb' -exec cp -f {} "$build_root/" \;

packages=("$build_root"/*.deb)
if [ "${#packages[@]}" -eq 0 ]; then
    echo 'No Debian packages were generated.' >&2
    exit 1
fi

printf 'Generated packages:\n'
printf '  %s\n' "${packages[@]}"
