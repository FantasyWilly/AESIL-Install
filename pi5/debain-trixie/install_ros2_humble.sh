#!/bin/bash

# µo¥Í¿ù»~´N°±¤î
set -e

WORKSPACE="${HOME}/ros2_humble"

SEP="============================================================"

echo "$SEP"
echo "ROS2 Humble Install Start"
echo "$SEP"

echo "[1/7] Install base dependencies"
sudo apt-get update
sudo apt-get install -y \
	python3-flake8-blind-except \
	python3-flake8-class-newline \
	python3-flake8-deprecated \
	python3-mypy \
	python3-pip \
	python3-pytest \
	python3-pytest-cov \
	python3-pytest-mock \
	python3-pytest-repeat \
	python3-pytest-rerunfailures \
	python3-pytest-runner \
	python3-pytest-timeout \
	python3-rosdep2 \
	python3-colcon-core \
	vcstool \
	build-essential \
	git
echo "$SEP"

echo "[2/7] Get ROS2 Source Code"
cd ~/
mkdir -p "${WORKSPACE}"
cd "${WORKSPACE}"

mkdir -p src
if [ ! -f ros2.repos ]; then
  echo "Download ros2.repos..."
  wget https://raw.githubusercontent.com/ros2/ros2/humble/ros2.repos
else
  echo "ros2.repos Already exists... Skip Download"
fi
vcs import src < ros2.repos
echo "$SEP"

echo "[3/7] Install System Dependencies"
sudo rm -rf /etc/ros/rosdep/sources.list.d/20-default.list
sudo rosdep init || true
rosdep update
rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
  --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers python3-vcstool ignition-math6 ignition-cmake2 ignition-common3 ignition-transport8" || true
echo "$SEP"

echo "[4/7] Refer to ROS2 using Cyclone DDS"
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export MAKEFLAGS="-j$(nproc)"
echo "$SEP"

echo "[5/7] exclude Fast DDS / Connext"
shopt -s globstar nullglob
for d in \
  src/**/rmw_fastrtps \
  src/**/rmw_fastrtps_shared_cpp \
  src/**/rmw_fastrtps_cpp \
  src/**/rmw_fastrtps_dynamic_cpp \
  src/**/rmw_connextdds \
  src/**/rmw_connextdds_common \
  src/**/rmw_connextddsmicro
do
  if [ -d "$d" ]; then
    touch "$d/COLCON_IGNORE"
    echo "  ignored: $d"
  fi
done
echo "$SEP"

echo "[6/7] Clear old files && Start build"
rm -rf install build log
colcon build \
  --symlink-install \
  --event-handlers console_direct+ \
  --cmake-args \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DRMW_IMPLEMENTATION=rmw_cyclonedds_cpp
echo "$SEP"

echo "[7/7] Setting ROS2 environment"
if ! grep -Fxq "source ${WORKSPACE}/install/setup.bash" ~/.bashrc; then
    echo "source ${WORKSPACE}/install/setup.bash" >> ~/.bashrc
fi

echo "Add to source ~/$WORKSPACE/setup.bash >> ~/.bashrc"

echo "$SEP"
echo "Install successful"
echo "[Next] Please run¡G"
echo "source ${WORKSPACE}/install/setup.bash"
echo "$SEP"
