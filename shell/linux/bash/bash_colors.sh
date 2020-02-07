if [[ "$SHELL" =~ zsh$ ]]; then
    return 0
fi

# Ubuntu default prompt colors
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
