#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 <Nitrux Latinoamericana S.C. <hello@nxos.org>>

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    apt_command=(sudo apt-get)
else
    apt_command=(apt-get)
fi

"${apt_command[@]}" update -q
"${apt_command[@]}" install -y --no-install-recommends \
    autoconf \
    automake \
    autotools-dev \
    build-essential \
    ca-certificates \
    cmake \
    dbus-daemon \
    debhelper-compat \
    devscripts \
    doxygen \
    dpkg-dev \
    fakeroot \
    g++ \
    gcc \
    git \
    glslang-dev \
    glslang-tools \
    hwdata \
    libaudit-dev \
    libcairo2-dev \
    libcanberra-dev \
    libdbus-1-dev \
    libdisplay-info-dev \
    libdrm-dev \
    libegl-dev \
    libeis-dev \
    libexpat1-dev \
    libffi-dev \
    libfontconfig-dev \
    libgbm-dev \
    libgl-dev \
    libgl1-mesa-dev \
    libgles-dev \
    libgmock-dev \
    libgtest-dev \
    libheif-dev \
    libicu-dev \
    libinput-dev \
    libiniparser-dev \
    libjxl-dev \
    libjpeg-dev \
    liblcms2-dev \
    liblua5.4-dev \
    libmagic-dev \
    libmuparser-dev \
    libpam0g-dev \
    libpango1.0-dev \
    libpci-dev \
    libpipewire-0.3-dev \
    libpixman-1-dev \
    libpng-dev \
    libpolkit-agent-1-dev \
    libpolkit-qt6-1-dev \
    libpugixml-dev \
    libqalculate-dev \
    libre2-dev \
    libreadline-dev \
    librsvg2-dev \
    libseat-dev \
    libspa-0.2-dev \
    libsystemd-dev \
    libtool \
    libtomlplusplus-dev \
    libudev-dev \
    libvulkan-dev \
    libwayland-bin \
    libwayland-dev \
    libwebp-dev \
    libxcb-composite0-dev \
    libxcb-icccm4-dev \
    libxcb-res0-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxcursor-dev \
    libxkbcommon-dev \
    libzip-dev \
    meson \
    ninja-build \
    pkgconf \
    python-is-python3 \
    python3 \
    python3-sphinx \
    qt6-base-dev \
    qt6-base-private-dev \
    qt6-declarative-dev \
    qt6-svg-dev \
    qt6-wayland \
    qt6-wayland-dev \
    qt6-wayland-private-dev \
    uuid-dev \
    wayland-protocols \
    xcb-proto \
    xutils-dev \
    xxd \
    yq
