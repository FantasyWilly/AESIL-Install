#!/usr/bin/env bash
set -e

WORKSPACE="$HOME/mavros_ws"

echo "[1/8] Installing base tools..."
sudo apt update
sudo apt install -y \
  vcstool \
  python3-rosinstall-generator \
  python3-osrf-pycommon \
  python3-pip

echo "[2/8] Creating workspace..."
mkdir -p "$WORKSPACE/src"
cd "$WORKSPACE"

echo "[3/8] Fetching MAVLink and MAVROS source..."
rosinstall_generator --format repos mavlink | tee /tmp/mavlink.repos
rosinstall_generator --format repos --upstream mavros | tee /tmp/mavros.repos

if [ ! -d "$WORKSPACE/src/mavlink" ]; then
  vcs import src < /tmp/mavlink.repos
else
  echo "  - mavlink already exists, skipping"
fi

if [ ! -d "$WORKSPACE/src/mavros" ]; then
  vcs import src < /tmp/mavros.repos
else
  echo "  - mavros already exists, skipping"
fi

echo "[4/8] Cloning missing dependencies for Debian..."
cd "$WORKSPACE/src"

if [ ! -d diagnostics ]; then
  git clone https://github.com/ros/diagnostics.git -b ros2-humble
else
  echo "  - diagnostics already exists, skipping"
fi

if [ ! -d geographic_info ]; then
  git clone https://github.com/ros-geographic-info/geographic_info.git -b ros2
else
  echo "  - geographic_info already exists, skipping"
fi

echo "[5/8] Installing Python dependencies..."
python3 -m pip install --break-system-packages future

echo "[6/8] Installing remaining ROS dependencies..."
cd "$WORKSPACE"
rosdep install --from-paths src --ignore-src \
  --skip-keys "geographic_msgs python3-future" -y

echo "[7/8] Installing GeographicLib datasets..."
sudo ./src/mavros/mavros/scripts/install_geographiclib_datasets.sh

echo "[8/8] Building workspace..."
colcon build --symlink-install

echo
echo "✅ Done"
echo "Run the following command to source the workspace:"
echo "source $WORKSPACE/install/setup.bash"
echo
echo "To auto-source on startup, run:"
echo "echo 'source $WORKSPACE/install/setup.bash' >> ~/.bashrc"
