#!/bin/zsh

typeset -F 3 SECONDS=0

autoload -U compaudit compinit
compinit -i -C

# load zgen
source "${HOME}/.zgen/zgen.zsh"

if zgen saved && [[ $(( $(date +%s) - $(stat -f "%m" ~/.zgen/init.zsh) )) -gt 1000000 ]]; then
    touch ~/.zgen/init.zsh
    { brew update; brew upgrade; brew cleanup; } &
    pipx upgrade-all &
    apm upgrade --no-confirm &
    zgen selfupdate; zgen update;
fi

# if the init scipt doesn't exist
if ! zgen saved; then

    # the gist has what's left of ohmyzsh
    zgen load https://gist.github.com/528dc0693e8dfacdfdc0cef6bd7f844b.git
    zgen load hauntsaninja/my_git_aliases

    zgen load junegunn/fzf shell
    # zgen load Aloxaf/fzf-tab
    zgen load lincheney/fzf-tab-completion zsh

    zgen load rupa/z
    zgen load djui/alias-tips
    zgen load shannonmoeller/up
    # nice, but can't group notifs, bug in removing failure notifs, bad default titles
    # zgen load marzocchi/zsh-notify

    # zgen oh-my-zsh plugins/dircycle

    zgen load zsh-users/zsh-autosuggestions
    # order matters
    zgen load zsh-users/zsh-syntax-highlighting  # should be last
    zgen load zsh-users/zsh-history-substring-search  # except for this

    # generate the init script from plugins above
    zgen save
fi


# ==========
# Plugin config
# ==========

# history substring search
HISTORY_SUBSTRING_SEARCH_FUZZY='yes'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=11,fg=black,bold'
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

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

# fzf config
_fzf_compgen_path() {
  fd --hidden --follow . "$1"
}

_fzf_compgen_dir() {
  fd --hidden --follow --type d . "$1"
}

# ==========
# Directory
# ==========
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

export LSCOLORS="Gxfxcxdxbxegedabagacad"
alias ls='ls -G'  # might not work on other platforms
alias ll='ls -lah'
alias lt='ls -latrh'

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

alias -- -='cd -'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'

function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -10
  fi
}

fz() {
    cd $(z | pyp 'x.split()[1]' | fzf --tac $([[ -z "$1" ]] && echo "" || echo "--query $@") || pwd)
}


# ==========
# History
# ==========
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

setopt extended_history        # record timestamp of command in HISTFILE
setopt hist_expire_dups_first  # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups        # ignore duplicated commands in history list
setopt hist_ignore_space       # ignore commands that start with space
setopt hist_verify             # show command with history expansion to user before running it
setopt share_history           # share command history data

function _git_current_branch() {
    local ref
    ref=$(git symbolic-ref --short HEAD 2> /dev/null)
    local ret=$?
    if [[ $ret != 0 ]]; then
        ref=$(git rev-parse --short HEAD 2> /dev/null) || return
    fi
    echo -n $ref && echo ' '
}

# full screen fuzzy history search
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


# ==========
# Prompt
# ==========
setopt prompt_subst  # makes prompts dynamic

RPROMPT="%B%(?::%F{red}%? %f)%b"
PROMPT="$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f \$([[ -n \$(git status --porcelain --untracked-files=no 2    > /dev/null) ]] && echo '%F{red}' || echo '%F{green}')\${\$(git symbolic-ref HEAD 2> /dev/null || return 0)#refs/heads/}%f λ "
# PROMPT="%B%(?::%F{red}%? %f)%b$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')\$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f λ "

# Maybe look into romkatv/powerlevel10k (or possibly sindresorhus/pure)

# ==========
# Ripgrep
# ==========

# needs curl -fLo ~/.local/bin/preview.sh https://raw.githubusercontent.com/junegunn/fzf.vim/master/bin/preview.sh
export BAT_THEME=GitHub
frg() {
    rg --color ansi --vimgrep $@ | fzf --ansi --preview '~/.local/bin/preview.sh {}'
}

# ripgrep aliases
alias rg='rg -M 250'
alias rgc='rg -t c -t cpp'
alias rgp='rg -t py'
alias rgj='rg -t java'

# ==========
# Misc
# ==========
export PAGER=less
export LESS=-R              # deals with colours better

setopt correct_all          # adds corrections
setopt interactivecomments  # recognise comments
setopt multios              # something to do with redirection?

function google() {
    if [[ $# -gt 0 ]]; then
        url="https://www.google.com/search?q=${(j:+:)@}"
    else
        url="https://www.google.com/"
    fi
    open "$url"
}

alias brewdeplist='brew leaves | xargs brew deps --installed --for-each'

echo "$SECONDS seconds"
