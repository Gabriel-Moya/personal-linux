#!/bin/bash
# Runs as the desktop user; started by modules/discord-badge.sh.
# Makes Discord's unread counter show on its Dash to Dock icon.

set -euo pipefail
trap 'printf "Discord badge: error on line %s.\n" "$LINENO" >&2' ERR

: "${REPO_DIR:?run this module through install.sh}"

app_id="com.discordapp.Discord"
unit="discord-badge-bridge.service"
bridge_file="$HOME/.local/bin/discord-badge-bridge.py"
unit_file="$HOME/.config/systemd/user/$unit"
wants_link="$HOME/.config/systemd/user/graphical-session.target.wants/$unit"

# Electron only sends the badge when XDG_CURRENT_DESKTOP contains Unity.
flatpak override --user --env=XDG_CURRENT_DESKTOP=Unity:GNOME "$app_id"

# Discord names itself "discord", but the dock only knows the Flatpak desktop ID.
# The bridge repeats each badge update under that ID.
install -Dm755 "$REPO_DIR/files/discord-badge-bridge.py" "$bridge_file"
install -Dm644 "$REPO_DIR/files/$unit" "$unit_file"

if systemctl --user show-environment > /dev/null 2>&1; then
  user_manager=true
  systemctl --user daemon-reload
  systemctl --user enable "$unit"
  # Restart instead of start, so a new run also loads an updated bridge script.
  systemctl --user restart "$unit"
else
  # No user systemd to talk to: enable the unit the way systemctl would.
  user_manager=false
  mkdir -p "${wants_link%/*}"
  ln -sfn "$unit_file" "$wants_link"
  echo "No user systemd session found. The Discord badge bridge will start at the next login."
fi

# Read back what was saved.
overrides="$(flatpak override --user --show "$app_id")"
if ! grep -qxF 'XDG_CURRENT_DESKTOP=Unity:GNOME' <<< "$overrides"; then
  printf 'Discord badge: the Flatpak override was not saved for %s.\n' "$app_id" >&2
  exit 1
fi
printf 'Saved Flatpak override for %s:\n%s\n' "$app_id" "$overrides"

if [[ "$user_manager" == true ]]; then
  # Give the bridge a moment to fail if it cannot start (e.g. missing python3-gobject).
  sleep 1
  if ! systemctl --user is-enabled --quiet "$unit" || ! systemctl --user is-active --quiet "$unit"; then
    systemctl --user status --no-pager "$unit" >&2 || true
    printf 'Discord badge: %s is not running. Check it with journalctl --user -u %s\n' "$unit" "$unit" >&2
    exit 1
  fi
  printf '%s is enabled and running.\n' "$unit"
elif [[ ! -L "$wants_link" ]]; then
  printf 'Discord badge: could not enable %s.\n' "$unit" >&2
  exit 1
fi

# The override only applies to new Discord processes. Restarting it is left to the user.
running_apps="$(flatpak ps --columns=application 2> /dev/null || true)"
if grep -qxF "$app_id" <<< "$running_apps"; then
  printf 'Discord is running. Restart it to show the badge: flatpak kill %s, then open it again.\n' "$app_id"
fi
