#!/bin/sh

# Run from your localhost
# This script will:
#   + ssh copy all the MQTT requirements to the Wyze Cam V3 (that already has wz_mini hacks installed)
#   + overwrite /configs/.user_config iCamera settings with all default settings
#   + overwrite web server init script with a fixed version

if [ -z "$1" ]; then
    echo "Usage: $0 <wyze cam v3 host address> /path/to/keyfile"
    echo "Example: $ ./install.sh 10.0.0.172 ./opensshkey"
    echo "Ensure to update mosquitto.conf with MQTT broker connection details and desired status update interval."
    exit 1
fi
WYZECAMV3_HOST=$1
WYZECAM_KEY=$2

echo "Uploading MQTT client to camera at ${WYZECAMV3_HOST}..."
ssh -i ${WYZECAM_KEY} root@${WYZECAMV3_HOST} 'mkdir -p /media/mmc/mosquitto/bin; mkdir -p /media/mmc/mosquitto/lib; mkdir -p /media/mmc/mosquitto/installer'
scp -i ${WYZECAM_KEY} ./installer/* root@${WYZECAMV3_HOST}:/media/mmc/mosquitto/installer
scp -i ${WYZECAM_KEY} ./bin/* root@${WYZECAMV3_HOST}:/media/mmc/mosquitto/bin
scp -i ${WYZECAM_KEY} ./lib/* root@${WYZECAMV3_HOST}:/media/mmc/mosquitto/lib
scp -i ${WYZECAM_KEY} mosquitto.conf root@${WYZECAMV3_HOST}:/media/mmc/mosquitto
scp -i ${WYZECAM_KEY} floodlight_ctl.sh root@${WYZECAMV3_HOST}:/opt/wz_mini/bin

echo "Installing MQTT client on camera..."
ssh -i ${WYZECAM_KEY} root@${WYZECAMV3_HOST} '/media/mmc/mosquitto/installer/setup.sh'
echo "Camera rebooting..."
echo "You should see MQTT messages published when camera restarts."
echo "Done"
