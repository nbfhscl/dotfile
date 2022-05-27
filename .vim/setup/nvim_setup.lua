local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end
local use = require('packer').use
require('packer').startup({function(use)
    use {
        'phaazon/hop.nvim',
        branch = 'v1', -- optional but strongly recommended
        config = function()
            -- need to call PackerCompile in order to make this work?
            vim.api.nvim_set_keymap('n', 'sk', ":HopChar2<CR>", {noremap = true})
            vim.api.nvim_set_keymap('o', 'sk', ":HopChar2<CR>", {noremap = true})
            vim.api.nvim_set_keymap('n', 'sj', ":HopWord<CR>", {noremap = true})
            vim.api.nvim_set_keymap('o', 'sj', ":HopWord<CR>", {noremap = true})
            -- you can configure Hop the way you like here; see :h hop-config
            require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
        end
    }
    use { 'nvim-lua/plenary.nvim' }
    use {
        disable = true,
        'sindrets/diffview.nvim',
        requires = {'nvim-lua/plenary.nvim'},
    }
    use {
        disable = true,
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup {
                -- A list of parser names, or "all"
                ensure_installed = { "c", "lua", "go", "java" },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- List of parsers to ignore installing (for "all")
                ignore_install = { "javascript" },

                highlight = {
                    -- `false` will disable the whole extension
                    enable = true,

                    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
                    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
                    -- the name of the parser)
                    -- list of language that will be disabled
                    disable = {},

                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
            }
        end
    }
    use {
        "ThePrimeagen/refactoring.nvim",
        requires = {
            {"nvim-lua/plenary.nvim"},
            {"nvim-treesitter/nvim-treesitter"}
        },
        config = function()
            -- Remaps for the refactoring operations currently offered by the plugin
            vim.api.nvim_set_keymap("v", "<leader>re", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>]], {noremap = true, silent = true, expr = false})
            vim.api.nvim_set_keymap("v", "<leader>rf", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]], {noremap = true, silent = true, expr = false})
            vim.api.nvim_set_keymap("v", "<leader>rv", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>]], {noremap = true, silent = true, expr = false})
            vim.api.nvim_set_keymap("v", "<leader>ri", [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], {noremap = true, silent = true, expr = false})

            -- Extract block doesn't need visual mode
            vim.api.nvim_set_keymap("n", "<leader>rb", [[ <Cmd>lua require('refactoring').refactor('Extract Block')<CR>]], {noremap = true, silent = true, expr = false})
            vim.api.nvim_set_keymap("n", "<leader>rbf", [[ <Cmd>lua require('refactoring').refactor('Extract Block To File')<CR>]], {noremap = true, silent = true, expr = false})

            -- Inline variable can also pick up the identifier currently under the cursor without visual mode
            vim.api.nvim_set_keymap("n", "<leader>ri", [[ <Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], {noremap = true, silent = true, expr = false})
            require('refactoring').setup({})
        end
    }
    if packer_bootstrap then
        require('packer').sync()
    end
end,
config = {
    display = {
        open_fn = require('packer.util').float,
    },
    git = {
        clone_timeout = 30,
    }
}
})


