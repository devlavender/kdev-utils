#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

########################################################################
# Copyright (C) 2024 - Ágatha Isabelle Chris Moreira Guedes
#
# Author: Ágatha Isabelle Chris Moreira Guedes <code@agatha.dev>
#
# @file: build.sh
# @description kernel build & deploy tools
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

ku_load_module root-trees

# A build config is composed of a toolchain and a kernel config.
# A kernel config has per-toolchain and per-tree variations
# A toolchain config is composed of toolchain specs, that include
#       compiler, linker, utils, etc and architecture
# A build config is something like:
#BUILD_NAME="full description"
#BUILD_TOOLCHAIN="toolchainID"
#BUILD_CONFIGID="configid"

# Kernel configs are stored into:
#       $KU_CONFIG_PATH/kconfig/<config-id>/config-<toolchain-id>



BUILD_CFG_DIR="$KU_CONFIG_PATH/build.d"
TC_DIR="$KU_CONFIG_PATH/toolchain.d"
KCONFIG_BASE="$KU_CONFIG_PATH/kconfig"

TC_NAME=""
TC_ID=""
TC_ARCH="x86_64" #default arch
TC_CACHED=1 #1: uses ccache, 0: no ccache
TC_CCACHE_DIR=""
TC_VARS=()

CCACHE_DIR="$CCACHE_BASE"

BUILD_NAME=""
BUILD_TOOLCHAIN=""
BUILD_CONFIGID=""
BUILD_THREADS="1"

___get_config_path(){
        CONFIG_ID="$1"
        TOOLCHAIN_ID="$2"
        echo "$KCONFIG_BASE/$CONFIG_ID/config-$TOOLCHAIN_ID"
        ___debug "CONFIG_ID=$CONFIG_ID TOOLCHAIN_ID=$TOOLCHAIN_ID"
        ___debug "$KCONFIG_BASE/$CONFIG_ID/config-$TC_ID"
}

___get_ccache_build_path(){
        echo "$CCACHE_BASE/$BUILD_TOOLCHAIN/$BUILD_CONFIGID"
}

___get_suffix(){
        echo "$(basename "$1")"
}

___load_conf(){
        TYPE="$1"
        ID="$2"
        CFG="$KU_CONFIG_PATH/$TYPE.d/$ID.conf"
        ___load_cfg_if_exists "$CFG" || return $?
}

___build_load_conf(){
        ___load_conf "build" "$1" || return $?
}

___toolchain_load_conf(){
        TC_ID="$1"
        ___load_conf "toolchain" "$TC_ID" || return $?
}

__toolchain_build_cmd(){
        echo "${TC_VARS[@]}"
}

__do_build(){
        TARGET="$1"
        #EXTRAPARAMS=( "${@:1:$#-1}" )
        EXTRAPARAMS=( "${@:2:$#-1}" )
        BUILD_ARGS=( "$(__toolchain_build_cmd)" )
        if [ "$TC_CACHED" = "1"]; then
                KTSTAMP="$(printf "y%0.s" $(seq 1 $(date | wc -c)))"
                export KBUILD_BUILD_TIMESTAMP=$KTSTAMP
        fi
        echo "Building target '$TARGET'..."
        ___debug "CCACHE_DIR=$CCACHE_DIR BUILD_THREADS=$BUILD_THREADS" \
                "EXTRAPARAMS=(" "${EXTRAPARAMS[@]}" ")"
        ___debug "Toolchain command flags: $(__toolchain_build_cmd)"
        CCACHE_DIR="$CCACHE_DIR" make -j"$BUILD_THREADS" \
                "${TC_VARS[@]}" "${EXTRAPARAMS[@]}" "$TARGET"
}

get_config_path(){
        ___get_config_path "$BUILD_CONFIGID" "$BUILD_TOOLCHAIN"
}

load_build(){
        ID="$1"
        ___debug "load_build(): ID=$1"
        ___build_load_conf "$1"
        RET=$?
        if [ "$RET" != 0 ]; then
                echo "Error loading build $ID (ret $RET)"
                return $RET
        fi
        echo "Loaded build '$BUILD_NAME'"

        ___debug "BUILD_CFG_DIR=$BUILD_CFG_DIR " \
                "BUILD_CONFIGID=$BUILD_CONFIGID " \
                "BUILD_TOOLCHAIN=$BUILD_TOOLCHAIN " \
                "BUILD_THREADS=$BUILD_THREADS"
        
        ___debug "\t Loading toolchain '$BUILD_TOOLCHAIN'"
        ___toolchain_load_conf "$BUILD_TOOLCHAIN"
        RET=$?
        if [ "$RET" != 0 ]; then
                echo "Error loading toolchain $BUILD_TOOLCHAIN " \
                "(ret $RET)"
                return $RET
        fi

        echo "Loaded toolchain '$BUILD_TOOLCHAIN'"
        ___debug "TC_ARCH=$TC_ARCH TC_CACHED=$TC_CACHED " \
                "TC_DIR=$TC_DIR TC_ID=$TC_ID TC_NAME=$TC_NAME " \
                "TC_VARS=(${TC_VARS[@]})"
        ___debug "\tLoading kconfig $BUILD_CONFIGID"

        #___rt_load_conf "$BUILD_CONFIGID"
        #RET=$?
        #        if [ "$RET" != 0 ]; then
        #        echo "Error loading root tree $BUILD_CONFIGID (ret $RET)"
        #        return $RET
        #fi
        #echo "Loaded root tree '

        if [ "$TC_CACHED" = "1" ]; then
                if [ "$TC_CCACHE_DIR" = "" ]; then
                        CCACHE_DIR="$(___get_ccache_build_path)"
                else
                        CCACHE_DIR="$TC_CCACHE_DIR"
                fi
                ___debug "Activatig ccache on '$CCACHE_DIR'"
                ___debug "Creating dir '$CCACHE_DIR' if absent..."
                test -d "$CCACHE_DIR" || mkdir -p "$CCACHE_DIR"
        fi
}

build_bzimage(){
         __do_build bzImage "${@}"
}

build_modules(){
        __do_build modules "${@}"
}

build_all(){
        build_bzimage "${@}" && build_modules "${@}" || return $?
}

deploy_modules(){
        "$ROOT_EXEC" make INSTALL_MOD_PATH="$(rt_deploy_getdest)" "${@}"\
                modules_install
}

build_and_deploy(){
        build_all "${@}" && deploy_modules "${@}"
}

build_save_config(){
        cp -i --preserve=timestamps ".config" "$(get_config_path)"
}

build_reload_config(){
        cp -i --preserve=timestamps "$(get_config_path)" ".config"
}

build_edit_config(){
        cp --preserve=timestamps .config .config-bkp
        __do_build menuconfig "${@}"
        cp --preserve=timestamps .config .config-last-edit
        build_save_config
}

build_config_clone(){
        SRC_TC="$1"
        DST_TC="$2"
        SRC_PATH="$(___get_config_path "$BUILD_CONFIGID" "$SRC_TC")"
        DST_PATH="$(___get_config_path "$BUILD_CONFIGID" "$DST_TC")"
        cp -i --preserve=timestamps "$SRC_PATH" "$DST_PATH"
}

kconfig_add(){
        CONFIG="$1"
        mkdir -p "$KCONFIG_BASE/$CONFIG_ID"
}

