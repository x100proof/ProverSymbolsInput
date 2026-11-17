#!/usr/bin/env python3
"""Install a unicode abbreviation table (Lean 4 or Agda) into Math Symbols
Input's custom commands and render the searchable shortcut viewer page.

Usage: build.py [--title T] [--replace TABLE ...] <table> <viewer-template.html> <output.html>

<table> is either a flat JSON object {"abbrev": "symbol"} (Lean's
abbreviations.json, abbreviations-agda.json) or agda-mode-vscode's keymap.js
trie. Commands that came from any --replace table (same key, same symbol) are
removed first, so switching tables doesn't leave the old one behind; custom
commands you added yourself are kept.
"""
import argparse
import json
import plistlib
import subprocess
import unicodedata

DOMAIN = "com.mathsymbolsinput.inputmethod.MathSymbolsInput"


def read_domain():
    out = subprocess.run(["defaults", "export", DOMAIN, "-"],
                         capture_output=True).stdout
    return plistlib.loads(out) if out else {}


def flatten_trie(node, prefix=""):
    """agda-mode-vscode keymap: {"a": {"b": {">>": ["sym", ...]}}}.
    The first candidate is Agda's default; the input method takes one."""
    for k, v in node.items():
        if k == ">>":
            if v:
                yield prefix, v[0]
        else:
            yield from flatten_trie(v, prefix + k)


def read_table(path):
    text = open(path, encoding="utf-8").read()
    if text.lstrip().startswith("module.exports"):
        text = text[text.index("=") + 1:].strip().rstrip(";")
        return dict(flatten_trie(json.loads(text)))
    return json.loads(text)


def commands(path):
    cmds = {}
    for k, v in read_table(path).items():
        v = v.replace("$CURSOR", "")
        # The input method ends a command on whitespace, so skip those.
        if not k or not v or any(c.isspace() for c in k + v):
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


def main():
    ap = argparse.ArgumentParser(usage=__doc__)
    ap.add_argument("--title", default="Lean")
    ap.add_argument("--replace", action="append", default=[])
    ap.add_argument("table")
    ap.add_argument("template")
    ap.add_argument("out")
    a = ap.parse_args()

    prefs = read_domain()
    custom = dict(prefs.get("CustomCommands", {}))
    before = dict(custom)
    for path in a.replace:
        for k, v in commands(path).items():
            if custom.get(k) == v:
                del custom[k]
    new = commands(a.table)
    added = sum(1 for k in new if k not in before)
    removed = sum(1 for k in before if k not in custom and k not in new)
    custom.update(new)  # New table wins; your own custom commands are kept.
    prefs["CustomCommands"] = custom
    subprocess.run(["defaults", "import", DOMAIN, "-"],
                   input=plistlib.dumps(prefs), check=True)
    print(f"{a.title} commands: {len(new)} ({added} new, {removed} old removed); "
          f"total custom commands: {len(custom)}")

    rows = [[k, v, kind(v)] for k, v in
            sorted(custom.items(), key=lambda kv: (kv[0].lower(), kv[0]))]
    data = json.dumps(rows, ensure_ascii=False).replace("</", "<\\/")
    page = (open(a.template, encoding="utf-8").read()
            .replace("__TITLE__", a.title).replace("__DATA__", data))
    with open(a.out, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"Viewer: {a.out}")


if __name__ == "__main__":
    main()
