# Hyprland Packages for Nitrux

[![Generic badge](https://img.shields.io/badge/Arch-amd64%20%7C%20arm64-yellowgreen.svg)](https://shields.io/)

<p align="center">
  <img width="128" height="128" src="https://raw.githubusercontent.com/Nitrux/luv-icon-theme/master/Luv/apps/64/wayland.svg">
</p>

# Introduction

This repository builds the Nitrux Hyprland package set: the Hyprland compositor, supporting libraries and tools, related applications, plugins, and the Hyprland desktop portal.

# Building

The package version is read from `VERSION`.

Initialize the package sources and install the build dependencies:

```sh
git submodule update --init --recursive
sudo ./scripts/install-build-deps.sh
```

Build the complete package set:

```sh
./scripts/build-deb.sh
```

The builder supports native `amd64` and `arm64` builds.

The stable build contains only the release-pinned package sources listed by
`scripts/build-deb.sh`; packages without a stable release pin are not built.


# Licensing

This repository contains files under multiple licenses.

- Repository build and packaging automation is licensed under **BSD-3-Clause** (see `LICENSE`).
- Debian package metadata keeps its respective upstream licensing.
- Hyprland source, installer, and package content retain their applicable upstream licensing.

# Issues

If you find problems with the contents of this repository, please create an issue and use the **🐞 Bug report** template.

## Submitting a bug report

Before submitting a bug, you should look at the [existing bug reports](https://github.com/Nitrux/nvidia-open-kernel-module/issues) to verify that no one has reported the bug already.

©2026 Nitrux Latinoamericana S.C.
