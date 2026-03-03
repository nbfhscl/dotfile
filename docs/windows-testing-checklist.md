# Windows 安装脚本测试清单

## 环境检测测试
- [ ] PowerShell 版本检测（< 7.0 应报错）
- [ ] winget 可用性检测
- [ ] 管理员权限检测
- [ ] 已安装工具检测

## 工具安装测试
- [ ] Windows Terminal 安装
- [ ] PowerShell 7 安装
- [ ] Git 安装
- [ ] Node.js 安装
- [ ] Neovim 安装

## PowerShell 模块测试
- [ ] Oh-My-Posh 安装
- [ ] PSReadLine 安装
- [ ] Terminal-Icons 安装
- [ ] zoxide 安装
- [ ] PSFzf 安装（可选）

## dotfile 部署测试
- [ ] dotfile 仓库克隆
- [ ] 配置文件备份
- [ ] PowerShell Profile 部署
- [ ] Windows Terminal 配置部署
- [ ] dot alias 添加

## 验证测试
- [ ] 所有工具验证通过
- [ ] 版本信息显示正确
- [ ] 后续步骤指引显示

## 参数测试
- [ ] -DryRun 参数工作正常
- [ ] -SkipTools 参数工作正常
- [ ] -OnlyDotfile 参数工作正常