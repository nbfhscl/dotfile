EDITOR=vim
export EDITOR
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
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

