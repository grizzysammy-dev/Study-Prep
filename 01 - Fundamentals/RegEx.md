---
tags: [jcu, module1, linux, text]
jqr: "Module 1 — learn RegEx for find/extract/replace across tools (grep, sed, Python re)"
---

# RegEx

Regular expressions = a pattern language for finding, extracting, and replacing text. You'll use it constantly in `grep`, `sed`, `vim`, and Python. "Learn it. Live it. Love it." (Practice at the JQR's slash-escape game.)

## TL;DR — the pieces you actually need
| Pattern | Matches |
|---|---|
| `.` | any single character |
| `\d` `\w` `\s` | digit · word char (`[A-Za-z0-9_]`) · whitespace |
| `\D` `\W` `\S` | the negations (non-digit, etc.) |
| `[abc]` `[a-z]` `[^abc]` | one of a set · a range · **not** in the set |
| `^` `$` | start / end of line (anchors) |
| `*` `+` `?` | 0-or-more · 1-or-more · 0-or-1 (optional) |
| `{2}` `{2,4}` `{2,}` | exactly 2 · 2 to 4 · 2 or more |
| `(...)` | group / capture |
| `a\|b` | a **or** b (alternation) |
| `\.` `\/` | a literal dot / slash (escape a special char) |

## Use it in the tools
```bash
grep -E "error|fail" app.log            # -E = extended regex; find lines with either word
grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" access.log   # -o = print only the match (pull IPs)
grep -c "Failed password" auth.log      # -c = count matching lines
sed -E "s/[0-9]{4}/XXXX/g" file         # substitute: mask any 4-digit run
```
```python
import re
re.findall(r"\d+\.\d+\.\d+\.\d+", text)      # all IPv4-looking strings
re.sub(r"\s+", " ", text)                     # collapse whitespace
m = re.search(r"user=(\w+)", line); m.group(1)  # capture the username
```
→ In `vim`: `:%s/\d\+/NUM/g`. Basic `grep` needs `\+`/`\{}` escaped; `grep -E` (or `-P`) lets you write them plain — prefer `-E`.

## Worked patterns (copy these)
```
IPv4 (rough)   \b\d{1,3}(\.\d{1,3}){3}\b
Email (rough)  [\w.+-]+@[\w-]+\.[\w.-]+
MAC address    ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}
Date YYYY-MM-DD \d{4}-\d{2}-\d{2}
Hex / hashes   \b[0-9a-fA-F]{32,}\b
```

## Greedy vs lazy (the classic trap)
- `.*` is **greedy** — grabs as much as possible.
- `.*?` is **lazy** — grabs as little as possible.
- On `<a><b>`, the pattern `<.*>` matches the whole `<a><b>`; `<.*?>` matches just `<a>`.

## Exam tips & gotchas
- **`grep -E`** (extended) or **`grep -P`** (Perl, gives `\d`) saves you escaping `+ ? { } ( ) |`. Plain `grep` (BRE) needs backslashes.
- Anchor your patterns (`^`, `$`, `\b`) or you'll match inside words you didn't mean to.
- Escape literals that are also special: a real dot is `\.`, a real slash `\/`.
- Test patterns against sample text before trusting them on real data (regex101.com is great for this).

## References
- Slash Escape (JQR-named practice game) — https://www.therobinlord.com/projects/slash-escape
- regex101 (interactive tester/explainer) — https://regex101.com
- `grep`(1) / `sed`(1) man pages — https://man7.org/linux/man-pages/man1/grep.1.html

## Related
- [Files Search and Permissions](../03%20-%20Linux%20Skills/Files%20Search%20and%20Permissions.md)
- [Python Scripting](Python%20Scripting.md)
- [Logs and journalctl](../03%20-%20Linux%20Skills/Logs%20and%20journalctl.md)
- [Vim](Vim.md)
