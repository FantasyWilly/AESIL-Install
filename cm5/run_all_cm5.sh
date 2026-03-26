#!/bin/bash
set -e

cd ~/AESIL-Install/cm5

sudo -v

keep_sudo_alive() {
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done
}

keep_sudo_alive &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

chmod +x install_ros2_jazzy.sh
chmod +x install_opencv-4.10.0.sh
chmod +x install_mavros_jazzy.sh

./install_ros2_jazzy.sh
./install_opencv-4.10.0.sh
./install_mavros_jazzy.sh
