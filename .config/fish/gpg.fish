# GPG agent
function __refresh_gpg_agent_info -d "Reload ~/.gpg-agent-info into environment"
	cat ~/.gpg-agent-info | sed 's/=/ /' | while read key value
		set -e $key
		set -U -x $key "$value"
	end
end

if command -s gpg-agent > /dev/null
	if not set -q -x GPG_AGENT_INFO
		gpg-agent --daemon --write-env-file ~/.gpg-agent-info > /dev/null ^ /dev/null
	end

	if test -f ~/.gpg-agent-info
		__refresh_gpg_agent_info

		gpg-connect-agent /bye ^/dev/null
		if test $status -eq 1
			pkill -U $USER gpg-agent
			gpg-agent --daemon --write-env-file ~/.gpg-agent-info > /dev/null ^ /dev/null
			__refresh_gpg_agent_info
		end
	end

	# Use curses based Pinentry
	set -x GPG_TTY (tty)
end
