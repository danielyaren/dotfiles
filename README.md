# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap on a new Mac

```sh
git clone https://github.com/danielyaren/dotfiles.git ~/dotfiles
cd ~/dotfiles
brew bundle
stow zsh starship scripts
./macos.sh
```

## Updating

* **CLI tools:** `brew bundle`
* **Zsh plugins:** `sheldon lock --update`
* **Re-apply symlinks:** `cd ~/dotfiles && stow -R zsh starship`
* **Machine-local overrides / secrets:** put them in `~/.zshrc.local` (not tracked in git).
