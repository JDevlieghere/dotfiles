infocmp -1 xterm-256color > xterm-256color.terminfo
echo -e "\tsitm=\\E[3m,\n\tritm=\\E[23m," >> xterm-256color.terminfo
tic xterm-256color.terminfo
