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
				"debugpy",
				"java-debug-adapter",
				"java-test",
				"jdtls",
				"json-lsp",
				"lua-language-server",
				"markdown-toc",
				"markdownlint-cli2",
				"marksman",
				"ruff",
				"shfmt",
				"sqlfluff",
				"stylua",
				"taplo",
				"tree-sitter-cli",
				"vtsls",
				"yaml-language-server",
				"typescript-language-server",
			},
			-- 自动把已安装的 server 交给 lspconfig setup
			automatic_installation = true,
		},
	},
}
