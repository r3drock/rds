#!/bin/sh
putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	echo "Downloading and installing config files..."
	dir=$(mktemp -d)
	chown -R "$USER":"$USER" "$dir"
	sudo -u "$USER" git clone "$1" "$dir/gitrepo" >/dev/null 2>&1 &&
	sudo -u "$USER" mkdir -p "$2" &&
	sudo -u "$USER" cp -rfT "$dir"/gitrepo "$2"
	}


#set up ssh-agent to be started with systemd
systemctl is-active --user --quiet ssh-agent 
if [[ $? -ne 0 ]]; then
	systemctl --user enable ssh-agent 
	systemctl --user start ssh-agent 
else
	echo "nothing to be done"
fi

#fetch my dotfiles
putgitrepo "https://github.com/redroc/dotfiles.git" "/home/$USER"

#start ssh-agent at startup
systemctl --user enable --now ssh-agent 

#install vim with clipboard support
sudo apt-get -y remove vim
sudo apt-get -y install vim-gtk

#install vundle plugins
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
echo "Now all vim plugins will be installed."
echo "After installing you need to press :q two times in order to close vim."
read -p "Press [Enter] key to start install."
vim -E -c "PluginInstall"

#install YCM
sudo apt-get -y install build-essential cmake python3-dev
cd ~/.vim/bundle/YouCompleteMe
python3 install.py --clang-completer

echo "installation complete"
