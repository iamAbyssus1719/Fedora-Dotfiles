export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="afowler"
export QT_QPA_PLATFORMTHEME="qt5ct"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

setopt PROMPT_SUBST
export PATH="$HOME/.local/bin:$PATH"

# function parse_git_branch {
#     local branch
#     branch=$(git symbolic-ref --short HEAD 2> /dev/null)
#     [[ -n "$branch" ]] && echo "%F{yellow}  $branch%f"
# }
# PROMPT=' %F{36}%~%f$(parse_git_branch) %F{white}>%f ' 

FNM_PATH="$HOME/.local/share/fnm"
if [[ -d "$FNM_PATH" ]]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

[[ -o interactive ]] && fastfetch

eval "$(starship init zsh)"
PROMPT_EOL_MARK=""export PATH="/home/abyssus1719/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/abyssus1719/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
