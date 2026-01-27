 return {
     {
         "smoka7/hop.nvim",
         enabled = false,
         version = "*",
         event = "VimEnter",
         config = function()
             multi_windows = true
             vim.api.nvim_set_keymap('n', ';f', ":HopChar2<CR>", {noremap = true})
             vim.api.nvim_set_keymap('o', ';f', ":HopChar2<CR>", {noremap = true})
             vim.api.nvim_set_keymap('n', ';t', ":HopWord<CR>", {noremap = true})
             vim.api.nvim_set_keymap('o', ';t', ":HopWord<CR>", {noremap = true})
         end
     }
 }
