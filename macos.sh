#!/usr/bin/env bash
set -euo pipefail

# Finder: show hidden dotfiles and all filename extensions
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Restart affected apps
killall Finder || true

echo "macOS defaults applied."
