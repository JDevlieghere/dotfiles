function fzf_default_opts -d "Generate FZF default options"
  # Solarized Dark color scheme
  set -f base03 "#002b36"
  set -f base02 "#073642"
  set -f base01 "#586e75"
  set -f base00 "#657b83"
  set -f base0 "#839496"
  set -f base1 "#93a1a1"
  set -f base2 "#eee8d5"
  set -f base3 "#fdf6e3"
  set -f yellow "#b58900"
  set -f orange "#cb4b16"
  set -f red "#dc322f"
  set -f magenta "#d33682"
  set -f violet "#6c71c4"
  set -f blue "#268bd2"
  set -f cyan "#2aa198"
  set -f green "#859900"

  set -x FZF_DEFAULT_OPTS "--color fg:-1,bg:-1,hl:$blue,fg+:$base2,bg+:$base02,hl+:$blue
                           --color info:$yellow,prompt:$yellow,pointer:$base3,marker:$base3,spinner:$yellow"
end

function fzf_user_key_bindings -d "Configure user key bindings"
  fzf --fish | source
end

if type -q fzf
  fzf_default_opts
  fzf_user_key_bindings
end
