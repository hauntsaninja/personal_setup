#!/usr/bin/env sh

print_bold_red() {
    set +x
    printf '\n'>&2
    printf '\033[1;31m%s\033[0m\n' "$1">&2
    printf '\n'>&2
}

print_bold_green() {
    printf '\033[1;32m%s\033[0m\n' "$1"
}

canonicalize_arch() {
    INPUT_ARCH="$1"
    case "$INPUT_ARCH" in
        "aarch64") printf "arm64";;
        "arm64") printf "arm64";;
        "i386") printf "x86_64";;
        "x86_64") printf "x86_64";;
        *)
            print_bold_red "ERROR: Unknown architecture: $INPUT_ARCH"
            return 1
        ;;
    esac
}

python_setup() (
    # To use, do something like:
    # ```
    # source python_setup.sh
    # python_setup 3.11.7 arm64
    # ```
    # Note that this uses pyenv as a convenient way to build and house the Pythons, but doesn't
    # actually really use or install pyenv. You can just use the binaries in e.g.
    # ~/.pyenv/versions/3.12.2/bin/python like normal without thinking about pyenv at all.
    set -eux

    PYTHON_VERSION="${1:-3.11.7}"
    ARCH_EXPECTED="${2:-$(canonicalize_arch $(arch))}"

    # TODO: look into something like https://github.com/AdrianDAlessandro/pyenv-suffix
    # to have Python version on both architectures
    print_bold_green "Setting up Python ${PYTHON_VERSION} for ${ARCH_EXPECTED}"

    BREW_ROOT_X86=/usr/local
    BREW_ROOT_ARM=/opt/homebrew
    case "$ARCH_EXPECTED" in
        "arm64") BREW_ROOT="$BREW_ROOT_ARM";;
        "x86_64") BREW_ROOT="$BREW_ROOT_X86";;
        *)
            print_bold_red "ERROR: Unexpected architecture: $ARCH_EXPECTED"
            return 1
        ;;
    esac
    BREW="$BREW_ROOT/bin/brew"

    PYENV_ROOT="$HOME/.pyenv"
    PYENV="$PYENV_ROOT/bin/pyenv"

    if [ $(canonicalize_arch $(arch)) != "${ARCH_EXPECTED}" ]; then
        print_bold_red "ERROR: expected arch ${ARCH_EXPECTED}, but running $(arch). \
Create a shell with arch -${ARCH_EXPECTED} zsh and try again \
(once the binary is built you should never need to do that again)."
        return 1
    fi

    # ------------------------------
    print_bold_green 'Step 1: dependencies for python'
    # ------------------------------
    if [ "$(uname)" = "Darwin" ]; then
        if ! xcode-select -p > /dev/null; then
            print_bold_red "ERROR: run 'xcode-select --install'"
            return 1
        fi
        if ! gcc --help > /dev/null; then
            print_bold_red "ERROR: run 'xcode-select --install'"
            return 1
        fi
        if [ ! -x "$BREW" ]; then
            print_bold_red "ERROR: could not find ${ARCH_EXPECTED} brew installation"
            return 1
        fi
        $BREW install openssl readline sqlite3 xz zlib ncurses
    elif [ "$(uname)" = "Linux" ]; then
        apt-get update
        apt-get install -y --no-install-recommends \
            build-essential \
            gdb \
            lcov \
            libbz2-dev \
            libffi-dev \
            libgdbm-dev \
            liblzma-dev \
            libncurses5-dev \
            libreadline6-dev \
            libsqlite3-dev \
            libssl-dev \
            lzma \
            lzma-dev \
            tk-dev \
            uuid-dev \
            zlib1g-dev
    fi

    # ------------------------------
    print_bold_green 'Step 2: get pyenv'
    # ------------------------------
    if [ ! -d "$PYENV_ROOT" ]; then
        git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
    else
        # if pyenv doesn't have the python version we want, update it
        if ! "$PYENV" install -l | grep -E "^\s*$PYTHON_VERSION$" > /dev/null; then
            if git -C "$PYENV_ROOT" rev-parse > /dev/null; then
                git -C "$PYENV_ROOT" pull
            else
                print_bold_red "ERROR: $PYENV_ROOT is a) out of date, b) not a git repo so couldn't be updated automatically. Consider deleting it and retrying"
                return 1
            fi
        fi
    fi

    # ------------------------------
    print_bold_green 'Step 3: install python!'
    # ------------------------------

    # make sure that pyenv picks up the correct brew installation
    eval "$($BREW shellenv)"

    # PGO and LTO are worth like 30+% speedup
    export PYTHON_CONFIGURE_OPTS='--enable-optimizations --with-lto --disable-shared'
    export PROFILE_TASK='-m test.regrtest --pgo -j0'
    export PYTHON_CFLAGS='-march=native -mtune=native'

    # installs python 3.11.x to $(pyenv root)/versions/3.11.x/bin/python
    $PYENV install --skip-existing $PYTHON_VERSION
    # tells pyenv's shims to default to the python we just installed
    $PYENV global | head -n 1 | grep -q $PYTHON_VERSION || $PYENV global $PYTHON_VERSION

    # ------------------------------
    print_bold_green 'Step 4: check python installation'
    # ------------------------------
    if [ ! -x "$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python" ]; then
        print_bold_red 'ERROR: pyenv failed to install Python'
        return 1
    fi
    if ! "$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python" -c 'import hashlib; import lzma; import ssl'; then
        print_bold_red "ERROR: pyenv failed to correctly build Python, check the log to diagnose. Maybe uninstall libb2 and gettext, run rm -rf $PYENV_ROOT/versions/$PYTHON_VERSION and try again?"
        return 1
    fi
    if ! "$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python" -c '
import sysconfig
assert sysconfig.get_config_var("Py_DEBUG") == 0
assert sysconfig.get_config_var("Py_ENABLE_SHARED") == 0
assert "--enable-optimizations" in sysconfig.get_config_var("CONFIG_ARGS")
assert "--with-lto" in sysconfig.get_config_var("CONFIG_ARGS")
'; then
        print_bold_red "ERROR: pyenv failed to correctly propagate configuration when building Python"
        return 1
    fi
    if ! "$SHELL" --login -c "
        eval \"\$($PYENV init --path)\"
        python --version | grep -q $PYTHON_VERSION
    "; then
        print_bold_red 'ERROR: pyenv setup failed'
        return 1
    fi
    if [ $(canonicalize_arch "$("$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python" -c 'import platform; print(platform.machine())')") != "${ARCH_EXPECTED}" ]; then
        print_bold_red "ERROR: Python is not running under ${ARCH_EXPECTED}"
        return 1
    fi
)
