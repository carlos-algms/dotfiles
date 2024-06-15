#!/usr/bin/env zsh

scriptDir="${0:a:h}"

source $scriptDir/../common/01_logging.sh


if [[ ! -f ~/.zshrc ]]; then
    touch ~/.zshrc
fi


if ! grep -q "source \"$scriptDir/zshrc-zinit.zsh\"" ~/.zshrc
then
    echo "source \"$scriptDir/zshrc-zinit.zsh\"" | cat - ~/.zshrc > ~/.temp && mv ~/.temp ~/.zshrc

    if [ $? -ne 0 ]; then
        echo "Failed to add zsh config to ~/.zshrc"
        exit 1
    fi
fi


e_success "Done installing ZSH with Zinit"

unset scriptDir
