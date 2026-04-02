#!/usr/bin/env bash
set -e

WORKSPACE="$HOME/mavros_ws"
SRC_DIR="$WORKSPACE/src"

SEP="============================================================"

echo "$SEP"
echo "ROS2 MAVROS Install Start"
echo "$SEP"

echo "[1/9] Installing base tools..."
sudo apt update
sudo apt install -y \
  vcstool \
  python3-rosinstall-generator \
  python3-osrf-pycommon \
  python3-pip
echo "$SEP"

echo "[2/9] Creating workspace..."
mkdir -p "$SRC_DIR"
cd "$WORKSPACE"
echo "$SEP"

echo "[3/9] Fetching MAVLink and MAVROS source..."
rosinstall_generator --format repos mavlink | tee /tmp/mavlink.repos
rosinstall_generator --format repos --upstream mavros | tee /tmp/mavros.repos

if [ ! -d "$SRC_DIR/mavlink" ]; then
  vcs import "$SRC_DIR" < /tmp/mavlink.repos
else
  echo "  - mavlink already exists, skipping"
fi

if [ ! -d "$SRC_DIR/mavros" ]; then
  vcs import "$SRC_DIR" < /tmp/mavros.repos
else
  echo "  - mavros already exists, skipping"
fi
echo "$SEP"

echo "[4/9] Cloning missing dependencies for Debian..."
if [ ! -d "$SRC_DIR/diagnostics" ]; then
  git clone https://github.com/ros/diagnostics.git -b ros2-humble "$SRC_DIR/diagnostics"
else
  echo "  - diagnostics already exists, skipping"
fi

if [ ! -d "$SRC_DIR/geographic_info" ]; then
  git clone https://github.com/ros-geographic-info/geographic_info.git -b ros2 "$SRC_DIR/geographic_info"
else
  echo "  - geographic_info already exists, skipping"
fi
echo "$SEP"

echo "[5/9] Installing Python dependencies..."
python3 -m pip install --break-system-packages future
echo "$SEP"

echo "[6/9] Installing remaining ROS dependencies..."
rosdep install --from-paths "$SRC_DIR" --ignore-src -y \
  --skip-keys "launch_testing launch_testing_ament_cmake geographic_msgs python3-future"
echo "$SEP"

echo "[7/9] Installing GeographicLib datasets..."
sudo "$SRC_DIR/mavros/mavros/scripts/install_geographiclib_datasets.sh"
echo "$SEP"

echo "[8/9] Building workspace..."
colcon build --symlink-install --cmake-args -DBUILD_TESTING=OFF
echo "$SEP"

echo "[9/9] Setting ROS2 MAVROS environment"
if ! grep -Fxq "source $WORKSPACE/install/setup.bash" ~/.bashrc; then
    echo "# ROS2 - MAVROS" >> ~/.bashrc
    echo "source $WORKSPACE/install/setup.bash" >> ~/.bashrc
fi
echo "Add to source $WORKSPACE/install/setup.bash >> ~/.bashrc"
echo "$SEP"

echo
echo "✅ Done"
echo "Run the following command to source the terminal:"
echo
echo "To run:"
echo "source $WORKSPACE/install/setup.bash"
echo "$SEP"
