# personal-linux

Post-install setup for my Fedora Workstation (GNOME) machines.

## Install

On a fresh Fedora, from your regular user account (not with `sudo`):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/master/boot.sh)"
```

`boot.sh` downloads this repository to a temporary directory and runs `sudo bash install.sh`.

## Modules

`install.sh` runs these modules in order. Modules in `modules/` run as root; the scripts in `modules/user/` run as the desktop user.

| Module | What it does |
|---|---|
| `repos` | RPM Fusion, Flathub, VS Code, Docker and Google Chrome repositories |
| `packages` | Brave, Flatpak apps (`packages/flatpak.txt`) and DNF packages (`packages/dnf.txt`) |
| `jetbrains-toolbox` | Installs JetBrains Toolbox in the user's home |
| `docker` | Enables Docker and adds the user to the `docker` group |
| `gnome` | Enables the AppIndicator and Dash to Dock extensions, dock settings and pinned apps |
| `discord-badge` | Shows Discord's unread counter on its dock icon (see [Discord badge](#discord-badge)) |

To run only some modules, pass their names:

```bash
sudo bash install.sh gnome
```

## Discord badge

The Discord Flatpak does not show its unread counter on Dash to Dock by default, for two reasons:

1. Electron only sends the badge (a `com.canonical.Unity.LauncherEntry` D-Bus signal) when `XDG_CURRENT_DESKTOP` contains `Unity`. On GNOME it is `GNOME`.
2. Discord sends it as `application://discord`, but the dock only recognizes the Flatpak desktop ID, `application://com.discordapp.Discord.desktop`.

The `discord-badge` module fixes both:

- a Flatpak override sets `XDG_CURRENT_DESKTOP=Unity:GNOME` for Discord;
- `~/.local/bin/discord-badge-bridge.py` (from `files/`) repeats each badge update under the Flatpak ID and clears the badge when Discord exits;
- the user service `discord-badge-bridge.service` runs the bridge with the graphical session.

Restart Discord after the first install. In Discord's notification settings, "Enable Unread Message Badge" must be on; that setting cannot be automated.

This only covers the Flatpak. Another Discord package uses a different `.desktop` name, so `DST_URI` in the bridge must be changed.

To check the signals, run the command below and wait for a new message. Each update should appear twice: once for `application://discord` and once for `application://com.discordapp.Discord.desktop`, with the same `count`. If the badge stops working after a Discord update, use it to see which URI Discord sends and update `SRC_URIS` in the bridge.

```bash
dbus-monitor --session "interface='com.canonical.Unity.LauncherEntry'"
```

To undo it:

```bash
flatpak override --user --unset-env=XDG_CURRENT_DESKTOP com.discordapp.Discord
systemctl --user disable --now discord-badge-bridge.service
rm ~/.local/bin/discord-badge-bridge.py ~/.config/systemd/user/discord-badge-bridge.service
systemctl --user daemon-reload
```

## Testing in a VM

From Git Bash on the host, with SSH enabled on the VM (`sudo systemctl enable --now sshd`) and a `fedora-vm` entry in `~/.ssh/config`:

```bash
tar -czf - --exclude=.git . | ssh fedora-vm 'rm -rf ~/workstation && mkdir ~/workstation && tar -xzf - -C ~/workstation'
ssh -t fedora-vm 'sudo bash ~/workstation/install.sh'
```

To test the `curl` flow from a pushed branch:

```bash
REF=my-branch bash -c "$(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/my-branch/boot.sh)"
```

## TODO

- Install video codecs
- Create directories like `~/dev` to store GitHub projects
- Configure zsh and oh-my-zsh
- Configure window tiling
