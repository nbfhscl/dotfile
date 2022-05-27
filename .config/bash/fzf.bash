HERE="${BASH_SOURCE[0]%/*}"

# export FZF_DEFAULT_COMMAND='fd --type f --color=never'
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_ALT_C_COMMAND="fd --type d --color=never"

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!{.git,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="rg --sort-files --files --null 2> /dev/null | xargs -0 dirname | uniq"

# # cdf - cd into the directory of the selected file
# function cdf {
#   local file
#   local dir
#   file=$(fd . -t=f ${1:-.} 2> /dev/null | fzf +m) && dir=$(dirname "$file") && cd "$dir"
# }
# cdf - cd into the directory of the selected file
cdf() {
   local file
   local dir
   file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
}

# cd. - including hidden directories
function cd. {
  local dir
  # dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m) && cd "$dir"
  dir=$(fd . -t=d ${1:-.} 2> /dev/null | fzf +m) && cd "$dir"
}
 
# cd. - cd to selected parent directory
function cd.. {
  local declare dirs=()
  get_parent_dirs() {
    if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
    if [[ "${1}" == '/' ]]; then
      for _dir in "${dirs[@]}"; do echo $_dir; done
    else
      get_parent_dirs $(dirname "$1")
    fi
  }
  local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf-tmux --tac)
  cd "$DIR"
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
function fkill {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}

