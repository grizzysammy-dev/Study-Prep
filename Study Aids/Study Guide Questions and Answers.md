---
tags: [cyber, qa, examprep]
jqr: "Direct basic answers to every question embedded in the study guide (Modules 1-3)"
---

# Study Guide Questions & Answers

Every "what is / how do you / describe" question the study guide throws at me, with a short answer for each. Each group links out to the full note when I want the deeper version.

## Bash basics (Module 1)
- **`date`** prints the current date/time. · **`pwd`** prints the directory I'm in. · **`ls`** lists what's in a directory (`ls -la` is long + hidden).
- **`cat`** prints or joins file contents. · **`echo`** prints text/variables. · **`which`** shows the full path a command runs from.
- **`vi`/`vim`** is the built-in terminal editor. · **`bash`** is the shell itself (and it runs a script: `bash x.sh`).
- **What's `#!/bin/bash`?** The *shebang*: the first line that tells the OS which interpreter runs the script.
- **What's `.sh`?** Just the conventional extension for a shell script. It's convention only, not required.

Full note: [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md)

## Module 2: Knowledge ("describe/explain")
- **Cyber kill chain**: Lockheed Martin's 7 stages of an intrusion, Recon → Weaponization → Delivery → Exploitation → Installation → Command & Control → Actions on Objectives. The whole point is that if you break any one link you disrupt the entire attack. More in [Cyber Kill Chain](../Knowledge%20Req/Cyber%20Kill%20Chain.md).
- **Enumeration tools & techniques**: actively listing out a target's users, shares, services, and versions before I attack, basically casing the building. Tools I'd reach for: `nmap`, `enum4linux-ng` (SMB), and WinPEAS/WindowsEnum/JAWS. More in [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md).
- **Exploitation & privilege escalation**: exploitation is getting that *initial* code execution (Metasploit, ExploitDB/`searchsploit`, `msfvenom`). Privesc is climbing from a low user up to root or SYSTEM (PEASS-ng; on Linux, SUID/sudo tricks via GTFOBins; on Windows, unquoted service paths and token abuse via LOLBAS). More in [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md).
- **Zero-day exploit**: an exploit for a vuln the vendor doesn't even know about yet, or hasn't patched, so they've had zero days to fix it. Once it's disclosed and patched it turns into an "n-day." More in [Zero-Day Exploits](../Knowledge%20Req/Zero-Day%20Exploits.md).
- **Common software vulnerabilities**: two big buckets, memory-corruption bugs (buffer/stack/heap overflow, use-after-free) and input-handling bugs (SQL injection, command injection, XSS, path traversal). These map onto the OWASP Top 10 (2025) and CWE. More in [Common Software Vulnerabilities](../Knowledge%20Req/Common%20Software%20Vulnerabilities.md).
- **Pivoting & tunneling**: using a host I've already compromised to reach networks I can't touch directly (that's the pivot), by wrapping my traffic inside another protocol (the tunnel). Tools: SSH (`-L`/`-R`/`-D`), iptables NAT, OpenVPN, WireGuard, Chisel. More in [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md).
- **Sources for current & emerging tech**: NIST, IEEE, arXiv (cs.CR), DARPA, vendor research blogs, DEF CON/Black Hat talks. More in [Vulnerability Sources (CVE CWE MITRE)](../Knowledge%20Req/Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md).
- **Sources for vuln research / novel vectors**: Google Project Zero, Zero Day Initiative (ZDI), Exploit-DB, PortSwigger Research, vendor PSIRTs, GitHub Security Advisories.
- **Sources to list actual vulnerabilities (CVE, CCE)**: CVE (cve.org) and NVD (nvd.nist.gov) for specific vulns; CCE for configuration issues; CWE for weakness classes; CVSS for scoring; CISA KEV for the ones being actively exploited.
- **Sources for mitigations**: MITRE ATT&CK mitigations, CISA advisories, vendor patches and bulletins, CIS Benchmarks, NIST guidance.
- **Network security devices + detection/prevention**: firewall (filters by IP/port, stateful), IDS/IPS (detect or block by signature or anomaly), EDR/XDR (watches endpoint behavior and responds), and **PSP** which is a *Personal Security Product* (host AV/endpoint protection). Detection splits into signature vs anomaly/behavioral; prevention is segmentation, allow/deny-listing, and patching. More in [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md).
- **DevOps testing automation, benefits & challenges**: CI/CD auto-runs the tests on every change. Benefits are speed, repeatability, catching bugs and vulns early ("shift-left"), and consistency. Challenges: pipelines get complex, tests go flaky, false positives pile up, and the pipeline itself turns into a high-value target because it holds the secrets. More in [DevOps Testing Automation](../Knowledge%20Req/DevOps%20Testing%20Automation.md).
- **Cellular technologies**: the generations run 1G→5G (GSM/CDMA=2G, UMTS=3G, LTE=4G, 5G NR). SIM and **IMSI** are the subscriber identity, **IMEI** is the device serial; the towers are eNodeB on 4G and gNodeB on 5G. Threats worth knowing: IMSI catchers (Stingrays) and SS7 weaknesses. More in [Cellular Technologies](../Knowledge%20Req/Cellular%20Technologies.md).
- **802.11 wireless**: the Wi-Fi standard family, a/b/g/n/ac/ax (Wi-Fi 6)/be (Wi-Fi 7) across 2.4/5/6 GHz. Security evolved WEP (broken) → WPA/WPA2 → WPA3, and deauth attacks abuse the unprotected management frames. More in [802.11 Wireless](../Knowledge%20Req/802.11%20Wireless.md).

## Module 3: Linux logs ([Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md))
- **What's `dmesg` for?** It shows the kernel ring buffer: boot messages and hardware/driver stuff (like a disk I just plugged in). It's volatile, so it clears on reboot.
- **What's `syslog` for?** The standard system logging service and format; it collects general system and application messages (on Debian/Ubuntu that's `/var/log/syslog`).
- **What's `wtmp`?** A binary log of login/logout history; I read it with `last`.
- **What's `btmp`?** A binary log of *failed* login attempts; read that one with `lastb`.
- **What's `auth.log`?** Authentication events (logins, `sudo`, `sshd`) on Debian/Ubuntu, over at `/var/log/auth.log`. On RHEL/CentOS the equivalent is `/var/log/secure`.

## Module 3: Interfaces, connections, packages
- **Two ways to show interfaces**: `ip addr` (or `ip link`) is the modern one, and `ifconfig` is the legacy net-tools one. For a quick view I use `ip -br addr`. More in [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md).
- **netstat/ss, reading the output**: each row is a socket, so protocol, local address:port, peer address:port, and the **state** (`LISTEN` means it's waiting for connections; `ESTABLISHED` means an active connection). `ss -tulpn` also shows the process that owns it. More in [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md).
- **Open files by a specific user**: `lsof -u <username>` (and `lsof -i` for network files).
- **Download a package without installing it**: `apt download <pkg>` on Debian or `dnf download <pkg>` on RHEL. That grabs the `.deb`/`.rpm` and stops there. More in [Package Management](../Linux%20Admin/Package%20Management.md).
- **What's `dpkg` and how do I use it?** Debian's low-level package tool: `dpkg -i file.deb` (install), `-l` (list installed), `-L pkg` (files a pkg placed), `-S /path` (which pkg owns a file). `apt` is just the higher-level front-end sitting over it.
- **Install an rpm**: `sudo rpm -ivh file.rpm`, or `sudo dnf install ./file.rpm` if I want it to auto-resolve dependencies.
- **Install a .deb**: `sudo dpkg -i file.deb`, then `sudo apt -f install` to fix any deps. Or just skip ahead with `sudo apt install ./file.deb`.
- **Install a pip package**: `pip install <pkg>`, but these days I do it inside a **venv** since PEP 668 blocks bare system pip. `pipx` for standalone apps.
- **What's a `.whl` file?** A Python "wheel," a pre-built package that installs fast because nothing has to compile.
- **Where do apt/yum find their repos?** apt looks at `/etc/apt/sources.list` plus `/etc/apt/sources.list.d/` (the newer `.sources` deb822 format). yum/dnf uses `/etc/yum.repos.d/*.repo`.

## Module 3: Disks, recovery, environments ([Disks Mounts and fstab](../Linux%20Admin/Disks%20Mounts%20and%20fstab.md), [chroot and Python venv](../Linux%20Admin/chroot%20and%20Python%20venv.md))
- **`chroot`, when to use it**: it changes what a process sees as its root `/`. I'd use it to repair or recover a broken install from a live USB, or to box a process into a directory subtree.
- **Python `venv`, when to use it**: an isolated environment so one project's pip packages don't collide with the system or with other projects. Basically any project with dependencies gets one.
- **`parted` / `gparted`, when to use them**: creating, resizing, or deleting disk partitions. `parted` is the CLI (scriptable, works over SSH); `gparted` is the GUI (visual, easier to eyeball). Reach for either when adding a disk or repartitioning.
- **What's `/etc/fstab` for?** The table of filesystems to mount automatically at boot: it maps a device or UUID to a mount point, plus the type and options. Add `_netdev` for network shares so they wait for the network to come up.
- **What's `fsck` for?** It checks and repairs a filesystem's integrity (inodes, directory structure). Run it on an **unmounted** filesystem, usually after an unclean shutdown.

## Module 3: man pages, systemd, permissions, filesystem
- **The man page sections**: there are 8. 1 user commands, 2 syscalls, 3 library funcs, 4 devices, 5 file formats/config, 6 games, 7 misc/overviews, 8 admin. So `man 5 passwd` (the file) is different from `man 1 passwd` (the command). More in [Linux Filesystem (FHS)](../Linux%20Admin/Linux%20Filesystem%20%28FHS%29.md).
- **Where a command runs from**: `which ls`, `type ls`, or `command -v ls`.
- **Other binaries tied to a binary**: `whereis ls` gives the binary, source, and man page.
- **Where systemctl config files live**: unit files sit in `/etc/systemd/system` (my overrides), and `/lib/systemd/system` and `/usr/lib/systemd/system` (the package ones). Run `systemctl daemon-reload` after editing. More in [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md).
- **What's systemd?** The modern init system (PID 1) and service manager: it boots the machine and starts, stops, and monitors services (the "units").
- **What's `777`?** Full permissions for everyone: `rwx` for owner, group, and other (r=4, w=2, x=1, so 7 is rwx). It's risky because anyone can read, write, and execute. More in [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md).
- **What's `drwxr-xr-x`?** A **d**irectory where owner=`rwx`, group=`r-x`, other=`r-x`, which is `755`. That first char is the type (`d`=dir, `-`=file, `l`=symlink).
- **General Linux file structure**: `/` root; `/etc` config; `/home` users; `/root` root's home; `/var` logs+variable data; `/tmp` scratch; `/bin`+`/usr/bin` user binaries; `/sbin`+`/usr/sbin` system binaries; `/opt` optional add-on software; `/lib` libraries; `/proc`+`/sys` live kernel state; `/dev` devices; `/boot` kernel+bootloader.

## Module 3: networking concepts
- **telnet, use case & limitations**: connect to a text service to test it or grab a banner (`telnet host 25`). The limits: **no encryption** at all (it's cleartext, so unsafe for logins, which is why SSH replaced it) and no real file transfer. More in [Netcat](../Recon%20Tools/Netcat.md).
- **OSI model, protocols/services per layer**: L1 Physical (cables, hubs); L2 Data Link (MAC, switches, Ethernet/ARP); L3 Network (IP, routers, ICMP); L4 Transport (TCP/UDP, ports); L5 Session; L6 Presentation (encryption/encoding like TLS, JPEG); L7 Application (HTTP, DNS, SSH, SMTP). More in [OSI Model](../Linux%20Admin/OSI%20Model.md).
- **What's SSH (and WinSCP)?** Secure Shell, an encrypted protocol for remote login, running commands, tunneling, and file transfer (scp/sftp). WinSCP is just a Windows GUI client for SCP/SFTP over SSH. More in [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md).

## Module 3: Windows
- **Windows log categories (what each one is)**: in Event Viewer, **Application** (app events/errors), **Security** (audit success/failure, logons 4624 / failed 4625), **System** (OS, drivers, services), **Setup** (install/upgrade), and **Forwarded Events** (collected from other machines). More in [Windows Logs and Scheduled Tasks](../Win%20Admin/Windows%20Logs%20and%20Scheduled%20Tasks.md).

## Related
- [Master Index](Master%20Index%20%28MOC%29.md) · [JQR Progress Checklist](JQR%20Progress%20Checklist.md) · [Command Cheat Sheet](Command%20Cheat%20Sheet.md)
