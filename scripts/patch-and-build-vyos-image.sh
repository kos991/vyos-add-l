#!/bin/bash

set -euo pipefail

# nowdir: $PROJECT_ROOT
# this script should be run as root

: "${PROJECT_ROOT:?PROJECT_ROOT is not set}"
: "${VYOS_BUILD_ROOT:?VYOS_BUILD_ROOT is not set}"

IMAGE_PHASE="${VYOS_IMAGE_PHASE:-build}"
IMAGE_PATCH="${PROJECT_ROOT}/patches/vyos-build/0015-add-nexttrace-and-landscape.patch"
IMAGE_HOOK="${PROJECT_ROOT}/patches/vyos-build/9999-kawaii-networks-custom.chroot"
VERSION_FILE="${PROJECT_ROOT}/build/vyos_version"

prepare_image_inputs() {
  cd "${VYOS_BUILD_ROOT}"

  if patch --dry-run -p1 < "${IMAGE_PATCH}" >/dev/null; then
    patch -p1 < "${IMAGE_PATCH}"
  elif grep -q '^\[packages\.landscape-router\]' data/architectures/amd64.toml &&
       grep -q '^\[additional_repositories\.nexttrace\]' data/architectures/amd64.toml; then
    echo "VyOS image patch already applied"
  else
    echo "VyOS image patch cannot be applied and expected settings are missing" >&2
    return 1
  fi

  cp "${IMAGE_HOOK}" data/live-build-config/hooks/live/

  mkdir -p "${PROJECT_ROOT}/build"
  if [ -s "${VERSION_FILE}" ]; then
    build_version="$(cat "${VERSION_FILE}")"
  else
    build_version="$(date +"%Y.%m.%d-%H%M-rolling")"
    echo "${build_version}" > "${VERSION_FILE}"
  fi
  export build_version
  echo "Build version: ${build_version}"
}

run_build_vyos_image() {
  cd "${VYOS_BUILD_ROOT}"
  local dry_run_arg="${1:-}"

#  for china builders
#  --debian-mirror "http://mirrors.pku.edu.cn/debian" \
#  --debian-security-mirror "http://mirrors.pku.edu.cn/debian-security" \

#  --custom-package fastnetmon \
#  --custom-package vnstat \

  ./build-vyos-image \
 ${dry_run_arg} \
 --architecture amd64 \
 --version "${build_version}" \
 --build-by "canoziia@projectk.org" \
 --custom-package bgpq4 \
 --custom-package btop \
 --custom-package containernetworking-plugins \
 --custom-package gdu \
 --custom-package nexttrace \
 --custom-package vim-tiny \
 --custom-package neofetch \
 --custom-package qemu-guest-agent \
 --custom-package ripgrep \
 --custom-package tree \
 --custom-package wget \
 --custom-package landscape-router \
 generic
}

case "${IMAGE_PHASE}" in
  prepare)
    prepare_image_inputs
    ;;
  dry-run)
    prepare_image_inputs
    run_build_vyos_image "--dry-run"
    ;;
  build)
    prepare_image_inputs
    run_build_vyos_image
    ls -la "${VYOS_BUILD_ROOT}/build/"
    mv "${VYOS_BUILD_ROOT}/build/vyos-${build_version}-generic-amd64.iso" "${PROJECT_ROOT}/build/"
    ;;
  *)
    echo "Unknown VYOS_IMAGE_PHASE: ${IMAGE_PHASE}" >&2
    exit 1
    ;;
esac
