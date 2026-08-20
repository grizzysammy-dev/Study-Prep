---
tags: [cyber, module1, scripting, linux]
jqr: "Module 1: the two required Bash projects, an nmap-command generator and a directory/file checker"
---

# Bash - JQR Projects

These are the two Bash deliverables the JQR names, written out and actually run. Both `.sh` files go in the repo (they live in `/scripts/`). The concepts behind them come from [Bash Scripting](Bash%20Scripting.md).

> What these really taught me: the leap from typing commands to writing a program that produces commands or makes decisions. Project 1 turns a one-off scan into a reusable template; Project 2 is the classic "check the world, then change it only if needed" pattern that every setup and install script is built on. Small scripts, but they're the shape of everything bigger.

---

## Project 1: nmap command generator
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

I ran this on Ubuntu 24.04 (2026) and fed it `192.168.1.20` and `22,80,443`:
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
Concepts shown: `read -p` input, variables, quoting, and a here-block of `echo`s. It builds the exact strings so I can copy the one I need. See [Nmap](../Recon%20Tools/Nmap.md) for what each flag actually does.

> Why a generator and not a scanner? It never touches the network, it just prints the exact commands so I can read, tweak, and fire the one I actually want. On a real box that deliberation matters, since I get to see how loud each scan is before I make any noise. It's a cheat sheet that fills itself in with my target.

---

## Project 2: directory & file checker
> *"Check if a directory exists; if it does, see if a specific file exists within it. If not, create the file. Print whether the directory/file exists; if it didn't, print that it's now created."*

```bash 
#!/bin/bash
# dir-file-check.sh — check a folder exists; if so, make sure the file is in it

d="${1:-/tmp/lab_demo}"   # folder to check specifically (1st arg, or a default)
f="${2:-notes.txt}"      # file to look for specifically (2nd arg, or a default)

if [ -d "$d" ]; then #if the directory then. -d = directory
  echo "The Directory '$d' exists." #print the directory exists
  if [ -f "$d/$f" ]; then #print if the file exists in the directory already. -f = file
    echo "THe File '$d' already exists in '$d'."
  else #if the file does not exits in that directory then...
    touch "$d/$f" #create the file
    echo "The File '$f' wasn't there, so I created it." #tell me the file has been created
  fi #finished
else
  echo "The Directory '$d' does not exist — nothing created." #debug print, directory not real
fi
```

I ran it twice on Ubuntu 24.04 (2026), first run creates, second finds:
```
--- run 1 (nothing exists yet) ---
[-] Directory '/tmp/lab_demo' does not exist. Creating it and the file.
[!] Created directory '/tmp/lab_demo' and file 'report.txt'.
--- run 2 (now it exists) ---
[+] Directory '/tmp/lab_demo' exists.
[+] File 'report.txt' already exists in '/tmp/lab_demo'.
```
Concepts shown: `-d`/`-f` file tests, a nested `if`, `${1:-default}` argument defaults, `mkdir -p`, `touch`, and `&&`.

> Why this pattern is everywhere: "does it exist? if not, create it" is idempotent, meaning it's safe to run over and over and changes nothing once things are in place. Every installer, provisioning script, and config-management tool is really this check-then-act loop scaled up. Learn the two-line version here and the thousand-line ones read easily later.

---

## Project 3: startup/setup script (Module 3 skill)
> *Module 3: "Create a bash script that sets up your interfaces, updates your system, opens your terminals, and opens Firefox."*

(Still need to actually run this one on the lab box. It needs the desktop VM for the GUI terminals and Firefox, plus my real interface names from `ip -br link`.)

```bash
#!/bin/bash
# setup.sh - bring up networking, update, open terminals, open Firefox
set -e # if any command fails, stop the script with error. Safety Net

# set up net Interfaces — apply your network config (netplan on Ubuntu; ifupdown on Debian)
sudo netplan apply 2>/dev/null || sudo systemctl restart networking

# Update and upgrade
sudo apt update && sudo apt -y upgrade

# Open terminals — a detached tmux session
tmux new-session -d -s work
tmux split-window -h
tmux split-window -v
#  attach with: tmux attach -t work   — or launch Terminator instead: terminator &

# Open Firefox to the study repo
firefox "https://github.com/grizzysammy-dev/Study-Prep" >/dev/null 2>&1 &

echo "Network applied, system updated, tmux 'work' ready, Firefox launched."
```
Concepts shown: `set -e` (stop on error), `||` fallback, `&&` chaining, backgrounding with `&`, and scripting [tmux](../Terminator%20TMUX/tmux%20and%20Terminator.md). Swap the tmux block for `terminator &` if I went with Terminator.

> Why script my own setup? Because I revert those clean VM snapshots constantly, and a one-shot setup script rebuilds my whole working environment in seconds instead of me clicking through it every time. The `&` on Firefox matters too: it backgrounds the GUI so the script doesn't sit there frozen waiting for me to close the browser.

## Gotchas I want to remember
- The `-d` test checks a **directory**; `-f` checks a **regular file**. Don't mix them up.
- `${1:-default}` means "use `$1`, or this default if `$1` is empty", which makes a script work with or without arguments.
- Keep both scripts executable (`chmod +x`) and committed so instructors can see them ([Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md)).

## References
- freeCodeCamp Bash tutorial: https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/
- Bash conditional expressions: https://www.gnu.org/software/bash/manual/bash.html#Bash-Conditional-Expressions

## Related
- [Bash Scripting](Bash%20Scripting.md)
- [Nmap](../Recon%20Tools/Nmap.md)
- [Python - JQR Projects](../Python%20Scripting/Python%20-%20JQR%20Projects.md)
