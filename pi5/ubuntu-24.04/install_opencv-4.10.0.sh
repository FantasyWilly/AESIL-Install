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
echo "OpenCV 4.10.0 安裝開始"
echo "$SEP"

echo "[0/6] 卸載舊版 OpenCV..."
sudo apt purge -y 'libopencv*' python3-opencv || true
sudo apt autoremove -y
sudo apt update
sudo apt install -y build-essential pkg-config

sudo rm -f /usr/local/lib/pkgconfig/opencv4.pc
sudo find /usr/local -path "*/pkgconfig/opencv4.pc" -delete 2>/dev/null || true

sudo rm -f /usr/local/lib/libopencv*.so*
sudo rm -f /usr/local/lib/libopencv*.a
sudo rm -rf /usr/local/include/opencv4
sudo rm -rf /usr/local/include/opencv2
sudo ldconfig
echo "$SEP"

echo "[2/6] 檢查舊版是否已移除..."
pkg-config --exists opencv4 && {
    echo "[警告] 仍偵測到舊的 opencv4.pc"
    pkg-config opencv4 --modversion || true
} || echo "[OK] 找不到舊版 OpenCV pkg-config"
echo "$SEP"

echo "[3/6] 安裝編譯依賴..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    gfortran \
    openexr \
    libatlas-base-dev \
    python3-dev \
    python3-numpy \
    libtbb-dev \
    libdc1394-dev \
    libopenexr-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev
echo "$SEP"

echo "[4/6] 下載 OpenCV 4.10.0 與 opencv_contrib..."
cd "$HOME"

wget -O opencv-4.10.0.tar.gz \
    https://github.com/opencv/opencv/archive/refs/tags/4.10.0.tar.gz

wget -O opencv-contrib-4.10.0.tar.gz \
    https://github.com/opencv/opencv_contrib/archive/refs/tags/4.10.0.tar.gz

tar -xzf opencv-4.10.0.tar.gz
tar -xzf opencv-contrib-4.10.0.tar.gz

rm -f opencv-4.10.0.tar.gz
rm -f opencv-contrib-4.10.0.tar.gz

mv ~/opencv_contrib-4.10.0 ~/opencv-4.10.0
echo "$SEP"

echo "[5/6] 開始編譯 OpenCV..."
cd "$HOME/opencv-4.10.0"
mkdir -p build
cd build

cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D OPENCV_EXTRA_MODULES_PATH="../opencv_contrib-4.10.0/modules" \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D OPENCV_PC_FILE_NAME=opencv4.pc \
  -D WITH_TBB=ON \
  -D WITH_GTK=ON \
  -D WITH_QT=OFF \
  -D WITH_OPENGL=ON \
  -D WITH_V4L=ON \
  -D WITH_GSTREAMER=ON \
  -D WITH_FFMPEG=ON \
  -D WITH_1394=OFF \
  -D BUILD_opencv_java=OFF \
  -D BUILD_EXAMPLES=OFF \
  -D INSTALL_C_EXAMPLES=OFF \
  -D INSTALL_PYTHON_EXAMPLES=OFF \
  -D OPENCV_ENABLE_NONFREE=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  -D BUILD_opencv_python3=ON \
  -D BUILD_opencv_python2=OFF \
  ..

make -j"$(nproc)"
sudo make install
sudo ldconfig
echo "$SEP"

echo "[6/6] 檢查 OpenCV 安裝結果..."
pkg-config opencv4 --modversion
pkg-config opencv4 --libs
python3 -c "import cv2; print(cv2.__version__)"
echo "$SEP"

echo "OpenCV 4.10.0 安裝完成"
echo "$SEP"
