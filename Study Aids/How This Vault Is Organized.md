---
tags: [cyber, meta]
jqr: "How the vault is laid out and how to get around it"
---

# How This Vault Is Organized

## The layout
The folders are grouped **by tool and by topic**, which is how I actually reach for things on the box. If I need nmap I go to `Recon Tools`; iptables on CentOS lives in `IP Tables CentOS`. It follows the repo structure I set up, just filled in and tidied.

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

## What changed (and where my old stuff went)
Everything from the earlier layout got **moved, not deleted**. Any of the old auto-generated numbered folders (`00-06`) or empty starter folders I had lying around got moved into a `_OLD_repo_backup` folder **next to** the repo (outside it, so it doesn't clutter things or get pushed). I can delete that whenever I'm happy it's all safe.

| Old / starter folder | Now |
|---|---|
| `VM Set Up/Main Set Up.md` | `VM Set Up/VM Lab Setup.md` (my original notes kept inside) |
| `Bash Scripting/Vim and Github Setup.md` | split into `Vim/Vim.md` + `Git and GitHub/Git and GitHub.md` (originals kept) |
| `Recon Tools/{Nmap,Netcat,TCPDUMP}/` subfolders | flattened to `Recon Tools/*.md` |
| `Knowledge Req/*` subfolders | flattened to `Knowledge Req/*.md` |
| `Exploit and Priv Esc Teq`, `Enum Tools and teq` | `Knowledge Req/Privilege Escalation Concepts.md`, `Enumeration Tools.md` |

## Reading a note
Each note is built to be understood, not just copied. They open with plain English on why the thing exists and the mental model, then the handful of commands or facts I actually need to remember, then the commands themselves with a note on what each one does and what the output means. After that come the exam traps and gotchas, and the official sources at the bottom.

When you see real output pasted into a note, that means I actually ran it and grabbed what came back. When something's only correct per the current docs and I haven't run it myself yet, I say so in plain words. Usually that means it needs my Windows VM, a second host, or root.

## GitHub vs Obsidian
- **GitHub** (open-book exam): start at the [README](../README.md) and every link clicks through. GitHub doesn't render Obsidian `[[wikilinks]]` or dataview, so I made every link in this vault a normal Markdown link that works in both places.
- **Obsidian:** graph view, Omnisearch, and the [Master Index](Master%20Index%20%28MOC%29.md).

## Pushing
I edit in Obsidian, then run **Obsidian Git: commit-and-sync** (gitpush). Keep the repo **public** (that's a JQR requirement), and never commit keys, tokens, or `_loot/` (the `.gitignore` covers those). See [Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md).
