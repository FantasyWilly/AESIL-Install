#!/bin/bash

# 發生錯誤就停止
set -e  

# 取得 sudo 權限
sudo -v

keep_sudo_alive() {
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done
}

# 背景持續更新 sudo 時效，直到腳本結束
keep_sudo_alive &
SUDO_KEEPALIVE_PID=$!

trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

SEP="============================================================"

echo "$SEP"
echo "ROS2 MAVROS - Jazzy 套件安裝開始"
echo "$SEP"

echo "[0/4] 更新套件清單"
sudo apt update
echo "$SEP"

echo "[2/4] 安裝 ROS Jazzy MAVROS"
sudo apt install -y ros-jazzy-mavros ros-jazzy-mavros-extras

echo "[3/4] 安裝 git"
sudo apt install -y git
echo "$SEP"

echo "[4/4] 安裝 git"
echo "下載 MAVROS (ROS2 分支)"

cd ~
if [ ! -d "mavros" ]; then
    git clone -b ros2 https://github.com/mavlink/mavros.git
else
    echo "mavros 資料夾已存在，略過 git clone 下載"
fi
echo "$SEP"

echo "[4/4] 安裝 GeographicLib datasets"
cd mavros/mavros/scripts
sudo bash install_geographiclib_datasets.sh
echo "$SEP"

echo "完成！MAVROS 已安裝"
echo "$SEP"