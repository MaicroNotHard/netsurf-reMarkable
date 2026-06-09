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

# install_dependencies.sh builds a static libevdev, but the sysroot also ships
# a prebuilt libevdev.so.2 that the linker would otherwise prefer; remove it so
# the static archive is used.
RUN rm -f "$SYSROOT"/usr/lib/libevdev.so* \
    && ./install_dependencies.sh
