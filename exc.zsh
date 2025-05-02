#!/bin/zsh
echo "[Processing Qemu]"
qemu-system-x86_64 -L . -m 64 -fda /users/ybmk_home/hmk/dev/hunt/disk.img -M pc
