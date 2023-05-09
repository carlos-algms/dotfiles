# TODO need to check if it is properly working on Win and Linux
if [ -x "$(command -v shopt)" ] || [ ! -z "$(command -v shopt)" ] ; then
    # append to history
    # shopt -s histappend
    # Combine multiline commands into one in history
    shopt -s cmdhist
    # Do not autocomplete when accidentally pressing Tab on an empty line.
    shopt -s no_empty_cmd_completion;
fi

if [ -x "$(command -v setopt)" ] || [ ! -z "$(command -v setopt)" ] ; then
    setopt EXTENDED_HISTORY
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_FIND_NO_DUPS
    setopt HIST_SAVE_NO_DUPS
    setopt HIST_REDUCE_BLANKS
    unsetopt share_history
fi

# Ignore duplicates, ls without options and builtin commands
export HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:exit:clear:ll:la:lsa:[ \t]*"
