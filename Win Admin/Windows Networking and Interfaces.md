---
tags: [cyber, module3, windows, networking]
jqr: "Configuring Windows interfaces: two NICs, static IP via GUI (ncpa.cpl), netsh, and New-NetIPAddress; persistent routes (route -p / New-NetRoute); IPv6; and troubleshooting with ipconfig/getmac/tracert/nbtstat"
---

# Windows Networking and Interfaces

These are my notes on giving a Windows box a **static IP on two NICs**, adding **routes** to networks it can't reach directly, handling **IPv6**, and troubleshooting from the CLI. Coming from Linux, the mental model is the same as [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md), only the tool names change. Every IP or route change needs an **elevated** shell.

## The commands I reach for
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

## Coming from Linux
- **The adapter name is the handle.** Where Linux has `eth0`/`ens33`, Windows uses a *friendly name* like `Ethernet` and `Ethernet 2`. Every command targets that string, so I **list the names first**. (Under the hood each NIC has an ugly GUID and the friendly name is just a relabel-able alias over it, which is why I can rename an adapter and nothing real changes.)
- **Default gateway is the default route.** Set it on **one** NIC only. A second NIC on an isolated segment gets **no gateway**, and if it needs to reach elsewhere, **specific static routes**.
- **`netsh` is not deprecated.** It's fully supported in 2026 and it's the cmd-side tool for IP config. PowerShell's `*-NetIPAddress` / `*-NetRoute` cmdlets do the same thing.

> **Why only one gateway:** the default route is the rule "for any destination I don't have a specific route for, hand the packet to *this* neighbour." It's the fallback of last resort, so having two is like giving someone two different "when lost, go here" instructions. The box can't choose deterministically, and traffic leaves the wrong NIC or black-holes. An isolated second NIC doesn't need a fallback, it needs **specific** routes for the specific far networks it has to reach, which is exactly what the routes section below sets up.

**Scenario I'm using below:** a lab VM with two adapters.
- `Ethernet` on the primary subnet **192.168.1.0/24** (this NIC owns the gateway)
- `Ethernet 2` on an isolated segment **10.10.0.0/24** (no gateway)

List them first:
```cmd
netsh interface show interface
```
```powershell
Get-NetAdapter | Select Name, InterfaceDescription, Status, MacAddress
```

## Static IP: GUI (`ncpa.cpl`)
Win+R → **`ncpa.cpl`** → right-click the adapter → **Properties** → select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties** → choose **Use the following IP address** → enter IP / mask / gateway and DNS → **OK**.
`ncpa.cpl` is the fast path to the adapter list. I've got that one memorised.

## Static IP: cmd (`netsh`)
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
(do this on the Windows VM to be sure, but it checks out against the docs). Quote adapter names that contain spaces (`name="Ethernet 2"`).

## Static IP: PowerShell
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.50 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,1.1.1.1

# Second NIC, no gateway:
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.10.0.50 -PrefixLength 24

Get-NetIPConfiguration            # verify
# Changing an existing IP: remove it first — New-NetIPAddress errors on a duplicate:
Remove-NetIPAddress -InterfaceAlias "Ethernet" -Confirm:$false
```
`-PrefixLength 24` is `255.255.255.0`. `New-NetIPAddress` **fails if the NIC already has that address**, so I remove or reset it first.

## Routes to a remote subnet
Say I need to reach **172.16.5.0/24** through a neighbour router **192.168.1.254** on my primary subnet:
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
**`-p` is the flag that matters.** Without it the route dies at reboot. This is the Windows version of a Linux `ip route add`.

> **Why it dies:** the live routing table lives in memory and gets rebuilt from scratch every boot. Plain `route add` only edits that in-RAM copy. `-p` *also* writes the route into the **registry**, so the network stack replays it on startup. "Persistent" here literally means "saved to disk so it can be re-applied," the same in-memory-vs-saved split I hit again with mapped drives.

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
`::1` is IPv6 localhost (like `127.0.0.1`). `2001:db8::/32` is the documentation-only prefix, so it's safe for notes and labs.

## Troubleshooting
### `ipconfig`: IP configuration
```cmd
ipconfig               :: brief: IP, mask, gateway per adapter
ipconfig /all          :: full: MAC, DHCP, DNS servers, lease times
ipconfig /release      :: drop the DHCP lease
ipconfig /renew        :: request a new lease
ipconfig /flushdns     :: clear the DNS resolver cache
ipconfig /displaydns   :: show the DNS cache
```
`ipconfig /all` is my first command when "networking is weird," since it shows MAC, DHCP vs static, and which DNS servers are actually in use.

### `getmac`: hardware addresses
```cmd
getmac        :: MAC per adapter
getmac /v     :: verbose (adapter name + connection state + transport)
```

### `tracert`: trace the route
```cmd
tracert 8.8.8.8       :: show each router hop to the destination
tracert -d 8.8.8.8    :: -d skips DNS lookups (faster, IPs only)
```
Each line is a hop, and `* * *` marks where the path stalls.

### `nbtstat`: NetBIOS over TCP/IP (legacy, still on the exam)
```cmd
nbtstat -A 192.168.1.20   :: remote NetBIOS name table by IP    (capital -A)
nbtstat -a HOSTNAME       :: remote NetBIOS name table by NAME  (lower -a)
nbtstat -n                :: THIS machine's local NetBIOS names
nbtstat -c                :: local NetBIOS name cache (name -> IP)
```
Reveals a host's name/workgroup plus its `<20>` (File Server) and `<00>` (Workstation) services. The case of `-A` vs `-a` matters. Often disabled on hardened networks.

### PowerShell troubleshooting
```powershell
Test-Connection 192.168.1.20 -Count 4          # ping
Test-NetConnection 192.168.1.20 -Port 445      # test a specific TCP port (great for SMB)
Resolve-DnsName example.com                    # DNS query
Get-NetNeighbor                                # ARP / neighbour table
Get-NetIPConfiguration                         # ipconfig-style summary
```
`Test-NetConnection -Port 445` is the modern "is SMB reachable?" check (see [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)).

## Gotchas that got me
- **Two default gateways means broken routing.** Put the gateway on ONE NIC and use static routes for the other NIC's remote networks.
- **`route -p`** for a route that survives reboot. Forgetting `-p` is the classic mistake.
- **List adapter names first** (`netsh interface show interface`). Commands fail silently on a mistyped name, and I quote names with spaces.
- **`New-NetIPAddress` errors on a duplicate**, so `Remove-NetIPAddress` or `Set-NetIPAddress` first.
- **Don't disable IPv6 to "simplify" things.** Microsoft supports and expects it, and disabling it can break local services.
- **`netsh` is supported, not deprecated**, so it's a valid exam answer right alongside PowerShell.
- All IP and route changes need **Administrator**.

## References
- netsh: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh
- route: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/route_ws2008
- NetTCPIP module (New-NetIPAddress/New-NetRoute): https://learn.microsoft.com/en-us/powershell/module/nettcpip/
- ipconfig: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig

## Related
- [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
- [Windows Firewall](Windows%20Firewall.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
