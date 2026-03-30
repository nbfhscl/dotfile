EDITOR=vim
export EDITOR

# Oh-My-Zsh configuration
ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

eval "$(zoxide init zsh)"
source <(fzf --zsh)

#bindkey -v
source ~/.config/bash/fzf.bash

# 接受 zsh-autosuggestions 的灰色建议
accept-suggestion() {
  if [[ -n $ZSH_AUTOSUGGEST_BUFFER ]]; then
    RBUFFER="$ZSH_AUTOSUGGEST_BUFFER"
    # 可选：清空建议缓存（避免重复）
    unset ZSH_AUTOSUGGEST_BUFFER
  else
    # 如果没有建议，执行默认行为（如 forward-word）
    zle forward-word
  fi
}
zle -N accept-suggestion

# 绑定 Alt-f,实际上生效的是alt-l
bindkey '^[f' accept-suggestion


_claude_with_profile() {
  export CLAUDE_CONFIG_DIR="$1"
  command claude "${@:2}"
}

# Personal profile (default)
claude() {
  _claude_with_profile "$HOME/.claude" "$@"
}

# Work profile
claude2() {
  _claude_with_profile "$HOME/.claude2" "$@"
}

alias py='python3'
