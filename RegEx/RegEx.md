---
tags: [cyber, module1, linux, text]
jqr: "Module 1: learn RegEx for find/extract/replace across tools (grep, sed, Python re)"
---

# RegEx

Regular expressions are a pattern language for finding, extracting, and replacing text. I use it constantly in `grep`, `sed`, `vim`, and Python. "Learn it. Live it. Love it." (I practice at the JQR's slash-escape game.)

> The way I think about it: a regex describes the shape of text, not exact words. So instead of hunting for one specific string, I say "anything shaped like an IP address" or "a date like YYYY-MM-DD" and the engine finds every match at once. Under the hood it's a tiny state machine that walks the text left to right, trying to make my pattern fit. The same pattern language is bolted into grep, sed, vim, and Python's `re`, which is why learning it once pays off everywhere.

## The pieces I actually use
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
In `vim`: `:%s/\d\+/NUM/g`. Basic `grep` needs `\+`/`\{}` escaped, while `grep -E` (or `-P`) lets me write them plain, so I reach for `-E`.

> Why `grep -E` saves me backslashes: plain grep speaks Basic regex (BRE), an older dialect where `+ ? { } ( ) |` are literal characters unless I escape them. `-E` (Extended) and `-P` (Perl) treat those as the operators I expect. Same pattern, different dialect, so I reach for `-E` and stop fighting the escaping.

## Worked patterns (copy these)
```
IPv4 (rough)   \b\d{1,3}(\.\d{1,3}){3}\b
Email (rough)  [\w.+-]+@[\w-]+\.[\w.-]+
MAC address    ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}
Date YYYY-MM-DD \d{4}-\d{2}-\d{2}
Hex / hashes   \b[0-9a-fA-F]{32,}\b
```

> Where I've already met this: every IDS signature, SIEM search, and log-redaction rule is regex under the hood, "alert when a line matches this shape." Writing a pattern to pull IPs out of a log is the same skill as writing the rule that flags them. I'm learning the offense and defense sides of one coin at the same time.

## Greedy vs lazy (the classic trap)
- `.*` is **greedy**, it grabs as much as possible.
- `.*?` is **lazy**, it grabs as little as possible.
- On `<a><b>`, the pattern `<.*>` matches the whole `<a><b>`; `<.*?>` matches just `<a>`.

> Why greedy is the trap: `*` and `+` grab as much as they possibly can, then back off only if the match would otherwise fail, so `<.*>` swallows everything to the last `>` on the line. Adding `?` makes it lazy: stop at the first. This one default is behind more "why did my regex eat the whole line?" moments than anything else.

## What keeps tripping me up
- **`grep -E`** (extended) or **`grep -P`** (Perl, gives `\d`) saves me escaping `+ ? { } ( ) |`. Plain `grep` (BRE) needs backslashes.
- Anchor my patterns (`^`, `$`, `\b`) or I'll match inside words I didn't mean to.
- Escape literals that are also special: a real dot is `\.`, a real slash `\/`.
- Test patterns against sample text before trusting them on real data (regex101.com is great for this).

## References
- Slash Escape (JQR-named practice game): https://www.therobinlord.com/projects/slash-escape
- regex101 (interactive tester/explainer): https://regex101.com
- `grep`(1) / `sed`(1) man pages: https://man7.org/linux/man-pages/man1/grep.1.html

## Related
- [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
- [Python Scripting](../Python%20Scripting/Python%20Scripting.md)
- [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md)
- [Vim](../Vim/Vim.md)
