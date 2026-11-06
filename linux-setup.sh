#!/usr/bin/env bash
set -euo pipefail

has_local() {
    # shellcheck disable=SC2034  # deliberately unused
    local _has_local
}

confirm_continue() {
  local prompt="${1:-Continue? (y/n): }"
  local answer
  while true; do
    if ! read -r -p "$prompt" answer < /dev/tty; then
      echo "No input available. Exiting." >&2
      exit 1
    fi
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo])     echo "Exiting."; exit 0 ;;
      *)                 echo "Please answer y or n." ;;
    esac
  done
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root, e.g.: curl -fsSL <url> | sudo bash" >&2
  exit 1
fi

echo "Initial setup of a new Debian system is starting ..."
confirm_continue "Proceed with setup? (y/n): "

echo "Install system packages"
cd /tmp
install -d -m 0755 /etc/apt/keyrings

# VS Code repo
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
rm -f microsoft.gpg

cat > /etc/apt/sources.list.d/vscode.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code/
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

# Sublime repo
wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg > /etc/apt/keyrings/sublimehq-pub.asc

cat > /etc/apt/sources.list.d/sublime-text.sources <<'EOF'
Types: deb
URIs: https://download.sublimetext.com/
Suites: apt/stable/
Signed-By: /etc/apt/keyrings/sublimehq-pub.asc
EOF

# /etc/apt/sources.list
cat > /etc/apt/sources.list <<'EOF'

# USE /etc/apt/sources.list.d/debian.sources

EOF

# /etc/apt/sources.list.d/debian.sources
cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://mirror.us.oneandone.net/debian/
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

apt update

apt install -y \
	curl vim neovim \
	git tree rsync \
	build-essential ca-certificates debsig-verify sudo


# Set Git Global Defaults
git config --global user.name 'Aaron Imbrock'
git config --global user.email 'aimbrock@gmail.com'
git config --global core.editor "code --wait"
git config --global init.defaultbranch main
git config --global pull.rebase false
git config --global core.pager "cat"
git config --global core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/stilnox_git"

echo ""
echo -n "Base system installed."
confirm_continue "Install X11 and Openbox? (y/n): "