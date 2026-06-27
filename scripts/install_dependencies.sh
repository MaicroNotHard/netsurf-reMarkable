#!/bin/sh

# This script installs and cross-compiles the dependencies required for netsurf build.
# To be run during the Dockerfile build.

# Build libiconv 1.16
export DEBIAN_FRONTEND=noninteractive \
    && mkdir libiconv \
    && cd libiconv \
    && curl --fail --retry 3 --retry-delay 3 --retry-connrefused "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz" -o libiconv.tar.gz \
    && echo "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04  libiconv.tar.gz" > sha256sums \
    && sha256sum -c sha256sums \
    && tar --strip-components=1 -xf libiconv.tar.gz \
    && rm libiconv.tar.gz sha256sums \
    && ./configure --prefix=$SYSROOT/usr --host="$CHOST" --enable-static --disable-shared \
    && make -j $(nproc) \
    && make install \
    && cd .. \
    && rm -rf libiconv || exit 1

# OpenSSL and curl are not built here: the toolchain sysroot already ships
# OpenSSL 3.x and curl (shared libs, headers and pkg-config files), which
# NetSurf picks up via pkg-config and links against dynamically. The device
# provides matching libssl.so.3/libcrypto.so.3/libcurl.so.4 at runtime.

# Build FreeType 2.10.4
export DEBIAN_FRONTEND=noninteractive \
    && mkdir freetype \
    && cd freetype \
    && curl --fail --retry 3 --retry-delay 3 --retry-connrefused "https://gitlab.freedesktop.org/freetype/freetype/-/archive/VER-2-10-4/freetype-VER-2-10-4.tar.gz" -o freetype.tar.gz \
    && echo "4d47fca95debf8eebde5d27e93181f05b4758701ab5ce3e7b3c54b937e8f0962  freetype.tar.gz" > sha256sums \
    && sha256sum -c sha256sums \
    && tar --strip-components=1 -xf freetype.tar.gz \
    && rm freetype.tar.gz sha256sums \
    && bash autogen.sh \
    && ./configure --without-zlib --without-png --enable-static=yes --enable-shared=no --without-bzip2 --host=arm-linux-gnueabihf --host="$CHOST" --disable-freetype-config \
    && make -j $(nproc) \
    && DESTDIR="$SYSROOT" make install \
    && cd .. \
    && rm -rf freetype || exit 1

# Build libjpeg-turbo 2.0.90
export DEBIAN_FRONTEND=noninteractive \
    && mkdir libjpeg-turbo \
    && cd libjpeg-turbo \
    && curl --fail --retry 3 --retry-delay 3 --retry-connrefused "https://codeload.github.com/libjpeg-turbo/libjpeg-turbo/tar.gz/refs/tags/2.0.90" -o libjpeg-turbo.tar.gz \
    && echo "6a965adb02ad898b2ae48214244618fe342baea79db97157fdc70d8844ac6f09  libjpeg-turbo.tar.gz" > sha256sums \
    && sha256sum -c sha256sums \
    && tar --strip-components=1 -xf libjpeg-turbo.tar.gz \
    && rm libjpeg-turbo.tar.gz sha256sums \
    && cmake -DCMAKE_SYSROOT="$SYSROOT" -DCMAKE_TOOLCHAIN_FILE=/usr/share/cmake/$CHOST.cmake -DCMAKE_INSTALL_LIBDIR=$SYSROOT/lib -DCMAKE_INSTALL_INCLUDEDIR=$SYSROOT/usr/include -DENABLE_SHARED=FALSE \
    && make -j $(nproc) \
    && make install \
    && cd .. \
    && rm -rf libjpeg-turbo || exit 1

# Build expat 2.8.1 (libdom's XML binding needs it; the armv7 toolchain
# sysroot ships a cross-compiled copy already, but the aarch64 one doesn't)
export DEBIAN_FRONTEND=noninteractive \
    && mkdir expat \
    && cd expat \
    && curl --fail --retry 3 --retry-delay 3 --retry-connrefused -L "https://github.com/libexpat/libexpat/releases/download/R_2_8_1/expat-2.8.1.tar.gz" -o expat.tar.gz \
    && echo "a52eb72108be160e190b5cafa5bba8663f1313f2013e26060d1c18e26e31067b  expat.tar.gz" > sha256sums \
    && sha256sum -c sha256sums \
    && tar --strip-components=1 -xf expat.tar.gz \
    && rm expat.tar.gz sha256sums \
    && ./configure --prefix=/usr --host="$CHOST" --enable-static --disable-shared \
    && make -j $(nproc) \
    && DESTDIR="$SYSROOT" make install \
    && cd .. \
    && rm -rf expat || exit 1

# Build libevdev 1.13.6 (statically linked into the netsurf binary; the
# device ships no libevdev.so.2)
export DEBIAN_FRONTEND=noninteractive \
    && mkdir libevdev \
    && cd libevdev \
    && curl --fail --retry 3 --retry-delay 3 --retry-connrefused -L "https://www.freedesktop.org/software/libevdev/libevdev-1.13.6.tar.xz" -o libevdev.tar.xz \
    && echo "73f215eccbd8233f414737ac06bca2687e67c44b97d2d7576091aa9718551110  libevdev.tar.xz" > sha256sums \
    && sha256sum -c sha256sums \
    && tar --strip-components=1 -xf libevdev.tar.xz \
    && rm libevdev.tar.xz sha256sums \
    && ./configure --prefix=/usr --host="$CHOST" --enable-static --disable-shared \
    && make -j $(nproc) \
    && DESTDIR="$SYSROOT" make install \
    && cd .. \
    && rm -rf libevdev || exit 1
