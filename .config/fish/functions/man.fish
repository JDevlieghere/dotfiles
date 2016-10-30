function man --description "wrap the 'man' manual page opener to use color in formatting"
  set -x LESS_TERMCAP_mb (printf "\033[01;31m")
  set -x LESS_TERMCAP_md (printf "\033[01;31m")
  set -x LESS_TERMCAP_me (printf "\033[0m")
  set -x LESS_TERMCAP_se (printf "\033[0m")
  set -x LESS_TERMCAP_so (printf "\033[01;44;33m")
  set -x LESS_TERMCAP_ue (printf "\033[0m")
  set -x LESS_TERMCAP_us (printf "\033[01;32m")

  env man $argv
end
