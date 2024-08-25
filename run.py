#!/usr/bin/env python3
import argparse
import functools
import subprocess
import textwrap
from pathlib import Path
import sys


def blue_print(arg):
    print("\033[1;34m{}\033[0m".format(arg))


def pretty_name(fn):
    return " ".join(fn.__name__.split("_")).title()


def run(cmd, verbose=True):
    if verbose:
        blue_print(cmd)
    proc = subprocess.Popen(
        ["/bin/bash", "-c", cmd], bufsize=1, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        cwd=Path(__file__).parent, universal_newlines=True
    )
    while True:
        if verbose:
            out = proc.stdout.readline()
            print(textwrap.indent(out, "\t"), end="")
            if out:
                continue
        if proc.poll() is not None:
            break
    return proc.poll()


fns = []


def collect(fn):
    global fns
    fns.append(fn)
    return fn


def skip_if(cmd, should_fail=False, should_raise=False):
    def decorator(fn):
        @functools.wraps(fn)
        def inner(*args, **kwargs):
            returncode = run(cmd, verbose=False)
            command_failed = bool(returncode)
            if should_fail:
                command_failed = not command_failed
            if command_failed:
                fn(*args, **kwargs)
            elif should_raise:
                raise subprocess.CalledProcessError(returncode, cmd)
            else:
                blue_print("=" * 25)
                blue_print(f"Skipping installing {pretty_name(fn)}...")
                blue_print("=" * 25)
                print()
        return inner
    return decorator


skip_if_fail = functools.partial(skip_if, should_fail=True)
raise_if_fail = functools.partial(skip_if, should_fail=True, should_raise=True)


def sh(check=True):
    def decorator(fn):
        @functools.wraps(fn)
        def inner(*args, **kwargs):
            blue_print("=" * 25)
            blue_print(f"Installing {pretty_name(fn)}...")
            blue_print("=" * 25)
            print()
            if not ARGS.yes:
                print("Enter to continue (or type something to skip)... ", end="")
                if input():
                    print()
                    return
            lines = fn(*args, **kwargs).splitlines()
            for l in lines:
                cmd = l.strip()
                if not cmd:
                    continue
                returncode = run(cmd)
                if check and returncode:
                    print("\n")
                    raise subprocess.CalledProcessError(returncode, cmd)
            print()
        return inner
    return decorator


# ==========================
# The actual setup begins...
# ==========================


@collect
@sh()
def zsh():
    return """
    [[ ! -f ~/.zshrc ]] || diff zshrc ~/.zshrc
    cp zshrc ~/.zshrc

    printf 'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"\\n' > ~/.zshenv

    rm -rf ~/.zgen
    rm -rf ~/.zgenom
    git clone -b pinned https://github.com/hauntsaninja/zgenom.git ~/.zgenom
    touch ~/.z
    touch ~/.pypconf.py

    zsh -i -c ''

    [[ $SHELL = "$(which zsh)" ]] || chsh -s $(which zsh)
    """


@collect
@sh()
def vim():
    return """
    [[ ! -f ~/.vimrc ]] || diff vimrc ~/.vimrc
    cp vimrc ~/.vimrc
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    rm -rf ~/.vim/.swp
    mkdir ~/.vim/.swp
    """


@collect
@skip_if_fail("lsb_release")
@sh()
def ubuntu_stuff():
    return """
    mkdir -p ${HOME}/.local/bin
    git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf
    /tmp/fzf/install --bin
    mv /tmp/fzf/bin/fzf ${HOME}/.local/bin

    python3 -m pip install pypyp virtualenv
    """


@collect
@skip_if("which brew")
@sh()
def brew():
    return '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'


@collect
@skip_if_fail("which brew")
@sh()
def main_brew_stuff():
    return """
    brew reinstall node
    brew reinstall ripgrep  # code search
    brew reinstall fzf      # fuzzy finder
    brew reinstall pipx     # manage python apps in their own venvs
    brew reinstall htop     # view processes
    brew reinstall tree     # show a directory tree
    """


@collect
@skip_if_fail("which brew")
@sh()
def provisional_brew_stuff():
    return """
    brew reinstall fd         # like find but sometimes more convenient
    brew reinstall bat        # like cat with syntax highlighting
    brew reinstall tokei      # count lines in code
    brew reinstall hyperfine  # benchmarking
    brew reinstall dust       # like du + tree
    brew reinstall gh         # github cli
    brew reinstall fastmod    # fast codemod (i hate sed)
    brew reinstall watch      # repeatedly run a command
    brew reinstall prettier   # code formatter
    brew reinstall jq         # parse json
    """


@collect
@skip_if_fail("which brew")
@sh()
def brew_casks():
    return """
    brew install --cask hammerspoon  # automate your mac

    brew install --cask basictex

    brew install --cask firefox
    brew install --cask google-chrome

    brew install --cask spotify

    brew install --cask visual-studio-code

    # brew install --cask --no-quarantine qlmarkdown
    # brew install --cask --no-quarantine qlstephen
    # brew install --cask --no-quarantine syntax-highlight
    """


@collect
@skip_if_fail("which code")
@sh()
def vscode_extensions():
    return """
    cp vscode_settings.json ~/"Library/Application Support/Code/User/settings.json"

    code --install-extension akamud.vscode-theme-onedark
    code --install-extension akamud.vscode-theme-onelight
    code --install-extension bibhasdn.unique-lines
    code --install-extension eamodio.gitlens
    code --install-extension GitHub.copilot
    code --install-extension gurumukhi.selected-lines-count
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension rust-lang.rust-analyzer
    code --install-extension stkb.rewrap
    code --install-extension tomoki1207.pdf
    code --install-extension usernamehw.errorlens
    """


@collect
@skip_if_fail("brew list --cask | grep hammerspoon")
@sh()
def hammerspoon_config():
    return """
    [[ ! -f ~/.hammerspoon/init.lua ]] || diff hammerspoon.lua ~/.hammerspoon/init.lua
    rm -rf ~/.hammerspoon
    mkdir ~/.hammerspoon
    cp hammerspoon.lua ~/.hammerspoon/init.lua
    """


@collect
@skip_if("python -c 'import sys; assert sys.version_info >= (3, 11)' && python3 -c 'import sys; assert sys.version_info >= (3, 11)'")
@sh()
def python():
    return """
    source python_setup.sh && python_setup 3.12.5
    mkdir -p ~/.local/bin
    ln -sf ~/.pyenv/versions/3.12.5/bin/python ~/.local/bin/python
    ln -sf ~/.pyenv/versions/3.12.5/bin/python3 ~/.local/bin/python3
    """


@collect
@raise_if_fail("which uv || which pipx")
@sh()
def python_tools():
    return """
    which uv || pipx install uv

    # use python on the command line easily
    uv tool install pypyp

    # some extra git commands
    uv tool install git-revise
    uv tool install git-delete-merged-branches

    # python formatting
    uv tool install black
    uv tool install darker
    uv tool install isort

    # python linting
    uv tool install ruff
    uv tool install pylint
    uv tool install pyright

    # python packaging, testing, profiling
    uv tool install poetry
    uv tool install pyinstrument
    uv tool install tox
    uv tool install virtualenv
    uv tool install ipython
    uv tool install pre-commit
    """


@collect
@sh()
def rust():
    return """
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    """


@collect
@sh()
def misc():
    return """
    # used in an alias
    mkdir -p ~/.local/bin
    curl https://raw.githubusercontent.com/junegunn/fzf.vim/master/bin/preview.sh -o ~/.local/bin/preview.sh

    cp pypconf.py ~/.pypconf.py
    """


# TODO:
# pre-populate shell history
# terminal font
# terminal touch id, "auth sufficient pam_tid.so" to first line of "/etc/pam.d/sudo"
# git config (per-folder)
# wemo

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--yes", action="store_true", help="Don't ask, just do!")
    parser.add_argument("sections", nargs="*", help="Things to run")
    ARGS = parser.parse_args(sys.argv[1:])

    for fn in fns:
        if not ARGS.sections or any(x == fn.__name__.lower() for x in ARGS.sections):
            fn()
