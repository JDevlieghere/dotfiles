function memento-agent -d "Run memento SSH agent"
    # Path to memento-agent as it's not in PATH.
    set -lx MEMENTO_AGENT /usr/local/memento/bin/memento-agent

    # Launch memento-agent if it's not already running.
    ps -ef | grep -v grep | grep $MEMENTO_AGENT > /dev/null
    if [ $status -ne 0 ]
        $MEMENTO_AGENT &> /dev/null &
    end

    # Find the memento-agent PID.
    set -lx MEMENTO_PID (ps -ef | grep -v grep | grep $MEMENTO_AGENT | awk '{ print $2 }')

    # Use the PID to find the unix socket.
    set -x SSH_AUTH_SOCK (lsof -p $MEMENTO_PID | grep unix | awk '{ print $8 }')

    # Verify that everything's working.
    memento test
end
