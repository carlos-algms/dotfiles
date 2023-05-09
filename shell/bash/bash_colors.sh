if [ ! -z "$IS_MAC" ] || [ ! -z "$IS_ZSH" ]; then
    return 0
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

# with GIT branch
#PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$BRANCH_COLOR\]$(print_git_info)\[$NORMAL_COLOR\]\n\$ "

# PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$NORMAL_COLOR\]\n\$ "


# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
