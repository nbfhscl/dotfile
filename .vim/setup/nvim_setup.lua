local use = require('packer').use
require('packer').startup({function()
    use {
        'phaazon/hop.nvim',
        branch = 'v1', -- optional but strongly recommended
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
        end
    }
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
        run = ':TSUpdate'
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

vim.api.nvim_set_keymap('n', 'sk', ":HopChar2<CR>", {noremap = true})
vim.api.nvim_set_keymap('o', 'sk', ":HopChar2<CR>", {noremap = true})
vim.api.nvim_set_keymap('n', 'sj', ":HopWord<CR>", {noremap = true})
vim.api.nvim_set_keymap('o', 'sj', ":HopWord<CR>", {noremap = true})

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

