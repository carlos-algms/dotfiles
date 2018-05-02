echo ssh win
# Source SSH settings, if applicable
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    /bin/ps -ef | grep ${SSH_AGENT_PID} | /bin/grep ssh-agent$ > /dev/null || { start_agent; }
else
    start_agent;
fi
