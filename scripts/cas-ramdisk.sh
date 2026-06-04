#!/usr/bin/env bash

set -euo pipefail

MOUNT_POINT="/Volumes/CAS"
VOLUME_NAME="CAS"
LABEL="com.jonas.cas-ramdisk"

info() {
  printf "\033[00;34m$@\033[0m\n"
}

create() {
  if [[ "$(uname)" != "Darwin" ]]; then
    info "Not on Darwin, skipping RAM disk."
    exit 0
  fi

  # Idempotent: bail out if the RAM disk is already mounted.
  if mount | grep -q " on ${MOUNT_POINT} "; then
    info "RAM disk already mounted at ${MOUNT_POINT}."
    exit 0
  fi

  local mem_gb
  mem_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))

  # A RAM disk isn't worth the memory on smaller machines.
  if (( mem_gb <= 64 )); then
    info "Only ${mem_gb}GB of RAM, skipping RAM disk."
    exit 0
  fi

  # Size at a quarter of RAM, clamped to [32GB, 128GB].
  local size_gb=$(( mem_gb / 4 ))
  (( size_gb < 32 )) && size_gb=32
  (( size_gb > 128 )) && size_gb=128

  # hdiutil counts in 512-byte sectors: size_gb * 1024^3 / 512.
  local sectors=$(( size_gb * 2 * 1024 * 1024 ))

  info "Creating ${size_gb}GB RAM disk at ${MOUNT_POINT}."
  local device
  # hdiutil pads the device path with trailing spaces; keep just the identifier.
  device=$(hdiutil attach -nomount "ram://${sectors}" | awk 'NR==1{print $1}')
  diskutil erasevolume APFS "${VOLUME_NAME}" "${device}"
}

install() {
  local script_path
  script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")

  local plist="${HOME}/Library/LaunchAgents/${LABEL}.plist"
  local log="${HOME}/Library/Logs/cas-ramdisk.log"

  mkdir -p "$(dirname "${plist}")" "$(dirname "${log}")"

  info "Installing LaunchAgent at ${plist}."
  cat > "${plist}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${script_path}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${log}</string>
  <key>StandardErrorPath</key>
  <string>${log}</string>
</dict>
</plist>
EOF

  # Reload so RunAtLoad creates the disk immediately. launchd also loads agents
  # in ~/Library/LaunchAgents at every login, so a failed reload here (e.g. when
  # not run from the GUI session) still leaves the agent active next login.
  local domain="gui/$(id -u)"
  launchctl bootout "${domain}/${LABEL}" 2>/dev/null || true
  if launchctl bootstrap "${domain}" "${plist}" 2>/dev/null; then
    info "LaunchAgent loaded."
  else
    info "LaunchAgent installed; it will load at next login."
  fi
}

help() {
  echo "Usage: $(basename "$0") [options]" >&2
  echo
  echo "   (no args)              Create the RAM disk if it does not exist"
  echo "   --install              Install and load the boot-time LaunchAgent"
  echo "   -h, --help             Show this help"
  echo
  exit 1
}

if [ $# -eq 0 ]; then
  create
else
  case "$1" in
    --install)
      install
      ;;
    -h|--help)
      help
      ;;
    *)
      help
      ;;
  esac
fi
