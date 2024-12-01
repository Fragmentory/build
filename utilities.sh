# Copyright (c) 2023, Roman Koch, koch.roman@gmail.com
# SPDX-License-Identifier: MIT

find_newest_file() {
    local directory="$1"
    local extension="$2"

    if [ -z "$directory" ] || [ -z "$extension" ]; then
        echo "Usage: find_newest_file <directory> <extension>"
        return 1
    fi

    local files=($(find "$directory" -maxdepth 1 -name "*$extension"))
    local file_count=${#files[@]}

    if [ "$file_count" -eq 0 ]; then
        echo "No $extension file found."
        return 1
    elif [ "$file_count" -eq 1 ]; then
        echo "${files[0]}"
    else
        newest_file=$(ls -t "${files[@]}" | head -n 1)
        echo "$newest_file"
    fi
}

flash_uf2_file() {
    local binary_file="$1"
    local picotool_path="$2"

    if [[ -n "$binary_file" ]]; then
        echo "Uploading binary file: $binary_file"
        ${picotool_path}/picotool load -v "${binary_file}"
    else
        echo "No binary file provided for flashing."
        return 1
    fi
}

find_usb_device() {
    local device_ids=("$@")
    local usb_device=""

    for device_id in "${device_ids[@]}"; do
        # Prüfen, ob das Gerät mit der ID vorhanden ist
        if lsusb | grep -q "$device_id"; then
            # Hole die Vendor und Product ID aus device_id
            local vendor_id="${device_id%%:*}"
            local product_id="${device_id##*:}"

            # Suche nach dem Gerät im Verzeichnis /dev/ttyUSB* oder /dev/ttyACM*
            for dev in /dev/ttyUSB* /dev/ttyACM*; do
                # Falls kein Gerät vorhanden, continue
                [ ! -e "$dev" ] && continue

                # Prüfe, ob das Gerät mit der Vendor/Product ID übereinstimmt
                if udevadm info --query=all --name="$dev" | grep -q "ID_VENDOR_ID=$vendor_id" && \
                   udevadm info --query=all --name="$dev" | grep -q "ID_MODEL_ID=$product_id"; then
                    echo "$dev"
                    return 0
                fi
            done
        fi
    done

    return 1
}

find_usb_device1() {
    local device_ids=("$@")
    local usb_device=""

    for device_id in "${device_ids[@]}"; do
        local device_count
        device_count=$(lsusb | grep -c "$device_id")

        if [ $device_count -lt 1 ]; then
            continue
        elif [ $device_count -gt 1 ]; then
            usb_device=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | grep -m 1 "tty")
            #usb_device=$(ls /dev/ttyACM* 2>/dev/null | grep -m 1 "tty")
            if [ -z "$usb_device" ]; then
                continue
            else
                echo "$usb_device"
                return 0
            fi
        else
            usb_device=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | grep -m 1 "tty")
            #usb_device=$(ls /dev/ttyACM* 2>/dev/null | grep -m 1 "tty")
            if [ -z "$usb_device" ]; then
                continue
            else
                echo "$usb_device"
                return 0
            fi
        fi
    done

    return 1
}

monitor_and_extract_address() {
    local usb_device="$1"
    local picotool_path="$2"
    local workspace="$3"
    local test_address_filename="$4"

    local log_filename="test_address_log.txt"
    local pass_phrase="__UNIT_TEST_DONE__"
    local address_pattern="address test_group:"

    echo "estimate test identifier address on ${usb_device}"

    stty -F ${usb_device} 115200 cs8 -cstopb -parenb
    stdbuf -oL cat ${usb_device} >>${workspace}/bin/${log_filename} &
    local cat_pid=$!

    trap "kill $cat_pid 2>/dev/null" EXIT

    ${picotool_path}/picotool reboot -a

    tail -f "${workspace}/bin/${log_filename}" | while read LINE; do
        if [[ "$LINE" == *${pass_phrase}* ]]; then
            kill -SIGTERM $cat_pid
            break
        elif [[ "$LINE" == *${address_pattern}* ]]; then
            local address=$(echo "$LINE" | sed -n 's/.*: *\([0-9A-Fa-fx]*\).*/\1/p')
            echo "found test address: $address"
            echo "$address" >"${workspace}/bin/${test_address_filename}"
            kill -SIGTERM $cat_pid
            break
        fi
    done

    for i in {1..50}; do
        sleep 0.1
        ${picotool_path}/picotool info >/dev/null
        if [ $? -eq 0 ]; then
            break
        fi
    done

    rm -f ${workspace}/bin/${log_filename}
}

find_test_group_address() {
    local workspace="$1"
    local map_file="$2"
    local test_address_filename="$3"

    local map_file_path="$map_file"

    if [ ! -f "$map_file_path" ]; then
        echo "map file $map_file_path not found!"
        return 1
    fi

    local address=$(grep -E "^\s*(0x[0-9A-Fa-f]+)\s+.*test_group" "$map_file_path" | awk '
    {
        if (NF >= 2) {
            # Die Adresse befindet sich in der ersten Spalte
            print $1
        }
    }')
    if [ -z "$address" ]; then
        echo "address of test_group not found."
        return 1
    fi

    # Schreibe die Adresse in die angegebene Datei
    echo "$address" >"${workspace}/bin/${test_address_filename}"
}
