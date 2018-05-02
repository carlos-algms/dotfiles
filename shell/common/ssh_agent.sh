export SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initialising new SSH agent..."

    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"

    echo "SSH agent started"

    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null

    /usr/bin/ssh-add;
}

function kill_ssh_agent {
    eval $(ssh-agent -k)
}
