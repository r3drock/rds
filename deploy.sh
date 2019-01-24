#!/bin/sh
putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	echo "Downloading and installing config files..."
	dir=$(mktemp -d)
	chown -R "$USER":wheel "$dir"
	sudo -u "$USER" git clone "$1" "$dir/gitrepo" >/dev/null 2>&1 &&
	sudo -u "$USER" mkdir -p "$2" &&
	sudo -u "$USER" cp -rfT "$dir"/gitrepo "$2"
	}

# Make pacman and yay colorful because why not.
sed -i "s/^#Color/Color/g" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

putgitrepo "https://github.com/redroc/dotfiles.git" "/home/$USER"
echo "installation complete"
