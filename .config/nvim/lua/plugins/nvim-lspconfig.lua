return {
	{
		"neovim/nvim-lspconfig",
		priority = 1000,
		opts = {
			--diagnostics = {
			--	-- 全局屏蔽 MD060，同时避免其他冗余规则干扰
			--	ignore_code = { "MD060" },
			--},
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							globals = { "vim" },
						},
					},
				},
				pyright = {
					settings = {
						pright = {
							-- 启用自动导入组织
							organizeImports = true,
						},
						python = {
							analysis = {
								-- Add current project root to module search path
								extraPaths = { vim.fn.getcwd() },
								typeCheckingMode = "basic",
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "workspace", -- 确保跨文件分析
							},
						},
					},
				},
			},
		},
	},
	--, before = {'williamfzc/nvim-diagnostic' }},
	-- { 'williamfzc/nvim-diagnostic', requires = 'neovim/nvim-lspconfig'},
}
