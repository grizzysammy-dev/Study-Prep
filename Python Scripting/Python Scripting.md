---
tags: [cyber, module1, scripting, python]
jqr: "Module 1: Python basics on the Ubuntu VM, then two practical projects"
---

# Python Scripting

The JQR wants me to learn Python basics (Google's Python class) and turn two of them into practice projects, which live in [Python - JQR Projects](Python%20-%20JQR%20Projects.md). This note is my language cheat sheet for reading and writing the small tools a defender needs.

> The way I think about it: reach for Python when a task outgrows the shell. Bash is perfect for gluing commands together, but the moment I need real data structures, parsing, math, or a library someone already wrote, I want a proper language. Python's whole deal is readable code and "batteries included" (a huge standard library, so common jobs need no install), and it's the lingua franca of security tooling, since most exploits, scanners, and parsers I'll ever read are Python. If Bash is a Swiss-army knife taped to other tools, Python is the workshop.

## The quick version
```python
#!/usr/bin/env python3
import sys
name = sys.argv[1] if len(sys.argv) > 1 else "world"   # CLI arg
print(f"hello {name}")                                  # f-string
for i in range(3): print(i)                             # loop
```
Run it with `python3 script.py arg`. I isolate dependencies with a **venv** (see [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md)).

## Core syntax
```python
# Variables & types
n = 42                     # int
pi = 3.14                  # float
s = "text"                 # str
ok = True                  # bool
items = [1, 2, 3]          # list (ordered, mutable)
pair = (10, 20)            # tuple (immutable)
kv = {"ip": "192.168.1.20", "port": 445}   # dict (key -> value)
seen = {1, 2, 3}           # set (unique)

# Strings
f"{n} on {s}"              # f-string interpolation
s.split(",")               # -> list
",".join(items_as_str)     # list -> string
s.strip()                  # trim whitespace
```

> Why the dict earns its keep: most security scripting is "look something up by a key", a port number, an IP, a username. `kv["port"]` is an instant lookup, no loop needed. Lists are ordered piles I walk through; dicts are labeled shelves I reach straight into. Knowing which shape fits the job is half of writing clean code.

```python
# Control flow
if n > 0:
    print("positive")
elif n == 0:
    print("zero")
else:
    print("negative")

for x in items:
    print(x)

while n > 0:
    n -= 1
```

```python
# Functions
def scan(host, port=80):        # default arg
    return f"{host}:{port}"
print(scan("192.168.1.20", 445))
```

## Reading input & files
```python
import sys
target = sys.argv[1]                    # positional CLI arg
name = input("Name: ")                  # interactive

with open("/var/log/auth.log") as f:    # 'with' auto-closes the file
    for line in f:
        print(line.rstrip())
```

## Handy standard-library modules (no install needed)
| Module | For |
|---|---|
| `sys`, `os` | args, env, paths, running commands |
| `argparse` | proper `--flags` CLIs |
| `socket` | TCP/UDP connections (port scanners, banner grab) |
| `re` | regex (see [RegEx](../RegEx/RegEx.md)) |
| `subprocess` | run other programs and capture output |
| `collections` | `Counter`, `defaultdict` for tallying |
| `json` | parse/emit JSON |

```python
import argparse
p = argparse.ArgumentParser()
p.add_argument("host")
p.add_argument("-p", "--ports", default="22,80,443")
a = p.parse_args()
print(a.host, a.ports)
```

> Why "no install needed" is a big deal: on a target or a locked-down box I often can't `pip install` anything. A tool that leans only on the standard library runs anywhere Python does, which is the scripting version of "living off the land," and it's exactly why the `socket` / `re` / `subprocess` trio shows up in so much security tooling.

## Third-party packages (2026 reality)
```bash
python3 -m venv venv && source venv/bin/activate   # make + enter a venv
pip install requests                                # installs INSIDE the venv
```
> [!warning] On modern distros a bare `pip install requests` fails with **"externally-managed-environment" (PEP 668)** to protect the system Python. Fixes, best first: use a **venv** (above), or `pipx` for apps, or `--break-system-packages` only if I truly mean it. Full detail in [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md) and [Package Management](../Linux%20Admin/Package%20Management.md).

> Why the wall exists: my distro's own tools (apt, netplan, chunks of the desktop) are written in Python and pinned to specific versions. If a stray `pip install` upgrades a shared library out from under them, I can break the OS itself. A venv sidesteps all of it by handing each project its own private copy of Python and its packages, an isolated sandbox, the same instinct as a chroot.

## What keeps tripping me up
- **Indentation is syntax** in Python: 4 spaces, stay consistent, no tabs mixed in.
- `python3`/`pip3`: on many boxes plain `python` is absent, so I use the `3`.
- Use `with open(...)` so files always close.
- `if __name__ == "__main__":` guards code so a file can be both run and imported.
- Keep tools in a **venv** so I never fight the system Python.

## References
- Google's Python Class (JQR-named): https://developers.google.com/edu/python
- Real Python projects (JQR-named): https://realpython.com/tutorials/projects/
- Python docs / stdlib: https://docs.python.org/3/

## Related
- [Python - JQR Projects](Python%20-%20JQR%20Projects.md)
- [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md)
- [RegEx](../RegEx/RegEx.md)
- [Package Management](../Linux%20Admin/Package%20Management.md)
