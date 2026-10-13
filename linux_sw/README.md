# PCIe AES-128 Accelerator Qt5 GUI

This directory contains an ARM Linux Qt5 application for the RK3588 board that
controls the PCIe BDMA-attached AES-128 accelerator.

## Hardware capability

The current FPGA AES core is encryption-only:

- Hardware path: AES-128 ECB encryption over BDMA H2C channel 0 and C2H channel 0.
- Control path: AXI-Lite registers mapped at BAR0 offset 0x4000.
- Decryption is not implemented in the current RTL. The GUI provides a software
  AES-128 fallback for decryption and marks the hardware path as encryption-only.

## GUI features

- English user interface.
- Text tab: AES-128 key generation, string encryption (hardware), and string
  decryption (software fallback).
- File tab: system file tree on the left, selected-file properties on the right,
  automatic key generation, configurable encrypted-file and key-save directories,
  and software decryption using a selected key file and encrypted file.

File encryption produces two files:

- `*.aes`: encrypted payload.
- `*.key`: hexadecimal AES-128 key.

The `.key` file is accepted during decryption either as 16 raw bytes or as 32
hexadecimal characters. The DMA adapter reverses every 16-byte AES block
internally, so hardware encryption produces ciphertext that matches the software
AES implementation and can be decrypted by the File Decryption tab.

## Display and touch

The window follows the geometry the platform plugin reports and starts
full-screen; in portrait the file tab stacks the tree above the properties
instead of placing them side by side. On startup the application prints the
platform plugin, the screen geometry and the touch devices Qt found, which is
the quickest way to tell a Wayland session from an eglfs one.

Start it through `run.sh` so the platform, rotation and input are set explicitly
instead of inherited from the board profile:

```sh
./run.sh                    # wayland if WAYLAND_DISPLAY is set, else eglfs
./run.sh --wayland          # join the Weston session
./run.sh --eglfs --rotate 270
```

| | orientation | touch |
|---|---|---|
| `--wayland` | inherited from the compositor; rotate the panel with `transform=rotate-90` in the `[output]` section of `/etc/xdg/weston/weston.ini` (add `name=` when several outputs are attached) | delivered by Weston, the same path the rest of the desktop uses |
| `--eglfs` | `QT_QPA_EGLFS_ROTATION`, default 90 | evdev handlers reading `/dev/input` directly; `QT_QPA_EGLFS_NO_LIBINPUT=1` is needed because eglfs prefers libinput, which enumerates devices through udev and the buildroot rootfs runs no udevd |

So if touch works in the Weston desktop but not in this application, the
application is not a Wayland client - it is drawing through eglfs and reading
input itself. `./run.sh --wayland` addresses the orientation and the touch in
one step. A Wayland client cannot rotate its output on its own, so when the
whole desktop comes up sideways the rotation belongs in `weston.ini`, not in the
application.

## Build prerequisites

- Cross toolchain and Qt5 buildroot sysroot with Qt5Widgets and Qt5Concurrent.
- qmake and the cross compiler from the SDK's `host/bin` directory.

Typical cross build steps:

```sh
./build.sh tl3588          # Tronlong TL3588F-EVM SDK
./build.sh evb7            # RK3588-EVB7-V11 SDK
./build.sh tl3588 debug    # same, with symbols, into build/tl3588-debug
./build.sh tl3588 clean    # remove the target build directory
```

The SDKs are spelled out in `build.sh`. Note that the TL3588 SDK's qmake needs
`QT_HOST_PREFIX` and `SDK_QMAKE_SYSROOT` exported to find its mkspecs, and the
generated Makefile expands `${QT_HOST_PREFIX}` as well, so `build.sh` keeps both
set for qmake and make.

From VS Code the same builds are available as the *Qt GUI: Build ... (linux_sw)*
tasks (`Ctrl+Shift+B` builds for the TL3588F-EVM by default).

Copy `aes_pcie_gui` and `run.sh` to the target and start it through `run.sh` as
root, because it accesses `/dev/mem`, `/dev/bdma0_user`, `/dev/bdma0_h2c_0`, and
`/dev/bdma0_c2h_0`.

## Runtime requirements

- PCIe link is up.
- `bdma.ko` is loaded and `/dev/bdma0_*` nodes exist.
- The AES BAR0 register window starts at 0x4000 in the user BAR.

The default control mapping is `/dev/bdma0_user`; if that device does not support
mmap, the application falls back to `/dev/mem` with physical base `0xf0210000`.
