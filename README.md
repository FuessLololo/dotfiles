# dotfiles

Shared config for my Linux machines (KDE Plasma 6 on Wayland). Each top-level folder is a
[GNU Stow](https://www.gnu.org/software/stow/) package mirrored into `$HOME`, so the repo files
are the live files.

| Package | Contents |
|---|---|
| `bash` | `.bashrc` (machine-only bits go in untracked `~/.bashrc.local`) |
| `tmux` | `.tmux.conf` (powerkit tokyo-night, wl-copy, tpm) |
| `nvim` | LazyVim config |
| `vim` | `.vimrc` |
| `bin` | small scripts in `~/.local/bin` |
| `kde` | Konsole profile + Tokyo Night colour scheme |
| `env` | `environment.d` (Fcitx 5 for X11 apps) |
| `system/` | files for `/etc` (installed with sudo, not stowed) |
| `extras/` | references, not installed |

## Setup

```bash
git clone git@github.com:FuessLololo/dotfiles.git ~/Documents/mine/dotfiles
cd ~/Documents/mine/dotfiles
./install.sh                 # packages fonts link tmux kde system checklist
./install.sh link tmux       # e.g. a machine whose packages are managed elsewhere
```

Existing files that would be replaced are moved to `*.pre-dotfiles.<timestamp>`.
The script ends with a checklist of GUI-only steps (Fcitx 5, KDE Store items, SDDM theme).

KDE rewrites its own config (`kdeglobals`, `kwinrc`, `konsolerc`), so those are *applied* by
`install.sh` with `plasma-apply-*` / `kwriteconfig6`, never symlinked.
