return {

	"ibhagwan/fzf-lua",
	lazy = true,
	opts = {
		winopts = {
			height = 0.85,
			width = 0.85,
			preview = {
				delay = 50,
				hidden = "nohidden",
				wrap = "wrap",
				layout = "horizontal",
				horizontal = "right:60%",
			},
		},
		previewers = {
			builtin = {
				syntax = true,
				limit_buffers = false,
			},
		},
	},
	-- config = function()
	-- 	local fzf = require("fzf-lua")
	-- 	-- 启动时打印可用方法，排查是否有 Call Hierarchy 相关 API
	-- 	vim.notify("fzf-lua 可用方法检测：" .. vim.inspect({
	-- 		lsp_call_hierarchy = fzf.lsp_call_hierarchy ~= nil,
	-- 		lsp_call_hierarchy_incoming = fzf.lsp_call_hierarchy_incoming ~= nil,
	-- 		lsp_call_hierarchy_outgoing = fzf.lsp_call_hierarchy_outgoing ~= nil,
	-- 	}))

	-- 	-- 手动绑定最基础的快捷键（跳过兼容逻辑，直接测试）
	-- 	vim.keymap.set("n", "<leader>ci", function()
	-- 		-- 直接调用新版 API（pyright 1.1.407 适配这个）
	-- 		fzf.lsp_call_hierarchy_incoming()
	-- 	end, { desc = "Incoming Calls", silent = true })

	-- 	vim.keymap.set("n", "<leader>co", function()
	-- 		fzf.lsp_call_hierarchy_outgoing()
	-- 	end, { desc = "Outgoing Calls", silent = true })
	-- end,
	keys = {
		--{
		--	"<leader>ci",
		--	function()
		--		vim.lsp.buf.incoming_calls()
		--	end,
		--},
		--{
		--	"<leader>co",
		--	function()
		--		vim.lsp.buf.outgoing_calls()
		--	end,
		--},
		{
			"<leader>fC",
			function()
				require("fzf-lua").files({
					cwd = vim.fn.expand("~/.local/share/nvim"),
					prompt = " NVim Files> ",
					previewer = "builtin",
					fzf_opts = {
						["--preview-window"] = "right:60%",
					},
				})
			end,
			desc = "Search NVim data files",
		},
		-- 搜索 ~/.local/share/nvim 目录下的文件内容
		{
			"<leader>sP",
			function()
				require("fzf-lua").live_grep({
					cwd = vim.fn.expand("~/.local/share/nvim"),
					prompt = " NVim Content> ",
					fzf_opts = {
						["--preview-window"] = "right:60%",
					},
				})
			end,
			desc = "Search NVim data content",
		},
	},
}
