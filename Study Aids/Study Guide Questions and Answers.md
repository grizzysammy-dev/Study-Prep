---
tags: [cyber, qa, examprep]
jqr: "Direct basic answers to every question embedded in the study guide (Modules 1-3)"
---

# Study Guide Questions & Answers

Every "what is… / how do you… / describe…" question the study guide asks, with a short basic answer. Each group links to the full note if you want the deeper version.

## Bash basics (Module 1)
- **`date`** — prints the current date/time. · **`pwd`** — prints the directory you're in. · **`ls`** — lists a directory's contents (`ls -la` = long + hidden).
- **`cat`** — prints/joins file contents. · **`echo`** — prints text/variables. · **`which`** — shows the full path a command runs from.
- **`vi`/`vim`** — the built-in terminal editor. · **`bash`** — the shell itself (also runs a script: `bash x.sh`).
- **What is `#!/bin/bash`?** — the *shebang*: the first line telling the OS which interpreter runs the script.
- **What is `.sh`?** — the conventional extension for a shell script (convention only, not required).

→ Full: [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md)

## Module 2 — Knowledge ("describe/explain")
- **Cyber kill chain** — Lockheed Martin's 7 stages of an intrusion: Recon → Weaponization → Delivery → Exploitation → Installation → Command & Control → Actions on Objectives. Break any one link and you disrupt the whole attack. → [Cyber Kill Chain](../Knowledge%20Req/Cyber%20Kill%20Chain.md)
- **Enumeration tools & techniques** — actively listing a target's users, shares, services and versions before attacking ("casing the building"). Tools: `nmap`, `enum4linux-ng` (SMB), WinPEAS/WindowsEnum/JAWS. → [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md)
- **Exploitation & privilege escalation** — exploitation = getting *initial* code execution (Metasploit, ExploitDB/`searchsploit`, `msfvenom`); privesc = going from low user to root/SYSTEM (PEASS-ng; Linux SUID/sudo via GTFOBins; Windows unquoted-service-paths/token abuse via LOLBAS). → [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md)
- **Zero-day exploit** — an exploit for a vuln the vendor doesn't know about / hasn't patched ("zero days to fix"). After disclosure+patch it becomes an "n-day." → [Zero-Day Exploits](../Knowledge%20Req/Zero-Day%20Exploits.md)
- **Common software vulnerabilities** — memory-corruption bugs (buffer/stack/heap overflow, use-after-free) and input-handling bugs (SQL injection, command injection, XSS, path traversal). Mapped to OWASP Top 10 (2025) + CWE. → [Common Software Vulnerabilities](../Knowledge%20Req/Common%20Software%20Vulnerabilities.md)
- **Pivoting & tunneling** — using a compromised host to reach networks you can't touch directly (pivot), by wrapping your traffic inside another protocol (tunnel). Tools: SSH (`-L`/`-R`/`-D`), iptables NAT, OpenVPN, WireGuard, Chisel. → [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- **Sources — current & emerging tech** — NIST, IEEE, arXiv (cs.CR), DARPA, vendor research blogs, DEF CON/Black Hat talks. → [Vulnerability Sources (CVE CWE MITRE)](../Knowledge%20Req/Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md)
- **Sources — vuln research / novel vectors** — Google Project Zero, Zero Day Initiative (ZDI), Exploit-DB, PortSwigger Research, vendor PSIRTs, GitHub Security Advisories.
- **Sources — list vulnerabilities (CVE, CCE)** — CVE (cve.org) / NVD (nvd.nist.gov) for specific vulns; CCE for configuration issues; CWE for weakness classes; CVSS for scoring; CISA KEV for actively-exploited ones.
- **Sources — mitigations** — MITRE ATT&CK mitigations, CISA advisories, vendor patches/bulletins, CIS Benchmarks, NIST guidance.
- **Network security devices + detection/prevention** — Firewall (filters by IP/port, stateful), IDS/IPS (detect/block by signature or anomaly), EDR/XDR (endpoint behavior monitoring + response), **PSP** = *Personal Security Product* (host AV/endpoint protection). Detection = signature vs anomaly/behavioral; prevention = segmentation, allow/deny-listing, patching. → [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md)
- **DevOps testing automation — benefits & challenges** — CI/CD auto-runs tests on every change. Benefits: speed, repeatability, early bug/vuln catch ("shift-left"), consistency. Challenges: pipeline complexity, flaky tests, false positives, and the pipeline becomes a high-value target (holds secrets). → [DevOps Testing Automation](../Knowledge%20Req/DevOps%20Testing%20Automation.md)
- **Cellular technologies** — generations 1G→5G (GSM/CDMA=2G, UMTS=3G, LTE=4G, 5G NR); SIM/**IMSI** = subscriber identity, **IMEI** = device serial; towers = eNodeB (4G)/gNodeB (5G). Threats: IMSI catchers (Stingrays), SS7 weaknesses. → [Cellular Technologies](../Knowledge%20Req/Cellular%20Technologies.md)
- **802.11 wireless** — the Wi-Fi standard family: a/b/g/n/ac/ax (Wi-Fi 6)/be (Wi-Fi 7) across 2.4/5/6 GHz. Security evolved WEP (broken) → WPA/WPA2 → WPA3; deauth attacks abuse unprotected management frames. → [802.11 Wireless](../Knowledge%20Req/802.11%20Wireless.md)

## Module 3 — Linux logs (→ [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md))
- **What is `dmesg` for?** — shows the kernel ring buffer: boot and hardware/driver messages (e.g., a disk you just plugged in). Volatile — clears on reboot.
- **What is `syslog` for?** — the standard system logging service/format; collects general system + application messages (Debian/Ubuntu: `/var/log/syslog`).
- **What is `wtmp`?** — a binary log of login/logout history; read it with `last`.
- **What is `btmp`?** — a binary log of *failed* login attempts; read it with `lastb`.
- **What is `auth.log`?** — authentication events (logins, `sudo`, `sshd`) on Debian/Ubuntu (`/var/log/auth.log`); on RHEL/CentOS the equivalent is `/var/log/secure`.

## Module 3 — Interfaces, connections, packages
- **Two ways to show interfaces** — `ip addr` (or `ip link`) — modern; and `ifconfig` — legacy (net-tools). Quick view: `ip -br addr`. → [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
- **netstat/ss — what the output means** — each row is a socket: protocol, local address:port, peer address:port, and **state** (`LISTEN` = waiting for connections; `ESTABLISHED` = active connection). `ss -tulpn` also shows the owning process. → [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md)
- **How to specify open files by user** — `lsof -u <username>` (and `lsof -i` for network files).
- **Download but not install a package** — `apt download <pkg>` (Debian) or `dnf download <pkg>` (RHEL) — fetches the `.deb`/`.rpm` without installing. → [Package Management](../Linux%20Admin/Package%20Management.md)
- **What is `dpkg` and how do you use it?** — Debian's low-level package tool: `dpkg -i file.deb` (install), `-l` (list installed), `-L pkg` (files a pkg placed), `-S /path` (which pkg owns a file). `apt` is the higher-level front-end over it.
- **Install an rpm** — `sudo rpm -ivh file.rpm`, or `sudo dnf install ./file.rpm` to auto-resolve dependencies.
- **Install a .deb** — `sudo dpkg -i file.deb` then `sudo apt -f install` to fix deps — or just `sudo apt install ./file.deb`.
- **Install a pip package** — `pip install <pkg>`, but in 2026 do it inside a **venv** (PEP 668 blocks bare system pip); `pipx` for standalone apps.
- **What is a `.whl` file?** — a Python "wheel": a pre-built package that installs fast because nothing has to be compiled.
- **Where do apt/yum find repos?** — apt: `/etc/apt/sources.list` + `/etc/apt/sources.list.d/` (newer `.sources` deb822 format). yum/dnf: `/etc/yum.repos.d/*.repo`.

## Module 3 — Disks, recovery, environments (→ [Disks Mounts and fstab](../Linux%20Admin/Disks%20Mounts%20and%20fstab.md), [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md))
- **`chroot` — when to use it** — changes a process's apparent root `/`. Use it to repair/recover a broken install from a live USB, or to confine a process to a directory subtree.
- **Python `venv` — when to use it** — an isolated environment so a project's pip packages don't collide with the system or other projects; use it for any project with dependencies.
- **`parted` / `gparted` — when to use them** — to create/resize/delete disk partitions. `parted` = CLI (scriptable, works over SSH); `gparted` = GUI (visual, safer to eyeball). Use when adding a disk or repartitioning.
- **What is `/etc/fstab` for?** — the table of filesystems to mount automatically at boot (device/UUID → mount point, type, options). Add `_netdev` for network shares so they wait for the network.
- **What is `fsck`'s purpose?** — checks and repairs a filesystem's integrity (inodes, directory structure). Run it on an **unmounted** filesystem, usually after an unclean shutdown.

## Module 3 — man pages, systemd, permissions, filesystem
- **The different man page types** — 8 sections: 1 user commands, 2 syscalls, 3 library funcs, 4 devices, 5 file formats/config, 6 games, 7 misc/overviews, 8 admin. e.g. `man 5 passwd` (file) vs `man 1 passwd` (command). → [Linux Filesystem (FHS)](../Linux%20Admin/Linux%20Filesystem%20%28FHS%29.md)
- **Where a command runs from** — `which ls`, `type ls`, or `command -v ls`.
- **Other binaries related to a binary** — `whereis ls` (binary + source + man page).
- **Where systemctl config files live** — unit files in `/etc/systemd/system` (your overrides), `/lib/systemd/system` and `/usr/lib/systemd/system` (packages). Run `systemctl daemon-reload` after editing. → [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md)
- **What is systemd?** — the modern init system (PID 1) and service manager: it boots the machine and starts/stops/monitors services ("units").
- **What is `777`?** — full permissions for everyone: `rwx` for owner, group, and other (r=4, w=2, x=1 → 7=rwx). Risky: anyone can read/write/execute. → [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
- **What is `drwxr-xr-x`?** — a **d**irectory where owner=`rwx`, group=`r-x`, other=`r-x` (that's `755`). The first char is the type (`d`=dir, `-`=file, `l`=symlink).
- **General Linux file structure** — `/` root; `/etc` config; `/home` users; `/root` root's home; `/var` logs+variable data; `/tmp` scratch; `/bin`+`/usr/bin` user binaries; `/sbin`+`/usr/sbin` system binaries; `/opt` optional add-on software; `/lib` libraries; `/proc`+`/sys` live kernel state; `/dev` devices; `/boot` kernel+bootloader.

## Module 3 — networking concepts
- **telnet — use case & limitations** — connect to a text service to test it / grab a banner (`telnet host 25`). Limitations: **no encryption** (cleartext — unsafe for logins, SSH replaced it) and no real file transfer. → [Netcat](../Recon%20Tools/Netcat.md)
- **OSI model — protocols/services per layer** — L1 Physical (cables, hubs); L2 Data Link (MAC, switches, Ethernet/ARP); L3 Network (IP, routers, ICMP); L4 Transport (TCP/UDP, ports); L5 Session; L6 Presentation (encryption/encoding — TLS, JPEG); L7 Application (HTTP, DNS, SSH, SMTP). → [OSI Model](../Linux%20Admin/OSI%20Model.md)
- **What is SSH (and WinSCP)?** — Secure Shell: an encrypted protocol for remote login, command execution, tunneling, and file transfer (scp/sftp). WinSCP is a Windows GUI client for SCP/SFTP over SSH. → [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)

## Module 3 — Windows
- **Windows log categories (what each is)** — Event Viewer: **Application** (app events/errors), **Security** (audit success/failure, logons 4624 / failed 4625), **System** (OS, drivers, services), **Setup** (install/upgrade), **Forwarded Events** (collected from other machines). → [Windows Logs and Scheduled Tasks](../Win%20Admin/Windows%20Logs%20and%20Scheduled%20Tasks.md)

## Related
- [Master Index](Master%20Index%20%28MOC%29.md) · [JQR Progress Checklist](JQR%20Progress%20Checklist.md) · [Command Cheat Sheet](Command%20Cheat%20Sheet.md)
