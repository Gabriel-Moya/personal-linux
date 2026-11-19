#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

: "${REPO_DIR:?run this module through install.sh}"
: "${TARGET_USER:?run this module through install.sh}"

# Install JetBrains Toolbox for the desktop user, who will manage its updates.
runuser -u "$TARGET_USER" -- bash "$REPO_DIR/modules/user/jetbrains-toolbox.sh"
