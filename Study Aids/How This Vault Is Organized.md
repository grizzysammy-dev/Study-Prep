---
tags: [cyber, meta]
jqr: "Orientation — how the vault is laid out and how to navigate it"
---

# How This Vault Is Organized

## The idea
Folders are grouped **by tool and by topic** — the way you actually reach for things on the box ("I need nmap" → `Recon Tools`; "iptables on CentOS" → `IP Tables CentOS`). It follows the repo structure you set up, filled in and tidied.

| Folder | What's in it |
|---|---|
| `Study Aids` | index, JQR checklist, cheat sheet, exam quick-ref, references |
| `VM Set Up` | the lab: which VMs, how they're networked, snapshots |
| `Bash Scripting` · `Python Scripting` | language notes + the graded JQR project scripts |
| `Vim` · `Git and GitHub` · `RegEx` · `Terminator TMUX` | fundamentals, one tool each |
| `Recon Tools` | nmap, netcat, tcpdump |
| `SSH Kali` | ssh (tunnels/jump), scp, chisel |
| `OpenVPN Wireguard` | the two VPN tunnels between VMs |
| `IP Tables CentOS` | the Linux host firewall + NAT project |
| `Linux Admin` | the Module-3 Linux skills (logs, packages, files/perms, processes, disks, interfaces/routing, rsyslog, OSI, FHS) |
| `Win Admin` | Windows CLI, PowerShell, firewall, icacls, PsExec, logs, processes |
| `C2 Frameworks/Metasploit` | msfconsole workflow, msfvenom, meterpreter, SMB/PsExec/DCOM |
| `Knowledge Req` | the "describe/explain" topics: kill chain, vulns, zero-days, pivoting, enum, privesc, sources, netsec devices, DevOps, cellular, 802.11 |

## What changed (and where your old stuff went)
Everything from the earlier layout was **moved, not deleted**. If you kept the earlier auto-generated numbered folders (`00–06`) or empty starter folders, they were moved to a `_OLD_repo_backup` folder **next to** the repo (outside it, so they don't clutter or get pushed) — delete that whenever you're happy.

| Old / starter folder | Now |
|---|---|
| `VM Set Up/Main Set Up.md` | `VM Set Up/VM Lab Setup.md` (your original notes kept inside) |
| `Bash Scripting/Vim and Github Setup.md` | split into `Vim/Vim.md` + `Git and GitHub/Git and GitHub.md` (originals kept) |
| `Recon Tools/{Nmap,Netcat,TCPDUMP}/` subfolders | flattened to `Recon Tools/*.md` |
| `Knowledge Req/*` subfolders | flattened to `Knowledge Req/*.md` |
| `Exploit and Priv Esc Teq`, `Enum Tools and teq` | `Knowledge Req/Privilege Escalation Concepts.md`, `Enumeration Tools.md` |

## Reading a note
Each note is built to be understood, not just copied:
1. **Why this exists / mental model** — plain English first.
2. **TL;DR** — the few commands/facts you must remember.
3. **Task sections** — each command has a `→ what it does / what the output means` line.
4. **Exam tips & gotchas** — the traps.
5. **References** — official sources.

**Callouts:** `✅ Tested output` = actually run, real output pasted. `🧪 Run this on your lab` = correct per current docs, needs your Windows VM / a second host / root.

## GitHub vs Obsidian
- **GitHub** (open-book exam): start at the [README](../README.md) — all links click. GitHub doesn't render Obsidian `[[wikilinks]]` or dataview, so every link in this vault is a normal Markdown link that works in both places.
- **Obsidian:** graph view, Omnisearch, and the [Master Index](Master%20Index%20%28MOC%29.md).

## Pushing
Edit in Obsidian → **Obsidian Git: commit-and-sync** (gitpush). Keep the repo **public** (JQR requirement); never commit keys/tokens/`_loot/` (the `.gitignore` covers them). See [Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md).
