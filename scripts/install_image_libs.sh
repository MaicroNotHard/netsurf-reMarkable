#!/bin/sh

# Cross-compiles the optional image-format libraries that latest upstream NetSurf
# gained since the 2021 base: libwebp (WEBP) and libjxl (JPEG-XL). The reMarkable
# OS ships neither, so they are built static and baked into the nsfb binary (the
# libevdev pattern). libjxl's deps highway + brotli are also absent everywhere and
# built static here; libstdc++/libgcc_s ARE on the device, so they stay dynamic.
# Run as a separate Dockerfile layer so the base-deps layer stays cached.

set -e
export DEBIAN_FRONTEND=noninteractive
JOBS=$(nproc)
TC=/usr/share/cmake/$CHOST.cmake
PREFIX=$SYSROOT/usr

cmake_build() {
  # $1 = src dir, rest = extra cmake args
  src="$1"; shift
  cmake -S "$src" -B "$src/_b" \
    -DCMAKE_TOOLCHAIN_FILE="$TC" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    "$@"
  cmake --build "$src/_b" -j "$JOBS"
  cmake --install "$src/_b"
}

cd /tmp

# --- libwebp 1.4.0 (autotools, decoder) ---
curl -L "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.4.0.tar.gz" -o libwebp.tar.gz
mkdir -p libwebp && tar --strip-components=1 -C libwebp -xf libwebp.tar.gz && rm libwebp.tar.gz
cd libwebp
./configure --host="$CHOST" --prefix="$PREFIX" --enable-static --disable-shared \
  --disable-libwebpmux --disable-libwebpextras --enable-libwebpdemux=no \
  --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff --disable-gif
make -j "$JOBS"
make install
cd /tmp && rm -rf libwebp

# --- brotli 1.1.0 (cmake, static; libjxl dep) ---
curl -L "https://github.com/google/brotli/archive/refs/tags/v1.1.0.tar.gz" -o brotli.tar.gz
mkdir -p brotli && tar --strip-components=1 -C brotli -xf brotli.tar.gz && rm brotli.tar.gz
cmake_build brotli -DBROTLI_DISABLE_TESTS=ON
rm -rf brotli

# --- highway 1.2.0 (cmake, static; libjxl dep) ---
curl -L "https://github.com/google/highway/archive/refs/tags/1.2.0.tar.gz" -o hwy.tar.gz
mkdir -p highway && tar --strip-components=1 -C highway -xf hwy.tar.gz && rm hwy.tar.gz
cmake_build highway -DHWY_ENABLE_TESTS=OFF -DHWY_ENABLE_EXAMPLES=OFF \
  -DHWY_ENABLE_CONTRIB=OFF -DHWY_ENABLE_INSTALL=ON
rm -rf highway

# --- libjxl 0.11.1 (cmake, static decoder; system hwy/brotli, bundled skcms) ---
# needs submodules (skcms etc.); hwy/brotli forced to the system static builds above.
git clone -b v0.11.1 --depth 1 --recursive --shallow-submodules \
  https://github.com/libjxl/libjxl.git libjxl
cmake_build libjxl \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_TOOLS=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_JNI=OFF \
  -DJPEGXL_ENABLE_SJPEG=OFF \
  -DJPEGXL_ENABLE_OPENEXR=OFF \
  -DJPEGXL_ENABLE_PLUGINS=OFF \
  -DJPEGXL_ENABLE_TRANSCODE_JPEG=OFF \
  -DJPEGXL_ENABLE_SKCMS=ON \
  -DJPEGXL_FORCE_SYSTEM_HWY=ON \
  -DJPEGXL_FORCE_SYSTEM_BROTLI=ON
rm -rf libjxl

echo "install_image_libs.sh: done"
