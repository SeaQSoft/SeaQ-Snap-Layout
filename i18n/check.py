"""Checks every <lang>.txt against master.txt: same line count, same
placeholders (%1, %2) and no empty lines."""
import glob, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
master = open(os.path.join(here, "master.txt"), encoding="utf-8").read().rstrip("\n").split("\n")
bad = 0
for path in sorted(glob.glob(os.path.join(here, "*.txt"))):
    lang = os.path.basename(path)[:-4]
    if lang == "master":
        continue
    lines = open(path, encoding="utf-8").read().rstrip("\n").split("\n")
    errs = []
    if len(lines) != len(master):
        errs.append("%d lines, expected %d" % (len(lines), len(master)))
    for i, (src, tr) in enumerate(zip(master, lines), 1):
        if not tr.strip():
            errs.append("line %d empty" % i)
        if sorted(re.findall(r"%\d", src)) != sorted(re.findall(r"%\d", tr)):
            errs.append("line %d placeholders: %r" % (i, tr))
    if errs:
        bad += 1
        print(lang, "->", "; ".join(errs[:5]))
    else:
        print(lang, "ok")
sys.exit(1 if bad else 0)
