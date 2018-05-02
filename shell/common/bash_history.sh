
# append to history
shopt -s histappend
# Combine multiline commands into one in history
shopt -s cmdhist
# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:exit:clear:ll:la"

# Do not autocomplete when accidentally pressing Tab on an empty line.
shopt -s no_empty_cmd_completion;
