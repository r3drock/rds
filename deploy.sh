#!/bin/sh

# DEFAULTS:
[ -z "$dotfilesrepo" ] && dotfilesrepo="https://gitlab.com/r3drock/dotfiles.git"
[ -z "$progsfile" ] && progsfile="https://gitlab.com/r3drock/rds/raw/master/progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="master"

# Functions
error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

pacmaninstall() {
	echo "Installing \"$1\" with pacman."
	sudo pacman -Syu --noconfirm "$1" > /dev/null
	sudo pacman -S --needed --noconfirm "$1" > /dev/null
} 

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
	[ -f "/usr/bin/$1" ] || (
	echo "Installing \"$1\", an AUR helper..."
	cd /tmp || exit
	rm -rf /tmp/"$1"*
	curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
	sudo -u "$name" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
	cd "$1" &&
	sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
	cd /tmp || return) ;}

gitmakeinstall() {
	dir=$(mktemp -d)
	echo "Installing \"$1\" with make install."
	git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;}

pipinstall() { \
	echo "Installing the python package \"$1\" with pip."
	command -v pip || pacman -S --noconfirm --needed python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	echo "Downloading and installing config files..."
	dir=$(mktemp -d)
	chown -R "$name":wheel "$dir"
	sudo -u "$name" git clone "$1" "$dir/gitrepo" >/dev/null 2>&1 &&
	sudo -u "$name" mkdir -p "$2" &&
	sudo -u "$name" cp -rfT "$dir"/gitrepo "$2"
}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qm | awk '{print $1}')
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"") pacmaninstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}


# Start of the script
# check for manjaro
MANJARO = 0
cat /etc/lsb-release | grep ManjaroLinux
if [ $? -eq 0 ]; then
    MANJARO = 1
fi

# ask whether to install sway or i3
if [ $MANJARO -eq 0 ]; then
    read -p "Would you like to install i3 or sway:" wm
    if [ "$wm" != "sway" -a "$wm" != "i3" ]; then
        error "type in i3 or sway!"
    fi
fi

pacman -Syu --noconfirm --needed base-devel git cowsay ||  error "Are you sure you're running this as the root user? Are you sure you're using an Arch-based distro? ;-) Are you sure you have an internet connection? Are you sure your Arch keyring is updated?"

read -p "Enter your username: " name
cut -d: -f1 /etc/passwd | grep "$name" || error "This user does not exist."

# Make pacman and yay colorful
sed -i "s/^#Color/Color/g" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

# Install aurhelper
manualinstall "$aurhelper" || error "Failed to install aurhelper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. 
installationloop

if [ $MANJARO -eq 0 ]; then
    # additionally install either sway or i3
    if [ $wm = sway ]; then
        progsfile="https://gitlab.com/r3drock/rds/raw/master/swayprogs.csv"
    elif [ $wm = i3 ]; then 
        progsfile="https://gitlab.com/r3drock/rds/raw/master/i3progs.csv"
    fi
fi
installationloop

# Installation steps as user

#set up ssh-agent to be started with systemd
sudo -u "$name" systemctl is-active --user --quiet ssh-agent 
if [ $? -ne 0 ]; then
	sudo -u "$name" systemctl --user enable --now ssh-agent 
	echo "Enabled ssh-agent on startup."
else
	echo "nothing to be done"
fi 

#fetch my dotfiles
putgitrepo "$dotfilesrepo" "/home/$name"

#install vim-plug plugins 
sudo -u "$name" curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 
sudo -u "$name" echo "Now all vim plugins will be installed."
sudo -u "$name" echo "After installing you need to press :q two times in order to close vim."
sudo -u "$name" read -p "Press [Enter] key to start install."
sudo -u "$name" nvim -E -c "PlugInstall"

sudo -u "$name" echo "installation complete"
