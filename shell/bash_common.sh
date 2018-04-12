if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

PATH="$HOME/bin:$HOME/.local/bin:$PATH"

SSH_ENV="$HOME/.ssh/environment"

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


# Ubuntu default
# PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# with GIT branch
#PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$BRANCH_COLOR\]$(print_git_info)\[$NORMAL_COLOR\]\n\$ "

# PS1="\[$USER_COLOR\]\u\[$HOST_COLOR\]@\h\[\033[00m\]:\[$WHERE_COLOR\]\w\[$NORMAL_COLOR\]\n\$ "


# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

function start_agent {
    echo "Initialising new SSH agent..."

    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"

    echo "SSH agent started"

    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null

    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
     start_agent;
    }
else
    start_agent;
fi

function kill_ssh_agent {
    eval $(ssh-agent -k)
}

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

# Easy extract
extract () {
  if [ -f $1 ] ; then
      case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       rar x $1       ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}
