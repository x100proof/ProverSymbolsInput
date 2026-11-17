#!/usr/bin/env bash
# Add every Lean 4 (or Agda) abbreviation to Math Symbols Input as a custom
# command, and bind a keyboard shortcut (default Ctrl+Option+Cmd+L) to a
# searchable shortcut viewer.
#
#   ./install.sh                 Lean 4 (the default): use the bundled abbreviations.json
#   ./install.sh --lean4         the same, explicitly
#   ./install.sh --agda          Agda: use the bundled abbreviations-agda.json
#   --update                     fetch the latest table first (vscode-lean4 / agda-mode-vscode)
#   --shortcut "Cmd+Shift+L"     key that opens the viewer; remembered for later runs
#
# Shortcut vocabulary (as in VS Code keybindings and Electron accelerators):
# modifiers and one key joined by "+", any order, any case.
#   Cmd | Command | Meta | Super | CmdOrCtrl | ⌘     Ctrl | Control | ⌃
#   Opt | Option | Alt | ⌥                          Shift | ⇧
#   Key: a letter, digit, or one of  ` - = [ ] \ ; ' , . /
#   At least one of Cmd, Ctrl or Option is required.
#
# Switching between Lean and Agda removes the other table's commands; custom
# commands you added yourself are kept.
set -euo pipefail

USAGE="usage: $0 [--lean4 | --agda] [--update] [--shortcut \"Ctrl+Option+Cmd+L\"]"
DEFAULT_SHORTCUT="Ctrl+Option+Cmd+L"

# parse_shortcut "Cmd+Ctrl+Shift+L" sets HOTKEY (macOS key-equivalent string,
# e.g. "^$@l") and HOTKEY_LABEL (e.g. "⌃⇧⌘L"), or fails with a message.
parse_shortcut() {
  local spec="$1" part lower ctrl= opt= shift= cmd= key= rest
  rest="$spec+"
  while [ -n "$rest" ]; do
    part="${rest%%+*}"; rest="${rest#*+}"
    part="$(printf %s "$part" | tr -d '[:space:]')"
    [ -n "$part" ] || { echo "Shortcut \"$spec\": empty part (use e.g. \"Cmd+Shift+L\")" >&2; return 1; }
    lower="$(printf %s "$part" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      cmd|command|meta|super|cmdorctrl|commandorcontrol|⌘) cmd=1 ;;
      ctrl|control|⌃) ctrl=1 ;;
      opt|option|alt|⌥) opt=1 ;;
      shift|⇧) shift=1 ;;
      *)
        [ -z "$key" ] || { echo "Shortcut \"$spec\": more than one key (\"$key\" and \"$part\")" >&2; return 1; }
        case "$lower" in
          [a-z0-9]|'`'|-|=|'['|']'|'\'|';'|"'"|,|.|/) key="$lower" ;;
          *) echo "Shortcut \"$spec\": unknown key or modifier \"$part\"" >&2; return 1 ;;
        esac ;;
    esac
  done
  [ -n "$key" ] || { echo "Shortcut \"$spec\": no key given" >&2; return 1; }
  [ -n "$cmd$ctrl$opt" ] || { echo "Shortcut \"$spec\": needs Cmd, Ctrl or Option" >&2; return 1; }
  HOTKEY="${ctrl:+^}${opt:+~}${shift:+\$}${cmd:+@}$key"
  HOTKEY_LABEL="${ctrl:+⌃}${opt:+⌥}${shift:+⇧}${cmd:+⌘}$(printf %s "$key" | tr '[:lower:]' '[:upper:]')"
}

LANG_NAME=Lean
UPDATE=
SHORTCUT=
while [ $# -gt 0 ]; do
  case "$1" in
    --agda) LANG_NAME=Agda ;;
    --lean4|--lean) LANG_NAME=Lean ;;
    --update) UPDATE=1 ;;
    --shortcut=*) SHORTCUT="${1#--shortcut=}" ;;
    --shortcut) [ $# -ge 2 ] || { echo "$USAGE" >&2; exit 2; }; SHORTCUT="$2"; shift ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    *) echo "$USAGE" >&2; exit 2 ;;
  esac
  shift
done

HERE="$(cd "$(dirname "$0")" && pwd)"
DOMAIN=com.mathsymbolsinput.inputmethod.MathSymbolsInput
IM_APP="/Library/Input Methods/Math Symbols Input.app"
PKG_URL=https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
LEAN_URL=https://raw.githubusercontent.com/leanprover/vscode-lean4/master/lean4-unicode-input/src/abbreviations.json
AGDA_URL=https://raw.githubusercontent.com/banacorn/agda-mode-vscode/master/asset/keymap.js
SUPPORT="$HOME/Library/Application Support/ProverSymbolsInput"
SERVICE_NAME="Open Symbol Shortcuts"
OLD_SUPPORT="$HOME/Library/Application Support/LeanSymbolsInput"   # before the rename
OLD_SERVICE_NAME="Open Lean Shortcuts"
SHORTCUT_FILE="$SUPPORT/shortcut"   # the last --shortcut given, reused by later runs

# 1. Input method must already be installed
if [ ! -d "$IM_APP" ]; then
  echo "Math Symbols Input is not installed. Download and install it first:" >&2
  echo "  $PKG_URL" >&2
  echo "Then log out and back in, and re-run this script." >&2
  exit 1
fi

# Carry backups and fetched tables over from the pre-rename folder.
if [ -d "$OLD_SUPPORT" ] && [ ! -e "$SUPPORT" ]; then
  mv "$OLD_SUPPORT" "$SUPPORT" && echo "==> Moved $OLD_SUPPORT to $SUPPORT"
fi
mkdir -p "$SUPPORT"

# Shortcut: --shortcut, else the one saved by an earlier run, else the default.
if [ -z "$SHORTCUT" ] && [ -s "$SHORTCUT_FILE" ]; then
  SHORTCUT="$(cat "$SHORTCUT_FILE")"
fi
parse_shortcut "${SHORTCUT:-$DEFAULT_SHORTCUT}" || exit 2
printf '%s\n' "${SHORTCUT:-$DEFAULT_SHORTCUT}" > "$SHORTCUT_FILE"

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
echo "==> Installing \"$SERVICE_NAME\" Quick Action on $HOTKEY_LABEL"
mkdir -p "$HOME/Library/Services"
if [ -d "$HOME/Library/Services/$OLD_SERVICE_NAME.workflow" ]; then
  echo "==> Removing old \"$OLD_SERVICE_NAME\" Quick Action"
  rm -rf "$HOME/Library/Services/$OLD_SERVICE_NAME.workflow"
  defaults export pbs - | /usr/bin/python3 -I -c '
import plistlib, sys
p = plistlib.loads(sys.stdin.buffer.read())
p.get("NSServicesStatus", {}).pop("(null) - " + sys.argv[1] + " - runWorkflowAsService", None)
sys.stdout.buffer.write(plistlib.dumps(p))' "$OLD_SERVICE_NAME" | defaults import pbs -
fi
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
echo "If $HOTKEY_LABEL does nothing, check System Settings > Keyboard >"
echo "Keyboard Shortcuts > Services > General > \"$SERVICE_NAME\"."
