#!/bin/sh

SYSROOT=/home/mix/Desktop/PL/gcc/install
TARGET_TRIPLE=aarch64-linux-gnu

export PATH=$SYSROOT/bin:$PATH
export QEMU_LD_PREFIX=$SYSROOT/$TARGET_TRIPLE

cd build-gcc
make check-gcc


