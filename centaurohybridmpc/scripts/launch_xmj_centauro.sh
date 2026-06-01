#!/bin/bash

usage() {
  echo "Usage: $0 [--rt_factor <value>] [--ros-version <ros2|ros1>] [--urdf_path <path>] [--runtime_dir <path>] [--headless] [--pub-rostime]"
  exit 1
}

RT_FACTOR=1.0
XMJ_ROS_VERSION="${XMJ_ROS_VERSION:-ros2}"
ROS1_DISTRO="${ROS1_DISTRO:-noetic}"
ROS2_DISTRO="${ROS2_DISTRO:-jazzy}"
RUNTIME_DIR="${XMJ_RUNTIME_DIR:-/tmp/CentauroHybridMPC}"
URDF_PATH="${XMJ_URDF_PATH:-${RUNTIME_DIR}/centauro_big_wheels_no_yaw.urdf}"
XBOT_CONFIG_PATH="${XMJ_XBOT_CONFIG_PATH:-${RUNTIME_DIR}/xbot2_basic.yaml}"
HEADLESS=false
PUB_ROSTIME=false
CENTAURO_URDF_ROOT="${CENTAURO_URDF_ROOT:-${HOME}/ibrido_ws/src/iit-centauro-ros-pkg/centauro_urdf}"
CENTAURO_URDF_XACRO="${CENTAURO_URDF_XACRO:-${CENTAURO_URDF_ROOT}/urdf/centauro.urdf.xacro}"
CENTAURO_XMJ_DIR="${CENTAURO_XMJ_DIR:-${HOME}/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/xmj_env_files}"
XBOT_CONFIG_SRC="${CENTAURO_XBOT_CONFIG_SRC:-${CENTAURO_XMJ_DIR}/xbot2_basic.yaml}"
CENTAURO_SRDF_PATH="${CENTAURO_SRDF_PATH:-${CENTAURO_XMJ_DIR}/centauro_old.srdf}"
CENTAURO_JNT_IMP_CONFIG_PATH="${CENTAURO_JNT_IMP_CONFIG_PATH:-${HOME}/ibrido_ws/src/CentauroHybridMPC/centaurohybridmpc/config/jnt_imp_config_with_ub.yaml}"
XBOT_CONFIG_BUILDER="${IBRIDO_XBOT_CONFIG_BUILDER:-${HOME}/ibrido_utils/ibrido_xbot_config_builder.py}"

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

patch_runtime_xbot_config() {
  python3 -c 'from pathlib import Path
import sys
cfg = Path(sys.argv[1])
text = cfg.read_text()
text = text.replace("urdf_path: $PWD/centauro.urdf", "urdf_path: " + sys.argv[2])
text = text.replace("srdf_path: $PWD/centauro_old.srdf", "srdf_path: " + sys.argv[3])
text = text.replace("sim: $PWD/hal/centauro_gz.yaml", "sim: " + sys.argv[4])
text = text.replace("dummy: $PWD/hal/centauro_dummy.yaml", "dummy: " + sys.argv[5])
cfg.write_text(text)
' "$XBOT_CONFIG_PATH" "$URDF_PATH" "$CENTAURO_SRDF_PATH" "${CENTAURO_XMJ_DIR}/hal/centauro_gz.yaml" "${CENTAURO_XMJ_DIR}/hal/centauro_dummy.yaml"
}

apply_runtime_impedance_config() {
  if [ ! -f "$XBOT_CONFIG_BUILDER" ]; then
    echo "XBot config builder not found: $XBOT_CONFIG_BUILDER"
    exit 2
  fi
  if [ ! -f "$CENTAURO_JNT_IMP_CONFIG_PATH" ]; then
    echo "Joint impedance config not found: $CENTAURO_JNT_IMP_CONFIG_PATH"
    exit 2
  fi

  XBOT_CONFIG_PATH="$(
    python3 "$XBOT_CONFIG_BUILDER" \
      --xbot-config "$XBOT_CONFIG_PATH" \
      --impedance-config "$CENTAURO_JNT_IMP_CONFIG_PATH" \
      --output-dir "${RUNTIME_DIR}/xbot_runtime"
  )"
}

prepare_runtime_files() {
  mkdir -p "$RUNTIME_DIR"
  ensure_urdf "$URDF_PATH"
  cp "$XBOT_CONFIG_SRC" "$XBOT_CONFIG_PATH"
  patch_runtime_xbot_config
  apply_runtime_impedance_config
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rt_factor) RT_FACTOR="$2"; shift ;;
    --ros-version|--ros_version) XMJ_ROS_VERSION="$2"; shift ;;
    --urdf_path|--urdf-path) URDF_PATH="$2"; shift ;;
    --runtime_dir|--runtime-dir) RUNTIME_DIR="$2"; shift ;;
    --headless) HEADLESS=true ;;
    --pub-rostime|--pub_rostime) PUB_ROSTIME=true ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
  shift
done

source "${HOME}/ibrido_utils/mamba_utils/bin/_activate_current_env.sh"
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
source "${HOME}/ibrido_ws/setup.bash"

prepare_runtime_files

python "${HOME}/ibrido_ws/src/xbot2_mujoco/tests/PyXBotMjSim/launch_simulator.py" --urdf_path "$URDF_PATH" \
    --simopt_path "${CENTAURO_XMJ_DIR}/sim_opt.xml" \
    --world_path "${CENTAURO_XMJ_DIR}/world.xml" \
    --sites_path "${CENTAURO_XMJ_DIR}/sites.xml" \
    --xbot_config_path "$XBOT_CONFIG_PATH" \
    --blink_name base_link \
    --rt_factor "$RT_FACTOR" \
    "${extra_args[@]}"
