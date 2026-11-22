# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap on a new Mac

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
brew bundle
stow zsh starship
./macos.sh
```

## Updating

* **CLI tools:** `brew bundle`
* **Zsh plugins:** `sheldon lock --update`
* **Re-apply symlinks:** `cd ~/dotfiles && stow -R zsh starship`
* **Machine-local overrides / secrets:** put them in `~/.zshrc.local` (not tracked in git).
