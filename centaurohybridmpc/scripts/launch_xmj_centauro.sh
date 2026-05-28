#!/bin/bash

usage() {
  echo "Usage: $0 [--rt_factor <value>] [--ros-version <ros2|ros1>] [--urdf_path <path>] [--headless] [--pub-rostime]"
  exit 1
}

RT_FACTOR=1.0
XMJ_ROS_VERSION="${XMJ_ROS_VERSION:-ros2}"
ROS1_DISTRO="${ROS1_DISTRO:-noetic}"
ROS2_DISTRO="${ROS2_DISTRO:-jazzy}"
URDF_PATH="${XMJ_URDF_PATH:-/tmp/CentauroHybridMPC/centauro_big_wheels_no_yaw.urdf}"
HEADLESS=false
PUB_ROSTIME=false
CENTAURO_URDF_ROOT="${CENTAURO_URDF_ROOT:-/root/ibrido_ws/src/iit-centauro-ros-pkg/centauro_urdf}"
CENTAURO_URDF_XACRO="${CENTAURO_URDF_XACRO:-${CENTAURO_URDF_ROOT}/urdf/centauro.urdf.xacro}"

require_valid_urdf() {
  local urdf_path="$1"

  if [ ! -s "$urdf_path" ]; then
    echo "URDF not found or empty: $urdf_path"
    exit 2
  fi

  if ! grep -Eq '<robot([[:space:]>])' "$urdf_path"; then
    echo "URDF does not contain a <robot> root: $urdf_path"
    exit 2
  fi
}

patch_generated_urdf_for_mujoco() {
  local urdf_path="$1"

  python - "$urdf_path" <<'PY'
import sys
import xml.etree.ElementTree as ET

urdf_path = sys.argv[1]
tree = ET.parse(urdf_path)
root = tree.getroot()
patched = 0

for geometry in root.findall(".//visual/geometry"):
    mesh = geometry.find("mesh")
    if mesh is None:
        continue

    filename = mesh.attrib.get("filename", "")
    if not filename.endswith("/realsense/d435.dae") and not filename.endswith("d435.dae"):
        continue

    geometry.remove(mesh)
    ET.SubElement(geometry, "box", {"size": "0.09 0.025 0.02505"})
    patched += 1

if patched:
    tree.write(urdf_path, encoding="utf-8", xml_declaration=True)
    print(f"Patched {patched} Realsense D435 visual mesh(es) in generated URDF for MuJoCo.")
PY
}

generate_centauro_urdf() {
  local urdf_path="$1"

  if ! command -v xacro >/dev/null 2>&1; then
    echo "Cannot generate URDF: xacro is not available on PATH."
    exit 2
  fi

  if [ ! -f "$CENTAURO_URDF_XACRO" ]; then
    echo "Cannot generate URDF: xacro file not found: $CENTAURO_URDF_XACRO"
    exit 2
  fi

  mkdir -p "$(dirname "$urdf_path")"
  echo "Generating Centauro URDF at $urdf_path"
  xacro "$CENTAURO_URDF_XACRO" \
    root:="$CENTAURO_URDF_ROOT" \
    legs:=true \
    big_wheel:=true \
    upper_body:=true \
    battery:=true \
    velodyne:=false \
    realsense:=false \
    floating_joint:=true \
    use_abs_mesh_paths:=true \
    use_local_filesys_for_meshes:=false \
    end_effector_left:=ball \
    end_effector_right:=ball \
    -o "$urdf_path"
  patch_generated_urdf_for_mujoco "$urdf_path"
}

ensure_urdf() {
  local urdf_path="$1"

  generate_centauro_urdf "$urdf_path"
  require_valid_urdf "$urdf_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rt_factor) RT_FACTOR="$2"; shift ;;
    --ros-version|--ros_version) XMJ_ROS_VERSION="$2"; shift ;;
    --urdf_path|--urdf-path) URDF_PATH="$2"; shift ;;
    --headless) HEADLESS=true ;;
    --pub-rostime|--pub_rostime) PUB_ROSTIME=true ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
  shift
done

source /root/ibrido_utils/mamba_utils/bin/_activate_current_env.sh
micromamba activate ibrido
if [ -f /opt/xbot/setup.sh ]; then
  source /opt/xbot/setup.sh
fi

extra_args=()
if [ "$HEADLESS" = true ]; then
  extra_args+=(--headless)
fi
if [ "$PUB_ROSTIME" = true ]; then
  case "$XMJ_ROS_VERSION" in
    1) XMJ_ROS_VERSION="ros1"; source "/opt/ros/${ROS1_DISTRO}/setup.bash" ;;
    2) XMJ_ROS_VERSION="ros2"; source "/opt/ros/${ROS2_DISTRO}/setup.bash" ;;
    ros1) source "/opt/ros/${ROS1_DISTRO}/setup.bash" ;;
    ros2) source "/opt/ros/${ROS2_DISTRO}/setup.bash" ;;
    *) echo "Unsupported ROS version: ${XMJ_ROS_VERSION}"; usage ;;
  esac
  extra_args+=(--pub_rostime --ros-version "$XMJ_ROS_VERSION")
fi
source /root/ibrido_ws/setup.bash

ensure_urdf "$URDF_PATH"

python /root/ibrido_ws/src/xbot2_mujoco/tests/PyXBotMjSim/launch_simulator.py --urdf_path "$URDF_PATH" \
    --simopt_path /root/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/xmj_env_files/sim_opt.xml \
    --world_path /root/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/xmj_env_files/world.xml \
    --sites_path /root/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/xmj_env_files/sites.xml \
    --xbot_config_path /root/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/xmj_env_files/xbot2_basic.yaml \
    --blink_name base_link \
    --rt_factor "$RT_FACTOR" \
    "${extra_args[@]}"
