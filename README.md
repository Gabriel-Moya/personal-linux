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

To run only some modules, pass their names:

```bash
sudo bash install.sh gnome
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
