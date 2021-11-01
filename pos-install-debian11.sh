#!/bin/bash

# ================================== Personal script for Debian xfce

# ================================== VARIABLES
CHROME_DEB="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
VSCODE_DEB="https://az764295.vo.msecnd.net/stable/6cba118ac49a1b88332f312a8f67186f7f3c1643/code_1.61.2-1634656828_amd64.deb"
ULAUNCHER_DEB="https://github.com/Ulauncher/Ulauncher/releases/download/5.14.0/ulauncher_5.14.0_all.deb"

DIRECTORY_BINARIES_DEB="$PWD/temps"

PROGRAMS_INSTALL=(
    git
    build-essential
    tilix
    flameshot
    plank
    conky
    htop
    neofetch
    # sources.list.d
    spotify-client
    anydesk
    brave-browser
)

# =================================== REQUIREMENTS
## Remove locks apt
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

sudo apt update
sudo apt install apt-transport-https curl -y


# =================================== ADD PROGRAMS sources.list.d
## SPOTIFY
sudo curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

## ANYDESK
sudo wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list

## BRAVE BROWSER
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list


# =================================== DOWNLOAD BINARIES DEB
mkdir "$DIRECTORY_BINARIES_DEB"
wget -c "$CHROME_DEB"       -P "$DIRECTORY_BINARIES_DEB"
wget -c "$VSCODE_DEB"       -P "$DIRECTORY_BINARIES_DEB"
wget -c "$ULAUNCHER_DEB"    -P "$DIRECTORY_BINARIES_DEB"


# =================================== INSTALL PROGRAMS APT AND .DEB
## Update repository
sudo apt update

## Programs apt
for program in ${PROGRAMS_INSTALL[@]}; do
    if ! dpkg -l | grep -q $program; then
        sudo apt install "$program" -y
    else
        echo "[INSTALADO] - $program"
    fi
done

## Programs .deb
sudo apt install $DIRECTORY_BINARIES_DEB/*.deb -y


# =================================== POST INSTALLATION
## finishing and cleaning
sudo apt update && sudo apt dist-upgrade -y
sudo apt autoclean
sudo apt autoremove -y
sudo rm -rf $DIRECTORY_BINARIES_DEB
