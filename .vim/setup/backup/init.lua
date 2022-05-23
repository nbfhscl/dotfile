-- dofile(vim.api.nvim_get_var('mypp')..'/init.lua')
-- dofile('<path-to-this-file>') to import this file in init.lua for nvim
--
--

-- local fn = vim.fn
-- local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
-- if fn.empty(fn.glob(install_path)) > 0 then
--   packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
-- end
-- return require('packer').startup(function(use)
--   -- My plugins here
--   -- use 'foo1/bar1.nvim'
--   -- use 'foo2/bar2.nvim'

--   -- Automatically set up your configuration after cloning packer.nvim
--   -- Put this at the end after all plugins
--   if packer_bootstrap then
--     require('packer').sync()
--   end
-- end)


--
--
--local Plug = vim.fn['plug#']
--vim.call('plug#begin', '~/.vim/plugged')
--Plug 'phaazon/hop.nvim'
--vim.call('plug#end')
-- require'hop'.setup() {}

-- local fn = vim.fn
-- local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
-- if fn.empty(fn.glob(install_path)) > 0 then
--   packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
-- end
-- -- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]
-- require('packer').startup(function()
--   use {
--     'phaazon/hop.nvim',
--     branch = 'v1', -- optional but strongly recommended
--     config = function()
--       -- you can configure Hop the way you like here; see :h hop-config
--       require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
--     end
--   }
--   if packer_bootstrap then
--     require('packer').sync()
--   end
-- end)

--require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
--vim.api.nvim_set_keymap('n', 'sk', ":HopChar2<CR>", {noremap = true})
--vim.api.nvim_set_keymap('o', 'sk', ":HopChar2<CR>", {noremap = true})
--vim.api.nvim_set_keymap('n', 'sj', ":HopWord<CR>", {noremap = true})
--vim.api.nvim_set_keymap('o', 'sj', ":HopWord<CR>", {noremap = true})
----vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_char2()<cr>", {})
