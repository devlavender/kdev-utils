Linux Kernel Development Utils (kdev-utils)
===========================================

kdev-utils is a set of scripts created to help in Linux Kernel development
tasks in general, in special those related to booting a kernel simulation
environment using qemu, with the intention to incorporate kgdb scripts in the
future, as well as possibly kernel testing automation frameworks, building,
etc.

1. REQUIREMENTS

Currently, it needs qemu with support for the intended architecture, including
virtiofsd, a kernel source and a system tree.

2. CONFIG

In the future I'll use `m4` and/or `autoconf` or something alike to allow
config path customization, but for the sake of simplicity, as of now, it will
read config in bash syntax from `~/.kdev-utils/kdevutils.conf`. In a future
I'll implement a `kdev_include()` bash function to allow spliting configs into
multiple files or something like that.

Read `docs/config.txt` for reference.

3. AUTHOR/MAINTAINER

kdev-utils is brought to you and maintained by Ágatha Isabelle, hoping it to be
useful.
