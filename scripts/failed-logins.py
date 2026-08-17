#!/usr/bin/env python3
"""JQR Python Project 2 - parse auth.log for failed SSH logins (concepts: files, regex, dict)."""
import re, sys, collections
path = sys.argv[1] if len(sys.argv) > 1 else "/var/log/auth.log"
counts = collections.Counter()
pat = re.compile(r"Failed password for (?:invalid user )?(\S+) from (\d+\.\d+\.\d+\.\d+)")
try:
    with open(path) as f:
        for line in f:
            m = pat.search(line)
            if m: counts[m.group(2)] += 1
except FileNotFoundError:
    print(f"[-] {path} not found"); sys.exit(1)
print(f"Top source IPs by failed SSH logins in {path}:")
for ip, n in counts.most_common(5):
    print(f"  {n:>4}  {ip}")
if not counts: print("  (no failed-login lines found)")
