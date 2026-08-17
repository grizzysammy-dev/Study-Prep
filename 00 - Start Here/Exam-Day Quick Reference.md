---
tags: [jcu, examday]
jqr: "Highest-yield facts, sequences, and gotchas across every module"
---

# Exam-Day Quick Reference

The stuff that's easy to blank on under pressure. Skim this last. Pure commands live in [Command Cheat Sheet](Command%20Cheat%20Sheet.md).

## Attack a target — the order
1. **Discover** hosts: `nmap -sn 192.168.1.0/24`
2. **Scan** ports/services: `sudo nmap -sS -sV -p- 192.168.1.20`
3. **Enumerate** the service (SMB → `enum4linux-ng`, web → dirs, etc.) — [Enumeration Tools](../05%20-%20Metasploit%20and%20Exploitation/Enumeration%20Tools.md)
4. **Exploit** (Metasploit or a known PoC) — [Metasploit Workflow](../05%20-%20Metasploit%20and%20Exploitation/Metasploit%20Workflow.md)
5. **Escalate** (linpeas/winPEAS, SUID, tokens) — [Privilege Escalation Concepts](../05%20-%20Metasploit%20and%20Exploitation/Privilege%20Escalation%20Concepts.md)
6. **Pivot** (SSH `-D`, chisel, routes) — [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
> Always start with [Nmap](../02%20-%20Recon%20and%20Network%20Tools/Nmap.md). "I don't know where to begin" = run nmap.

## Commands you must have cold
```bash
sudo nmap -sC -sV -p- 192.168.1.20        # full scan, versions + default scripts
ss -tulpn                                  # what's listening + which process
ip -br addr ; ip route                     # my IPs / my routes
sudo tcpdump -i eth0 -nA port 4444         # watch traffic (proves nc is cleartext)
```

## SSH forwarding — the #1 trap
- **`-L` local:** listen on **MY** box, exit on the **remote** side → reach a service *behind* the remote. `ssh -L 8080:127.0.0.1:80 user@bastion` → my `localhost:8080` = remote's port 80.
- **`-R` remote:** listen on the **REMOTE** box, exit on **MY** side → expose something on my side to the remote network. `ssh -R 9000:127.0.0.1:3000 user@remote`.
- **`-D` dynamic:** SOCKS proxy on my box for pivoting → `ssh -D 1080 user@bastion` + proxychains.
- Jump: `ssh -J bastion internal-host` (or `ProxyJump` in `~/.ssh/config`). Port is `-p` for ssh, **`-P` for scp**.

## iptables — safe build order (don't lock yourself out)
```
loopback  →  established/related  →  ALLOW SSH  →  (other allows)  →  LOG  →  -P INPUT DROP (last!)
```
- Block all except SSH: allow lo + established + `--dport 22`, then `iptables -P INPUT DROP`.
- **NAT needs forwarding:** `sysctl -w net.ipv4.ip_forward=1`. SNAT/MASQUERADE = **POSTROUTING**; DNAT/REDIRECT = **PREROUTING**.
- Persist: Debian/Ubuntu `/etc/iptables/rules.v4`; CentOS `/etc/sysconfig/iptables`.

## Permissions
- `777` = `rwxrwxrwx` (r=4 w=2 x=1). `755` = rwx r-x r-x. `644` = rw- r-- r--.
- `drwxr-xr-x`: `d`=directory, then owner `rwx`, group `r-x`, other `r-x`.
- Recursive: `chmod -R`, `chown -R user:group`.

## OSI model (Please Do Not Throw Sausage Pizza Away)
7 App · 6 Presentation (encoding/encryption) · 5 Session · 4 Transport (TCP/UDP, ports) · 3 Network (IP, routers) · 2 Data Link (MAC, switches) · 1 Physical (cables). — [OSI Model](../03%20-%20Linux%20Skills/OSI%20Model.md)

## Cyber Kill Chain (Lockheed Martin, 7)
Recon → Weaponization → Delivery → Exploitation → Installation → C2 → Actions on Objectives. — [Cyber Kill Chain](../06%20-%20Knowledge%20Requirements/Cyber%20Kill%20Chain.md)

## Package managers (Debian vs RHEL)
| | Debian/Ubuntu | RHEL/CentOS |
|---|---|---|
| install | `apt install X` | `dnf install X` |
| package tool | `dpkg -i f.deb` | `rpm -ivh f.rpm` |
| logs | `/var/log/auth.log`, `syslog` | `/var/log/secure`, `messages` |
- Download not install: `apt download X` / `dnf download X`. `pip install` blocked? use a **venv** (PEP 668).

## Metasploit loop
```
sudo msfdb init → msfconsole → db_status (Connected!) → search → use <path> → show options
→ set RHOSTS <target> → set LHOST <my IP> → run/exploit
```
- **RHOSTS** (plural), **LHOST** = *your* IP on the right interface (tun0 on VPN).
- SMB version: `set SMB::ProtocolVersion 2,3` (advanced option). Non-meterpreter payload: `set payload windows/x64/shell/reverse_tcp`.

## Windows one-liners
```
net user  /  net localgroup  /  net share  /  net use Z: \\host\share
Get-LocalUser  /  New-LocalUser  /  Get-SmbShare  /  Get-Process
netsh advfirewall set allprofiles state off      (disable firewall)
systeminfo   /   tasklist   /   taskkill /PID n /F
```
Note: **wmic is removed in Win11 25H2** — use `Get-CimInstance Win32_Process` for a process's path.

## Log locations (fast)
- Linux: `/var/log/` — `auth.log`/`secure` (logins), `syslog`/`messages`, `kern.log`; live: `journalctl -xe`, `dmesg`.
- Windows: Event Viewer — **Security** (4624 logon / 4625 fail), **System**, **Application**.

## Gotchas that cost points
- `-sS` and `tcpdump` need **root**. UDP scans are slow — narrow ports.
- Kali default `nc` (OpenBSD) has **no `-e`** — don't rely on it for shells.
- netplan YAML = spaces not tabs; `gateway4:` is gone → use `routes: to: default`.
- `ping` may be missing on minimal images → `getent hosts <name>` to test DNS.
- Live iptables/`ip`/`sysctl -w` changes **die on reboot** unless you persist them.

## Related
- [Command Cheat Sheet](Command%20Cheat%20Sheet.md) · [JQR Progress Checklist](JQR%20Progress%20Checklist.md) · [Master Index (MOC)](Master%20Index%20%28MOC%29.md)
