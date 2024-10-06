#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

########################################################################
# Copyright (C) 2024 - Ágatha Isabelle Chris Moreira Guedes
#
# Author: Ágatha Isabelle Chris Moreira Guedes <code@agatha.dev>
#
# @file: qemu.sh.sh
# @description qemu-related tools
#
########################################################################
#
#                           L  I  C  E  N  S  E
#
########################################################################
#
# This code is licensed under the GNU General Public License version 3
# <https://www.gnu.org/licenses/gpl-3.0.html>. See the `LICENSE.txt`
# and the `README.txt` files at the project root for more information,
# or the license link above.
#
# This file is part of kdev-utils.
#
# kdev-utils is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, in the version 3 of the License.
#
# kdev-utils is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with kdev-utils. If not, see <https://www.gnu.org/licenses/>
# and <https://www.gnu.org/licenses/gpl-3.0.html>.

# Dependencies
ku_load_module virtiofsd

VM_ARCH="$KU_ARCH"
VM_RAM="2G"
VM_CPU="host"
VM_EXTRA_ARGS=()
VM_KERNEL_CMDLINE=()
VM_CONSOLE_OPTS=(
        "-nographic"
        "-serial mon:stdio"
)
SOCK=""

# Non-configurable:
VM_MEM_BE_PREFIX="memory-backend-file,id=mem,size="
VM_MEM_BE_SUFIX=",mem-path=/dev/shm,share=on"


__qemu_ld_vm_conf(){
        VM_NAME="$1"
        VM_CFG="$VMCFG_DIR/$VM_NAME.conf"
        SOCK="$(___get_vm_socket_path "$VM_NAME")"
        ___load_cfg_if_exists "$VM_CFG" || return 255
}

__qemu_run_vm(){
        ARGS=( "${@}" )
        VM_NAME="$1"
        shift 1
        KERNEL_PATH="$1"
        shift 1
        INIT_PATH="$1"
        shift 1
        EXTRA_CMDLINE="$1"
        shift 1
        RMDR=$(( ${#ARGS[@]} - 4))
        EXTRA_ARGS=( "${ARGS[@]:4:$RMDR}" )
        CMD="$QEMU_PREFIX$VM_ARCH"

        INIT_APPEND=""
        if [ "$INIT_PATH" != "" ]; then
                INIT_APPEND="init=$INIT_PATH"
        fi

        __qemu_ld_vm_conf "$VM_NAME"
        ___debug "VM_NAME=$VM_NAME KERNEL_PATH=$KERNEL_PATH" \
                "INIT_PATH=$INIT_PATH EXTRA_CMDLINE=$EXTRA_CMDLINE" \
                "RMDR=$RMDR SOCK=$SOCK EXTRA_ARGS=${EXTRA_ARGS[*]}"
        ___debug_array "EXTRA_ARGS" "${EXTRA_ARGS[@]}"
        ___debug_array "VM_CONSOLE_OPTS" "${VM_CONSOLE_OPTS[@]}"
        ___debug "$CMD" -m "$VM_RAM" \
                -object "$VM_MEM_BE_PREFIX$VM_RAM$VM_MEM_BE_SUFIX" \
                -numa node,memdev=mem \
                -cpu "$VM_CPU" -enable-kvm \
                -chardev "socket,id=char0,path=$SOCK" \
                -device \
                "vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=rootfs" \
                ${VM_CONSOLE_OPTS[*]} \
                -kernel "$KERNEL_PATH" \
                -append \
                "${VM_KERNEL_CMDLINE[*]} $INIT_APPEND $EXTRA_CMDLINE" \
                "${EXTRA_ARGS[@]}"
        "$CMD" -m "$VM_RAM" \
                -object "$VM_MEM_BE_PREFIX$VM_RAM$VM_MEM_BE_SUFIX" \
                -numa node,memdev=mem \
                -cpu "$VM_CPU" -enable-kvm \
                -chardev "socket,id=char0,path=$SOCK" \
                -device \
                "vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=rootfs" \
                ${VM_CONSOLE_OPTS[*]} \
                -kernel "$KERNEL_PATH" \
                -append \
                "${VM_KERNEL_CMDLINE[*]} $INIT_APPEND $EXTRA_CMDLINE" \
                "${EXTRA_ARGS[@]}"
        reset
}

ku_qemu(){
        __qemu_run_vm "${@}"
}

ku_qemu_bashinit(){
        #ku_qemu_bashinit
        ku_qemu "$1" "$2" "init=/bin/bash" "$3" "${@}"
}