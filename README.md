# LeanSymbolInput

Type [Lean 4](https://lean-lang.org) unicode abbreviations (`\to` → `→`, `\R` → `ℝ`, `\<>` → `⟨⟩`)
in any macOS app, with a searchable cheat sheet on **⌃⌥⌘L**.

This repo works in conjunction with
[Math Symbols Input](https://github.com/knrafto/MathSymbolsInput), a macOS input method that turns
`\commands` into unicode characters in whichever app has keyboard focus. Math Symbols Input does
the typing; this repo loads Lean's abbreviation table into it and adds the cheat sheet.

![The searchable Lean shortcuts cheat sheet](cheatsheet.png)

## Install

1. Download and install [MathSymbolsInput.pkg][pkg], then log out and back in. If the package
   doesn't work, see the original [Math Symbols Input](https://github.com/knrafto/MathSymbolsInput)
   repo.
2. Run:

   ```sh
   ./install.sh            # or: ./install.sh --update  (fetch the latest Lean table)
   ```

This adds every Lean abbreviation to Math Symbols Input's **Custom Commands** (existing ones are
kept; Lean wins on a name clash) and installs the **Open Lean Shortcuts** Quick Action. Re-run it
to refresh the cheat sheet.

Preferences are backed up to `~/Library/Application Support/LeanSymbolsInput/` first. To undo:
`defaults import com.mathsymbolsinput.inputmethod.MathSymbolsInput <backup.plist>`.

`abbreviations.json` is from [leanprover/vscode-lean4](https://github.com/leanprover/vscode-lean4)
(Apache License 2.0).

[pkg]: https://github.com/knrafto/MathSymbolsInput/releases/latest/download/MathSymbolsInput.pkg
