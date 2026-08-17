# JCU Cyber Candidate — Study Vault

My study notes for the **Joint Communications Unit (JCU) Cyber Candidate JQR**. Organized by tool and topic (the way I built the repo), so I can jump straight to the thing I'm working on. Built in [Obsidian](https://obsidian.md), synced here so it's readable during prep and open-book work — when the only thing I can pull up is this public repo.

> **Fast start:** open the **[Command Cheat Sheet](Study%20Aids/Command%20Cheat%20Sheet.md)** and **[Exam-Day Quick Reference](Study%20Aids/Exam-Day%20Quick%20Reference.md)**. Track what I can actually *do* in the **[JQR Progress Checklist](Study%20Aids/JQR%20Progress%20Checklist.md)**.

**How the notes are written:** every note leads with a plain-English *why this exists / how it works* before any commands, then commands each with a `→ what it does` line. **Legend:** ✅ = output I actually ran and captured · 🧪 = correct per current docs, run it on your lab to confirm.

---

## Study Aids
- [Master Index](Study%20Aids/Master%20Index%20%28MOC%29.md) — every note in one map
- [JQR Progress Checklist](Study%20Aids/JQR%20Progress%20Checklist.md) — every requirement as a checkbox
- [Exam-Day Quick Reference](Study%20Aids/Exam-Day%20Quick%20Reference.md) · [Command Cheat Sheet](Study%20Aids/Command%20Cheat%20Sheet.md)
- [How This Vault Is Organized](Study%20Aids/How%20This%20Vault%20Is%20Organized.md) · [References and Sources](Study%20Aids/References%20and%20Sources.md)

## Setup & Fundamentals
- [VM Set Up → VM Lab Setup](VM%20Set%20Up/VM%20Lab%20Setup.md)
- [Bash Scripting](Bash%20Scripting/Bash%20Scripting.md) · [Bash - JQR Projects](Bash%20Scripting/Bash%20-%20JQR%20Projects.md)
- [Python Scripting](Python%20Scripting/Python%20Scripting.md) · [Python - JQR Projects](Python%20Scripting/Python%20-%20JQR%20Projects.md)
- [Vim](Vim/Vim.md) · [Git and GitHub](Git%20and%20GitHub/Git%20and%20GitHub.md) · [RegEx](RegEx/RegEx.md) · [Terminator / tmux](Terminator%20TMUX/tmux%20and%20Terminator.md)

## Recon & Remote Access
- **Recon Tools:** [Nmap](Recon%20Tools/Nmap.md) · [Netcat](Recon%20Tools/Netcat.md) · [Tcpdump](Recon%20Tools/Tcpdump.md)
- **SSH Kali:** [SSH – Tunneling & Jump Hosts](SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) · [SCP](SSH%20Kali/SCP.md) · [Chisel](SSH%20Kali/Chisel.md)
- **VPN tunnels:** [OpenVPN](OpenVPN%20Wireguard/OpenVPN.md) · [WireGuard](OpenVPN%20Wireguard/WireGuard.md)

## Linux
- [IP Tables CentOS → iptables](IP%20Tables%20CentOS/iptables.md)
- **Linux Admin:** [Logs & journalctl](Linux%20Admin/Logs%20and%20journalctl.md) · [Interfaces, IPs & Routing](Linux%20Admin/Interfaces%20IPs%20and%20Routing.md) · [Package Management](Linux%20Admin/Package%20Management.md) · [Files, Search & Permissions](Linux%20Admin/Files%20Search%20and%20Permissions.md) · [Processes & systemd](Linux%20Admin/Processes%20and%20systemd.md) · [Disks, Mounts & fstab](Linux%20Admin/Disks%20Mounts%20and%20fstab.md) · [chroot & Python venv](Linux%20Admin/chroot%20and%20Python%20venv.md) · [cron](Linux%20Admin/cron.md) · [rsyslog Remote Logging](Linux%20Admin/rsyslog%20Remote%20Logging.md) · [OSI Model](Linux%20Admin/OSI%20Model.md) · [Linux Filesystem (FHS)](Linux%20Admin/Linux%20Filesystem%20%28FHS%29.md)

## Windows — Win Admin
- [Windows CLI & net Commands](Win%20Admin/Windows%20CLI%20and%20net%20Commands.md) · [PowerShell Essentials](Win%20Admin/PowerShell%20Essentials.md) · [Networking & Interfaces](Win%20Admin/Windows%20Networking%20and%20Interfaces.md) · [Firewall](Win%20Admin/Windows%20Firewall.md) · [icacls & Permissions](Win%20Admin/icacls%20and%20Permissions.md) · [PsExec & Sysinternals](Win%20Admin/PsExec%20and%20Sysinternals.md) · [Logs & Scheduled Tasks](Win%20Admin/Windows%20Logs%20and%20Scheduled%20Tasks.md) · [Processes & System Info](Win%20Admin/Windows%20Processes%20and%20System%20Info.md)

## Exploitation — C2 Frameworks / Metasploit
- [Metasploit Workflow](C2%20Frameworks/Metasploit/Metasploit%20Workflow.md) · [MSFvenom](C2%20Frameworks/Metasploit/MSFvenom.md) · [Meterpreter](C2%20Frameworks/Metasploit/Meterpreter.md) · [SMB, PsExec & DCOM](C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)

## Knowledge Requirements — Knowledge Req
- [Cyber Kill Chain](Knowledge%20Req/Cyber%20Kill%20Chain.md) · [Common Software Vulnerabilities](Knowledge%20Req/Common%20Software%20Vulnerabilities.md) · [Zero-Day Exploits](Knowledge%20Req/Zero-Day%20Exploits.md) · [Pivoting & Tunneling](Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- [Enumeration Tools](Knowledge%20Req/Enumeration%20Tools.md) · [Privilege Escalation Concepts](Knowledge%20Req/Privilege%20Escalation%20Concepts.md) · [Vulnerability Sources (CVE/CWE/MITRE)](Knowledge%20Req/Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md) · [Network Security Devices](Knowledge%20Req/Network%20Security%20Devices.md)
- [DevOps Testing Automation](Knowledge%20Req/DevOps%20Testing%20Automation.md) · [Cellular Technologies](Knowledge%20Req/Cellular%20Technologies.md) · [802.11 Wireless](Knowledge%20Req/802.11%20Wireless.md)

---

*Runnable scripts live in [`/scripts`](scripts). Notes marked ✅ include output tested in a current Linux environment; sources are listed at the bottom of each note and consolidated in [References and Sources](Study%20Aids/References%20and%20Sources.md).*
