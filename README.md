# Dotfiles

Managed with [mise](https://mise.jdx.dev/dotfiles.html) (`mise dotfiles` + `mise bootstrap`).

## Bootstrap

Install [Homebrew](https://brew.sh/) and [mise](https://mise.jdx.dev/getting-started.html), then run:

```sh
mise bootstrap --from git@github.com:danielyaren/dotfiles.git --from-dir ~/dotfiles --config-dir .config/mise
killall Finder || true
```

## Updating

* **Full sync / bootstrap:** `mise bootstrap` (or `mise bootstrap --dry-run` to preview)
* **Dotfiles symlinks:** `mise dot apply` / `mise dot status`
* **Tools & runtimes:** update pinned versions in `.config/mise/config.toml`, then run `mise install`
* **Homebrew casks:** `mise bootstrap packages upgrade`
* **macOS defaults:** `mise bootstrap macos defaults apply && killall Finder || true`
* **Zsh plugins:** `sheldon lock --update`
* **Machine-local overrides / secrets:** put them in `~/.zshrc.local` (not tracked in git).
