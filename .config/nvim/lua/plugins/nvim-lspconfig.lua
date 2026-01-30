return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							globals = { "vim" },
						},
					},
				},
				marksman = {
					settings = {
						markdown = {
							-- 全局禁用某些规则
							disableRules = { "MD013", "MD024", "MD032", "MD036", "MD060" }, -- 行长、重复标题等
							-- 或启用自定义配置文件
							--configPath = vim.fn.expand("~/.config/markdownlint.json"),
						},
					},
				},
				pyright = {
					settings = {
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
