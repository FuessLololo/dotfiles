# shellcheck shell=bash disable=SC1090,SC1091
# ~/.bashrc — shared across machines (managed by dotfiles, linked with stow).
# Machine-specific settings and secrets go in ~/.bashrc.local (never committed).

# Only for interactive shells.
case $- in
    *i*) ;;
      *) return;;
esac

# Start inside tmux only in Konsole (VS Code inherits KONSOLE_VERSION when launched from it).
# if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -n "$KONSOLE_VERSION" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
#     tmux attach-session -t default || tmux new-session -s default
# fi

# ---------------- history ----------------
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000000
HISTFILESIZE=200000
shopt -s checkwinsize

# ---------------- completion ----------------
if ! shopt -oq posix; then
    for f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        [ -f "$f" ] && { . "$f"; break; }
    done
fi

# __git_ps1 for the prompt: Debian ships it via bash-completion, Fedora in git-core.
if ! declare -F __git_ps1 >/dev/null; then
    for f in /usr/share/git-core/contrib/completion/git-prompt.sh /usr/lib/git-core/git-sh-prompt; do
        [ -f "$f" ] && { . "$f"; break; }
    done
fi
declare -F __git_ps1 >/dev/null || __git_ps1() { :; }

# ---------------- prompt ----------------
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1) \$ '
case "$TERM" in
    xterm*|rxvt*|tmux*|screen*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
esac

# ---------------- colors ----------------
if command -v dircolors &>/dev/null; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
alias ll='ls -alF'
alias la='ls -A'

# ---------------- PATH ----------------
path_prepend() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.local/share/nvim/mason/bin"
path_prepend "$HOME/go/bin"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH

# ---------------- tools ----------------
export EDITOR=vim
export LESS="-FRX --mouse --wheel-lines=3"

alias docker-compose="docker compose"
alias git-branch='git branch --sort=-committerdate | less -Ri'
gd()   { git diff "$@" | less -Ri; }
gds()  { git diff --staged "$@" | less -Ri; }
cdcd() { mkdir -p "$1" && cd "$1" || return; }

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# ---------------- machine-local ----------------
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
