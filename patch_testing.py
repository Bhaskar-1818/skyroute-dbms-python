"""One-off: add Evidence column to TESTING.md tables + fix check count."""
import re

p = "dbms/docs/TESTING.md"
lines = open(p, encoding="utf-8").read().splitlines(keepends=False)
out, group = [], ""
for ln in lines:
    m = re.match(r"## (T\d)", ln)
    if m:
        group = m.group(1)
    if ln.startswith("| # |"):
        out.append("| # | Check | Expected | Evidence |")
    elif re.match(r"^\|---", ln):
        out.append(ln + "----------|")
    elif ln.startswith("| ") and group:
        out.append(ln + f" Shot {group} |")
    else:
        out.append(ln)
s = "\n".join(out)
s = s.replace("30 checks in 8 groups", "24 checks in 8 groups")
open(p, "w", encoding="utf-8").write(s)
print("testing patched")
