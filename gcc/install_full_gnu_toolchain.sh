#!/bin/sh

sudo apt install texinfo flex bison gawk libgmp-dev expect tcl dejagnu qemu-user-static

SYSROOT=/home/mix/Desktop/PL/gcc/install
TARGET_TRIPLE=aarch64-linux-gnu
LINUX_ARCH=arm64

# Clone GCC source
git clone git://gcc.gnu.org/git/gcc.git gcc

# Get GMP/MPFG/MPC/ISL/CLOOG
wget ftp://gcc.gnu.org/pub/gcc/infrastructure/gmp-4.3.2.tar.bz2
bunzip2 gmp-4.3.2.tar.bz2
tar xvf gmp-4.3.2.tar
rm gmp-4.3.2.tar

wget ftp://gcc.gnu.org/pub/gcc/infrastructure/mpfr-3.1.4.tar.bz2
bunzip2 mpfr-3.1.4.tar.bz2
tar xvf mpfr-3.1.4.tar
rm mpfr-3.1.4.tar

wget ftp://gcc.gnu.org/pub/gcc/infrastructure/mpc-1.0.3.tar.gz
tar xzvf mpc-1.0.3.tar.gz
rm mpc-1.0.3.tar.gz

wget ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2
bunzip2 isl-0.18.tar.bz2
tar xvf isl-0.18.tar
rm isl-0.18.tar

wget ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-0.18.1.tar.gz
tar xzvf cloog-0.18.1.tar.gz
rm cloog-0.18.1.tar.gz

cd gcc
ln -s ../gmp-4.3.2 gmp
ln -s ../mpfr-3.1.4 mpfr
ln -s ../mpc-1.0.3 mpc
ln -s ../isl-0.18 isl
ln -s ../cloog-0.18.1 cloog
cd ../

# Get dejagnu
git clone git://git.sv.gnu.org/dejagnu.git
cd gcc
ln -s ../dejagnu dejagnu
cd ../

# Create installation dir
mkdir install
export PATH=$SYSROOT/bin:$PATH

# Clone and build binutils
git clone git://sourceware.org/git/binutils-gdb.git binutils
mkdir build-binutils
cd build-binutils
../binutils/configure --prefix=$SYSROOT --target=$TARGET --disable-multilib
nice make -j4
make install
cd ../

# Clone linux and install system headers
git clone https://github.com/torvalds/linux.git linux
cd linux
make ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$SYSROOT/$TARGET headers_install
cd ../

# Install compiler
mkdir build-gcc; cd build-gcc
../gcc/configure --prefix=$SYSROOT --target=$TARGET --disable-multilib --disable-libsanitizer
make -j4 all-gcc
make install-gcc
cd ../

# Install glibc headers and startup files
git clone https://sourceware.org/git/glibc.git glibc
mkdir build-glibc; cd build-glibc
../glibc/configure --prefix=$SYSROOT/$TARGET --build=$MACHTYPE --host=$TARGET --target=$TARGET --with-headers=$SYSROOT/$TARGET/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/$TARGET/lib/
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $SYSROOT/$TARGET/lib/libc.so
touch $SYSROOT/$TARGET/include/gnu/stubs.h
cd ../

# Build libgcc
cd build-gcc
make -j4 all-target-libgcc
make install-target-libgcc
cd ../

# Build and install glibc
cd build-glibc
make -j4
make install
cd ../

# Finish runtime lib build
cd build-gcc
make -j4
make install
cd ../
