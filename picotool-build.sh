#!/bin/bash

# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

# --------------------------------------------------
# update ubuntu
# --------------------------------------------------

#sudo apt update
#sudo apt upgrade -y
sudo apt install build-essential pkg-config libusb-1.0-0-dev cmake

# ------------------------------------------------------------
# "remove" relaite path
# ------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extra_path=$(realpath --relative-to=$(pwd) ${script_dir})
pushd ${extra_path} >/dev/null

# ------------------------------------------------------------
# set path variables
# ------------------------------------------------------------

current_path=$(pwd)
workspace=${current_path}/..
picotool_path="${workspace}/bin/picotool"

# --------------------------------------------------
# download picotool sources
# --------------------------------------------------

if [ -d ${picotool_path} ]; then
	cd ${picotool_path}
	git checkout master
	git reset --hard
	git pull
	git submodule update --init --recursive
else
	git clone https://github.com/raspberrypi/picotool.git ${picotool_path}
	cd ${picotool_path}
	git checkout master
	git pull
	git submodule update --init --recursive
fi

if [ ! -d ${picotool_path}/build ]; then
	mkdir ${picotool_path}/build
fi

rm -f ${picotool_path}/build/CMakeCache.txt

# --------------------------------------------------
# build & install picotool
# --------------------------------------------------

if [ -z "${PICO_SDK_PATH}" ]; then
	# ATTENTION: pico sdk dependency
	export PICO_SDK_PATH=${workspace}/../pico-sdk/pico_sdk-src/
fi

cd ${picotool_path}/build
cmake -DCMAKE_INSTALL_PREFIX=${workspace}/bin/picotool -G "Unix Makefiles" ..
make -j6 install
#make clean

# --------------------------------------------------
# copy usb dev rules
# --------------------------------------------------

echo "copy ${picotool_path}/udev/99-picotool.rules"
sudo cp ${picotool_path}/udev/99-picotool.rules /etc/udev/rules.d/

cd ${current_path}
popd >/dev/null

