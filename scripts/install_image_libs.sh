#!/bin/sh

# Cross-compiles the optional image-format libraries that latest upstream NetSurf
# gained since the 2021 base: libwebp (WEBP) and libjxl (JPEG-XL). The reMarkable
# OS ships neither, so they are built static and baked into the nsfb binary (the
# libevdev pattern). libjxl's deps highway + brotli are also absent everywhere and
# built static here; libstdc++/libgcc_s ARE on the device, so they stay dynamic.
# Run as a separate Dockerfile layer so the base-deps layer stays cached.

# Fetch policy (keep consistent with install_dependencies.sh):
#   * Official release tarball published by the project -> curl + `sha256sum -c`
#     (canonical, self-contained, stable publisher checksum). e.g. libwebp.
#   * Only GitHub auto-archives (their checksums drift) or submodules needed
#     -> git clone pinned to an immutable COMMIT SHA. e.g. brotli, highway, libjxl.
#   Never pin a bare tag/branch, never curl an unchecked auto-archive.

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

git_clone_pinned() {
  # $1 = url, $2 = commit SHA, $3 = dir; shallow fetch of that exact commit
  git init -q "$3" && git -C "$3" remote add origin "$1"
  git -C "$3" fetch -q --depth 1 origin "$2"
  git -C "$3" checkout -q FETCH_HEAD
}

cd /tmp

# --- libwebp 1.4.0 (autotools, decoder) ---
curl -L "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.4.0.tar.gz" -o libwebp.tar.gz
echo "61f873ec69e3be1b99535634340d5bde750b2e4447caa1db9f61be3fd49ab1e5  libwebp.tar.gz" | sha256sum -c
mkdir -p libwebp && tar --strip-components=1 -C libwebp -xf libwebp.tar.gz && rm libwebp.tar.gz
cd libwebp
./configure --host="$CHOST" --prefix="$PREFIX" --enable-static --disable-shared \
  --disable-libwebpmux --disable-libwebpextras --enable-libwebpdemux=no \
  --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff --disable-gif
make -j "$JOBS"
make install
cd /tmp && rm -rf libwebp

# --- brotli 1.1.0 (cmake, static; libjxl dep) — pinned commit (upstream ships only auto-archives) ---
git_clone_pinned https://github.com/google/brotli ed738e842d2fbdf2d6459e39267a633c4a9b2f5d brotli
cmake_build brotli -DBROTLI_DISABLE_TESTS=ON
rm -rf brotli

# --- highway 1.2.0 (cmake, static; libjxl dep) — pinned commit (upstream ships only auto-archives) ---
git_clone_pinned https://github.com/google/highway 457c891775a7397bdb0376bb1031e6e027af1c48 highway
cmake_build highway -DHWY_ENABLE_TESTS=OFF -DHWY_ENABLE_EXAMPLES=OFF \
  -DHWY_ENABLE_CONTRIB=OFF -DHWY_ENABLE_INSTALL=ON
rm -rf highway

# --- libjxl 0.11.1 (cmake, static decoder; system hwy/brotli, bundled skcms) ---
# pinned commit; needs submodules (skcms etc.); hwy/brotli forced to the system static builds above.
git_clone_pinned https://github.com/libjxl/libjxl 794a5dcf0d54f9f0b20d288a12e87afb91d20dfc libjxl
git -C libjxl submodule update --init --recursive --depth 1
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
