# ProverSymbolsInput

Type [Lean 4](https://lean-lang.org) or [Agda](https://agda.readthedocs.io) unicode
abbreviations in any macOS app (`\to` → `→`, `\all` → `∀`, `\==` → `≡`), with a searchable
cheat sheet one keystroke away (**⌃⌥⌘L** by default, and you can change it).

![The searchable shortcuts cheat sheet](cheatsheet.png)

## How it works

[Math Symbols Input](https://github.com/knrafto/MathSymbolsInput) is a macOS input method that
turns `\commands` into unicode characters in whichever app has keyboard focus. It does the typing.
This repo:

- loads the full Lean 4 or Agda abbreviation table into Math Symbols Input as custom commands, and
- adds an **Open Symbol Shortcuts** Quick Action on ⌃⌥⌘L (or your own shortcut) that opens a
  searchable cheat sheet of every command. Search by abbreviation (`to`, `\bN`) or paste a symbol to find how to type it.

You use one proof assistant's table at a time. The two mostly agree, but not everywhere:

| Symbol | Lean 4 | Agda   |
|--------|--------|--------|
| →      | `\to`  | `\to`  |
| ∀      | `\all` | `\all` |
| ≡      | `\==`  | `\==`  |
| ℕ      | `\N`   | `\bN`  |
| ℝ      | `\R`   | `\bR`  |

## Install

1. Download and install [MathSymbolsInput.pkg][pkg], then log out and back in. If the package
   doesn't work, see the original [Math Symbols Input](https://github.com/knrafto/MathSymbolsInput)
   repo.
2. Clone this repo and run the installer for your proof assistant:

   ```sh
   ./install.sh            # Lean 4 (the default; same as --lean4)
   ./install.sh --agda     # Agda
   ```

3. Press **⌃⌥⌘L** (or your `--shortcut`) to open the cheat sheet. If nothing happens, check that
   **Open Symbol Shortcuts** is ticked under System Settings → Keyboard → Keyboard Shortcuts →
   Services → General.

### Options

| Flag              | Effect                                                                 |
|-------------------|------------------------------------------------------------------------|
| `--lean4`         | Install the Lean 4 table (the default).                                |
| `--agda`          | Install the Agda table.                                                |
| `--update`        | Download the latest table first instead of using the copy in this repo. |
| `--shortcut KEYS` | Set the shortcut that opens the cheat sheet (default `Ctrl+Option+Cmd+L`). |

### Choosing the shortcut

```sh
./install.sh --shortcut "Cmd+Ctrl+Shift+L"
```

`KEYS` is one or more modifiers and a single key joined by `+`, in any order and any case, the
same style as VS Code keybindings and Electron accelerators. So `cmd+shift+l`,
`Command+Shift+L` and `⌘+⇧+L` all mean the same shortcut.

| Modifier | Accepted names                                          |
|----------|---------------------------------------------------------|
| ⌘        | `Cmd`, `Command`, `Meta`, `Super`, `CmdOrCtrl`, `⌘`     |
| ⌃        | `Ctrl`, `Control`, `⌃`                                  |
| ⌥        | `Opt`, `Option`, `Alt`, `⌥`                             |
| ⇧        | `Shift`, `⇧`                                            |

The key is a letter, a digit, or one of `` ` - = [ ] \ ; ' , . / ``. At least one of Cmd, Ctrl or
Option is needed. Function keys, Space and arrow keys are not supported. Pick a combination that
no app you use already claims, or that app's shortcut wins while it is focused.

The installer remembers your shortcut, so later runs (switching to Agda, `--update`) keep it.
Pass `--shortcut "Ctrl+Option+Cmd+L"` to go back to the default.

### Switching and re-running

Run the installer again with the other flag to switch: the previous table's commands are removed
and the new ones added. Custom commands you created yourself are always kept; if one has the same
name as a table entry, the table's version wins. Re-running also refreshes the cheat sheet.

Agda sometimes offers several symbols for one abbreviation (picked with number keys in Emacs).
Math Symbols Input maps each command to one string, so the first, Agda's default, is used.

### The cheat sheet window

The cheat sheet opens as a Google Chrome app window if Chrome is installed, otherwise in your
default browser. It first opens centred at a comfortable size; resize it and it keeps your size.

## Undo

Each run backs up Math Symbols Input's preferences to
`~/Library/Application Support/ProverSymbolsInput/` first. To restore one:

```sh
defaults import com.mathsymbolsinput.inputmethod.MathSymbolsInput <backup.plist>
```

To remove the cheat sheet shortcut, delete
`~/Library/Services/Open Symbol Shortcuts.workflow`.

## Sources

- `abbreviations.json` is from
  [leanprover/vscode-lean4](https://github.com/leanprover/vscode-lean4) (Apache License 2.0).
- `abbreviations-agda.json` is flattened from the `keymap.js` in
  [banacorn/agda-mode-vscode](https://github.com/banacorn/agda-mode-vscode) (MIT), which is
  generated from Agda's Emacs `agda-input.el`.

[pkg]: https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
