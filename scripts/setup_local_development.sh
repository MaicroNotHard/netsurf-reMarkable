#!/bin/bash

# Set up script for local development.
# Clones libnsfb and the netsurf core into the build directory. The repository
# URLs come from versions.sh so there is a single source of truth.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/versions.sh

clone() {
    git clone ${LIBNSFB_REPOSITORY}.git ${BUILD_DIR}/libnsfb
    git clone ${NETSURF_REPOSITORY}.git ${BUILD_DIR}/netsurf
}

if [ -z ${BUILD_DIR} ]; then echo "BUILD_DIR must be set" && exit 1; fi

case $1 in
    versioned)
        echo "Setting up fixed versions of repositories"
        clone
        pushd ${BUILD_DIR}/libnsfb
        git checkout ${LIBNSFB_VERSION}
        popd
        pushd ${BUILD_DIR}/netsurf
        git checkout ${NETSURF_VERSION}
        popd
        ;;
    head)
        echo "Setting up HEAD of repositories"
        clone
        ;;
    *)
        echo "You must run the script with the first argument either 'versioned' or 'head'"
        exit 1
        ;;
esac
