function __gen_fzf_default_opts -d "Generate FZF default options"
  # Solarized Dark color scheme for fzf
  set -x FZF_DEFAULT_OPTS "--color dark,hl:33,hl+:37,fg+:235,bg+:136,fg+:254 --color info:254,prompt:37,spinner:108,pointer:235,marker:235"
end

__gen_fzf_default_opts
