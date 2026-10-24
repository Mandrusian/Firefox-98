#!/usr/bin/env bash
# install.sh - Firefox-98 theme installer
# Detects Firefox profile, copies theme files, sets required preference.
# Requires: dialog or whiptail. Restart Firefox after installation.

set -euo pipefail

TUI=$(command -v dialog || command -v whiptail || true)
if [[ -z "$TUI" ]]; then
    echo "Error: dialog or whiptail is required." >&2
    echo "Void Linux: sudo xbps-install dialog" >&2
    exit 1
fi

info() { "$TUI" --title "Firefox-98 Installer" --msgbox "$1" "${2:-10}" "${3:-64}"; }
confirm() { "$TUI" --title "Confirm" --yesno "$1" "${2:-7}" "${3:-50}"; }
err() { "$TUI" --title "Error" --msgbox "$1" 8 60; exit 1; }

find_firefox_profile() {
    local candidates=(
        "$HOME/.mozilla/firefox"/*.default*
        "$HOME/.mozilla/firefox"/*.default-release*
        "$HOME/snap/firefox/common/.mozilla/firefox"/*.default*
        "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"/*.default*
    )
    for dir in "${candidates[@]}"; do
        [[ -d "$dir" && -f "$dir/prefs.js" ]] && { echo "$dir"; return 0; }
    done
    return 1
}

# Source files are in the repository's chrome/ subdirectory.
SRC_DIR="chrome"
THEME_FILES=("userChrome.css" "userContent.css")

info "Firefox-98 theme installer.

This script will:
1. Locate your Firefox profile directory.
2. Copy theme files into the profile's 'chrome' folder.
3. Set toolkit.legacyUserProfileCustomizations.stylesheets=true.

Firefox must be restarted after installation."

PROFILE_DIR=$(find_firefox_profile) || err "Could not find a Firefox profile.
Launch Firefox at least once, then rerun this script."

info "Profile directory:
$PROFILE_DIR"

confirm "Proceed with installation?" || exit 0

CHROME_DIR="$PROFILE_DIR/chrome"
mkdir -p "$CHROME_DIR"

for f in "${THEME_FILES[@]}"; do
    [[ -f "$SRC_DIR/$f" ]] || err "Required file not found: $SRC_DIR/$f"
    cp "$SRC_DIR/$f" "$CHROME_DIR/"
done

PREFS_OUT="$PROFILE_DIR/user.js"
PREF_LINE='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if ! grep -qF "$PREF_LINE" "$PREFS_OUT" 2>/dev/null; then
    echo "$PREF_LINE" >> "$PREFS_OUT"
fi

info "Installation complete.

Restart Firefox, then clear the startup cache:
about:support > Clear startup cache" 10 64

clear
