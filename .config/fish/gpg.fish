# GPG agent
if command -s gpg-agent 2>&1 > /dev/null
	gpg-connect-agent --quiet /bye 2> /dev/null
	if test $status -eq 1
		pkill -U $USER gpg-agent
		gpg-agent --daemon 2>&1 > /dev/null
	end

	# Use curses based Pinentry
	set -x GPG_TTY (tty)
end
