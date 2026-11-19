#!/bin/bash

# Downloads this repository and runs install.sh. Run it from your regular user
# account, without sudo (it asks for your password when needed):
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/master/boot.sh)"
#
# To test another branch, use it both in the URL and in REF:
# REF=my-branch bash -c "$(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/my-branch/boot.sh)"

set -euo pipefail

# Everything runs inside main, so bash reads the whole file before starting.
main() {
  if [ "$EUID" -eq 0 ]; then
    echo "Run without sudo; the script asks for it when needed." >&2
    exit 1
  fi

  local ref="${REF:-master}"
  # Global on purpose: the EXIT trap runs after main has returned.
  work_dir="$(mktemp -d)"
  trap 'rm -rf -- "$work_dir"' EXIT

  if ! command -v tar > /dev/null; then
    sudo dnf install -y tar
  fi

  curl -fsSL --retry 3 "https://github.com/Gabriel-Moya/personal-linux/archive/refs/heads/$ref.tar.gz" \
    | tar -xz -C "$work_dir" --strip-components=1

  sudo bash "$work_dir/install.sh" "$@"
}

main "$@"
