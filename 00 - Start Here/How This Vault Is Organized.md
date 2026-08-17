---
tags: [jcu, meta]
jqr: "Orientation — how the vault is structured and how to navigate it"
---

# How This Vault Is Organized

## The structure
Notes are grouped into **numbered sections** that follow the JQR's own shape, so the folder order = the order you'd study/answer in:

| Folder | Covers | JQR |
|---|---|---|
| `00 - Start Here` | index, checklist, cheat sheets | — |
| `01 - Fundamentals` | VMs, Bash, Python, Vim, tmux, RegEx, Git | Module 1 |
| `02 - Recon and Network Tools` | nmap, netcat, tcpdump, ssh, scp, VPNs | Module 1 |
| `03 - Linux Skills` | logs, packages, files/perms, processes, disks, networking, iptables | Module 3 |
| `04 - Windows Skills` | net cmds, PowerShell, firewall, icacls, PsExec, logs | Module 3 |
| `05 - Metasploit and Exploitation` | msfconsole, msfvenom, meterpreter, SMB/PsExec, enum, privesc | Modules 1 & 3 |
| `06 - Knowledge Requirements` | kill chain, vulns, zero-days, tunneling, sources, wireless/cellular | Module 2 |

## What changed from my old layout
I kept everything and reorganized it so it's faster to find things:

| Old folder | Now lives in |
|---|---|
| `Bash Scripting/` | `01 - Fundamentals` (Bash Scripting + Bash - JQR Projects) |
| `VM Set Up/` | `01 - Fundamentals/VM Lab Setup` |
| `Recon Tools/` (Nmap, Netcat, TCPDUMP) | `02 - Recon and Network Tools` |
| `SSH Kali/`, `OpenVPN Wireguard/` | `02 - Recon and Network Tools` |
| `IP Tables CentOS/` | `03 - Linux Skills/iptables` |
| `Knowledge Req/` (kill chain, vulns, enum, privesc, pivoting, zero-days) | `05` and `06` |
| `C2 Frameworks/Metasploit/` | `05 - Metasploit and Exploitation` |
| `Win Admin/`, `Python Scripting/`, `RegEx/`, `Terminator TMUX/` | their numbered homes above |

The old empty folders don't show on GitHub (git ignores empty dirs), so the repo now shows only the numbered structure.

## Navigating on GitHub vs Obsidian
- **On GitHub** (what I'll have in the exam): start at the repo **[README](../README.md)** — every link there is clickable. Or use GitHub's file tree. GitHub does **not** render Obsidian `[[wikilinks]]` or dataview, which is why the README/index use normal Markdown links.
- **In Obsidian:** use the graph, search (Omnisearch), and the `[[wikilinks]]` in each note's **Related** section. The [Master Index (MOC)](Master%20Index%20%28MOC%29.md) has an auto-updating dataview list.

## Reading a note
Every note follows the same shape so you can skim fast:
1. **TL;DR** — the few commands/facts you must remember.
2. **Concept** — plain-English explanation.
3. **Task sections** — commands with a `→ what it does` line each.
4. **Exam tips & gotchas** — the traps.
5. **References** — official sources.

**Callouts:** `✅ Tested output` = I actually ran it and pasted real output. `🧪 Run this on your lab` = correct per current docs but needs your Windows VM / a second host / root, so confirm on your box.

## Pushing updates
Edit in Obsidian → **Obsidian Git: Commit-and-sync** (gitpush) → it appears on GitHub. See [Git and GitHub](../01%20-%20Fundamentals/Git%20and%20GitHub.md). Keep the repo **public** (JQR requirement) and never commit keys/tokens/`_loot/`.

## Related
- [Master Index (MOC)](Master%20Index%20%28MOC%29.md)
- [JQR Progress Checklist](JQR%20Progress%20Checklist.md)
- [Git and GitHub](../01%20-%20Fundamentals/Git%20and%20GitHub.md)
