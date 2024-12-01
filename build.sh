#!/bin/bash

# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

# Exit immediately if a command exits with a non-zero status
set -e  

# ------------------------------------------------------------
# "remove" relative path
# ------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extra_path=$(realpath --relative-to=$(pwd) "${script_dir}")
pushd "${extra_path}"

# ------------------------------------------------------------
# set variables
# ------------------------------------------------------------

current_path=$(pwd)
workspace="${current_path}/.."

# Define hardware platform
# available platforms are...
hw_platform=PLATFORM_PROTO
#hw_platform=PLATFORM_SERIE

# Define product variant
# available products are...
#fw_product=APPLICATION
fw_product=TEST_APPLICATION

clean_up=true

# ------------------------------------------------------------
# check cmake
# ------------------------------------------------------------

if ! command -v cmake >/dev/null 2>&1; then
    echo "error: cmake could not be found"
    exit 1
fi

# ------------------------------------------------------------
# Parse command line arguments
# ------------------------------------------------------------

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --no-clean)
            clean_up=false
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# ------------------------------------------------------------
# clean up & build all
# ------------------------------------------------------------

if [[ $clean_up == true ]]; then
    rm -f "${workspace}/bin/CMakeCache.txt"
    rm -rf "${workspace}/bin/CMakeFiles"

    # configure
    cmake --no-warn-unused-cli \
        -DCMAKE_BUILD_TYPE:STRING=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
        -DCMAKE_C_COMPILER:FILEPATH=/usr/bin/arm-none-eabi-gcc \
        -DCMAKE_CXX_COMPILER:FILEPATH=/usr/bin/arm-none-eabi-g++ \
        -DHARDWARE_PLATFORM:STRING="${hw_platform}" \
        -DFIRMWARE_PRODUCT:STRING="${fw_product}" \
        -DENABLE_UNIT_TESTING="ON" \
        -S"${workspace}" \
        -B"${workspace}/bin" \
        -G "Ninja"

    # clean
    cmake --build "${workspace}/bin" --config Debug --target clean -j 6
fi

# Build all
cmake --build "${workspace}/bin" --config Debug -j 6 --

popd
