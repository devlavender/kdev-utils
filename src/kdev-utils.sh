#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

########################################################################
# Copyright (C) 2024 - Ágatha Isabelle Chris Moreira Guedes
#
# Author: Ágatha Isabelle Chris Moreira Guedes <code@agatha.dev>
#
# @file: kdev-utils.sh
# @description main kdev-utils script
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

LOG_FILE="/tmp/kdevutils.log"

___debug(){
        if [ "$DEBUG" = 1 ]; then
                echo -e "$*" >&2
        fi
        if [ "$DEBUG_LOG" = 1 ]; then
                echo -e "${*}" >> "$LOG_FILE"
        fi
}

___dump_array(){
        ARGS=( "${@}" )
        #___debug "Showing ${#ARGS[@]} elements..."
        for i in "${!ARGS[@]}"; do
                ___debug "\t[$i]=${ARGS[$i]}"
        done
}

___debug_array(){
        ARGS=( "${@}")
        ARRAY_NAME="$1"
        RMDR=$(( ${#ARGS[@]} - 1 ))
        ARRAY_ELEMENTS=( "${ARGS[@]:1:$RMDR}" )
        ___debug "$ARRAY_NAME:"
        ___dump_array "${ARRAY_ELEMENTS[@]}"
}

___get_path(){
        CMD="$1" # The command to find path
        DEF_VAL="$2" # The value if not found
        echo "$(which "$CMD" 2>/dev/null || echo "$DEF_VAL")"
}

___load_cfg(){
        . "$1"
        return $?
}

___load_cfg_if_exists(){
        test -f "$1" && ___load_cfg "$1"
        return $?
}

# Non-configurable values:
KU_BASE_DIR="/opt/kdev-utils"
KU_LIB="$KU_BASE_DIR/lib"
KU_BIN="$KU_BASE_DIR/bin"
KU_CONFIG_PATH="$HOME/.kdev-utils"
KU_CONFIG_MAIN="$KU_CONFIG_PATH/kdevutils.conf"

# Configurable values:
VIRTIOFSD=$(___get_path virtiofsd /usr/lib/virtiofsd)
ROOT_EXEC=$(___get_path sudo /bin/sudo)
VM_BASE="$KU_BASE_DIR/var/vms"
VIOFSD_GROUP="$(grep "${GROUPS[0]}" /etc/group|cut -d: -f1)"

AUTOLOAD_MODULES=()

KU_ARCH="$(uname -m)"
QEMU_PREFIX="qemu-system-"
QDP="/usr/bin"
QEMU="$(___get_path "$QEMU_PREFIX$KU_ARCH" \
        "$QDP$QEMU_PREFIX$KU_ARCH")"
VMCFG_DIR="$KU_CONFIG_PATH/vms.d"

LOOP_INTERVAL=3
VFSD_LOOP_INTERVAL=""
QEMU_LOOP_INTERVAL=""
###############################################
___load_cfg "$KU_CONFIG_MAIN" || \
        ___debug "Error loading $KU_CONFIG_MAIN"

VFSD_LOOP_INTERVAL="$LOOP_INTERVAL"
QEMU_LOOP_INTERVAL="$LOOP_INTERVAL"

VM_SOCKET_DIR="/tmp"
VM_SOCKET_PREFIX="ku-"
VM_SOCKET_SUFFIX="-viofsd.sock"


##############################################
KU_LOADED_MODS=()

____ku_load_source(){
        SRC_PATH="$1"
        test -x "$SRC_PATH" && . "$SRC_PATH" || return 255
}

___ku_load_module(){
        MOD_PATH="$KU_LIB/$1.sh"
        ____ku_load_source "$MOD_PATH"
        return $?
}

__ku_load_module(){
        ___ku_load_module "$1" && KU_LOADED_MODS+=( "$1" ) || \
                echo "ERROR: error loading $1!"
}

__ku_autoload_modules(){
        for mod in "${AUTOLOAD_MODULES[@]}"; do
                __ku_load_module "$mod"
        done
}

ku_load_module(){
        for mod in "${KU_LOADED_MODS[@]}"; do
                if [ "$1" = "$mod" ]; then
                        return 255
                fi
        done
        __ku_load_module "$1"
}

___ku_reload_itself(){
        ____ku_load_source "$KU_BIN/kdev-utils.sh"
}

ku_reload_config(){
        ___debug "Reloading config file $KU_CONFIG_MAIN"
        ___load_cfg_if_exists "$KU_CONFIG_MAIN" || \
                echo "Error reloading config!"
}

ku_reload_modules(){
        for mod in "${KU_LOADED_MODS[@]}"; do
                ___ku_load_module "$mod"
        done
}

ku_reload(){
        ___ku_reload_itself
        ku_reload_config
        ku_reload_modules
}

cat << EOF
kdev-utils - utilities to help automate Linux Kernel Development
Copyright (C) <2024>  <Ágatha Isabelle Chris Moreira Guedes>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

EOF

___debug "Checking if BASH_ = 0 [${BASH_SOURCE[0]}, $0]"

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
        echo "ERROR: You're not supposed to execute $0, but to source " \
                "it nstead!"
        echo "Run: . ${BASH_SOURCE[0]}"
        exit
fi

__ku_autoload_modules