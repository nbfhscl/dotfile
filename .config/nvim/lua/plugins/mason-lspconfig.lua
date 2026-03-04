return {
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			-- 让 mason 自动安装这些 LSP
			ensure_installed = {
				"basedpyright",
				"jdtls",
				"jsonls",
				"lua_ls",
				"marksman",
				"taplo",
				"yamlls",

				-- TypeScript 二选一（按你 nvim-lspconfig 版本）
				-- 新版常用：
				"ts_ls",
				-- 老版（如果你那边还是 tsserver）：
				-- "tsserver",

				-- 如果你用 vtsls：
				"vtsls",
			},
			-- 自动把已安装的 server 交给 lspconfig setup
			automatic_installation = true,
		},
	},
}
