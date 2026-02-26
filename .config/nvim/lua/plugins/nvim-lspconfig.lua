return {
	{
		"neovim/nvim-lspconfig",
		priority = 1000,
		opts = {
			servers = {
				-- 配置 JSON-LSP，禁用无关警告
				jsonls = {
					handlers = {
						-- 禁用 workspace/diagnostic/refresh 方法的错误
						["workspace/diagnostic/refresh"] = function(_, _, ctx)
							return {}
						end,
					},
					settings = {
						-- 仅保留 JSON-LSP 原生支持的配置，删除所有 python/analysis 字段
						json = {
							schemas = {},
							validate = { enable = true },
						},
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							globals = { "vim" },
						},
					},
				},
				basedpyright = {
					settings = {
						basedpyright = {
							-- 关键：不要 single-file 启动，避免 root=nil 的第二个实例
							single_file_support = false,
							analysis = {
								ignorePatterns = { "*.pyi" },
								diagnosticSeverityOverrides = {
									reportCallIssue = "warning",
									reportUnreachable = "warning",
									reportUnusedImport = "none",
									reportUnusedCoroutine = "warning",
								},
								autoImportCompletions = true,
								autoSearchPaths = true,
								diagnosticMode = "workspace",
								--diagnosticMode = "openFilesOnly",
								typeCheckingMode = "off",
								reportCallIssue = "none",
								disableOrganizeImports = true,
							},
						},
					},
				},
				pyright = false,
				-- pyright = {
				-- 	settings = {
				-- 		pright = {
				-- 			-- 启用自动导入组织
				-- 			organizeImports = true,
				-- 		},
				-- 		python = {
				-- 			analysis = {
				-- 				-- Add current project root to module search path
				-- 				extraPaths = { vim.fn.getcwd() },
				-- 				typeCheckingMode = "basic",
				-- 				autoSearchPaths = true,
				-- 				useLibraryCodeForTypes = true,
				-- 				diagnosticMode = "workspace", -- 确保跨文件分析
				-- 				autoImportCompletions = true,
				-- 			},
				-- 		},
				-- 	},

				-- 	-- 确保 LSP 客户端支持 codeAction/resolve
				-- 	capabilities = {
				-- 		textDocument = {
				-- 			codeAction = {
				-- 				dynamicRegistration = false,
				-- 				isPreferredSupport = true,
				-- 				disabledSupport = true,
				-- 				dataSupport = true, -- ⭐ 允许 codeAction 携带数据（Pyright 需要）
				-- 				resolveSupport = {
				-- 					properties = { "edit" }, -- ⭐ 支持动态解析 codeAction
				-- 				},
				-- 			},
				-- 		},
				-- 	},
				-- },
			},
			diagnostics = {
				-- 核心配置：控制行内虚拟文本（virtual text）的显示规则
				virtual_text = {
					-- 自定义函数：仅 ERROR 级别显示行内文本
					severity = {
						min = vim.diagnostic.severity.ERROR, -- 最小级别为 ERROR（仅错误显示）
						max = vim.diagnostic.severity.ERROR, -- 最大级别为 ERROR（仅错误显示）
					},
					-- 可选：自定义行内错误文本的样式（保持 LazyVim 风格）
					prefix = "●", -- 行内错误前缀符号
					source = "if_many", -- 显示诊断源（如 pyright），仅当多个源时显示
				},
				-- 保留侧边栏符号（signcolumn）：错误/警告都显示图标，仅行内不显示警告
				signs = {
					severity = {
						min = vim.diagnostic.severity.HINT, -- 侧边栏显示 警告+错误 图标
					},
				},
				-- 保留诊断浮动提示（鼠标悬停时显示所有级别）
				float = {
					severity = {
						min = vim.diagnostic.severity.INFO, -- 悬停显示 警告+错误 详情
					},
				},
				-- 其他可选配置（保持 LazyVim 默认）
				-- underline = true, -- 错误/警告都下划线标记（可根据需求关闭）
				--update_in_insert = false, -- 插入模式不更新诊断
				--severity_sort = true, -- 诊断列表按级别排序（错误在前）
			},
		},
		-- 初始化诊断配置（确保生效）
		-- config = function(_, opts)
		-- 	-- 应用诊断全局配置
		-- 	--vim.diagnostic.config(opts.diagnostics)

		-- 	-- 可选：自定义诊断符号（侧边栏显示的图标，保持 LazyVim 风格）
		-- 	local signs = {
		-- 		Error = "",
		-- 		Warn = "",
		-- 		Hint = "",
		-- 		Info = "",
		-- 	}
		-- 	-- for type, icon in pairs(signs) do
		-- 	-- 	local hl = "DiagnosticSign" .. type
		-- 	-- 	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		-- 	-- end
		-- end,
	},
}
