# ProverSymbolsInput

Type [Lean 4](https://lean-lang.org) or [Agda](https://agda.readthedocs.io) unicode abbreviations (`\to` → `→`, `\R` → `ℝ`, `\<>` → `⟨⟩`)
in any macOS app, with a searchable cheat sheet on **⌃⌥⌘L**.

This repo works in conjunction with
[Math Symbols Input](https://github.com/knrafto/MathSymbolsInput), a macOS input method that turns
`\commands` into unicode characters in whichever app has keyboard focus. Math Symbols Input does
the typing; this repo loads Lean's or Agda's abbreviation table into it and adds the cheat sheet.

![The searchable shortcuts cheat sheet](cheatsheet.png)

## Install

1. Download and install [MathSymbolsInput.pkg][pkg], then log out and back in. If the package
   doesn't work, see the original [Math Symbols Input](https://github.com/knrafto/MathSymbolsInput)
   repo.
2. Run:

   ```sh
   ./install.sh            # Lean 4
   ./install.sh --agda     # Agda
   ```

   Add `--update` to fetch the latest table first.

This adds every Lean (or Agda) abbreviation to Math Symbols Input's **Custom Commands** (your own
are kept; the table wins on a name clash). Switching between `--agda` and Lean removes the other
table's commands. Where Agda offers several symbols for one key, the first (Agda's default) is used.
It also installs the **Open Symbol Shortcuts** Quick Action (the cheat sheet, for either table).
Re-run it to refresh the cheat sheet.

Preferences are backed up to `~/Library/Application Support/ProverSymbolsInput/` first. To undo:
`defaults import com.mathsymbolsinput.inputmethod.MathSymbolsInput <backup.plist>`.

`abbreviations.json` is from [leanprover/vscode-lean4](https://github.com/leanprover/vscode-lean4)
(Apache License 2.0). `abbreviations-agda.json` is flattened from the `keymap.js` in
[banacorn/agda-mode-vscode](https://github.com/banacorn/agda-mode-vscode) (MIT), itself generated
from Agda's Emacs `agda-input.el`.

[pkg]: https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
