# Load user specific aliases
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Load user specific functions
if [ -f ~/.bash_functions ]; then
    source ~/.bash_functions
fi
