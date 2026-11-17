#!/usr/bin/env bash
# Add every Lean 4 abbreviation to Math Symbols Input as a custom command, and
# bind Ctrl+Option+Cmd+L to a searchable shortcut viewer.
#
#   ./install.sh            use the bundled abbreviations.json
#   ./install.sh --update   fetch the latest table from vscode-lean4 first
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DOMAIN=com.mathsymbolsinput.inputmethod.MathSymbolsInput
IM_APP="/Library/Input Methods/Math Symbols Input.app"
PKG_URL=https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
ABBREV_URL=https://raw.githubusercontent.com/leanprover/vscode-lean4/master/lean4-unicode-input/src/abbreviations.json
SUPPORT="$HOME/Library/Application Support/LeanSymbolsInput"
SERVICE_NAME="Open Lean Shortcuts"
HOTKEY='^~@l'   # ^ Ctrl, ~ Option, @ Cmd

# 1. Input method must already be installed
if [ ! -d "$IM_APP" ]; then
  echo "Math Symbols Input is not installed. Download and install it first:" >&2
  echo "  $PKG_URL" >&2
  echo "Then log out and back in, and re-run this script." >&2
  exit 1
fi

ABBREV="$HERE/abbreviations.json"
mkdir -p "$SUPPORT"

# 2. Lean abbreviations -> CustomCommands (+ backup), and the viewer page
if [ "${1:-}" = "--update" ]; then
  echo "==> Fetching latest Lean abbreviations"
  curl -fsSL -o "$SUPPORT/abbreviations.json" "$ABBREV_URL"
  ABBREV="$SUPPORT/abbreviations.json"
fi
backup="$SUPPORT/prefs-backup-$(date +%Y%m%d-%H%M%S).plist"
defaults export "$DOMAIN" "$backup" 2>/dev/null && echo "==> Backed up preferences to $backup" || true
echo "==> Installing Lean commands"
/usr/bin/python3 -I "$HERE/build.py" "$ABBREV" "$HERE/viewer.html" "$SUPPORT/shortcuts.html"

# 3. Quick Action + hotkey
echo "==> Installing \"$SERVICE_NAME\" Quick Action on Ctrl+Option+Cmd+L"
mkdir -p "$HOME/Library/Services"
ditto "$HERE/$SERVICE_NAME.workflow" "$HOME/Library/Services/$SERVICE_NAME.workflow"
defaults write pbs NSServicesStatus -dict-add \
  "\"(null) - $SERVICE_NAME - runWorkflowAsService\"" \
  "{ \"key_equivalent\" = \"$HOTKEY\"; \"enabled_context_menu\" = 1; \"enabled_services_menu\" = 1; }"
/System/Library/CoreServices/pbs -flush
/System/Library/CoreServices/pbs -update

# 4. Reload the input method so it picks up the new commands
pkill -f "Math Symbols Input.app/Contents/MacOS" 2>/dev/null || true

echo
echo "Done."
echo "If Ctrl+Option+Cmd+L does nothing, check System Settings > Keyboard >"
echo "Keyboard Shortcuts > Services > General > \"$SERVICE_NAME\"."
