---
tags: [jcu, module3, windows, networking]
jqr: "Configure Windows interfaces: two NICs, static IP via GUI (ncpa.cpl) + netsh + New-NetIPAddress; persistent routes (route -p / New-NetRoute); IPv6; troubleshoot with ipconfig/getmac/tracert/nbtstat"
---

# Windows Networking and Interfaces

How to give a Windows box a **static IP on two NICs**, add **routes** to networks it can't reach directly, handle **IPv6**, and troubleshoot from the CLI. Coming from Linux, the mental model is the same as [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md) — only the tool names change. Every IP/route change needs an **elevated** shell.

## TL;DR
```cmd
netsh interface show interface                          :: list adapters + exact names
netsh interface ip set address name="Ethernet" static 192.168.1.50 255.255.255.0 192.168.1.1
route -p add 172.16.5.0 mask 255.255.255.0 192.168.1.254 :: PERSISTENT route to a remote subnet
ipconfig /all                                           :: full IP/MAC/DNS per adapter
tracert -d 8.8.8.8                                      :: trace the path, no DNS
```
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.50 -PrefixLength 24 -DefaultGateway 192.168.1.1
New-NetRoute -DestinationPrefix "172.16.5.0/24" -InterfaceAlias "Ethernet" -NextHop 192.168.1.254
```

## Concept — for a Linux person
- **Adapter name is the handle.** Where Linux has `eth0`/`ens33`, Windows uses a *friendly name* like `Ethernet` and `Ethernet 2`. Every command targets that string, so **list the names first**.
- **Default gateway = default route.** Set it on **one** NIC only. A second NIC on an isolated segment gets **no gateway** and, if it needs to reach elsewhere, **specific static routes**.
- **`netsh` is not deprecated** — it's fully supported in 2026 and is the cmd-side tool for IP config. PowerShell's `*-NetIPAddress` / `*-NetRoute` cmdlets do the same.

**Scenario used below:** a lab VM with two adapters —
- `Ethernet` on the primary subnet **192.168.1.0/24** (this NIC owns the gateway)
- `Ethernet 2` on an isolated segment **10.10.0.0/24** (no gateway)

List them first:
```cmd
netsh interface show interface
```
```powershell
Get-NetAdapter | Select Name, InterfaceDescription, Status, MacAddress
```

## Static IP — GUI (`ncpa.cpl`)
Win+R → **`ncpa.cpl`** → right-click the adapter → **Properties** → select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties** → choose **Use the following IP address** → enter IP / mask / gateway and DNS → **OK**.
→ `ncpa.cpl` is the fast path to the adapter list; memorise it.

## Static IP — cmd (`netsh`)
```cmd
:: Primary NIC — has the default gateway:
netsh interface ip set address name="Ethernet" static 192.168.1.50 255.255.255.0 192.168.1.1
netsh interface ip set dns     name="Ethernet" static 8.8.8.8
netsh interface ip add    dns  name="Ethernet" 1.1.1.1 index=2      :: secondary DNS

:: Second NIC — NO gateway (see gotcha):
netsh interface ip set address name="Ethernet 2" static 10.10.0.50 255.255.255.0

:: Revert to DHCP:
netsh interface ip set address name="Ethernet" dhcp
netsh interface ip set dns     name="Ethernet" dhcp
```
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. Quote adapter names that contain spaces (`name="Ethernet 2"`).

## Static IP — PowerShell
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.50 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,1.1.1.1

# Second NIC, no gateway:
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.10.0.50 -PrefixLength 24

Get-NetIPConfiguration            # verify
# Changing an existing IP: remove it first — New-NetIPAddress errors on a duplicate:
Remove-NetIPAddress -InterfaceAlias "Ethernet" -Confirm:$false
```
→ `-PrefixLength 24` = `255.255.255.0`. `New-NetIPAddress` **fails if the NIC already has that address** — remove or reset first.

## Routes to a remote subnet
Reach **172.16.5.0/24** through a neighbour router **192.168.1.254** on your primary subnet:
```cmd
route add    172.16.5.0 mask 255.255.255.0 192.168.1.254   :: temporary (lost at reboot)
route -p add 172.16.5.0 mask 255.255.255.0 192.168.1.254   :: -p = PERSISTENT
route print                                                :: view routing table
route delete 172.16.5.0                                    :: remove
```
```powershell
New-NetRoute -DestinationPrefix "172.16.5.0/24" -InterfaceAlias "Ethernet" -NextHop 192.168.1.254
Get-NetRoute
Remove-NetRoute -DestinationPrefix "172.16.5.0/24" -Confirm:$false
```
→ **`-p` is the flag that matters** — without it the route dies at reboot. This is the Windows equivalent of a Linux `ip route add`.

## IPv6
```cmd
:: View
netsh interface ipv6 show addresses      :: IPv6 addresses per interface
netsh interface ipv6 show route          :: IPv6 routing table
ipconfig                                 :: also lists IPv6 addresses

:: Set a static IPv6 address + DNS
netsh interface ipv6 set address "Ethernet" 2001:db8::50
netsh interface ipv6 set dnsservers "Ethernet" static 2001:4860:4860::8888

:: Test
ping -6 2001:db8::1
```
```powershell
Get-NetIPAddress -AddressFamily IPv6
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 2001:db8::50 -PrefixLength 64 -AddressFamily IPv6
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 2001:4860:4860::8888
Test-NetConnection 2001:db8::1
```
→ `::1` is IPv6 localhost (like `127.0.0.1`). `2001:db8::/32` is the documentation-only prefix — safe for notes and labs.

## Troubleshooting
### `ipconfig` — IP configuration
```cmd
ipconfig               :: brief: IP, mask, gateway per adapter
ipconfig /all          :: full: MAC, DHCP, DNS servers, lease times
ipconfig /release      :: drop the DHCP lease
ipconfig /renew        :: request a new lease
ipconfig /flushdns     :: clear the DNS resolver cache
ipconfig /displaydns   :: show the DNS cache
```
→ `ipconfig /all` is the first command when "networking is weird" — it shows MAC, DHCP vs static, and which DNS servers are actually in use.

### `getmac` — hardware addresses
```cmd
getmac        :: MAC per adapter
getmac /v     :: verbose (adapter name + connection state + transport)
```

### `tracert` — trace the route
```cmd
tracert 8.8.8.8       :: show each router hop to the destination
tracert -d 8.8.8.8    :: -d skips DNS lookups (faster, IPs only)
```
→ Each line is a hop; `* * *` marks where the path stalls.

### `nbtstat` — NetBIOS over TCP/IP (legacy, still on the exam)
```cmd
nbtstat -A 192.168.1.20   :: remote NetBIOS name table by IP    (capital -A)
nbtstat -a HOSTNAME       :: remote NetBIOS name table by NAME  (lower -a)
nbtstat -n                :: THIS machine's local NetBIOS names
nbtstat -c                :: local NetBIOS name cache (name -> IP)
```
→ Reveals a host's name/workgroup and its `<20>` (File Server) / `<00>` (Workstation) services. Case of `-A` vs `-a` matters. Often disabled on hardened networks.

### PowerShell troubleshooting
```powershell
Test-Connection 192.168.1.20 -Count 4          # ping
Test-NetConnection 192.168.1.20 -Port 445      # test a specific TCP port (great for SMB)
Resolve-DnsName example.com                    # DNS query
Get-NetNeighbor                                # ARP / neighbour table
Get-NetIPConfiguration                         # ipconfig-style summary
```
→ `Test-NetConnection -Port 445` is the modern "is SMB reachable?" check — see [SMB PsExec and DCOM](../05%20-%20Metasploit%20and%20Exploitation/SMB%20PsExec%20and%20DCOM.md).

## Exam tips & gotchas
- **Two default gateways = broken routing.** Put the gateway on ONE NIC; use static routes for the other NIC's remote networks.
- **`route -p`** for a route that survives reboot — forgetting `-p` is the classic mistake.
- **List adapter names first** (`netsh interface show interface`) — commands fail silently on a mistyped name; quote names with spaces.
- **`New-NetIPAddress` errors on a duplicate** — `Remove-NetIPAddress` or `Set-NetIPAddress` first.
- **Don't disable IPv6 to "simplify"** — Microsoft supports and expects it; disabling can break local services.
- **`netsh` is supported, not deprecated** — it's a valid exam answer alongside PowerShell.
- All IP/route changes need **Administrator**.

## References
- netsh — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh
- route — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/route_ws2008
- NetTCPIP module (New-NetIPAddress/New-NetRoute) — https://learn.microsoft.com/en-us/powershell/module/nettcpip/
- ipconfig — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig

## Related
- [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md)
- [Windows Firewall](Windows%20Firewall.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [SMB PsExec and DCOM](../05%20-%20Metasploit%20and%20Exploitation/SMB%20PsExec%20and%20DCOM.md)
- [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
