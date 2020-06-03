# [ -f ~/.gnupg/gpg-agent.env ] && source ~/.gnupg/gpg-agent.env

# if [ -S "${GPG_AGENT_INFO%%:*}" ]; then
#  export GPG_AGENT_INFO
# else
#  eval $(gpg-agent --daemon --log-file /tmp/gpg.log --write-env-file ~/.gnupg/gpg-agent.env --pinentry-program /usr/local/bin/pinentry-mac)
# fi
