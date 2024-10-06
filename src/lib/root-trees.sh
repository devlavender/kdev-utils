#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

########################################################################
# Copyright (C) 2024 - Ágatha Isabelle Chris Moreira Guedes
#
# Author: Ágatha Isabelle Chris Moreira Guedes <code@agatha.dev>
#
# @file: root-trees.sh
# @description manages root trees for kdev-utils
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

RT_CFG_DIR="$KU_CONFIG_PATH/root-trees.d"
CURRENT_ROOT=""

___rt_get_conf_path(){
        echo "$RT_CFG_DIR/$1.conf"
}

___rt_load_conf(){
        RT_ID="$1"
        RT_CFG="$(___rt_get_conf_path "$RT_ID")"
        ___load_cfg_if_exists "$RT_CFG" || return 255
}

___rt_retrieve_name(){
        echo "$1" | sed 's/\.conf$//' 
}

___rt_count(){
        RTS=($RT_CFG_DIR/*.conf)
        for i in "${!RT_CFG[@]}"; do
                continue
        done
        echo $(( $i + 1 ))
}

___rt_get_array(){
        RTS=($RT_CFG_DIR/*.conf)
        RTARRAY=()
        for rt in "${RTS[@]}"; do
                RTARRAY+=( "$(___rt_retrieve_name "$(basename "$rt")")" )
        done
        echo "${RTARRAY[@]}"
}

___rt_gen_conf(){
        RT_ID="$1"
        RT_DESCR="$2"
        echo "RT_ID=\"$RT_ID\""
        echo "RT_DESCR=\"$RT_DESCR\""
}

rt_ls(){
        echo "$(___rt_get_array)"
}

rt_load(){
        RT="$1"
        RT_PATH="$RT_BASE/$RT"
        ___rt_load_conf "$1" && \
                echo "Loaded root tree $RT ($RT_PATH)" || \
                (RET="$?"; echo "Tree $RT not configured"; return $RET); 
        CURRENT_ROOT="$RT"
}

rt_add(){
        # Usage: ___rt_gen_conf rtname rtdescr
        RT="$1"
        RT_CFG="$(___rt_get_conf_path "$RT")"
        DESCR="$2"
        test -d "$RT_BASE/$RT" && \
                ___rt_gen_conf "${@}" > "$RT_CFG" || \
                echo "Root tree directory $RT_BASE/$RT not found"
}

__rt_deploy_getdest(){
        TREE="$1"
        DEST="$2"
        echo "$RT_BASE/$TREE/$DESTINATION"
}

__rt_deploy_help(){
        echo "Usage: $1 tree element-list destination"
}

rt_deploy_getdest(){
        __rt_deploy_getdest "$CURRENT_ROOT" ""
}

rt_deploy_to(){
        if [ $# -lt 3 ]; then
                __rt_deploy_help
                return 255
        fi

        TREE="$1"
        DESTINATION="${!#}"
        DEPLOY_ELEMENTS=( "${@:2:$#-2}" )

        DEPLOY_PATH="$(__rt_reploy_getdest "$TREE" "$DESTINATION")"
        for element in "${DEPLOY_ELEMENTS[@]}"; do
                "$ROOT_EXEC" cp -i "$element" "$DEPLOY_PATH"
        done
}

deploy_dest_cwt(){
        __rt_deploy_getdest "$CURRENT_ROOT" "$1"
}

rt_deploy(){
        rt_deploy_to "$CURRENT_ROOT" "${@}"
}