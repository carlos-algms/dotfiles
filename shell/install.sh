#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${SCRIPT_DIR}/common/00_os.sh"
source "${SCRIPT_DIR}/common/01_logging.sh"


if [[ ! -z "$IS_WIN" ]]; then
    "${SCRIPT_DIR}/windows/install-windows.sh"
    # Link mintTTY config file only for windows
    ln -snf $SCRIPT_DIR/minttyrc $HOME/.minttyrc
elif [[ ! -z "$IS_MAC" ]]; then
    "${SCRIPT_DIR}/macos/install-mac.sh"
elif [[ ! -z "$IS_LINUX" ]]; then
    "${SCRIPT_DIR}/linux/install-linux.sh"
else
    e_error "No OS identified to install"
    exit 1
fi

### TODO: instead of backing up the files, it should be possible to inject code at the end of the file, if it is not already there
# e_header "Backup bash files"
#
# TODAY="`date`"
#
# if [ -f $HOME/.bash_profile ]; then
#     mv $HOME/.bash_profile "$HOME/.bash_profile-${TODAY}"
# fi
#
# if [ -f $HOME/.bashrc ]; then
#     mv $HOME/.bashrc "$HOME/.bashrc-${TODAY}"
# fi
#
# e_header "Linking bash config files"
#
# ln -snf $SCRIPT_DIR/bashrc.sh              $HOME/.bash_profile
# ln -snf $SCRIPT_DIR/bashrc.sh              $HOME/.bashrc
#


# Unix needs to add execution rights
for f in `find $SCRIPT_DIR/bin -type f ! -name ".*"`; do
    chmod u+x "$f"
done

for f in `find $SCRIPT_DIR/linux/bin -type f ! -name ".*"`; do
    chmod u+x "$f"
done

for f in `find $SCRIPT_DIR/macos/bin -type f ! -name ".*"`; do
    chmod u+x "$f"
done

e_success "Done installing shell configs"
