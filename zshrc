#!/bin/zsh

typeset -F 3 SECONDS=0

autoload -U compinit
compinit -i -C

# load zgen
source "${HOME}/.zgen/zgen.zsh"


function file_mtime() {
  local cmd
  case "$OSTYPE" in
    darwin*)  stat -f '%m' $1 ;;
    linux*)   date +%s -r $1 ;;
  esac
}

# automatically update things every now and then
if zgen saved && [[ $(( $(date +%s) - $(file_mtime ~/.zgen/init.zsh) )) -gt 1000000 ]]; then
    touch ~/.zgen/init.zsh
    { brew update; brew upgrade; brew cleanup; } &
    pipx upgrade-all &
    zgen selfupdate; zgen update;
fi

# if the init scipt doesn't exist
if ! zgen saved; then

    # the gist has a couple things scavenged from ohmyzsh
    zgen load https://gist.github.com/528dc0693e8dfacdfdc0cef6bd7f844b.git
    # git aliases
    zgen load hauntsaninja/my_git_aliases

    # fzf for everything
    zgen load junegunn/fzf shell
    zgen load Aloxaf/fzf-tab

    zgen load docker/cli contrib/completion/zsh

    # use z to cd to recently used directories
    zgen load rupa/z
    # suggest use of defined aliases
    zgen load djui/alias-tips
    # cd upwards in the directory tree
    zgen load shannonmoeller/up

    # nice, but can't group notifs, bug in removing failure notifs, bad default titles
    # zgen load marzocchi/zsh-notify

    zgen load MichaelAquilina/zsh-autoswitch-virtualenv

    # provide suggestions as you type
    zgen load zsh-users/zsh-autosuggestions

    # order matters for the next two
    zgen load zsh-users/zsh-syntax-highlighting  # should be last
    # press up and down to fuzzy search history for your partial command
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
export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*'"

_fzf_compgen_path() {
  find $1 -type f -not -path '*/\.git/*'
}

_fzf_compgen_dir() {
  find $1 -type d -not -path '*/\.git/*'
}

# fuzzy vim
alias fvim='vim $(fzf)'

# fuzzy ps
case "$OSTYPE" in
  darwin*)  alias fps='ps -e -o "pid %cpu %mem args" -m | fzf  --header-lines=1 | pyp "x.strip().split()[0]"' ;;
  linux*)   alias fps='ps -e -o "pid %cpu %mem comm args" --sort rss | fzf  --header-lines=1 --tac | pyp "x.strip().split()[0]"' ;;
esac

# ==========
# Directory
# ==========

alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

export LSCOLORS="Gxfxcxdxbxegedabagacad"
case "$OSTYPE" in
  darwin*)  alias ls='ls -G' ;;
  linux*)   alias ls='ls --color=tty' ;;
esac
alias ll='ls -lah'
alias lt='ls -latrh'

setopt auto_cd            # use directory name to cd
setopt auto_pushd         # cd adds directory to the stack
setopt pushd_ignore_dups  # don't push directory if it's already on the stack
setopt pushdminus         # use - instead of + for specifying a directory in the stack

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

# fuzzy z
fz() {
    cd $(z | pyp 'x.split()[1]' | fzf --tac $([[ -z "$1" ]] && echo "" || echo "--query $@") || pwd)
}

# ==========
# History
# ==========

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=25000

setopt extended_history        # record timestamp of command in HISTFILE
setopt hist_expire_dups_first  # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups        # ignore duplicated commands in history list
setopt hist_ignore_space       # don't add commands that start with space to history
setopt hist_verify             # show command with history expansion before running it
setopt share_history           # share history between shells

# full screen fuzzy history search bound to ctrl-r
_fhist () {
    [ -n "$BUFFER" ] && BUFFER="${BUFFER%% ##} "
    LINE="$(history 0 | fzf -q "$BUFFER" --tac --tiebreak=index | tr -s ' ' | cut -c7-)"

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

function _git_current_branch() {
    local ref
    ref=$(git symbolic-ref --short HEAD 2> /dev/null)
    local ret=$?
    if [[ $ret != 0 ]]; then
        ref=$(git rev-parse --short HEAD 2> /dev/null) || return
    fi
    echo -n $ref && echo ' '
}

RPROMPT="%B%(?::%F{red}%? %f)%b"  # exit code to the right
PROMPT="$([ -z $SSH_CLIENT ] || echo '%F{blue}%n@%m:%f')$([ -z $STY ] || echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "

# maybe look into romkatv/powerlevel10k (or possibly sindresorhus/pure)

# ==========
# Ripgrep
# ==========

# fuzzy ripgrep
# needs curl -fLo ~/.local/bin/preview.sh https://raw.githubusercontent.com/junegunn/fzf.vim/2bf85d25e203a536edb2c072c0d41b29e8e4cc1b/bin/preview.sh
export BAT_THEME=GitHub
frg() (
    set -o pipefail
    rg --color ansi --vimgrep $@ | fzf --ansi --preview '~/.local/bin/preview.sh {}' | pyp 'z = x.split(":"); print(f"+{z[1]} -c \"normal {z[2]}|\" {shlex.quote(z[0])}")' | xargs -o vim
)

frgc() (
    set -o pipefail
    rg --color ansi --vimgrep $@ | fzf --ansi --preview '~/.local/bin/preview.sh {}' | pyp 'shlex.quote(":".join(x.split(":")[:3]))' | xargs -o code --goto
)

# ripgrep aliases
alias rg='rg -M 250 -S'     # limit max columns, use smart case
alias rgh='rg --hidden'     # search hidden files
alias rgs='rg --sort path'  # sort results by path, slower
alias rgc='rg -t c -t cpp'
alias rgp='rg -t py'
alias rgj='rg -t js -t ts'

# ==========
# Misc
# ==========

export EDITOR=vim
export PAGER=less
export LESS=-R              # deals with colours better

setopt correct_all          # adds corrections
setopt interactivecomments  # recognise comments
setopt multios              # something to do with redirection?
CORRECT_IGNORE_FILE='.*|*test*'  # ignore corrections for files matching these globs

function google() {
    if [[ $# -gt 0 ]]; then
        url="https://www.google.com/search?q=${(j:+:)@}"
    else
        url="https://www.google.com/"
    fi
    open "$url"
}

export PATH="${HOME}/.local/bin:${HOME}/.pyenv/bin:${PATH}"

# put machine specific things in zshrc_local
if [ -f "$HOME/.zshrc_local" ]; then
  source "$HOME/.zshrc_local"
fi

echo "$SECONDS seconds"
