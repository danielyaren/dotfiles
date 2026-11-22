# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap on a new Mac

```sh
git clone git@github.com:danielyaren/dotfiles.git ~/dotfiles
cd ~/dotfiles
brew bundle
stow zsh starship scripts
./macos.sh

# Emacs config (separate repo)
git clone --recurse-submodules git@github.com:danielyaren/emacs.d.git ~/.emacs.d
```

## Updating

* **CLI tools:** `brew bundle`
* **Zsh plugins:** `sheldon lock --update`
* **Re-apply symlinks:** `cd ~/dotfiles && stow -R zsh starship`
* **Machine-local overrides / secrets:** put them in `~/.zshrc.local` (not tracked in git).
