---
tags: [jcu, module1, scripting, linux]
jqr: "Module 1 — the two required Bash projects: nmap-command generator + directory/file checker"
---

# Bash - JQR Projects

The two Bash deliverables the JQR names, written and **actually run**. Drop both `.sh` files in the repo (they live in `/scripts/`). Concepts come from [Bash Scripting](Bash%20Scripting.md).

> **What these really teach:** the leap from *typing commands* to *writing a program that produces commands or makes decisions*. Project 1 turns a one-off scan into a reusable template; Project 2 is the classic "check the world, then change it only if needed" pattern that every setup and install script is built on. Small scripts, but they're the shape of everything bigger.

---

## Project 1 — nmap command generator
> *"Create a script that prints out the most commonly needed nmap commands based off of user input for IP(s) and port(s)."*

```bash
#!/bin/bash
# nmap-helper.sh - print common nmap commands from user-supplied IP(s) and port(s)
read -p "Target IP(s) (e.g. 192.168.1.20 or 192.168.1.0/24): " TGT
read -p "Port(s) (e.g. 22,80,443 or - for all): " PORTS
echo
echo "===== Common nmap commands for $TGT (ports: $PORTS) ====="
echo "Ping sweep / host discovery : nmap -sn $TGT"
echo "Quick top-1000 SYN scan     : sudo nmap -sS $TGT"
echo "Full TCP port scan          : sudo nmap -sS -p- $TGT"
echo "Service + default scripts   : sudo nmap -sV -sC -p $PORTS $TGT"
echo "Aggressive (OS,ver,scripts) : sudo nmap -A -p $PORTS $TGT"
echo "UDP top ports               : sudo nmap -sU --top-ports 20 $TGT"
echo "Vuln scripts                : sudo nmap --script vuln -p $PORTS $TGT"
echo "Save all formats            : sudo nmap -sV -p $PORTS -oA scan_$TGT $TGT"
```

> ✅ **Tested output** (Ubuntu 24.04, 2026): fed `192.168.1.20` and `22,80,443`:
```
===== Common nmap commands for 192.168.1.20 (ports: 22,80,443) =====
Ping sweep / host discovery : nmap -sn 192.168.1.20
Quick top-1000 SYN scan     : sudo nmap -sS 192.168.1.20
Full TCP port scan          : sudo nmap -sS -p- 192.168.1.20
Service + default scripts   : sudo nmap -sV -sC -p 22,80,443 192.168.1.20
Aggressive (OS,ver,scripts) : sudo nmap -A -p 22,80,443 192.168.1.20
UDP top ports               : sudo nmap -sU --top-ports 20 192.168.1.20
Vuln scripts                : sudo nmap --script vuln -p 22,80,443 192.168.1.20
Save all formats            : sudo nmap -sV -p 22,80,443 -oA scan_192.168.1.20 192.168.1.20
```
**Concepts shown:** `read -p` input, variables, quoting, a here-block of `echo`s. It builds the exact strings so you can copy the one you need. See [Nmap](../Recon%20Tools/Nmap.md) for what each flag does.

> **Why a generator, not a scanner?** It never touches the network — it just prints the exact commands so you can read, tweak, and fire the *one* you actually want. On a real box that deliberation matters: you see precisely how loud each scan is before you make any noise. It's a cheat sheet that fills itself in with your target.

---

## Project 2 — directory & file checker
> *"Check if a directory exists; if it does, see if a specific file exists within it. If not, create the file. Print whether the directory/file exists; if it didn't, print that it's now created."*

```bash
#!/bin/bash
# dir-file-check.sh - check dir exists; if so check file; create file if missing
DIR="${1:-/tmp/jcu_demo}"          # 1st arg, or default
FILE="${2:-notes.txt}"             # 2nd arg, or default
if [ -d "$DIR" ]; then
    echo "[+] Directory '$DIR' exists."
    if [ -f "$DIR/$FILE" ]; then
        echo "[+] File '$FILE' already exists in '$DIR'."
    else
        touch "$DIR/$FILE"
        echo "[!] File '$FILE' did NOT exist -> it has now been created."
    fi
else
    echo "[-] Directory '$DIR' does not exist. Creating it and the file."
    mkdir -p "$DIR" && touch "$DIR/$FILE"
    echo "[!] Created directory '$DIR' and file '$FILE'."
fi
```

> ✅ **Tested output** (Ubuntu 24.04, 2026): run twice — first creates, second finds:
```
--- run 1 (nothing exists yet) ---
[-] Directory '/tmp/jcu_demo' does not exist. Creating it and the file.
[!] Created directory '/tmp/jcu_demo' and file 'report.txt'.
--- run 2 (now it exists) ---
[+] Directory '/tmp/jcu_demo' exists.
[+] File 'report.txt' already exists in '/tmp/jcu_demo'.
```
**Concepts shown:** `-d`/`-f` file tests, nested `if`, `${1:-default}` argument defaults, `mkdir -p`, `touch`, `&&`.

> **Why this pattern is everywhere:** "does it exist? if not, create it" is *idempotent* — safe to run over and over, changing nothing once things are in place. Every installer, provisioning script, and config-management tool is really this check-then-act loop scaled up. Learn the two-line version here and you can read the thousand-line ones later.

---

## Project 3 — startup/setup script (Module 3 skill)
> *Module 3: "Create a bash script that sets up your interfaces, updates your system, opens your terminals, and opens Firefox."*

> 🧪 **Run this on your lab** — it needs the desktop VM (GUI for terminals/Firefox) and your real interface names (`ip -br link`).

```bash
#!/bin/bash
# setup.sh - bring up networking, update, open terminals, open Firefox
set -e

# 1) Interfaces — apply your network config (netplan on Ubuntu; ifupdown on Debian)
sudo netplan apply 2>/dev/null || sudo systemctl restart networking

# 2) Update the system
sudo apt update && sudo apt -y upgrade

# 3) Open terminals — a detached tmux session split into panes
tmux new-session -d -s work
tmux split-window -h
tmux split-window -v
#   (attach with: tmux attach -t work   — or launch Terminator instead: terminator &)

# 4) Open Firefox to the study repo
firefox "https://github.com/grizzysammy-dev/Study-Prep" >/dev/null 2>&1 &

echo "[+] Network applied, system updated, tmux 'work' ready, Firefox launched."
```
**Concepts shown:** `set -e` (stop on error), `||` fallback, `&&` chaining, backgrounding with `&`, scripting [tmux](../Terminator%20TMUX/tmux%20and%20Terminator.md). Swap the tmux block for `terminator &` if you chose Terminator.

> **Why script your own setup?** Because you'll revert those clean VM snapshots constantly — a one-shot setup script rebuilds your whole working environment in seconds instead of clicking through it every time. The `&` on Firefox matters too: it backgrounds the GUI so the script doesn't sit there frozen waiting for you to close the browser.

## Exam tips & gotchas
- The `-d` test checks a **directory**; `-f` checks a **regular file**. Don't mix them up.
- `${1:-default}` = "use `$1`, or this default if `$1` is empty" — makes a script work with or without arguments.
- Keep both scripts executable (`chmod +x`) and committed so instructors can see them ([Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md)).

## References
- freeCodeCamp Bash tutorial — https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/
- Bash conditional expressions — https://www.gnu.org/software/bash/manual/bash.html#Bash-Conditional-Expressions

## Related
- [Bash Scripting](Bash%20Scripting.md)
- [Nmap](../Recon%20Tools/Nmap.md)
- [Python - JQR Projects](../Python%20Scripting/Python%20-%20JQR%20Projects.md)
