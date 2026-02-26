-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "basedpyright"
-- In case you don't want to use `:LazyExtras`,
-- then you need to set the option below.
-- vim.g.lazyvim_picker = "fzf"
-- Enable terminal/window title updates (needed for the Vim[INSERT]/Vim[NORMAL] marker)
vim.opt.title = true
vim.opt.titleold = "" -- optional: title when exiting Neovim (only works if 'title' is on)
-- vim.opt.titlelen = 0 -- optional: 0 means do not shorten the title
