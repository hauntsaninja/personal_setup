#!/bin/zsh

typeset -F 3 SECONDS=0

# load zgen
source "${HOME}/.zgen/zgen.zsh"

if zgen saved && [[ $(( $(date +%s) - $(stat -f "%m" ~/.zgen/init.zsh) )) -gt 1000000 ]]; then
    touch ~/.zgen/init.zsh
    { brew update; brew upgrade; brew cleanup; brew cask cleanup; } &
    apm upgrade --no-confirm &
    zgen selfupdate; zgen update;
fi

# if the init scipt doesn't exist
if ! zgen saved; then

    # specify plugins here
    zgen oh-my-zsh

    zgen oh-my-zsh plugins/osx
    # zgen oh-my-zsh plugins/fasd
    # zgen oh-my-zsh plugins/colorize
    # zgen oh-my-zsh plugins/rand-quote
    # zgen oh-my-zsh plugins/dircycle

    zgen load hauntsaninja/my_git_aliases

    zgen load junegunn/fzf shell
    zgen load rupa/z
    zgen load djui/alias-tips
    zgen load shannonmoeller/up
    # zgen load marzocchi/zsh-notify
    # zgen load clvv/fasd
    # zgen load nvbn/thefuck

    # order matters
    zgen load zsh-users/zsh-autosuggestions
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-history-substring-search

    # generate the init script from plugins above
    zgen save
fi

# history substring search
HISTORY_SUBSTRING_SEARCH_FUZZY='yes'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=11,fg=black,bold'
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

# syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
ZSH_HIGHLIGHT_PATTERNS+=('rm *' 'fg=9')
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='underline'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue'
ZSH_HIGHLIGHT_STYLES[builtin]='none'
ZSH_HIGHLIGHT_STYLES[command]='none'
ZSH_HIGHLIGHT_STYLES[hashed-command]='none'
ZSH_HIGHLIGHT_STYLES[precommand]='none'
ZSH_HIGHLIGHT_STYLES[redirection]='bold'

# setopt interactivecomments
# setopt autocd
# setopt promptsubst

function _git_current_branch() {
    local ref
    ref=$(git symbolic-ref --short HEAD 2> /dev/null)
    local ret=$?
    if [[ $ret != 0 ]]; then
        ref=$(git rev-parse --short HEAD 2> /dev/null) || return
    fi
    echo -n $ref && echo ' '
}

RPROMPT="%B%(?::%F{red}%? %f)%b"
PROMPT="$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f \$([[ -n \$(git status --porcelain --untracked-files=no 2    > /dev/null) ]] && echo '%F{red}' || echo '%F{green}')\${\$(git symbolic-ref HEAD 2> /dev/null || return 0)#refs/heads/}%f λ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')\$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f λ "

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# fzf stuff
# full screen history search
_fhist () {
    [ -n "$BUFFER" ] && BUFFER="${BUFFER%% ##} "
    LINE="$(history | fzf -q "$BUFFER" --tac --tiebreak=index | tr -s ' ' | cut -c7-)"

    zle redisplay
    zle kill-buffer
    BUFFER="$LINE"
    CURSOR=${#BUFFER}

    region_highlight=()
    _zsh_highlight
}
zle -N _fhist
bindkey '^r' _fhist

_fzf_compgen_path() {
  fd --hidden --follow . "$1"
}

_fzf_compgen_dir() {
  fd --hidden --follow --type d . "$1"
}

# general things
function google() {
    if [[ $# -gt 0 ]]; then
        url="https://www.google.com/search?q=${(j:+:)@}"
    else
        url="https://www.google.com/"
    fi
    open "$url"
}

alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"

alias brewdeplist='brew leaves | xargs brew deps --installed --for-each'

export BAT_THEME=GitHub

# needs curl -fLo ~/Downloads/preview.sh https://raw.githubusercontent.com/junegunn/fzf.vim/master/bin/preview.sh
frg() {
    rg --color ansi --vimgrep $@ | fzf --ansi --preview '~/Downloads/preview.sh {}'
}

fz() {
    cd $(z | pyp 'x.split()[1]' | fzf --tac $([[ -z "$1" ]] && echo "" || echo "--query $@") || pwd)
}

# ripgrep aliases
alias rg='rg -M 150'
alias rgc='rg -t c -t cpp'
alias rgp='rg -t py'
alias rgj='rg -t java'

echo "$SECONDS seconds"
