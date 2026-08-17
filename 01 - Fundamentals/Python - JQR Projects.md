---
tags: [jcu, module1, scripting, python]
jqr: "Module 1 — two practical Python projects (choose two, put concepts into practice)"
---

# Python - JQR Projects

Two small, practical tools that exercise the Python basics from [Python Scripting](Python%20Scripting.md) — both **actually run** below. They lean defensive/recon so they double as study aids. Files live in `/scripts/`.

---

## Project 1 — TCP port scanner
Concepts: `socket`, loops, `argparse`, string formatting.

```python
#!/usr/bin/env python3
"""portscan.py - simple TCP port scanner."""
import socket, argparse
p = argparse.ArgumentParser(description="Tiny TCP port scanner")
p.add_argument("host")
p.add_argument("-p", "--ports", default="22,80,443,8080")
a = p.parse_args()
ports = [int(x) for x in a.ports.split(",")]
print(f"Scanning {a.host} ...")
for port in ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.5)
    state = "OPEN" if s.connect_ex((a.host, port)) == 0 else "closed"
    print(f"  {port:>5}/tcp  {state}")
    s.close()
```

> ✅ **Tested output** (Ubuntu 24.04, 2026): with a listener on 8080:
```
Scanning 127.0.0.1 ...
     22/tcp  closed
     80/tcp  closed
    443/tcp  closed
   8080/tcp  OPEN
```
→ `connect_ex()` returns `0` when the TCP handshake completes (port open). This is the Python version of what [Nmap](../02%20-%20Recon%20and%20Network%20Tools/Nmap.md) does under the hood — good for understanding, use nmap for real work.

---

## Project 2 — failed-login log parser (defensive)
Concepts: file reading, `re` regex, `collections.Counter`.

```python
#!/usr/bin/env python3
"""failed-logins.py - parse auth.log for failed SSH logins."""
import re, sys, collections
path = sys.argv[1] if len(sys.argv) > 1 else "/var/log/auth.log"
counts = collections.Counter()
pat = re.compile(r"Failed password for (?:invalid user )?(\S+) from (\d+\.\d+\.\d+\.\d+)")
try:
    with open(path) as f:
        for line in f:
            m = pat.search(line)
            if m:
                counts[m.group(2)] += 1
except FileNotFoundError:
    print(f"[-] {path} not found"); sys.exit(1)
print(f"Top source IPs by failed SSH logins in {path}:")
for ip, n in counts.most_common(5):
    print(f"  {n:>4}  {ip}")
if not counts:
    print("  (no failed-login lines found)")
```

> ✅ **Tested output** (Ubuntu 24.04, 2026): against a sample auth.log:
```
Top source IPs by failed SSH logins in /tmp/sample_auth.log:
     3  192.168.1.50
     1  10.0.0.9
```
→ Ties straight into your defensive background: this is brute-force detection from [Logs and journalctl](../03%20-%20Linux%20Skills/Logs%20and%20journalctl.md). The regex captures user + source IP; `Counter.most_common()` ranks the noisiest attackers.

## Exam tips & gotchas
- `socket.settimeout()` — without it a closed/filtered port hangs your scan.
- Compile the regex once (`re.compile`) outside the loop for speed on big logs.
- Wrap file opens in `try/except FileNotFoundError` so the tool fails cleanly.
- These are learning tools; on the box use [Nmap](../02%20-%20Recon%20and%20Network%20Tools/Nmap.md) and real log tooling for anything serious.

## References
- Python `socket` — https://docs.python.org/3/library/socket.html
- Python `re` — https://docs.python.org/3/library/re.html
- Real Python projects — https://realpython.com/tutorials/projects/

## Related
- [Python Scripting](Python%20Scripting.md)
- [Bash - JQR Projects](Bash%20-%20JQR%20Projects.md)
- [Nmap](../02%20-%20Recon%20and%20Network%20Tools/Nmap.md)
- [Logs and journalctl](../03%20-%20Linux%20Skills/Logs%20and%20journalctl.md)
