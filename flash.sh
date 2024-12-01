#!/bin/bash

# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

# ------------------------------------------------------------
# "remove" relaite path
# ------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extra_path=$(realpath --relative-to=$(pwd) ${script_dir})
pushd ${extra_path} >/dev/null

source ./utilities.sh

# ------------------------------------------------------------
# set variables
# ------------------------------------------------------------

current_path=$(pwd)
workspace=${current_path}/..
picotool_path="${workspace}/bin/picotool/bin"

# ------------------------------------------------------------
# check picotool
# ------------------------------------------------------------

if [[ ! -d $picotool_path ]]; then
    echo "error: picotool not found in $picotool_path"
    ./picotool-build.sh
fi
if ! command -v $picotool_path/picotool >/dev/null 2>&1; then
    echo "Error: $picotool_path/picotool could not be found"
    echo "Please call picotool-build.sh script from build/ directory."
    exit 1
fi

# ------------------------------------------------------------
# search /dev/ttyUSB* device
# Attention: add your device identifier to the list
# ------------------------------------------------------------

# device_ids=("0403:6001" "1234:5678" "abcd:ef12" "1366:0105" "2e8a:0003")
# usb_device=$(find_usb_device "${device_ids[@]}")
# if [ $? -ne 0 ]; then
#     echo "no suitable device found in ${device_ids[@]}"
#     exit 1
# fi

# ------------------------------------------------------------
# update test binary
# ------------------------------------------------------------

test_address_filename=test_address.txt
binary_file=$(find_newest_file "${workspace}/bin" "uf2")
map_file=$(find_newest_file "${workspace}/bin" "elf.map")
if [ $? -eq 0 ]; then
    flash_uf2_file "$binary_file" "$picotool_path"
    #monitor_and_extract_address "$usb_device" "$picotool_path" "$workspace" "$test_address_filename"
    find_test_group_address "$workspace" "$map_file" "$test_address_filename"
else
    echo "no suitable .uf2 file found for flashing."
fi

# ------------------------------------------------------------
# get proper test group/identifier
# ------------------------------------------------------------

test_address_path="${workspace}/bin/${test_address_filename}"
if [ ! -f "$test_address_path" ]; then
    echo "warning: $test_address_path not found"
    flash_address=""
    flash_address_end=""
else
    flash_address=$(cat "${workspace}/bin/${test_address_filename}")
    flash_address_end="$(printf "0x%08x" $((${flash_address}+4)))"
fi

# ------------------------------------------------------------
# create binary file with parameter values
# note: little endian!
# ------------------------------------------------------------

if [[ ! -z "$flash_address" ]]; then
    param_filename=parameter.bin
    echo "param filename: ${workspace}/bin/${param_filename}"
    printf '%04x%04x' 0xffff 0xffff | sed 's/\(..\)\(..\)/\2\1/g' | xxd -r -p >${workspace}/bin/${param_filename}
    if [[ -n "${workspace}/bin/${param_filename}" ]]; then
        echo "reset test group and identifier by parameter file"
        ${picotool_path}/picotool load -u -v ${workspace}/bin/${param_filename} -o ${flash_address}
    fi
    rm -f ${param_filename}
fi

popd >/dev/null
