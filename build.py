#!/usr/bin/env python3
"""Merge Lean 4 abbreviations into Math Symbols Input's custom commands
and render the searchable shortcut viewer page.

Usage: build.py <abbreviations.json> <viewer-template.html> <output.html>
"""
import json
import plistlib
import subprocess
import sys
import unicodedata

DOMAIN = "com.mathsymbolsinput.inputmethod.MathSymbolsInput"


def read_domain():
    out = subprocess.run(["defaults", "export", DOMAIN, "-"],
                         capture_output=True).stdout
    return plistlib.loads(out) if out else {}


def lean_commands(path):
    cmds = {}
    for k, v in json.load(open(path, encoding="utf-8")).items():
        v = v.replace("$CURSOR", "")
        # The input method ends a command on whitespace, so skip those.
        if not v or any(c.isspace() for c in k):
            continue
        cmds["\\" + k] = v
    return cmds


def kind(v):
    names = [unicodedata.name(c, "") for c in v]
    if names and all("SUPERSCRIPT" in n or n.startswith(
            ("MODIFIER LETTER SMALL", "MODIFIER LETTER CAPITAL")) for n in names):
        return "sup"
    if names and all("SUBSCRIPT" in n for n in names):
        return "sub"
    return ""


def main(abbrev, template, out):
    prefs = read_domain()
    custom = dict(prefs.get("CustomCommands", {}))
    lean = lean_commands(abbrev)
    added = sum(1 for k in lean if k not in custom)
    custom.update(lean)  # Lean table wins; other custom commands are kept.
    prefs["CustomCommands"] = custom
    subprocess.run(["defaults", "import", DOMAIN, "-"],
                   input=plistlib.dumps(prefs), check=True)
    print(f"Lean commands: {len(lean)} ({added} new); "
          f"total custom commands: {len(custom)}")

    rows = [[k, v, kind(v)] for k, v in
            sorted(custom.items(), key=lambda kv: (kv[0].lower(), kv[0]))]
    data = json.dumps(rows, ensure_ascii=False).replace("</", "<\\/")
    page = open(template, encoding="utf-8").read().replace("__DATA__", data)
    with open(out, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"Viewer: {out}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
