#!/usr/bin/env bash
set -euo pipefail


readonly HOME=/home/aimbrock

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
  echo "Please run as root, e.g.: wget -qO- https://aaron-imbrock.github.io/new-system-setup/linux-setup.sh | sh" >&2
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

# Set APT::Install-Suggests defaults to false
cat > /etc/apt/apt.conf.d/99no-recommends <<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

# /etc/apt/sources.list.d/debian.sources
cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian/
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
	git tree rsync unzip \
	build-essential ca-certificates debsig-verify sudo openssh-server


# Set Git Global Defaults
cat > $HOME/.gitconfig <<'EOF'
[user]
  email = aimbrock@gmail.com
  name = Aaron Imbrock
[core]
  editor = code --wait
  pager = cat
  sshCommand = ssh -o IdentitiesOnly=yes -i /home/aimbrock/.ssh/stilnox_git
[init]
  defaultbranch = main
[http]
    postBuffer = 157286400
[delta]
    navigate = true
    line-numbers = true
[merge]
    conflictstyle = zdiff3
[pull]
  rebase = false
EOF

git init --bare $HOME/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config remote add origin https://github.com/aaron-imbrock/dotfiles.git
config fetch origin
config reset --hard origin/main
config clean -f -d

echo ""
echo "Base system installed. Remember to reboot."
echo ""
echo "To install X11/Openbox: wget -qO- https://aaron-imbrock.github.io/setup/desktop.sh | sh"
