return {
	{
		"mfussenegger/nvim-lint",
		opts = {
			-- 覆盖默认的 lint 配置，排除 markdown 文件
			linters_by_ft = {
				-- 保留你其他文件类型的 lint 配置，例如：
				-- python = { "pylint" },
				-- lua = { "luacheck" },
				-- 关键：将 markdown 的 linters 设为空表，屏蔽所有 lint 检查
				markdown = {},
			},
		},
	},
}
