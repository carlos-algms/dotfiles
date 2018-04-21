#!/usr/bin/env bash

PATH="$HOME/bin:$HOME/.bin:$HOME/.local/bin:${DOTFILES_SHELL_PATH}/bin:$PATH"

if [ "$IS_UNIX" = true ]; then
    PATH="${DOTFILES_SHELL_PATH}/customizations/linux/bin:$PATH"
fi

if [ "$IS_WIN" = true ]; then
    PATH="${DOTFILES_SHELL_PATH}/customizations/windows/bin:$PATH"
fi

if [ "$IS_MAC" = true ]; then
    PATH="${DOTFILES_SHELL_PATH}/customizations/mac/bin:$PATH"
fi

# Set proper ls colors
export CLICOLOR=1

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes
color_prompt=yes


# USER_COLOR='\033[01;32m'
# HOST_COLOR='\033[01;32m'
# WHERE_COLOR='\033[38;5;11m'
# BRANCH_COLOR='\e[0;33m'
# NORMAL_COLOR='\e[0m'
# MSYSTEM_COLOR='\e[0;35m'
# UNAME_S=`uname -s`

# Ubuntu default prompt colors
if [ "$IS_UNIX" = true ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# with GIT branch
#PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$BRANCH_COLOR\]$(print_git_info)\[$NORMAL_COLOR\]\n\$ "

# PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$NORMAL_COLOR\]\n\$ "


# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
# if ! shopt -oq posix; then
#   if [ -f /usr/share/bash-completion/bash_completion ]; then
#     . /usr/share/bash-completion/bash_completion
#   elif [ -f /etc/bash_completion ]; then
#     . /etc/bash_completion
#   fi
# fi

# append to history
shopt -s histappend
# Combine multiline commands into one in history
shopt -s cmdhist
# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:exit:clear:ll:la"

# Do not autocomplete when accidentally pressing Tab on an empty line.
shopt -s no_empty_cmd_completion;
