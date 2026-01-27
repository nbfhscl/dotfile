return
{
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              globals = { 'vim' },
            }
          }
        }
      }
    },
  },
  --, before = {'williamfzc/nvim-diagnostic' }},
  -- { 'williamfzc/nvim-diagnostic', requires = 'neovim/nvim-lspconfig'},
}
