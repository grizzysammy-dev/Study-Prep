---
tags: [cyber, module1, scripting, python]
jqr: "Module 1: two practical Python projects (choose two, put the concepts into practice)"
---

# Python - JQR Projects

Two small, practical tools that exercise the Python basics from [Python Scripting](Python%20Scripting.md), both actually run below. They lean defensive and recon so they double as study aids. The files live in `/scripts/`.

> What these two teach together: the two halves of security scripting, reaching out to the network (the port scanner opens sockets) and making sense of what a machine wrote down (the log parser turns messy text into a ranked list). Read side by side, one generates the activity and the other detects it. That's the offense/defense pairing in ~15 lines each.

---

## Project 1: Common TCP port scanner
Concepts: `socket`, loops, `argparse`, string formatting.

> The way I picture it: a socket is one end of a network conversation, my program's plug into the wire. "Scanning a port" is just trying to complete the TCP handshake with it: if something's listening the connection succeeds, and if nothing is it's refused or times out. A port scan is knocking on every door and noting which ones open.

```python
#!/usr/bin/env python3
"""portscan.py - simple TCP port scanner."""
import socket, argparse
p = argparse.ArgumentParser(description="TCP port scanner")
p.add_argument("Host")
p.add_argument("-p", "--ports", default="21,22,23,25,53,80,443,445,8080,3389,")
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

I ran this on Ubuntu 24.04 (2026) with a listener on 8080 and got:
```
Scanning 127.0.0.1 ...
     22/tcp  closed
     80/tcp  closed
    443/tcp  closed
    ...
   8080/tcp  OPEN
```
`connect_ex()` returns `0` when the TCP handshake completes, meaning the port's open. This is the Python version of what [Nmap](../Recon%20Tools/Nmap.md) does under the hood, good for understanding but I use nmap for real work.

---

## Project 2: failed-login log parser (defensive)
Concepts: file reading, `re` regex, `collections.Counter`.

```python
#!/usr/bin/env python3
"""failed-logins.py - parse auth.log for failed SSH logins."""
import re, sys, collections
path = sys.argv[1] if len(sys.argv) > 1 else "/var/log/auth.log"
counts = collections.Counter()
pat = re.compile(r"Failed password: (?:invalid user )?(\S+) from:(\d+\.\d+\.\d+\.\d+)")
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

I ran it on Ubuntu 24.04 (2026) against a sample auth.log:
```
Top source IPs by failed SSH logins in /tmp/sample_auth.log:
     3  192.168.1.50
     1  10.0.0.9
```
This ties straight into my defensive background: it's brute-force detection, same idea as [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md). The regex captures user and source IP, and `Counter.most_common()` ranks the noisiest attackers.

> Why this shape recurs: almost all log analysis is the same three moves, read the lines, pull the fields I care about with a regex, tally them up. Swap the pattern and I'm hunting failed sudo, odd user-agents, or beaconing intervals instead. This is the manual, one-file version of what a SIEM does across a whole fleet, which is why it maps so cleanly onto my defensive background.

## Gotchas I want to remember
- `socket.settimeout()`: without it a closed or filtered port hangs the whole scan.
- Compile the regex once (`re.compile`) outside the loop for speed on big logs.
- Wrap file opens in `try/except FileNotFoundError` so the tool fails cleanly.
- These are learning tools; on the box I use [Nmap](../Recon%20Tools/Nmap.md) and real log tooling for anything serious.

## References
- Python `socket`: https://docs.python.org/3/library/socket.html
- Python `re`: https://docs.python.org/3/library/re.html
- Real Python projects: https://realpython.com/tutorials/projects/

## Related
- [Python Scripting](Python%20Scripting.md)
- [Bash - JQR Projects](../Bash%20Scripting/Bash%20-%20JQR%20Projects.md)
- [Nmap](../Recon%20Tools/Nmap.md)
- [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md)
