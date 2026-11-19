#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

# Enable RPM Fusion repositories for additional software
FEDORA_VERSION="$(rpm -E %fedora)"
dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm"

# config-manager is provided by dnf5-plugins
dnf install -y fedora-workstation-repositories dnf5-plugins

# Prepare flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Setup Visual Studio Code repository
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null

# Setup Docker Repository
dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

# Setup Google Chrome Repository
dnf config-manager setopt google-chrome.enabled=1
