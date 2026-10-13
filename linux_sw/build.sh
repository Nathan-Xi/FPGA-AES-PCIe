#!/bin/bash

# Build helper for the Qt5 GUI in this directory.
#
#   ./build.sh [target] [action]
#
#   target: tl3588 (default) - Tronlong TL3588F-EVM buildroot SDK
#           evb7             - RK3588-EVB7-V11 buildroot SDK
#   action: build (default)  - generate the Makefile if needed, then make
#           debug            - same, but with symbols (-g) in build/<target>-debug
#           clean            - remove the build directory of the target

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-tl3588}"
ACTION="${2:-build}"

# Each SDK ships its own cross toolchain, qmake and Qt5 (Widgets + Concurrent).
case "$TARGET" in
    tl3588)
        HOST="/home/tronlong/RK3588/rk3588-buildroot-2021.11-sysroot-v1.0/buildroot/output/rockchip_rk3588/host"
        ;;
    evb7)
        HOST="/home/tronlong/RK3588-EVB7-V11/rockchip_3588_linux/buildroot/output/rockchip_rk3588_evb7_v11/rockchip_rk3588/host"
        ;;
    *)
        echo "unknown target '$TARGET' (expected tl3588 or evb7)" >&2
        exit 2
        ;;
esac

SYSROOT="$HOST/aarch64-buildroot-linux-gnu/sysroot"
QMAKE="$HOST/bin/qmake"

# buildroot's qmake resolves its mkspecs and sysroot through these variables;
# the generated Makefile also expands ${QT_HOST_PREFIX}, so keep them exported
# for make as well.
export QT_HOST_PREFIX="$HOST"
export SDK_QMAKE_SYSROOT="$SYSROOT"

if [ "$ACTION" = "clean" ]; then
    for dir in "$SCRIPT_DIR/build/$TARGET" "$SCRIPT_DIR/build/$TARGET-debug"; do
        rm -rf "$dir"
    done
    echo "Cleaned build/$TARGET"
    exit 0
fi

if [ "$ACTION" = "debug" ]; then
    BUILD_DIR="$SCRIPT_DIR/build/$TARGET-debug"
    QMAKE_EXTRA_ARGS="CONFIG+=debug CONFIG-=release"
else
    BUILD_DIR="$SCRIPT_DIR/build/$TARGET"
    QMAKE_EXTRA_ARGS=
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Re-run qmake so changes to the .pro file are picked up; the Makefile itself
# tracks header/source dependencies.
$QMAKE $QMAKE_EXTRA_ARGS "$SCRIPT_DIR/aes_pcie_gui.pro"

make -j"$(nproc)"

echo
echo "Built for $TARGET: $BUILD_DIR/aes_pcie_gui"
echo "Run it on the board as root (/dev/mem, /dev/bdma0_* access)."
