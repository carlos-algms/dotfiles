#!/usr/bin/env bash

# Install Homebrew.
if [[ ! "$(type -P brew)" ]]; then
  echo "Installing Homebrew"
  true | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Exit if, for some reason, Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Homebrew failed to install." && return 1

e_header "Updating Homebrew"
brew doctor
brew update

e_header "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Hide username from ZSH
CONFIG_STR="DEFAULT_USER=`whoami`"

grep -q -F "${CONFIG_STR}" ~/.zshrc

if [ $? -ne 0 ]; then
  echo $'\n'"$CONFIG_STR"$'\n' >> ~/.zshrc
fi


# include a line to source common shell configs
grep -q -F 'source ~/.bashrc' ~/.zshrc

if [ $? -ne 0 ]; then
  echo -e $'\n'"source ~/.bashrc"$'\n\n' >> ~/.zshrc
fi
