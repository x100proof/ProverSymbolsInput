#!/usr/bin/env bash
# Add every Lean 4 (or Agda) abbreviation to Math Symbols Input as a custom
# command, and bind Ctrl+Option+Cmd+L to a searchable shortcut viewer.
#
#   ./install.sh            Lean 4: use the bundled abbreviations.json
#   ./install.sh --agda     Agda: use the bundled abbreviations-agda.json
#   --update                fetch the latest table first (vscode-lean4 / agda-mode-vscode)
#
# Switching between Lean and Agda removes the other table's commands; custom
# commands you added yourself are kept.
set -euo pipefail

LANG_NAME=Lean
UPDATE=
for arg in "$@"; do
  case "$arg" in
    --agda) LANG_NAME=Agda ;;
    --lean) LANG_NAME=Lean ;;
    --update) UPDATE=1 ;;
    *) echo "usage: $0 [--agda] [--update]" >&2; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "$0")" && pwd)"
DOMAIN=com.mathsymbolsinput.inputmethod.MathSymbolsInput
IM_APP="/Library/Input Methods/Math Symbols Input.app"
PKG_URL=https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
LEAN_URL=https://raw.githubusercontent.com/leanprover/vscode-lean4/master/lean4-unicode-input/src/abbreviations.json
AGDA_URL=https://raw.githubusercontent.com/banacorn/agda-mode-vscode/master/asset/keymap.js
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

mkdir -p "$SUPPORT"
if [ "$LANG_NAME" = Agda ]; then
  ABBREV="$HERE/abbreviations-agda.json"; URL="$AGDA_URL"; FETCHED="$SUPPORT/agda-keymap.js"
else
  ABBREV="$HERE/abbreviations.json"; URL="$LEAN_URL"; FETCHED="$SUPPORT/abbreviations.json"
fi

# 2. Abbreviations -> CustomCommands (+ backup), and the viewer page
if [ -n "$UPDATE" ]; then
  echo "==> Fetching latest $LANG_NAME abbreviations"
  curl -fsSL -o "$FETCHED" "$URL"
  ABBREV="$FETCHED"
fi
backup="$SUPPORT/prefs-backup-$(date +%Y%m%d-%H%M%S).plist"
defaults export "$DOMAIN" "$backup" 2>/dev/null && echo "==> Backed up preferences to $backup" || true
# Every table we may have installed before, so its commands can be cleared out.
REPLACE=()
for t in "$HERE/abbreviations.json" "$HERE/abbreviations-agda.json" \
         "$SUPPORT/abbreviations.json" "$SUPPORT/agda-keymap.js"; do
  [ -f "$t" ] && REPLACE+=(--replace "$t")
done
echo "==> Installing $LANG_NAME commands"
/usr/bin/python3 -I "$HERE/build.py" --title "$LANG_NAME" "${REPLACE[@]}" \
  "$ABBREV" "$HERE/viewer.html" "$SUPPORT/shortcuts.html"

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
