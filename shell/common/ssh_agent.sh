export SSH_ENV="${HOME}/.ssh/environment"

function start_agent {
    echo "DOTFILES is initializing new SSH agent..."

    if [ ! -d "${HOME}/.ssh" ]; then
        echo "Folder '${HOME}/.ssh' does not exists, please create."
        echo
    else
        /usr/bin/ssh-agent | /bin/sed 's/^echo/#echo/' > "${SSH_ENV}"

        echo "SSH agent started"

        /bin/chmod 600 "${SSH_ENV}"
        . "${SSH_ENV}" > /dev/null

        /usr/bin/ssh-add;
    fi
}

function kill_ssh_agent {
    eval $(ssh-agent -k)
}
