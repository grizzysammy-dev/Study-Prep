---
tags: [jcu, moc]
jqr: "Map of Content — every note, grouped by the repo's tool/topic folders"
---

# Master Index

Every note in the vault, grouped by folder. On **GitHub** the repo [README](../README.md) is the same map and always renders on the landing page. In **Obsidian**, the dataview list at the bottom auto-updates as you add notes.

## Study Aids
[JQR Progress Checklist](JQR%20Progress%20Checklist.md) · [Exam-Day Quick Reference](Exam-Day%20Quick%20Reference.md) · [Command Cheat Sheet](Command%20Cheat%20Sheet.md) · [How This Vault Is Organized](How%20This%20Vault%20Is%20Organized.md) · [References and Sources](References%20and%20Sources.md)

## Setup & Fundamentals
[VM Lab Setup](../VM%20Set%20Up/VM%20Lab%20Setup.md) · [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md) · [Bash - JQR Projects](../Bash%20Scripting/Bash%20-%20JQR%20Projects.md) · [Python Scripting](../Python%20Scripting/Python%20Scripting.md) · [Python - JQR Projects](../Python%20Scripting/Python%20-%20JQR%20Projects.md) · [Vim](../Vim/Vim.md) · [Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md) · [RegEx](../RegEx/RegEx.md) · [tmux and Terminator](../Terminator%20TMUX/tmux%20and%20Terminator.md)

## Recon Tools
[Nmap](../Recon%20Tools/Nmap.md) · [Netcat](../Recon%20Tools/Netcat.md) · [Tcpdump](../Recon%20Tools/Tcpdump.md)

## SSH Kali (remote access & tunneling)
[SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) · [SCP](../SSH%20Kali/SCP.md) · [Chisel](../SSH%20Kali/Chisel.md)

## OpenVPN Wireguard
[OpenVPN](../OpenVPN%20Wireguard/OpenVPN.md) · [WireGuard](../OpenVPN%20Wireguard/WireGuard.md)

## IP Tables CentOS
[iptables](../IP%20Tables%20CentOS/iptables.md)

## Linux Admin
[Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md) · [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md) · [Package Management](../Linux%20Admin/Package%20Management.md) · [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md) · [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md) · [Disks Mounts and fstab](../Linux%20Admin/Disks%20Mounts%20and%20fstab.md) · [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md) · [cron](../Linux%20Admin/cron.md) · [rsyslog Remote Logging](../Linux%20Admin/rsyslog%20Remote%20Logging.md) · [OSI Model](../Linux%20Admin/OSI%20Model.md) · [Linux Filesystem (FHS)](../Linux%20Admin/Linux%20Filesystem%20%28FHS%29.md)

## Win Admin
[Windows CLI and net Commands](../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md) · [PowerShell Essentials](../Win%20Admin/PowerShell%20Essentials.md) · [Windows Networking and Interfaces](../Win%20Admin/Windows%20Networking%20and%20Interfaces.md) · [Windows Firewall](../Win%20Admin/Windows%20Firewall.md) · [icacls and Permissions](../Win%20Admin/icacls%20and%20Permissions.md) · [PsExec and Sysinternals](../Win%20Admin/PsExec%20and%20Sysinternals.md) · [Windows Logs and Scheduled Tasks](../Win%20Admin/Windows%20Logs%20and%20Scheduled%20Tasks.md) · [Windows Processes and System Info](../Win%20Admin/Windows%20Processes%20and%20System%20Info.md)

## C2 Frameworks / Metasploit
[Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md) · [MSFvenom](../C2%20Frameworks/Metasploit/MSFvenom.md) · [Meterpreter](../C2%20Frameworks/Metasploit/Meterpreter.md) · [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)

## Knowledge Req
[Cyber Kill Chain](../Knowledge%20Req/Cyber%20Kill%20Chain.md) · [Common Software Vulnerabilities](../Knowledge%20Req/Common%20Software%20Vulnerabilities.md) · [Zero-Day Exploits](../Knowledge%20Req/Zero-Day%20Exploits.md) · [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md) · [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md) · [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md) · [Vulnerability Sources (CVE CWE MITRE)](../Knowledge%20Req/Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md) · [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md) · [DevOps Testing Automation](../Knowledge%20Req/DevOps%20Testing%20Automation.md) · [Cellular Technologies](../Knowledge%20Req/Cellular%20Technologies.md) · [802.11 Wireless](../Knowledge%20Req/802.11%20Wireless.md)

---
> [!note] Obsidian-only: live list of every note
> ```dataview
> LIST
> FROM !"Study Aids" AND !".obsidian"
> WHERE file.name != "README"
> SORT file.folder ASC, file.name ASC
> ```
> (On GitHub this shows as a code block — use the groups above.)
