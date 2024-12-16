local fzf = require("fzf-lua")

fzf.setup(
  {
    "fzf-vim",
    defaults = {file_icons = false, git_icons = false}
  }
)
