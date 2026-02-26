return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			--{
			--	"<leader>dbx",
			--	function()
			--		require("dap").set_exception_breakpoints({ "all" })
			--	end,
			--	desc = "Break on all exceptions",
			--},
			--{
			--	"<leader>dbu",
			--	function()
			--		require("dap").set_exception_breakpoints({ "uncaught" })
			--	end,
			--	desc = "Break on uncaught exceptions",
			--},
		},
		config = function()
			local dap = require("dap")
			-- 关键1：在会话启动前设置异常断点（避免竞争条件）
			dap.listeners.before.event_initialized["dap-set-caught-exceptions"] = function()
				dap.set_exception_breakpoints({ "all" }) -- 确保每次启动都启用
			end
			-- Auto-enable exception breakpoints on every debug session
			dap.listeners.after.event_initialized["stop_on_exception"] = function()
				dap.set_exception_breakpoints({ "all" })
			end

			-- 预配置 Python 异常断点行为
			dap.configurations.python = dap.configurations.python or {}
			table.insert(dap.configurations.python, 1, {
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				pythonPath = function()
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
						return cwd .. "/venv/bin/python"
					else
						return "python"
					end
				end,
				console = "integratedTerminal",
				justMyCode = false,
				redirectOutput = true,
				showReturnValue = true,
				-- 关键：捕获所有异常（包括 try-except 中的）
				exceptionHandling = {
					ignoreCaughtExceptions = false,
					ignoreUncaughtExceptions = false,
				},
			})
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		keys = {},
		opts = {
			layouts = {
				{
					elements = {
						{
							id = "scopes",
							size = 0.6,
						},
						{
							id = "breakpoints",
							size = 0.1,
						},
						{
							id = "stacks",
							size = 0.15,
						},
						{
							id = "watches",
							size = 0.15,
						},
					},
					position = "left",
					size = 40,
				},
				{
					elements = {
						{
							id = "repl",
							size = 0.5,
						},
						{
							id = "console",
							size = 0.5,
						},
					},
					position = "bottom",
					size = 10,
				},
			},
		},
	},
}
