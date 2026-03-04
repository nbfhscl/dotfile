return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			-- 这里默认是 *Mason 包名*（最稳）
			ensure_installed = {
				"debugpy",
				"java-debug-adapter",
				"java-test",

				"markdown-toc",
				"markdownlint-cli2",

				"ruff",
				"shfmt",
				"sqlfluff",
				"stylua",

				"tree-sitter-cli",
			},
			auto_update = false, -- 内网建议 false
			run_on_start = true, -- 启动时确保工具齐
		},
	},
}
