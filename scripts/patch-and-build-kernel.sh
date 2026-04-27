#!/bin/bash

set -e

# nowdir: $PROJECT_ROOT

# apply patches
bash $PROJECT_ROOT/scripts/set_kernel_version.sh
cd $VYOS_BUILD_ROOT
cp $PROJECT_ROOT/patches/vyos-build/0001-linkstate-ip-device-attribute.patch $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel/patches/kernel/
cp $PROJECT_ROOT/patches/vyos-build/0002-inotify-support-for-stackable-filesystems.patch $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel/patches/kernel/
cp $PROJECT_ROOT/patches/vyos-build/0003-build-linux-perf-package.patch $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel/patches/kernel/
patch -p1 < $PROJECT_ROOT/patches/main/linux-kernel-defconfig.patch

# Copy BPF/BTF configuration file
echo "Adding BPF/BTF kernel configuration..."
cp $PROJECT_ROOT/patches/main/linux-kernel-bpf-btf.config $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel/config/00-bpf-btf.config

cd $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel
./build.py --packages linux-kernel

ls -la ./*.deb
mv ./*.deb $VYOS_BUILD_ROOT/packages/