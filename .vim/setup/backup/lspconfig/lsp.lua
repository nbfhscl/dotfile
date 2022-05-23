-- vim.lsp.set_log_level("debug")

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
OnAttach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- Mappings.
    local opts = { noremap=true, silent=true }
    -- refactor extract method
    -- refactor move class
    -- refactor rename
    -- show git blame
    -- auto add/remove import
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<leader>rr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    -- quick fix?
    buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    -- buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    -- buf_set_keymap('n', '<leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    -- buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    -- buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    -- buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<leader>of', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '<C-h>', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', '<C-l>', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    -- buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    -- buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

vim.cmd([[packadd packer.nvim]])
require('packer').startup({function()
    use {
        'neovim/nvim-lspconfig',
        opt = true,
        config = function()
        end
    }
    use {
        'williamboman/nvim-lsp-installer',
        disable = true,
        after = 'nvim-lspconfig',
        opt = true,
        config = function()
            local enhance_server_opts = {
                -- not work
                ["ccls"] = function(o)
                    o.init_options = {
                        compilationDatabaseDirectory = "build",
                        index = {
                            threads = 0,
                        },
                    }
                end,
            }
            -- Include the servers you want to have installed by default below
            local servers = {
                -- "ccls",
                -- "clangd",
                -- "vimls",
                "sumneko_lua",
                -- "jdtls"
            }
            local lsp_installer = require "nvim-lsp-installer"
            for _, name in pairs(servers) do
                local server_is_found, server = lsp_installer.get_server(name)
                if server_is_found then
                    if not server:is_installed() then
                        print("Installing " .. name)
                        server:install()
                    else
                        lsp_installer.on_server_ready(function(sv)
                            local opts = {
                                on_attach = OnAttach,
                                flags = {
                                    debounce_text_changes = 150,
                                }
                            }
                            if enhance_server_opts[sv.name] then
                                enhance_server_opts[sv.name](opts)
                            end
                            server:setup(opts)
                        end)
                    end
                end
            end
        end
    }
    use {
        'mfussenegger/nvim-jdtls',
        after = 'nvim-lspconfig',
        disable = true,
        opt = true,
        ft = "java",
        config = function()
            vim.cmd([[
            augroup jdtls
                autocmd!
                autocmd FileType java lua require'jdtls_setup'.setup()
            augroup end
            ]])
        end
    }
    -- use 'mfussenegger/nvim-dap'
    -- use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
    -- use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
    -- use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
    -- use 'L3MON4D3/LuaSnip' -- Snippets plugin
    -- use {
    --     "glepnir/lspsaga.nvim",
    --     disable = true,
    --     after = 'nvim-lspconfig',
    -- config = function()
    -- require('lspsaga').init_lsp_saga {}
    -- end
    -- -- }
    -- use {
    --     'ojroques/nvim-lspfuzzy',
    --     -- requires = {
    --     --     {'junegunn/fzf'},
    --     --     {'junegunn/fzf.vim'},  -- to enable preview (optional)
    --     -- },
    --     config = function()
    --         require('lspfuzzy').setup {}
    --     end
    -- }
end,
config = {
    display = {
        open_fn = require('packer.util').float,
    },
    git = {
        clone_timeout = 30,
    }
}})


-- packadd coq
-- packadd coq.artifacts
-- packadd coq.thirdparty
-- vim.cmd 'packadd nvim-cmp' -- Autocompletion plugin
-- vim.cmd 'packadd cmp-nvim-lsp' -- LSP source for nvim-cmp
-- vim.cmd 'packadd cmp_luasnip' -- Snippets source for nvim-cmp
-- vim.cmd 'packadd LuaSnip' -- Snippets plugin
-- vim.cmd 'packadd nvim-lspconfig'
-- vim.cmd 'packadd lspsaga.nvim'
-- if vim.fn.exists('g:loaded_lspsaga')
-- then
-- 	require('lspsaga').init_lsp_saga {}
-- end
-- vim.cmd 'packadd nvim-lspfuzzy'
-- if vim.fn.exists('g:loaded_lspfuzzy') then
--     require('lspfuzzy').setup {}
-- end


-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
-- -- Enable some language servers with the additional completion capabilities offered by nvim-cmp
-- local servers = { 'clangd' }
-- for _, lsp in ipairs(servers) do
--     lspconfig[lsp].setup {
--         -- on_attach = my_custom_on_attach,
--         capabilities = capabilities,
--     }
-- end
-- -- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'

-- -- luasnip setup
-- local luasnip = require 'luasnip'

-- -- nvim-cmp setup
-- local cmp = require 'cmp'
-- cmp.setup {
--     snippet = {
--         expand = function(args)
--             require('luasnip').lsp_expand(args.body)
--         end,
--     },
--     mapping = {
--         ['<C-p>'] = cmp.mapping.select_prev_item(),
--         ['<C-n>'] = cmp.mapping.select_next_item(),
--         ['<C-d>'] = cmp.mapping.scroll_docs(-4),
--         ['<C-f>'] = cmp.mapping.scroll_docs(4),
--         ['<C-Space>'] = cmp.mapping.complete(),
--         ['<C-e>'] = cmp.mapping.close(),
--         ['<CR>'] = cmp.mapping.confirm {
--             behavior = cmp.ConfirmBehavior.Replace,
--             select = true,
--         },
--         ['<Tab>'] = function(fallback)
--             if cmp.visible() then
--                 cmp.select_next_item()
--             elseif luasnip.expand_or_jumpable() then
--                 luasnip.expand_or_jump()
--             else
--                 fallback()
--             end
--         end,
--         ['<S-Tab>'] = function(fallback)
--             if cmp.visible() then
--                 cmp.select_prev_item()
--             elseif luasnip.jumpable(-1) then
--                 luasnip.jump(-1)
--             else
--                 fallback()
--             end
--         end,
--     },
--     sources = {
--         { name = 'nvim_lsp' },
--         { name = 'luasnip' },
--     },
-- }
