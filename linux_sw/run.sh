#!/bin/bash

# Launch the Qt5 GUI on the target board.
#
#   ./run.sh [--wayland|--eglfs] [--rotate 0|90|180|270] [--] [app args...]
#
# Why this exists: the same binary behaves differently depending on the Qt
# platform plugin it picks up, and the ambient QT_QPA_PLATFORM exported by the
# board's profile is often not the one you want.
#
#   wayland  The app is a Wayland client under Weston. It inherits the
#            compositor's output transform (so the panel orientation set in
#            weston.ini applies) and gets touch through the compositor, which
#            already works for the rest of the desktop.
#   eglfs    The app drives DRM/GL directly, ignoring Weston. Nothing applies
#            the panel rotation for you, so QT_QPA_EGLFS_ROTATION does it, and
#            input has to come from /dev/input.
#
# Environment overrides: ROTATE, BINARY, TOUCH_DEVICE.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${BINARY:-$SCRIPT_DIR/aes_pcie_gui}"
ROTATE="${ROTATE:-90}"
TOUCH_DEVICE="${TOUCH_DEVICE:-}"
MODE=""
ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --wayland) MODE="wayland"; shift ;;
        --eglfs)   MODE="eglfs"; shift ;;
        --rotate)  ROTATE="$2"; shift 2 ;;
        --)        shift; ARGS+=("$@"); break ;;
        *)         ARGS+=("$1"); shift ;;
    esac
done

if [ ! -x "$BINARY" ]; then
    echo "run.sh: no binary at $BINARY - build it first with ./build.sh tl3588" >&2
    exit 1
fi

# Qt falls back to wayland-0 in XDG_RUNTIME_DIR when WAYLAND_DISPLAY is unset,
# so look for the socket itself rather than for the variable - on the board the
# variable is empty and the application still joins Weston.
wayland_socket="${XDG_RUNTIME_DIR:-/var/run}/${WAYLAND_DISPLAY:-wayland-0}"

if [ -z "$MODE" ]; then
    if [ -S "$wayland_socket" ]; then
        MODE="wayland"
    else
        MODE="eglfs"
    fi
fi

if [ "$(id -u)" != "0" ]; then
    echo "run.sh: warning: not running as root, /dev/mem and /dev/bdma0_* will not open" >&2
fi

if [ "$MODE" = "wayland" ]; then
    # The board profile may export eglfs; force the client plugin so the app
    # joins the Weston session instead of fighting it for the display.
    export QT_QPA_PLATFORM=wayland
    if [ ! -S "$wayland_socket" ]; then
        echo "run.sh: warning: no Wayland socket at $wayland_socket - start this from a" >&2
        echo "         terminal inside the Weston session, or set WAYLAND_DISPLAY / XDG_RUNTIME_DIR" >&2
    fi
    # No rotation handling here: a Wayland client cannot rotate the output.
    # If the whole desktop is the wrong way round, fix weston.ini (transform).
else
    export QT_QPA_PLATFORM=eglfs
    export QT_QPA_EGLFS_ROTATION="$ROTATE"
    # eglfs prefers libinput, and libinput enumerates devices through udev.
    # The buildroot rootfs has no udevd running, so libinput finds nothing and
    # the app gets no touch at all; the evdev handlers read /dev/input directly.
    export QT_QPA_EGLFS_NO_LIBINPUT=1
    export QT_QPA_GENERIC_PLUGINS="${QT_QPA_GENERIC_PLUGINS:-evdevtouch}"
    if [ -n "$TOUCH_DEVICE" ]; then
        # The evdevtouch plugin applies the screen rotation to touch events
        # only when told, so keep the two in step.
        export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="$TOUCH_DEVICE:rotate=$ROTATE"
    fi
fi

echo "run.sh: platform=$QT_QPA_PLATFORM${QT_QPA_EGLFS_ROTATION:+ rotation=$QT_QPA_EGLFS_ROTATION} binary=$BINARY"
exec "$BINARY" "${ARGS[@]}"
