#!/bin/sh
# This script is used to control the floodlight on the camera

# This function takes a brightness percentage as an argument and returns the command string to set the brightness of the floodlight
get_floodlight_command_string() {
        initial_total=405
        brightness_pct=$1
        brightness_hex=$(printf "%02x" $((255*brightness_pct/100)))
        #echo "brightness_hex: ${brightness_hex}"
        brightness_dec=$((255*brightness_pct/100))
        sequence_start="\xaa\x55\x43\x06\x46"
        brightness_sequence="\x${brightness_hex}\x00\x07"
        combined_sequence="${sequence_start}${brightness_sequence}"
        # add brightness_dec and initial_total and print it as a 2 byte hex value in the format \x##\x##
        check_bytes_raw=$(printf "%.4x" $((${brightness_dec} + ${initial_total})))
        #echo "check_bytes_raw: ${check_bytes_raw}"
        # get the first 2 bytes of the check_bytes_raw using awk
        first_two_chars=$(echo $check_bytes_raw | awk '{print substr($0, 1, 2)}')
        # get the last 2 bytes of the check_bytes_raw using awk
        last_two_chars=$(echo $check_bytes_raw | awk '{print substr($0, 3, 2)}')
        # combine the first and last 2 bytes into a single string
        check_bytes="\x${first_two_chars}\x${last_two_chars}"
        echo -n "${combined_sequence}${check_bytes}"
}

# if there is no argument, print help
help() {
        echo "usage: floodlight_ctl ON <% value: 1-100>"
        echo "usage: floodlight_ctl OFF"
}

# if the script is run with no args, display help
if [ $# -eq 0 ]; then
        echo "Invalid number of arguments"
        help
        exit 1
fi

# if /dev/ttyUSB0 exists and is a character device, set DEVICE to /dev/ttyUSB0
if [ -c /dev/ttyUSB0 ]; then
    DEVICE="/dev/ttyUSB0"
fi

# if /dev/ttyUSB1 exists and is a character device, set DEVICE to /dev/ttyUSB1
if [ -c /dev/ttyUSB1 ]; then
    DEVICE="/dev/ttyUSB1"
fi

# if DEVICE is not set, print an error message and exit
if [ -z ${DEVICE} ]; then
    echo "Could not find a valid device"
    exit 1
fi

# if the argument is off or 0, set the brightness to 0 and exit
if [ "$1" == "off" ] || [ "$1" == "OFF" ]; then
        echo "OFF" > /var/run/floodlight.status
        brightness_pct=0
        echo "Setting brightness to 0"
        brightness_string=$(get_floodlight_command_string 0)
        echo -ne "${brightness_string}" > ${DEVICE}
fi

# if the argument is on, set the brightness to the value
if [ "$1" == "on" ] || [ "$1" == "ON" ]; then
        if [ $# -ne 2 ]; then
                echo "Invalid number of arguments"
                help
                exit 1
        fi
        if [ $2 -lt 1 ] || [ $2 -gt 100 ]; then
                echo "Invalid brightness value"
                help
                exit 1
        fi
        brightness_pct=$2
        echo "ON" > /var/run/floodlight.status
        echo ${brightness_pct} > /var/run/floodlight.brightness
        echo "Brightness PCT is ${brightness_pct}"
        brightness_string=$(get_floodlight_command_string ${brightness_pct})
        echo "Setting brightness to ${brightness_pct}: [${brightness_string}]"
        echo -ne "${brightness_string}" > ${DEVICE}
fi