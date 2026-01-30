return {

	"ibhagwan/fzf-lua",
	keys = {
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
