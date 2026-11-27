#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

: "${REPO_DIR:?run this module through install.sh}"
: "${TARGET_USER:?run this module through install.sh}"

# Run in the desktop user's session when there is one, so IBus can be restarted
# right away. Without it, the change applies at the next login.
target_runtime_dir="/run/user/$(id -u "$TARGET_USER")"
user_session=(env -u DBUS_SESSION_BUS_ADDRESS -u XDG_RUNTIME_DIR)
if [[ -d "$target_runtime_dir" ]]; then
  user_session+=("XDG_RUNTIME_DIR=$target_runtime_dir")
fi
if [[ -S "$target_runtime_dir/bus" ]]; then
  user_session+=("DBUS_SESSION_BUS_ADDRESS=unix:path=$target_runtime_dir/bus")
fi

runuser -u "$TARGET_USER" -- "${user_session[@]}" bash "$REPO_DIR/modules/user/cedilla.sh"
