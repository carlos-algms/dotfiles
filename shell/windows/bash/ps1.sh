#!/usr/bin/env bash

# export COLOR_NC='\[\e[0m\]' # No Color
# export COLOR_BLACK='\[\e[0;30m\]'
# export COLOR_BLUE='\[\e[0;34m\]'
# export COLOR_LIGHT_BLUE='\[\e[1;34m\]'
# export COLOR_GREEN='\[\e[0;32m\]'
# export COLOR_LIGHT_GREEN='\[\e[1;32m\]'
# export COLOR_CYAN='\[\e[0;36m\]'
# export COLOR_LIGHT_CYAN='\[\e[1;36m\]'
# export COLOR_RED='\[\e[0;31m\]'
# export COLOR_LIGHT_RED='\[\e[1;31m\]'
# export COLOR_PURPLE='\[\e[0;35m\]'
# export COLOR_LIGHT_PURPLE='\[\e[1;35m\]'
# export COLOR_BROWN='\[\e[0;33m\]'
# export COLOR_YELLOW='\[\e[1;33m\]'
# export COLOR_GRAY='\[\e[1;30m\]'
# export COLOR_LIGHT_GRAY='\[\e[0;37m\]'
# export COLOR_WHITE='\[\e[1;37m\]'

# get current branch in git repo
function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]; then
        STAT=`parse_git_dirty`
        echo "${BRANCH}${STAT}"
    else
        echo ""
    fi
}

# get current status of git repo
function parse_git_dirty {
    status=`git status 2>&1 | tee`
    dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
    untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
    ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
    newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
    renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
    deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
    bits=''

    if [ "${renamed}" == "0" ]; then
        bits=">${bits}"
    fi
    if [ "${ahead}" == "0" ]; then
        bits="*${bits}"
    fi
    if [ "${newfile}" == "0" ]; then
        bits="+${bits}"
    fi
    if [ "${untracked}" == "0" ]; then
        bits="?${bits}"
    fi
    if [ "${deleted}" == "0" ]; then
        bits="x${bits}"
    fi
    if [ "${dirty}" == "0" ]; then
        bits="!${bits}"
    fi

    if [ ! "${bits}" == "" ]; then
        echo " ${bits}"
    else
        echo ""
    fi
}


function format_git_branch {
    branch="$(parse_git_branch)"

    if [ "${branch}" == "" ]; then
        branch="\[\e[32m\]"
    else
        branch="\[\e[32;5;43m\]\[\e[0m\]\[\e[30;5;43m\]  ${branch} \[\e[0m\]"
        branch="${branch}\[\e[1;33m\]\[\e[0m\]"
    fi

    echo $branch;
}

# User @ Host
PS1="\[\e[1;37;46m\] \u@\h\[\e[0m\]"
PS1="${PS1}\[\e[0;36;42m\]\[\e[0m\]"
# current dir
PS1="${PS1}\[\e[37;42m\]\w\[\e[0m\]"
# git
PS1="${PS1}`format_git_branch`\[\e[0m\] "
# new line
PS1="${PS1}\nλ "

export PS1;
