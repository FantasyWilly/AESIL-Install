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

fix_ubuntu_sources() {
    FILE="/etc/apt/sources.list.d/ubuntu.sources"
    TMP_FILE="$(mktemp)"

    echo "[修正] 檢查 ubuntu.sources..."

    if ! grep -q "noble-updates" "$FILE"; then
        echo "[修正] 更新 Suites..."

        awk '
        /^Suites:/ {
            if ($0 == "Suites: noble") {
                print "Suites: noble noble-updates noble-backports"
            } else {
                print $0
            }
            next
        }
        { print }
        ' "$FILE" > "$TMP_FILE"

        sudo cp "$TMP_FILE" "$FILE"
        rm -f "$TMP_FILE"

        echo "[OK] 已更新 ubuntu.sources"
    else
        echo "[OK] 已包含 noble-updates"
        rm -f "$TMP_FILE"
    fi
}

SEP="============================================================"

echo "$SEP"
echo "ROS2 Jazzy 安裝開始"
echo "$SEP"

echo "[0/7] 修正 apt sources..."
fix_ubuntu_sources
sudo apt update
echo "$SEP"

echo "[1/7] 設定 locale (UTF-8)..."
sudo apt update
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo "[Test] 目前 locale:"
locale
echo "$SEP"


echo "[2/7] 安裝必要工具..."
sudo apt install -y software-properties-common
echo "$SEP"

echo "[3/7] 啟用 Universe repository..."
sudo add-apt-repository -y universe
echo "$SEP"

echo "[4/7] 安裝 ROS 2 apt source..."
sudo apt update 
sudo apt install curl -y
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb
echo "$SEP"

echo "[5/7] 更新系統套件..."
sudo apt update
sudo apt upgrade -y
echo "$SEP"

echo "[6/7] 安裝 ROS2 Jazzy (ros-base)..."
sudo apt install -y ros-jazzy-ros-base
echo "$SEP"

echo "[7/7] 設定 ROS2 環境..."
if ! grep -Fxq "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

source ~/.bashrc
echo "已添加 source /opt/ros/jazzy/setup.bash >> ~/.bashrc"

echo "$SEP"
echo "安裝完成"
echo "請重新開機 執行 sudo reboot"
echo "$SEP"
