#!/usr/bin/env bash
set -euo pipefail

# Finder: show hidden dotfiles by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Restart affected apps
killall Finder || true

echo "macOS defaults applied."
