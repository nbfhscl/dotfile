return {
	{
		"neovim/nvim-lspconfig",
		priority = 1000,
		opts = {
			--diagnostics = {
			--	-- 全局屏蔽 MD060，同时避免其他冗余规则干扰
			--	ignore_code = { "MD060" },
			--},
			servers = {
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
							analysis = {
								ignorePatterns = { "*.pyi" },
								diagnosticSeverityOverrides = {
									reportCallIssue = "warning",
									reportUnreachable = "warning",
									reportUnusedImport = "none",
									reportUnusedCoroutine = "warning",
								},
								diagnosticMode = "workspace",
								--diagnosticMode = "openFilesOnly",
								typeCheckingMode = "basic",
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
		},
	},
}
