#!/usr/bin/env bash
set -euo pipefail

readonly HOME=/home/aimbrock
readonly USER='aimbrock'
readonly GROUP='aimbrock'


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
  echo "Must be run as root, e.g.: wget -qO- https://aaron-imbrock.github.io/new-system-setup/linux-setup.sh | sh" >&2
  exit 1
fi

echo "Initial setup of a new Debian X11/Openbox system is starting ..."
confirm_continue "Install X11 and Openbox? (y/n): "

cd /tmp

apt install -y \
  xserver-xorg-core xserver-xorg-input-libinput xinit openbox x11-xserver-utils \
  lxpolkit hsetroot picom pcmanfm xscreensaver xfce4-notifyd \
  mate-media mate-power-manager \
  pipewire-pulse wireplumber \
  alacritty iputils-ping lemonbar lxde-icon-theme arandr

echo ""
echo "Install of: X11 and Openbox completed."

echo "Add Fonts..."
rm -rf $HOME/src/SF-All-Fonts
git clone https://github.com/aaron-imbrock/SF-All-Fonts.git $HOME/src/SF-All-Fonts

mkdir $HOME/.local/share/fonts/sf-family/
rsync -avHP $HOME/src/SF-All-Fonts/*/*.otf $HOME/.local/share/fonts/sf-family



# Regenerate the font cache
fc-cache -f -v
fc-list : family | grep -i "sf " | sort -u

wget -qO- https://astral.sh/uv/install.sh | sh
echo "uv install" >> $HOME/.bashrc.local
echo 'eval "$(uv generate-shell-completion bash)"' >> $HOME/.bashrc.local

chown -R $USER:$GROUP $HOME

rm -rf $HOME/src/SF-All-Fonts

echo "X11 setup completed"
