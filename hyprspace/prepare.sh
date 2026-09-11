#!/bin/bash

# shellcheck disable=SC2154
# sourcefolder, buildfolder, and debianfolder are supplied by the package builder.
set -xe
cd "$sourcefolder"

: Get rules from hyprland-plugins
cd "$buildfolder"
sed 's/^NAME ?=.*$/NAME ?= hyprspace/' "$sourcefolder/../../hyprland-plugins/debian/rules" > debian/rules
chmod 0775 debian/rules
