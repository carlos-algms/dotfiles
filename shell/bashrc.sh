# Avoid re-source files when starting
# Need to measure impact on windows and linux, but on Mac it was not working if you start a new shell session
# if [ -z "${DOTFILES_PATH}" ]; then
    export DOTFILES_SHELL_PATH="$(dirname "$(readlink "$HOME/.bashrc")")"
    export DOTFILES_PATH="$(dirname "$DOTFILES_SHELL_PATH")"
    export DOTFILES_VIM_PATH="$DOTFILES_PATH/vim"

    # function to DRY
    sourceFiles() {
        if [ ! -d "$1" ]; then
            return 1
        fi

        for f in $1/*.sh; do
            if [ -f "$f" ]; then
                source "$f"
            fi
        done
    }

    # load additional files stored into ~/.bash_extras to keep repo clean
    # it need to be the first to be loaded to override ENV or other configs
    sourceFiles $HOME/.bash_extras

    # Load common bash files
    sourceFiles "${DOTFILES_SHELL_PATH}/common"

    if [[ ! -z "$IS_WIN" ]]; then
        # Load windows specific bash files
        sourceFiles "${DOTFILES_SHELL_PATH}/windows/bash"
    elif [[ ! -z "$IS_MAC" ]]; then
        # Load mac specific bash files
        sourceFiles "${DOTFILES_SHELL_PATH}/macos/bash"
    elif [[ ! -z "$IS_LINUX" ]]; then
        # Load Linux specific bash files
        sourceFiles "${DOTFILES_SHELL_PATH}/linux/bash"
    else
        e_error "No OS identified to source files"
    fi

    # Load user specific aliases
    if [ -f ~/.bash_aliases ]; then
        source ~/.bash_aliases
    fi

    # Load user specific functions
    if [ -f ~/.bash_functions ]; then
        source ~/.bash_functions
    fi

    # Load custom configuration
    if [ -f ~/.dotfilesrc ]; then
        source ~/.dotfilesrc
    fi

# fi

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
