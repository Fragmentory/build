#!/bin/bash

# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

# ------------------------------------------------------------
# "remove" relaite path
# ------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extra_path=$(realpath --relative-to=$(pwd) ${script_dir})
pushd ${extra_path}

source ./utilities.sh

# ------------------------------------------------------------
# set variables
# ------------------------------------------------------------

current_path=$(pwd)
workspace=${current_path}/..
picotool_path=${workspace}/bin/picotool/bin

pass_phrase="__UNIT_TEST_DONE__"
log_filename=serial_output.txt
param_filename=parameter.bin
backup_filename=parameter-backup.bin

# ------------------------------------------------------------
# get proper test group/identifier
# ------------------------------------------------------------

test_addres_filename=test_address.txt
test_addres_path=${workspace}/bin/${test_addres_filename}
param_filename=parameter.bin
if [ ! -f "${test_addres_path}" ]; then
    echo "error: ${test_addres_path} not found."
    echo "run flash.sh (from build/) or enter the well-known memory address for the test grpoup/identifier."
    exit 1
fi
flash_address=$(cat ${test_addres_path})

# ------------------------------------------------------------
# check picotool
# ------------------------------------------------------------

if [ ! -d ${picotool_path} ]; then
    echo "error: picotool not found in ${picotool_path}"
    . ./picotool-build.sh
fi
if ! command -v ${picotool_path}/picotool >/dev/null 2>&1; then
    echo "Error: ${picotool_path}/picotool could not be found"
    echo "Please call build script in the ${workspace}/build directory."
    exit
fi

# ------------------------------------------------------------
# check parameter
# ------------------------------------------------------------

if [ "$#" -eq 2 ]; then
    group=$1
    identifier=$2
    binary_file=""
elif [ "$#" -eq 3 ]; then
    group=$1
    identifier=$2
    binary_file=$3
else
    echo "Usage: $0 <group> <identifier> [binary.uf2]"
    exit 1
fi

# ------------------------------------------------------------
# create binary file with parameter values
# note: little endian!
# ------------------------------------------------------------

echo "group:      ${group}"
echo "identifier: ${identifier}"

echo "param filename: ${workspace}/bin/${param_filename}"
printf '%04x%04x' $group $identifier | sed 's/\(..\)\(..\)/\2\1/g' | xxd -r -p >${workspace}/bin/${param_filename}
if [[ -n "${workspace}/bin/${param_filename}" ]]; then
    echo "reset test group and identifier by parameter file"
    ${picotool_path}/picotool load -u -v ${workspace}/bin/${param_filename} -o ${flash_address}
fi
rm -f ${param_filename}

# ------------------------------------------------------------
# reboot in app mode
# (= start app. don't worry: test app reboot in bootsel mode)
# ------------------------------------------------------------

${picotool_path}/picotool reboot -a

# ------------------------------------------------------------
# search /dev/ttyUSB* device
# Attention: add your device identifier to the list
# ------------------------------------------------------------
max_attempts=100
sleep_interval=0.01  # 10ms

device_ids=("0403:6001" "1234:5678" "abcd:ef12" "1366:0105")
#device_ids=("2e8a:0003")
for (( attempt=1; attempt<=max_attempts; attempt++ )); do
    usb_device=$(find_usb_device "${device_ids[@]}")
    find_usb_device_status=$?
    if [ $find_usb_device_status -eq 0 ]; then
        break
    fi
    sleep ${sleep_interval}
done
if [ -z $usb_device ]; then
    echo "No suitable device found after $max_attempts attempts in ${device_ids[@]}"
    exit 1
else
    echo "Found suitable device: [$usb_device]"
fi

# ------------------------------------------------------------
# set port params and redirect test output
# ------------------------------------------------------------

stty -F ${usb_device} 115200 cs8 -cstopb -parenb
stdbuf -oL cat ${usb_device} >>${workspace}/bin/${log_filename} &
cat_pid=$!

# ------------------------------------------------------------
# set trap to kill background processes on exit
# ------------------------------------------------------------
trap "kill $cat_pid 2>/dev/null" EXIT

# ------------------------------------------------------------
# update test binary
# ------------------------------------------------------------

if [ -n "$binary_file" ]; then
    echo "Flashing binary file: $binary_file"
    flash_uf2_file "$binary_file" "$picotool_path"
fi

# ------------------------------------------------------------
# check for a pass prase to kill this script
# ------------------------------------------------------------

tail -f ${workspace}/bin/${log_filename} | while read LINE; do
    echo "$LINE"
    if [[ "$LINE" == *${pass_phrase}* ]]; then
        kill -SIGTERM $cat_pid
        break
    fi
done

# ------------------------------------------------------------
# check if pico is back from the reboot
# ------------------------------------------------------------

for i in {1..200}; do
    sleep 0.1
    ${picotool_path}/picotool info >/dev/null
    if [ $? -eq 0 ]; then
        break
    fi
done

rm -f ${workspace}/bin/${log_filename}
