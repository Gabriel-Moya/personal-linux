#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

: "${REPO_DIR:?run this module through install.sh}"
: "${TARGET_USER:?run this module through install.sh}"

# Persist extension activation and dock settings for the desktop user. A new
# GNOME session may be needed before freshly installed extensions become available.
target_runtime_dir="/run/user/$(id -u "$TARGET_USER")"
gnome_session=(env -u DBUS_SESSION_BUS_ADDRESS -u XDG_RUNTIME_DIR)
if [[ -d "$target_runtime_dir" ]]; then
  gnome_session+=("XDG_RUNTIME_DIR=$target_runtime_dir")
fi
if [[ -S "$target_runtime_dir/bus" ]]; then
  # Use the desktop's dconf service so the running GNOME session sees the changes.
  gnome_session+=("DBUS_SESSION_BUS_ADDRESS=unix:path=$target_runtime_dir/bus")
  echo "Configuring GNOME through the existing D-Bus session for $TARGET_USER."
else
  gnome_session+=(dbus-run-session --)
  echo "No user D-Bus found. Saving GNOME settings for the next login."
fi

runuser -u "$TARGET_USER" -- "${gnome_session[@]}" bash "$REPO_DIR/modules/user/gnome.sh"
