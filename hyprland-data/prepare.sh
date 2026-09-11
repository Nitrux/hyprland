#!/bin/bash

# shellcheck disable=SC2154
# sourcefolder, buildfolder, and debianfolder are supplied by the package builder.
set -xe
cd "$sourcefolder"

: Copy install assets from Hyprland source
[ -d "$buildfolder/assets" ] || mkdir -p "$buildfolder/assets"
cp -ra ../../hyprland/source/assets/install/*.png "$buildfolder/assets"
