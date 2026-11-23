#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

: "${TARGET_USER:?run this module through install.sh}"

# Configure Docker to start on boot and add the current user to the docker group
systemctl enable --now docker

usermod -aG docker "$TARGET_USER"
