#!/usr/bin/env bash
# Reaplica defaults do macOS que costumam resetar após atualizações.
# Roda automaticamente a cada `chezmoi apply`.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

osascript -e 'tell application "System Settings" to quit'    >/dev/null 2>&1 || true
osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1 || true

# ─── Teclado ────────────────────────────────────────────────────────────────
defaults write NSGlobalDomain ApplePressAndHoldEnabled        -bool  false
defaults write NSGlobalDomain KeyRepeat                       -int   2
defaults write NSGlobalDomain InitialKeyRepeat                -int   15
defaults write NSGlobalDomain AppleKeyboardUIMode             -int   3

# ─── Autocorreção ───────────────────────────────────────────────────────────
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled    -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled  -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ─── Painéis Save / Print ───────────────────────────────────────────────────
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode  -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint     -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2    -bool true

# ─── Finder ─────────────────────────────────────────────────────────────────
defaults write NSGlobalDomain       AppleShowAllExtensions      -bool   true
defaults write com.apple.finder     AppleShowAllFiles            -bool   true
defaults write com.apple.finder     ShowStatusBar                -bool   true
defaults write com.apple.finder     ShowPathbar                  -bool   true
defaults write com.apple.finder     FXPreferredViewStyle         -string Nlsv
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool  true

# ─── Dock ───────────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide     -bool  true
defaults write com.apple.dock show-recents -bool  false
defaults write com.apple.dock tilesize     -int   48
defaults delete com.apple.dock persistent-apps   2>/dev/null || true
defaults delete com.apple.dock persistent-others 2>/dev/null || true

# ─── Screenshots ────────────────────────────────────────────────────────────
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# ─── Reinicia processos afetados ────────────────────────────────────────────
killall Finder Dock SystemUIServer >/dev/null 2>&1 || true
