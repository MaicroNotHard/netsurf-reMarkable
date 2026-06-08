FROM ghcr.io/toltec-dev/rust:v4.0

# base:v3.1 (Debian unstable/sid frozen in 2023) baked these in as image-level
# ENV; rust:v4.0 (Debian 12/bookworm) instead ships them in /opt/x-tools/switch-arm.sh
# for opt-in sourcing. Bake the same values in here so both this Dockerfile's
# RUN steps and any container later started from the built image (e.g. `make build`
# invoking scripts/build.sh) see them without having to source that script.
ENV PATH="$PATH:/opt/x-tools/arm-remarkable-linux-gnueabihf/bin" \
    CHOST="arm-linux-gnueabihf" \
    CROSS_COMPILE="arm-linux-gnueabihf-" \
    PKG_CONFIG_LIBDIR="/opt/x-tools/arm-remarkable-linux-gnueabihf/arm-remarkable-linux-gnueabihf/sysroot/usr/lib/pkgconfig:/opt/x-tools/arm-remarkable-linux-gnueabihf/arm-remarkable-linux-gnueabihf/sysroot/lib/pkgconfig:/opt/x-tools/arm-remarkable-linux-gnueabihf/arm-remarkable-linux-gnueabihf/sysroot/opt/lib/pkgconfig" \
    PKG_CONFIG_SYSROOT_DIR="/opt/x-tools/arm-remarkable-linux-gnueabihf/arm-remarkable-linux-gnueabihf/sysroot" \
    SYSROOT="/opt/x-tools/arm-remarkable-linux-gnueabihf/arm-remarkable-linux-gnueabihf/sysroot"

# libexpat-dev was renamed to libexpat1-dev between Debian sid (2023 snapshot
# in base:v3.1) and bookworm (rust:v4.0).
RUN apt-get update -y && apt-get install -y bison flex libexpat1-dev libpng-dev git gperf automake libtool

ADD scripts/install_dependencies.sh install_dependencies.sh

# The toolchain sysroot ships prebuilt shared libs for OpenSSL 3.x
# (libssl.so.3/libcrypto.so.3) and curl (libcurl.so.4, linked against that
# same OpenSSL 3.x). install_dependencies.sh cross-builds static OpenSSL
# 1.1.1k and curl 7.75.0 into the same prefix (--disable-shared, so no new
# .so files are produced; only headers/.a libs are (re)written) - but the
# linker still finds and prefers the preexisting prebuilt .so's over the
# freshly built .a's, causing "undefined reference to
# SSL_get_peer_certificate/EVP_PKEY_id/..." (symbol names changed between
# OpenSSL 1.1.x and 3.x). Remove the prebuilt shared libs up front so
# nothing ever links against them.
RUN rm -f "$SYSROOT"/usr/lib/libssl.so* "$SYSROOT"/usr/lib/libcrypto.so* \
        "$SYSROOT"/usr/lib/libcurl.so* \
    && ./install_dependencies.sh
