#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

########################################################################
# Copyright (C) 2024 - Ágatha Isabelle Chris Moreira Guedes
#
# Author: Ágatha Isabelle Chris Moreira Guedes <code@agatha.dev>
#
# @file: virtiofsd.sh
# @description virtiofsd tools
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

___get_vm_socket_path(){
	echo "$VM_SOCKET_DIR/$VM_SOCKET_PREFIX$1$VM_SOCKET_SUFFIX"
}

__viofs_load_vm_tree(){
	VM_TREE="$1"
	___debug "ROOT_EXEC=$ROOT_EXEC VIRTIOFSD=$VIRTIOFSD " \
		"VM_TREE=$VM_TREE VM_BASE=$VM_BASE " \
		"VIOFSD_GROUP=$VIOFSD_GROUP"
	"$ROOT_EXEC" "$VIRTIOFSD" \
		--socket-path="$(___get_vm_socket_path "$VM_TREE")" \
		--shared-dir="$VM_BASE/$VM_TREE" --tag rootfs \
		--sandbox chroot --socket-group "$VIOFSD_GROUP"
}

PID_PATH="/tmp"
PID_PREFIX="viofs-vm-"
PID_SUFFIX=".pid"
__viofs_daemonize(){
	VM_TREE="$1"
	PID_FILE="$PID_PATH/$PID_PREFIX$VM_TREE$PID_SUFFIX"
	___debug "PID file: $PID_FILE"
	echo "$BASH_PID" > "$PID_FILE"
	while test -f "$PID_FILE"; do
		sleep "$VFSD_LOOP_INTERVAL"
		__viofs_load_vm_tree "$VM_TREE"
	done
	rm "$PID_FILE"
}

__show_help(){
	echo "Usage: $1 command vm-name arguments"
	echo ""
	echo "COMMAND LIST:"
	echo -e "\trunonce:\tRuns the virtiofsd only once"
	echo -e "\trun:\tRuns virtiofsd in a loop"
}

virtio(){
	SUBCMD="$1"
	VM_TREE="$2"
	case "$SUBCMD" in
		"runonce") __viofs_load_vm_tree "$VM_TREE";;
		"run") __viofs_daemonize "$VM_TREE";;
		*) __show_help "$0";;
	esac
}
