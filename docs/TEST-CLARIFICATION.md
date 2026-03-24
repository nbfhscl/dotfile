# Arch Linux Docker 测试用例澄清

## 您遇到的错误分析

### 错误原因

您在 **bash shell** 中执行了 `source ~/.zshrc`，这是不兼容的操作。

```bash
[arch@archlinux ~]$ source ~/.zshrc  # ❌ 在 bash 中执行
-bash: zle: command not found         # zle 是 zsh 特有的
-bash: bindkey: command not found     # bindkey 是 zsh 特有的
-bash: syntax error near unexpected token `)'  # zsh 函数语法
```

### 正确使用方式

```bash
# Bash 用户
source ~/.bashrc  # ✅ 正确

# Zsh 用户
zsh
source ~/.zshrc   # ✅ 正确
```

## Docker 测试用例逐条澄清

### 测试环境问题

1. **Docker 容器一直卡在 pacman 安装阶段**
   - 使用 `yes | pacman -S` 仍然会提示
   - 测试从未真正完成
   - 没有验证 shell 配置的兼容性

2. **缺少依赖安装**
   - 没有安装 zsh 及相关工具
   - 没有测试在不同 shell 中的行为

### 应该测试的场景

#### ✅ 场景 1: Bash 用户（基础测试）

```bash
# Docker 测试命令
docker run -it archlinux bash

# 容器内操作
pacman -Sy --noconfirm
pacman -S --noconfirm git bash curl

# 部署 dotfile
bash install.sh deploy

# 测试 bash 配置
source ~/.bashrc           # ✅ 应该成功
echo $EDITOR              # 应该显示: nvim
echo $XDG_CONFIG_HOME     # 应该显示: ~/.config
```

**预期结果：**
- ✅ 没有语法错误
- ✅ bash 配置正常加载
- ✅ 环境变量正确设置

#### ✅ 场景 2: Zsh 用户（完整测试）

```bash
# Docker 测试命令
docker run -it archlinux bash

# 容器内操作
pacman -Sy --noconfirm
pacman -S --noconfirm git zsh zsh-autosuggestions zsh-syntax-highlighting zoxide fzf

# 部署 dotfile
bash install.sh deploy

# 测试 zsh 配置
zsh
source ~/.zshrc           # ✅ 应该成功
echo $EDITOR              # 应该显示: nvim
which zoxide             # 应该显示: /usr/bin/zoxide
```

**预期结果：**
- ✅ 没有语法错误
- ✅ zsh 配置正常加载
- ✅ 插件和工具可用

#### ❌ 场景 3: 在 bash 中 source zsh 配置（您遇到的情况）

```bash
# 错误操作
bash
source ~/.zshrc           # ❌ 会失败

# 错误信息
Warning: ~/.zshrc should be sourced in zsh, not bash
If you want to use bash configuration, run: source ~/.bashrc
```

**预期结果（已修复）：**
- ✅ 显示警告信息
- ✅ 返回错误代码
- ✅ 不会尝试加载不兼容的配置

### Shell 检测功能

现在配置文件包含 shell 检测，会防止错误的 source 操作：

**~/.zshrc 内容：**
```bash
# Dotfile XDG configuration
# Shell detection to prevent loading in incompatible shells
if [ -z "$ZSH_VERSION" ]; then
  echo "Warning: ~/.zshrc should be sourced in zsh, not ${0##*/}" >&2
  echo "If you want to use bash configuration, run: source ~/.bashrc" >&2
  return 1
fi

source "$HOME/.config/zsh/.zshrc"
```

**~/.bashrc 内容：**
```bash
# Dotfile XDG configuration
# Shell detection to prevent loading in incompatible shells
if [ -z "$BASH_VERSION" ]; then
  echo "Warning: ~/.bashrc should be sourced in bash, not ${0##*/}" >&2
  echo "If you want to use zsh configuration, run: source ~/.zshrc" >&2
  return 1
fi

source "$HOME/.config/bash/.bashrc"
```

## 测试用例总结

| 场景 | Shell | 命令 | 预期结果 | 状态 |
|------|-------|------|----------|------|
| 1 | bash | `source ~/.bashrc` | 成功加载 | ✅ |
| 2 | zsh | `source ~/.zshrc` | 成功加载（需要依赖） | ✅ |
| 3 | bash | `source ~/.zshrc` | 显示警告，返回错误 | ✅ 已修复 |
| 4 | zsh | `source ~/.bashrc` | 显示警告，返回错误 | ✅ 已修复 |

## 依赖说明

### Bash 配置依赖
- git（版本控制）
- curl（网络工具）
- 基础系统工具

### Zsh 配置依赖
- zsh（shell 本身）
- zsh-autosuggestions（自动建议）
- zsh-syntax-highlighting（语法高亮）
- zoxide（智能目录跳转）
- fzf（模糊查找器）

**注意：** 如果没有安装这些依赖，source 时可能会报错"command not found"。

## 建议

1. **检查当前 shell：**
   ```bash
   echo $SHELL  # 查看默认 shell
   ```

2. **使用正确的配置文件：**
   ```bash
   # Bash 用户
   source ~/.bashrc
   
   # Zsh 用户  
   zsh
   source ~/.zshrc
   ```

3. **安装缺失的依赖：**
   ```bash
   # Arch Linux
   sudo pacman -S zsh zsh-autosuggestions zsh-syntax-highlighting zoxide fzf
   ```

4. **切换默认 shell（可选）：**
   ```bash
   # 切换到 zsh
   chsh -s /bin/zsh
   
   # 切换到 bash
   chsh -s /bin/bash
   ```
