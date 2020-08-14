if [ ! -z "$IS_ZSH" ]; then
    return 0
fi

# get current branch in git repo
function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | /bin/sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]; then
        # STAT=`parse_git_dirty`
        echo "${BRANCH}"
        # echo "${BRANCH}${STAT}"
    else
        echo ""
    fi
}

function format_git_branch {
    branch="$(parse_git_branch)"

    if [ "${branch}" == "" ]; then
        branch="\e[32m\e[0m"
    else
        branch="\e[32;5;43m\e[0m\e[0;30;5;43m  ${branch} \e[0m"
        branch="${branch}\e[1;33m\e[0m"
    fi

    echo -e "$branch";
}

# Start trying to load the git bash-completions
# If /bin/bash git-completion is loaded automatically
# If /usr/bin/bash no
type __git_complete > /dev/null 2>&1

if [ ! $? -eq 0 ]; then
    source /mingw64/share/git/completion/git-completion.bash
fi

FANCY_PS1="\n"

# User @ Host
# FANCY_PS1="\n\e[1;37;46m  \u@\h\e[0m"
# FANCY_PS1="${FANCY_PS1}\e[0;36;42m\e[0m"

# current dir
FANCY_PS1="${FANCY_PS1}\e[1;37;42m  \w\e[0m"

# git
FANCY_PS1="${FANCY_PS1}"'`format_git_branch`'

# new line
FANCY_PS1="\e[0m${FANCY_PS1}\nλ "

export FANCY_PS1;

ORIGINAL_PS1="$PS1"
PS1="$FANCY_PS1"

export PS1;

function restore_ps1 {
    PS1="$ORIGINAL_PS1"
}

function fancy_ps1 {
    PS1="$FANCY_PS1"
}
