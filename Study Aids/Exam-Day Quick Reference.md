---
tags: [cyber, examday]
jqr: "Highest-yield facts, sequences, and gotchas across every module"
---

# Exam-Day Quick Reference

This is the stuff that's easy to blank on under pressure, so I skim it last. Pure commands live in [Command Cheat Sheet](Command%20Cheat%20Sheet.md).

## Attack a target, in order
1. **Discover** hosts: `nmap -sn 192.168.1.0/24`
2. **Scan** ports/services: `sudo nmap -sS -sV -p- 192.168.1.20`
3. **Enumerate** the service (SMB means `enum4linux-ng`, web means dirs, and so on), see [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md)
4. **Exploit** with Metasploit or a known PoC, see [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
5. **Escalate** (linpeas/winPEAS, SUID, tokens), see [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md)
6. **Pivot** (SSH `-D`, chisel, routes), see [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
> Always start with [Nmap](../Recon%20Tools/Nmap.md). If I don't know where to begin, that means run nmap.

## Commands I need cold
```bash
sudo nmap -sC -sV -p- 192.168.1.20        # full scan, versions + default scripts
ss -tulpn                                  # what's listening + which process
ip -br addr ; ip route                     # my IPs / my routes
sudo tcpdump -i eth0 -nA port 4444         # watch traffic (proves nc is cleartext)
```

## SSH forwarding, the #1 trap
- **`-L` local:** listen on **MY** box, exit on the **remote** side, so I reach a service *behind* the remote. `ssh -L 8080:127.0.0.1:80 user@bastion` makes my `localhost:8080` hit the remote's port 80.
- **`-R` remote:** listen on the **REMOTE** box, exit on **MY** side, so I expose something on my side to the remote network. `ssh -R 9000:127.0.0.1:3000 user@remote`.
- **`-D` dynamic:** SOCKS proxy on my box for pivoting: `ssh -D 1080 user@bastion` plus proxychains.
- Jump: `ssh -J bastion internal-host` (or `ProxyJump` in `~/.ssh/config`). Port is `-p` for ssh, **`-P` for scp**.

## iptables, safe build order (don't lock yourself out)
```
loopback  →  established/related  →  ALLOW SSH  →  (other allows)  →  LOG  →  -P INPUT DROP (last!)
```
- Block all except SSH: allow lo + established + `--dport 22`, then `iptables -P INPUT DROP`.
- **NAT needs forwarding:** `sysctl -w net.ipv4.ip_forward=1`. SNAT/MASQUERADE is **POSTROUTING**; DNAT/REDIRECT is **PREROUTING**.
- Persist: Debian/Ubuntu `/etc/iptables/rules.v4`; CentOS `/etc/sysconfig/iptables`.

## Permissions
- `777` = `rwxrwxrwx` (r=4 w=2 x=1). `755` = rwx r-x r-x. `644` = rw- r-- r--.
- `drwxr-xr-x`: `d`=directory, then owner `rwx`, group `r-x`, other `r-x`.
- Recursive: `chmod -R`, `chown -R user:group`.

## OSI model (Please Do Not Throw Sausage Pizza Away)
7 App · 6 Presentation (encoding/encryption) · 5 Session · 4 Transport (TCP/UDP, ports) · 3 Network (IP, routers) · 2 Data Link (MAC, switches) · 1 Physical (cables). More in [OSI Model](../Linux%20Admin/OSI%20Model.md).

## Cyber Kill Chain (Lockheed Martin, 7)
Recon → Weaponization → Delivery → Exploitation → Installation → C2 → Actions on Objectives. More in [Cyber Kill Chain](../Knowledge%20Req/Cyber%20Kill%20Chain.md).

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
- **RHOSTS** is plural, and **LHOST** is *my* IP on the right interface (tun0 when I'm on the VPN).
- SMB version: `set SMB::ProtocolVersion 2,3` (advanced option). Non-meterpreter payload: `set payload windows/x64/shell/reverse_tcp`.

## Windows one-liners
```
net user  /  net localgroup  /  net share  /  net use Z: \\host\share
Get-LocalUser  /  New-LocalUser  /  Get-SmbShare  /  Get-Process
netsh advfirewall set allprofiles state off      (disable firewall)
systeminfo   /   tasklist   /   taskkill /PID n /F
```
Heads up: **wmic is removed in Win11 25H2**, so use `Get-CimInstance Win32_Process` to get a process's path.

## Log locations (fast)
- Linux: `/var/log/` holds `auth.log`/`secure` (logins), `syslog`/`messages`, and `kern.log`; for live tailing, `journalctl -xe` and `dmesg`.
- Windows: Event Viewer, with **Security** (4624 logon / 4625 fail), **System**, and **Application**.

## Gotchas that cost points
- `-sS` and `tcpdump` need **root**. UDP scans are slow, so narrow the ports.
- Kali's default `nc` (OpenBSD) has **no `-e`**, so don't rely on it for shells.
- netplan YAML wants spaces not tabs; `gateway4:` is gone now, use `routes: to: default`.
- `ping` might be missing on minimal images, so `getent hosts <name>` to test DNS.
- Live iptables/`ip`/`sysctl -w` changes **die on reboot** unless I persist them.

## Related
- [Command Cheat Sheet](Command%20Cheat%20Sheet.md) · [JQR Progress Checklist](JQR%20Progress%20Checklist.md) · [Master Index (MOC)](Master%20Index%20%28MOC%29.md)
