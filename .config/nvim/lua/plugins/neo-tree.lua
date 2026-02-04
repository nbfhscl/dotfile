return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		keys = {
			{
				"<leader>nr",
				"<cmd>Neotree reveal<cr>",
				desc = "NeoTree Reveal",
			},
		},
		config = function()
			local function open_grug_far(prefills)
				local grug_far = require("grug-far")

				if not grug_far.has_instance("explorer") then
					grug_far.open({ instanceName = "explorer" })
				else
					grug_far.get_instance("explorer"):open()
				end
				-- doing it seperately because multiple paths doesn't open work when passed with open
				-- updating the prefills without clearing the search and other fields
				grug_far.get_instance("explorer"):update_input_values(prefills, false)
			end
			require("neo-tree").setup({
				commands = {
					-- create a new neo-tree command
					grug_far_replace = function(state)
						local node = state.tree:get_node()
						local prefills = {
							-- also escape the paths if space is there
							-- if you want files to be selected, use ':p' only, see filename-modifiers
							paths = node.type == "directory" and vim.fn.fnameescape(
								vim.fn.fnamemodify(node:get_id(), ":p")
							) or vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":h")),
						}
						open_grug_far(prefills)
					end,
					-- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/fbb631e818f48591d0c3a590817003d36d0de691/doc/neo-tree.txt#L535
					grug_far_replace_visual = function(state, selected_nodes, callback)
						local paths = {}
						for _, node in pairs(selected_nodes) do
							-- also escape the paths if space is there
							-- if you want files to be selected, use ':p' only, see filename-modifiers
							local path = node.type == "directory"
									and vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":p"))
								or vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":h"))
							table.insert(paths, path)
						end
						local prefills = { paths = table.concat(paths, "\n") }
						open_grug_far(prefills)
					end,
				},
				window = {
					mappings = {
						-- map our new command to z
						z = "grug_far_replace",
					},
				},
				-- rest of your config
			})
		end,
	},
}
