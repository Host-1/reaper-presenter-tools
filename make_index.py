"""
Builds index.xml, the file ReaPack reads to install and update these scripts.

Run it again after every change, then upload the changed scripts AND index.xml.
ReaPack only offers an update when a script's "-- @version" line goes up,
so bump that number in the script before running this.

Usage (from this folder):
    python make_index.py --owner YOUR-ORG --repo YOUR-REPO
Optional:
    --branch main        (default: main)
    --name "Brahma REAPER tools"   (name shown in ReaPack)

Each subfolder is a category in ReaPack; each .lua file in it is a package.
The script's "-- @description" line becomes its description in ReaPack.
"""

import argparse
import datetime
import os
import re
from urllib.parse import quote
from xml.sax.saxutils import escape, quoteattr

HERE = os.path.dirname(os.path.abspath(__file__))
SKIP_DIRS = {"extras"}   # helper files, not ReaPack packages


def read_header(path):
    """Return (description, version) from the script's -- @ tags."""
    desc, version = None, None
    with open(path, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("--"):
                break
            m = re.match(r"--\s*@description\s+(.*)", line)
            if m:
                desc = m.group(1).strip()
            m = re.match(r"--\s*@version\s+(\S+)", line)
            if m:
                version = m.group(1).strip()
    return desc, version


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--owner", required=True, help="GitHub user or organisation that owns the repo")
    ap.add_argument("--repo", required=True, help="Repository name")
    ap.add_argument("--branch", default="main")
    ap.add_argument("--name", default="Presenter tools", help="Repository name shown in ReaPack")
    args = ap.parse_args()

    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    base = f"https://github.com/{args.owner}/{args.repo}/raw/{args.branch}/"

    categories = sorted(
        d for d in os.listdir(HERE)
        if os.path.isdir(os.path.join(HERE, d)) and not d.startswith(".") and d not in SKIP_DIRS
    )

    lines = ['<?xml version="1.0" encoding="utf-8"?>',
             f'<index version="1" name={quoteattr(args.name)}>']
    problems = []

    for cat in categories:
        scripts = sorted(f for f in os.listdir(os.path.join(HERE, cat)) if f.lower().endswith(".lua"))
        if not scripts:
            continue
        lines.append(f'  <category name={quoteattr(cat)}>')
        for fname in scripts:
            desc, version = read_header(os.path.join(HERE, cat, fname))
            if not version:
                problems.append(f"{cat}/{fname}: no '-- @version' line, skipped")
                continue
            url = base + quote(f"{cat}/{fname}")
            lines.append(f'    <reapack name={quoteattr(fname)} type="script" desc={quoteattr(desc or fname)}>')
            lines.append(f'      <version name={quoteattr(version)} time="{now}">')
            # main="main": ReaPack registers it in the Action list's Main section
            lines.append(f'        <source main="main">{escape(url)}</source>')
            lines.append('      </version>')
            lines.append('    </reapack>')
            print(f"  {cat}/{fname}  v{version}")
        lines.append('  </category>')

    lines.append('</index>')

    with open(os.path.join(HERE, "index.xml"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")

    for p in problems:
        print("WARNING:", p)
    print(f"\nWrote index.xml. Colleagues add this link in ReaPack:\n  {base}index.xml")


if __name__ == "__main__":
    main()
