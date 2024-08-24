#!/bin/zsh

typeset -F 3 SECONDS=0

autoload -U compinit
compinit -i -C

# load zgenom
source "${HOME}/.zgenom/zgenom.zsh"

function file_mtime() {
  local cmd
  case "$OSTYPE" in
    darwin*)  stat -f '%m' $1 ;;
    linux*)   date +%s -r $1 ;;
  esac
}

# automatically update things every now and then
if zgenom saved &&
    [[ $(( $(date +%s) - $(file_mtime ~/.zgenom/sources/init.zsh) )) -gt 1000000 ]] &&
    [ -z "$KUBERNETES_SERVICE_HOST" ];
then
    touch ~/.zgenom/sources/init.zsh
    { brew update; brew upgrade; brew cleanup; } &
    pipx upgrade-all &
    uv tool upgrade --all &
    zgenom selfupdate; zgenom update;
fi

# if the init scipt doesn't exist
if ! zgenom saved; then

    # the gist has a couple things scavenged from ohmyzsh
    zgenom load https://gist.github.com/528dc0693e8dfacdfdc0cef6bd7f844b.git
    # git aliases
    zgenom load hauntsaninja/my_git_aliases

    # fzf for everything
    zgenom load junegunn/fzf shell f97d2754134607b24849fc4a2062dbfcaafddd6a
    zgenom load Aloxaf/fzf-tab . bf3ef5588af6d3bf7cc60f2ad2c1c95bca216241

    zgenom load docker/cli contrib/completion/zsh 78012b0ee587e49f4313051e414fe1acecf2ab12

    # use z to cd to recently used directories
    zgenom load rupa/z . d37a763a6a30e1b32766fecc3b8ffd6127f8a0fd
    # suggest use of defined aliases
    zgenom load djui/alias-tips . 41cb143ccc3b8cc444bf20257276cb43275f65c4
    # cd upwards in the directory tree
    zgenom load shannonmoeller/up . a1fe10fababd58567880380938fdae6d6b9d5bdf

    # nice, but can't group notifs, bug in removing failure notifs, bad default titles
    # zgenom load marzocchi/zsh-notify

    zgenom load MichaelAquilina/zsh-autoswitch-virtualenv . f8dffe5bce18ea4b6817e39f252f628a43b03712

    # provide suggestions as you type
    zgenom load zsh-users/zsh-autosuggestions . c3d4e576c9c86eac62884bd47c01f6faed043fc5

    # order matters for the next two...
    # ...syntax highlighting should be last
    zgenom load zsh-users/zsh-syntax-highlighting . e0165eaa730dd0fa321a6a6de74f092fe87630b0
    # press up and down to fuzzy search history for your partial command
    # ...except for history substring search
    zgenom load zsh-users/zsh-history-substring-search . 8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64

    # generate the init script from plugins above
    zgenom save
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

function r() {
    local dir="$PWD"
    while [[ "$dir" != "" && ! -e "$dir/.git" ]]; do
        dir="${dir%/*}"
    done
    cd "${dir:-$HOME}"
}

function rc() {
    local dir="$PWD"
    while [[ "$dir" != "" && ! -e "$dir/.git" ]]; do
        dir="${dir%/*}"
    done
    code "${dir:-$HOME}"
}

# fuzzy z
fz() {
    cd $(z | pyp 'x.split()[1]' | fzf --tac $([[ -z "$1" ]] && echo "" || echo "--query $@") || pwd)
}

# ==========
# History
# ==========

HISTFILE="$HOME/.zsh_history"
HISTSIZE=80000
SAVEHIST=40000

setopt extended_history        # record timestamp of command in HISTFILE
setopt hist_expire_dups_first  # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups        # ignore duplicated commands in history list
setopt hist_ignore_space       # don't add commands that start with space to history
setopt hist_verify             # show command with history expansion before running it
setopt share_history           # share history between shells

# full screen fuzzy history search bound to ctrl-r
_fhist () {
    [ -n "$BUFFER" ] && BUFFER="${BUFFER%% ##} "
    LINE="$(history 0 | fzf -q "$BUFFER" --tac --tiebreak=index | pyp 'x.lstrip().split(maxsplit=1)[1]')"

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
PROMPT="$([ -n "$SSH_CLIENT" ] || [ -n "$KUBERNETES_SERVICE_HOST" ] && echo '%F{blue}%n@%m:%f')$([ -n "$STY" ] && echo '%F{blue}screen:%f')%F{cyan}%-50<..<%~%f%F{8} \$(_git_current_branch)%fλ "

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

rgi() (
  key="$1"
  shift
  literal_key=$(python -c "import re, itertools; print(''.join(chr(c) for _, c in max((list(g) for k, g in itertools.groupby(re._parser.parse('$key'), key=lambda x: x[0]) if k == re._constants.LITERAL), key=len)))")
  mdfind -literal "kMDItemTextContent == \"*$literal_key*\"" -onlyin . | xargs rg "$key" "$@"
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

export REPORTTIME=1         # print time taken if longer than 1s
export EDITOR=vim
export PAGER=less
export LESS=-R              # deals with colours better

setopt correct_all          # adds corrections
setopt interactivecomments  # recognise comments
setopt multios              # something to do with redirection?
CORRECT_IGNORE_FILE='.*|*test*'  # ignore corrections for files matching these globs

export PYP_CONFIG_PATH="${HOME}/.pypconf.py"

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
