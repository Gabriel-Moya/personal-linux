#!/bin/bash
# Runs as the desktop user inside their D-Bus session; started by modules/gnome.sh.

set -euo pipefail
trap 'printf "GNOME configuration: error on line %s.\n" "$LINENO" >&2' ERR

printf 'GNOME settings: user=%s home=%s bus=%s\n' "$(id -un)" "$HOME" "${DBUS_SESSION_BUS_ADDRESS:-unset}"

extension_uuids=(
  appindicatorsupport@rgcjonas.gmail.com
  dash-to-dock@micxgx.gmail.com
)

for uuid in "${extension_uuids[@]}"; do
  enabled="$(gsettings get org.gnome.shell enabled-extensions)"
  if [[ "$enabled" != *"'$uuid'"* ]]; then
    # gsettings prints an empty string array as "@as []".
    if [[ "$enabled" == "@as []" || "$enabled" == "[]" ]]; then
      enabled="['$uuid']"
    else
      enabled="${enabled%]}, '$uuid']"
    fi
    gsettings set org.gnome.shell enabled-extensions "$enabled"
  fi

  disabled="$(gsettings get org.gnome.shell disabled-extensions)"
  if [[ "$disabled" == *"'$uuid'"* ]]; then
    # Remove this exact quoted UUID at the start, middle or end of the list.
    disabled="${disabled//"'$uuid', "/}"
    disabled="${disabled//", '$uuid'"/}"
    disabled="${disabled//"'$uuid'"/}"
    gsettings set org.gnome.shell disabled-extensions "$disabled"
  fi
done

extensions_disabled="$(gsettings get org.gnome.shell disable-user-extensions)"
if [[ "$extensions_disabled" == "true" ]]; then
  gsettings set org.gnome.shell disable-user-extensions false
fi

# Keep the bottom dock visible, with smaller icons (the default maximum is 48).
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
# Show unread counters (badges) on the dock icons.
gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-notifications-counter true

# Pinned applications, from left to right. This replaces the existing favorites.
favorite_apps=(
  org.gnome.Ptyxis.desktop         # Terminal
  org.gnome.Nautilus.desktop       # Files
  brave-browser.desktop           # Brave
  google-chrome.desktop           # Chrome
  org.mozilla.firefox.desktop     # Firefox
  code.desktop                    # Visual Studio Code
  com.discordapp.Discord.desktop  # Discord (Flatpak)
  md.obsidian.Obsidian.desktop     # Obsidian (Flatpak)
)
favorites="["
for desktop_id in "${favorite_apps[@]}"; do
  favorites+="'$desktop_id', "
done
favorites="${favorites%, }]"
gsettings set org.gnome.shell favorite-apps "$favorites"
gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites true

# Read back from new gsettings processes: a successful command alone does not
# guarantee the intended preferences were saved for this user.
enabled="$(gsettings get org.gnome.shell enabled-extensions)"
disabled="$(gsettings get org.gnome.shell disabled-extensions)"
extensions_disabled="$(gsettings get org.gnome.shell disable-user-extensions)"
dock_position="$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-position)"
dock_fixed="$(gsettings get org.gnome.shell.extensions.dash-to-dock dock-fixed)"
dock_icon_size="$(gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size)"
dock_counters="$(gsettings get org.gnome.shell.extensions.dash-to-dock show-icons-notifications-counter)"
saved_favorites="$(gsettings get org.gnome.shell favorite-apps)"
show_favorites="$(gsettings get org.gnome.shell.extensions.dash-to-dock show-favorites)"
printf 'Saved enabled extensions: %s\n' "$enabled"
printf 'Saved disabled extensions: %s\n' "$disabled"
printf 'Saved pinned applications: %s\n' "$saved_favorites"
printf 'Extensions globally disabled: %s; dock position: %s; always visible: %s; maximum icon size: %s; unread counters: %s\n' \
  "$extensions_disabled" "$dock_position" "$dock_fixed" "$dock_icon_size" "$dock_counters"

for uuid in "${extension_uuids[@]}"; do
  if [[ "$enabled" != *"'$uuid'"* || "$disabled" == *"'$uuid'"* ]]; then
    printf 'GNOME configuration: activation was not saved for %s.\n' "$uuid" >&2
    exit 1
  fi
done
if [[ "$extensions_disabled" != "false" || "$dock_position" != "'BOTTOM'" || "$dock_fixed" != "true" || "$dock_icon_size" != "32" || "$dock_counters" != "true" ]]; then
  echo "GNOME configuration: the saved preferences do not match the requested settings." >&2
  exit 1
fi
if [[ "${saved_favorites#@as }" != "$favorites" || "$show_favorites" != "true" ]]; then
  echo "GNOME configuration: the pinned applications or their order were not saved correctly." >&2
  exit 1
fi

# Saved preferences and a loaded extension are different things. Report what
# the current GNOME session knows; a first installation may need a new login.
if [[ -S "${XDG_RUNTIME_DIR:-}/bus" ]]; then
  for uuid in "${extension_uuids[@]}"; do
    if extension_info="$(LC_ALL=C gnome-extensions info "$uuid" 2>&1)"; then
      printf '%s\n' "$extension_info"
      if [[ "$extension_info" == *"State: ERROR"* || "$extension_info" == *"State: OUT OF DATE"* ]]; then
        printf 'GNOME could not load %s. Check its errors with journalctl -b /usr/bin/gnome-shell.\n' "$uuid" >&2
        exit 1
      fi
    else
      printf '%s\n' "$extension_info" >&2
      printf 'Settings saved for %s; its runtime state could not be checked. Log out and back in, then run: gnome-extensions info %s\n' "$uuid" "$uuid"
    fi
  done
fi
