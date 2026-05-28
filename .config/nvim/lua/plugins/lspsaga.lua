-- ~/.config/nvim/lua/plugins/lspsaga.lua
return {
	-- 第一个插件配置：lspsaga 核心配置（实现多层调用链可视化）
	{
		"nvimdev/lspsaga.nvim",
		-- 依赖：需要 nvim-web-devicons 支持图标显示（LazyVim 已默认安装）
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- 图标依赖（可选，不删更美观）
			"nvim-treesitter/nvim-treesitter", -- 语法高亮依赖（必须，保证界面渲染正常）
		},
		-- 版本锁定（可选，推荐锁定稳定版，避免自动更新出问题）
		version = "v0.3.0",
		-- 配置 lspsaga 选项，重点启用 callhierarchy（多层调用链）
		opts = {
			-- 全局通用配置（可选，优化整体体验）
			ui = {
				border = "rounded", -- 圆角边框，更美观
				winblend = 0, -- 窗口透明度
			},
			-- 核心：多层调用链（Call Hierarchy）配置（实现 VS Code 风格多层可视化）
			callhierarchy = {
				show_detail = true, -- 显示详细信息（必须开启，才能展示多层调用链）
				max_depth = 10, -- 最大调用链深度（自定义，对应 VS Code 多层效果）
				keys = {
					edit = "e", -- 跳转至选中的调用位置
					vsplit = "v", -- 垂直分屏跳转
					split = "s", -- 水平分屏跳转
					tabe = "t", -- 新标签页跳转
					quit = "q", -- 关闭调用链窗口
					expand_collapse = "<cr>", -- 折叠/展开当前层级（核心快捷键，操作多层）
					toggle_or_open = "<tab>", -- 切换折叠状态或打开对应代码
				},
			},
			-- 其他可选配置（按需保留，不影响核心调用链功能）
			symbol_in_winbar = {
				enable = false, -- 若不需要 winbar 显示符号，可关闭
			},
			outline = {
				win_position = "right",
				win_width = 30,
			},
		},
		-- 配置快捷键（LazyVim 推荐在 config 中绑定，确保插件加载后生效）
		config = function(_, opts)
			-- 初始化 lspsaga
			require("lspsaga").setup(opts)

			-- 绑定多层调用链快捷键（和之前的功能对应，LazyVim 中正常生效）
			local keymap = vim.keymap.set
			-- 多层传入调用（谁调用了当前函数，支持折叠/展开）
			keymap(
				"n",
				"<leader>ci",
				"<cmd>Lspsaga incoming_calls<CR>",
				{ desc = "LSP: 多层传入调用（Lspsaga）" }
			)
			-- 多层传出调用（当前函数调用了谁，支持折叠/展开）
			keymap(
				"n",
				"<leader>co",
				"<cmd>Lspsaga outgoing_calls<CR>",
				{ desc = "LSP: 多层传出调用（Lspsaga）" }
			)
		end,
	},
}
