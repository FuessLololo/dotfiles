#!/usr/bin/env bash
# Set up this machine from the dotfiles repo. Safe to re-run.
#
#   ./install.sh            # all steps
#   ./install.sh link tmux  # only some steps
#
# Steps: packages fonts link tmux kde system checklist
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(bash tmux vim nvim bin kde env)
# Directories that should be one symlink to the repo, not a folder of per-file links.
FOLD_DIRS=(.config/nvim)
PLASMA_TOKYO_NIGHT_REPO=https://github.com/Jayy-Dev/Plasma-Tokyo-Night.git
PLASMA_TOKYO_NIGHT_COMMIT=aed7e9faf9bc7ea6b6bbc8e21b5475bdda2412c7   # plasma-6 branch, 2026-11-07
NERD_FONT_URL=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" &>/dev/null; }

# ---------------------------------------------------------------- packages
step_packages() {
    # shellcheck source=/dev/null
    . /etc/os-release
    local common=(git curl unzip jq tmux stow neovim ripgrep fzf gcc make nodejs wl-clipboard fcitx5 fcitx5-mozc)
    case "$ID" in
        fedora)
            say "dnf install (Fedora)"
            sudo dnf install -y --skip-unavailable "${common[@]}" fd-find qt6-qtmultimedia
            # Separate: Fedora's build can lag libplasma and fail the whole transaction.
            sudo dnf install -y kcm-fcitx5 || warn "dnf: could not install kcm-fcitx5 (fcitx5-configtool works too)" ;;
        debian|ubuntu)
            say "apt install ($ID)"
            sudo apt-get update
            local p
            for p in "${common[@]}" fd-find kde-config-fcitx5 qml6-module-qtmultimedia; do
                sudo apt-get install -y "$p" || warn "apt: could not install $p"
            done ;;
        arch)
            say "pacman (Arch)"
            sudo pacman -S --needed --noconfirm "${common[@]}" fd fcitx5-configtool qt6-multimedia ;;
        *)
            warn "unknown distro '$ID': install these yourself: ${common[*]}" ;;
    esac
}

# ---------------------------------------------------------------- fonts
step_fonts() {
    local dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if fc-list : file | grep -q "$dir/JetBrainsMonoNerdFontMono-Regular.ttf"; then
        say "JetBrainsMono Nerd Font already installed"
        return
    fi
    say "downloading JetBrainsMono Nerd Font (v3)"
    local tmp; tmp="$(mktemp -d)"
    curl -fL --retry 3 -o "$tmp/JetBrainsMono.zip" "$NERD_FONT_URL"
    mkdir -p "$dir"
    unzip -o -q "$tmp/JetBrainsMono.zip" '*.ttf' -d "$dir"
    rm -rf "$tmp"
    fc-cache -f "$HOME/.local/share/fonts"
}

# ---------------------------------------------------------------- link
# Move a pre-existing real file/dir out of the way so stow can link it.
backup_if_real() {
    local target="$1"
    # Already ours (directly, or through a folded parent dir that stow linked)?
    case "$(realpath -m "$target")" in "$DOTFILES"/*) return ;; esac
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local bak
        bak="$target.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
        warn "backing up $target -> $bak"
        mv "$target" "$bak"
    fi
}

step_link() {
    have stow || { warn "stow not installed; run './install.sh packages' first"; return 1; }
    local d pkg rel
    for d in "${FOLD_DIRS[@]}"; do backup_if_real "$HOME/$d"; done
    for pkg in "${STOW_PACKAGES[@]}"; do
        while IFS= read -r rel; do
            rel="${rel#"$pkg"/}"
            backup_if_real "$HOME/$rel"
        done < <(cd "$DOTFILES" && find "$pkg" \( -type f -o -type l \) -not -path '*/.config/nvim/*')
    done
    # --no-folding: shared dirs like ~/.local/bin must stay real, or other tools write into the repo.
    local -a fold=() nofold=()
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$DOTFILES/$pkg/.config/nvim" ]; then fold+=("$pkg"); else nofold+=("$pkg"); fi
    done
    say "stow ${STOW_PACKAGES[*]}"
    stow --dir="$DOTFILES" --target="$HOME" --restow --no-folding "${nofold[@]}"
    [ ${#fold[@]} -eq 0 ] || stow --dir="$DOTFILES" --target="$HOME" --restow "${fold[@]}"
}

# ---------------------------------------------------------------- tmux
step_tmux() {
    local tpm="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm" ]; then
        say "installing tpm"
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
    fi
    say "installing tmux plugins"
    "$tpm/bin/install_plugins" >/dev/null
}

# ---------------------------------------------------------------- kde
find_libexec() {
    local f
    for f in /usr/libexec/"$1" /usr/lib/*/libexec/"$1"; do [ -x "$f" ] && { echo "$f"; return; }; done
}

step_kde() {
    have kwriteconfig6 || { warn "kwriteconfig6 not found; skipping KDE step (not on Plasma 6?)"; return; }
    local share="$HOME/.local/share"

    say "Plasma Tokyo Night (Jayy-Dev @ $PLASMA_TOKYO_NIGHT_COMMIT)"
    local tmp; tmp="$(mktemp -d)"
    git -C "$tmp" init -q
    git -C "$tmp" fetch -q --depth 1 "$PLASMA_TOKYO_NIGHT_REPO" "$PLASMA_TOKYO_NIGHT_COMMIT" \
        || git -C "$tmp" fetch -q --depth 1 "$PLASMA_TOKYO_NIGHT_REPO" plasma-6
    git -C "$tmp" checkout -q FETCH_HEAD
    mkdir -p "$share/color-schemes" "$share/plasma/desktoptheme" "$share/aurorae/themes"
    cp "$tmp/colorscheme/TokyoNight.colors" "$share/color-schemes/"
    rm -rf "$share/plasma/desktoptheme/Tokyo-Night" "$share/aurorae/themes/TokyoNight"
    cp -r "$tmp/plasma/desktoptheme/Tokyo-Night" "$share/plasma/desktoptheme/"
    cp -r "$tmp/aurorae/TokyoNight" "$share/aurorae/themes/"
    rm -rf "$tmp"

    plasma-apply-colorscheme TokyoNight || true
    plasma-apply-desktoptheme Tokyo-Night || true
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__TokyoNight
    local qdbus; qdbus="$(command -v qdbus6 || command -v qdbus-qt6 || true)"
    [ -n "$qdbus" ] && "$qdbus" org.kde.KWin /KWin reconfigure || true

    # Icons: Tokyo Night-SE comes from the KDE Store (see checklist); Breeze Dark until then.
    local changeicons icons=breeze-dark
    changeicons="$(find_libexec plasma-changeicons)"
    [ -d "$share/icons/TokyoNight-SE" ] && icons=TokyoNight-SE
    if [ -n "$changeicons" ]; then "$changeicons" "$icons"; else warn "plasma-changeicons not found"; fi

    say "Konsole default profile"
    kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Default.profile

    say "mouse wheel: 5 lines per step"
    kwriteconfig6 --file kdeglobals --group KDE --key WheelScrollLines 5
}

# ---------------------------------------------------------------- system (sudo)
step_system() {
    if [ -d /etc/sddm.conf.d ] || have sddm; then
        say "SDDM: disable the on-screen keyboard"
        sudo install -D -m 644 "$DOTFILES/system/sddm/10-no-virtual-keyboard.conf" /etc/sddm.conf.d/10-no-virtual-keyboard.conf
    fi
}

# ---------------------------------------------------------------- checklist
step_checklist() {
    cat <<'EOF'

Manual steps (GUI / KDE Store, not scriptable):
  [ ] System Settings > Keyboard > Virtual Keyboard: Fcitx 5
  [ ] System Settings > Input Method: Keyboard - English (US), then Mozc
        Mozc (gear): Vertical candidate list on, Expand Usage = On Focus
        Configure addons > Classic User Interface: Vertical Candidate List on
  [ ] Colors & Themes > Icons > Get New: "Tokyo Night Icons", select Tokyo Night-SE
  [ ] SDDM theme pixel-night-city into /usr/share/sddm/themes, select it in Login Screen (SDDM)
  [ ] Screen Locking > Appearance > Get New Plugins: "Smart Video Wallpaper Reborn",
        pick ~/Pictures/Wallpapers/<video>.mp4, keep it muted
  [ ] VS Code: Accounts > Backup and Sync Settings, choose "Replace Local"
  [ ] Machine-only shell settings and secrets: ~/.bashrc.local (template: extras/bashrc.local.example)
  [ ] Log out and back in (fonts, input method, environment.d)
EOF
}

# ---------------------------------------------------------------- main
ALL=(packages fonts link tmux kde system checklist)
steps=("$@"); [ ${#steps[@]} -eq 0 ] && steps=("${ALL[@]}")
for s in "${steps[@]}"; do
    declare -F "step_$s" >/dev/null || { warn "unknown step '$s' (valid: ${ALL[*]})"; exit 1; }
    "step_$s"
done
