return {
	{
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
		keys = {
			-- {
			-- 	"<leader>ci",
			-- 	function()
			-- 		vim.lsp.buf.incoming_calls()
			-- 	end,
			-- },
			-- {
			-- 	"<leader>co",
			-- 	function()
			-- 		vim.lsp.buf.outgoing_calls()
			-- 	end,
			-- },
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
	},
}
