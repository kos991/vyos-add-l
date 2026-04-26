# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (parent of scripts/)
export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export VYOS_BUILD_ROOT=$PROJECT_ROOT/vyos-build

set -e

echo "Project root: $PROJECT_ROOT"
echo "Scripts directory: $SCRIPT_DIR"

echo "Updating package lists..."
sudo apt-get update
# sudo apt-get install -y gcc-aarch64-linux-gnu u-boot-tools bc make gcc ccache libc6-dev libncurses5-dev libssl-dev bison flex device-tree-compiler libelf-dev kmod libdw-dev libdebuginfod-dev systemtap-sdt-dev libunwind-dev libslang2-dev libperl-dev python3-dev python3 llvm-dev libzstd-dev libnuma-dev libbabeltrace-ctf-dev libcapstone-dev libpfm4-dev libtraceevent-dev libtracefs-dev default-jdk clang binutils-dev libcap-dev libbpf-dev asciidoc xmlto u-boot-tools

echo "Cloning vyos-build repositories..."
git clone https://github.com/vyos/vyos-build

echo "Building vyos-1x package..."
bash "$SCRIPT_DIR/patch-and-build-vyos-1x.sh"

echo "Building kernel and related packages..."
bash "$SCRIPT_DIR/patch-and-build-kernel.sh"
bash "$SCRIPT_DIR/patch-and-build-kernel-related-packages.sh"
rm -rf $VYOS_BUILD_ROOT/scripts/package-build/linux-kernel

echo "Building Landscape package..."
bash "$SCRIPT_DIR/build-landscape-package.sh"

echo "Building VyOS image..."
sudo -E bash "$SCRIPT_DIR/patch-and-build-vyos-image.sh"
