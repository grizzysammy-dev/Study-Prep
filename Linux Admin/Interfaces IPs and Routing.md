---
tags: [cyber, module3, networking]
jqr: "Configure interfaces (DHCP/static) via netplan, /etc/network/interfaces, nmcli; /etc/networks; add persistent static routes; enable IPv4/IPv6 forwarding"
---

# Interfaces, IPs and Routing

How Linux names NICs, hands out addresses, and decides where packets go, plus flipping the box into a router. This is core Module 3 stuff. Every later pivot, NAT, and firewall task assumes I can do this cold, so I want it solid.

## What I reach for
```bash
ip -br addr                                          # interfaces + IPs, one line each
ip route ; ip route get 172.16.5.10                  # routing table; which route a dest uses
sudo ip route add 172.16.5.0/24 via 192.168.1.254    # static route via a neighbour router
sudo netplan try            # Ubuntu: apply 120s w/ auto-rollback, then `sudo netplan apply`
sudo nmcli con add type ethernet ifname ens34 ipv4.method manual ipv4.addresses 10.10.10.1/24  # CentOS (auto-persists)
sudo sysctl -w net.ipv4.ip_forward=1                 # make it a router (temp; persist in /etc/sysctl.d/)
ip -6 addr ; ping6 fe80::1%ens33                     # IPv6 — link-local needs %interface
```

Lab scheme I use below: `ens33` = DHCP on `192.168.1.0/24`; `ens34` = static `10.10.10.1/24`; remote `172.16.5.0/24` reached via neighbour router `192.168.1.254`.

## The mental model
I think of the kernel as a mailroom: each **interface** is a loading dock, each packet a parcel with a destination address, and the **routing table** is the clerk's one rulebook for which dock a parcel leaves by (and which neighbouring building to hand it to next). Everything below is just filling in and reading that rulebook.
- **Interface (NIC)** = a network port. Each gets an **IP + netmask** (e.g. `10.10.10.1/24`).
- **Routing table** = the kernel's rulebook: *"to reach network X, send out interface Y via next-hop Z."*
- **Default gateway** = the catch-all route `0.0.0.0/0`, used when no more specific route matches.
- **Longest-prefix match wins**, so a `/24` route beats the `/0` default for the addresses it covers.
- **Forwarding** flips the box from *host* (silently drops transit packets) to *router* (passes them between NICs).
- 2026 tool per distro: Ubuntu uses **netplan**, Debian uses **/etc/network/interfaces** (or systemd-networkd), CentOS uses **NetworkManager/nmcli**.

## Seeing interfaces, addresses and routes
```bash
ip a                       # full detail: every NIC, IPv4+IPv6, MAC, state
ip -br addr                # brief: NAME  STATE  IP/mask  (fastest read under time pressure)
ip -br link                # brief link/MAC + UP/DOWN, no addresses
ip route                   # IPv4 routing table (the `default` line is your gateway)
ip -6 route                # IPv6 routing table
ip route get 172.16.5.10   # ask the kernel exactly which route/next-hop it picks for a dest
```
`ip -br addr` is the one I make sure to remember; it answers "what are my IPs?" in one screen.

```bash
ifconfig -a                # legacy net-tools view of interfaces/addresses
```
`ifconfig` is deprecated and often **not installed** on modern minimal images (`sudo apt install net-tools` / `sudo dnf install net-tools`). I prefer `ip`, but I keep `ifconfig` in mind because older exam boxes still ship it.

### Confirm the box can resolve / reach out
Output when I ran it (Ubuntu 24.04):
```
$ ping -c2 8.8.8.8
/bin/bash: line 259: ping: command not found

$ getent hosts github.com
140.82.113.4    github.com
```
Real 2026 gotcha caught right there: minimal images often ship **without `ping`** (`sudo apt install iputils-ping`). `getent hosts <name>` resolves through the system resolver (nsswitch, so `/etc/hosts` + DNS), needs no extra package, and is a reliable "can I resolve?" check when `ping`/`nslookup` are missing.

## Configuring two interfaces (one DHCP, one static)
Scenario: `ens33` pulls a DHCP lease on the primary LAN; `ens34` gets a fixed `10.10.10.1/24` on an isolated segment.

(Still need to run this on my lab box, it edits live network config and needs root plus the real NICs.)

### Ubuntu (netplan, the 2026 way)
Netplan is a **front-end**. I write YAML and it *generates* config for the back-end **renderer** (`networkd` on servers, `NetworkManager` on desktops). Files live in `/etc/netplan/*.yaml`.
```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:                     # primary NIC — DHCP
      dhcp4: true
    ens34:                     # second NIC — static
      dhcp4: false
      addresses: [10.10.10.1/24]
      nameservers:
        addresses: [192.168.1.10, 1.1.1.1]
      # no default route here — the DHCP NIC supplies the gateway (static-route example below)
```
```bash
sudo netplan generate     # build/validate back-end config from the YAML (syntax check)
sudo netplan try          # apply for 120s, AUTO-ROLLS BACK if unconfirmed (safe over SSH)
sudo netplan apply        # apply now, permanently
```
On a box I reach over SSH I always `netplan try` first, because a typo that kills the link rolls back on its own after 120s instead of stranding me.

> [!warning] Netplan gotchas
> - **YAML is space-sensitive.** Indent with **2 spaces, never tabs**; one wrong space fails the whole file.
> - `renderer:` must match what's installed: Ubuntu **Server** = `networkd`, **Desktop** = `NetworkManager`.
> - The old `gateway4:` key is **removed in 2026**, so use the `routes:` block with `to: default` (below).
> - Files are read in **alphanumeric order** and later files override earlier keys, so keep to one file if you can.
> - Lock it down: `sudo chmod 600 /etc/netplan/*.yaml` (it can hold Wi-Fi secrets; new netplan warns if world-readable).

### Debian 13 (/etc/network/interfaces)
```
# /etc/network/interfaces
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

# primary NIC — DHCP
auto ens33
iface ens33 inet dhcp

# second NIC — static
auto ens34
iface ens34 inet static
    address 10.10.10.1/24        # or: address 10.10.10.1 + netmask 255.255.255.0
```
```bash
sudo ifdown ens34 && sudo ifup ens34     # bounce just this interface
sudo systemctl restart networking        # or restart all networking
```
ifupdown is **per-interface**; there's no global "apply". Debian 13 also supports systemd-networkd (`.network` files in `/etc/systemd/network/`), same idea in a different format, but `interfaces` is the classic exam answer.

### CentOS Stream 10 (nmcli / NetworkManager)
No netplan and no `interfaces` file here. CentOS uses **NetworkManager**, driven by `nmcli`.
```bash
# DHCP on the primary NIC
sudo nmcli con add type ethernet con-name lan-dhcp ifname ens33 ipv4.method auto

# Static on the second NIC
sudo nmcli con add type ethernet con-name seg-static ifname ens34 \
     ipv4.method manual ipv4.addresses 10.10.10.1/24 ipv4.dns 192.168.1.10

sudo nmcli con up seg-static                       # apply / bring up
nmcli con show ; nmcli dev status ; ip -br addr    # verify
```
`nmcli` writes persistent keyfiles under `/etc/NetworkManager/system-connections/` **automatically**, so there's no separate "make permanent" step. That's the big contrast with raw `ip` commands, which vanish on reboot.

### /etc/networks (exam trivia)
Maps **network names to network numbers**, like `/etc/hosts` but for whole *networks* instead of single hosts.
```
# /etc/networks
loopback      127.0.0.0
localnet      192.168.1.0
lab-segment   10.10.10.0
```
It's purely a name-lookup table so tools like `route` and older `netstat` can print a friendly name instead of a raw network number. It does **not** configure interfaces, addresses, or routing; setting it creates no route. Largely legacy in 2026 (classful, no CIDR), so I just know *what it is* and rarely edit it.

## Static route to a subnet you're not on
Scenario: I need `172.16.5.0/24`. It's on none of my NICs, but neighbour router `192.168.1.254` (which *is* on my primary LAN) knows the way, so I point a **specific route** at that next-hop.

### Temporary (this boot only)
```bash
sudo ip route add 172.16.5.0/24 via 192.168.1.254             # via the next-hop
sudo ip route add 172.16.5.0/24 via 192.168.1.254 dev ens33   # force the exit interface
ip route ; ip route get 172.16.5.10                           # confirm it appears / is chosen
sudo ip route del 172.16.5.0/24 via 192.168.1.254             # undo
```
Wiped on reboot, so persist it with a method below. Route present but hosts silent? Sweep what's actually reachable across it with [Nmap](../Recon%20Tools/Nmap.md).

### Persistent: netplan (Ubuntu)
Add a `routes:` block under the interface that reaches the next-hop:
```yaml
    ens33:
      dhcp4: true
      routes:
        - to: 172.16.5.0/24      # specific remote network
          via: 192.168.1.254     # next-hop on OUR subnet
        - to: default            # == 0.0.0.0/0 (the modern replacement for gateway4:)
          via: 192.168.1.254
```
Then `sudo netplan apply`.

### Persistent: nmcli (CentOS)
```bash
sudo nmcli con modify lan-dhcp +ipv4.routes "172.16.5.0/24 192.168.1.254"
sudo nmcli con up lan-dhcp ; ip route
```

### Persistent: Debian interfaces (post-up hook)
```
iface ens33 inet dhcp
    post-up   ip route add 172.16.5.0/24 via 192.168.1.254
    pre-down  ip route del 172.16.5.0/24 via 192.168.1.254
```

### Default gateway vs specific route
| | **Default gateway** | **Specific (static) route** |
|---|---|---|
| Destination | `0.0.0.0/0` (everything) | one network, e.g. `172.16.5.0/24` |
| Used when | no more specific route matches | dest falls in that range |
| Typical count | usually **one** per host | as many as you need |

Longest-prefix match again: the `/24` wins over the `/0` default, so my `172.16.5.0/24` route is honoured even with a default gateway present.

## Making the box a router (IPv4 forwarding)
By default Linux **drops** packets arriving on one NIC that are bound for a network behind another NIC, because a host isn't a router. I turn forwarding **on** to route between subnets, run a pivot, or do NAT. Without it, my `iptables` FORWARD rules and NAT/masquerade do **nothing** (see [iptables](../IP%20Tables%20CentOS/iptables.md)).

Why one bit flips host into router: a packet whose destination IP isn't the box's own normally hits a dead end. As a *host*, "not addressed to me" means "not my problem," so the kernel drops it. `ip_forward=1` changes that default to "not mine, but I have a route, so send it out the correct interface." That single switch is the entire technical difference between a host and a router. From the defender's chair, a workstation with forwarding unexpectedly enabled is a classic sign someone's turned it into a pivot.

### Temporary (until reboot)
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward   # equivalent
sysctl net.ipv4.ip_forward                        # check -> net.ipv4.ip_forward = 1
```

### Permanent (survives reboot)
```bash
# /etc/sysctl.d/99-forwarding.conf
net.ipv4.ip_forward = 1
```
```bash
sudo sysctl -p /etc/sysctl.d/99-forwarding.conf   # apply this one file
sudo sysctl --system                              # or reload ALL sysctl.d files
```
Do **both** temp and permanent, or the router quietly stops routing after reboot. Forwarding alone only reaches *directly attached* subnets; for a subnet with no local NIC I also need a **route** (above) or **NAT** (see [iptables](../IP%20Tables%20CentOS/iptables.md)).

## IPv6 basics + forwarding
### Two address types to know
- **Link-local `fe80::/10`** is auto-generated on every IPv6 NIC, valid **only on that one link**, never routed. Pinging one **requires** the interface: `ping6 fe80::1%ens33`.
- **Global unicast `2000::/3`** (e.g. `2001:db8:...`) is the internet-routable "real" address (assigned, or via SLAAC/DHCPv6). `2001:db8::/32` is the **documentation** range (the IPv6 equivalent of `192.0.2.0/24`), so it's safe in notes/labs.

### Assign a static IPv6
```bash
sudo ip -6 addr add 2001:db8:10::1/64 dev ens34   # temporary
ip -6 addr show ens34
sudo ip -6 addr del 2001:db8:10::1/64 dev ens34   # undo
```
Persistent (netplan), add under the interface:
```yaml
    ens34:
      addresses: [10.10.10.1/24, "2001:db8:10::1/64"]
      routes:
        - to: default
          via: "2001:db8:10::ffff"   # IPv6 default gateway
```

### Enable IPv6 forwarding (a separate knob from IPv4)
```bash
sudo sysctl -w net.ipv6.conf.all.forwarding=1     # temporary
# permanent — add to /etc/sysctl.d/99-forwarding.conf:
#   net.ipv6.conf.all.forwarding = 1
sudo sysctl --system
```
```bash
ping6 2001:db8:10::1 ; ping6 fe80::1%ens34 ; ip -6 route   # test (link-local needs %iface)
```
IPv4 and IPv6 forwarding are **independent**, so I set both if I route both. Enabling forwarding on a NIC can disable SLAAC/RA acceptance on it (expected router behaviour, but it surprises people).

## What I keep forgetting
- **netplan YAML is space-sensitive:** 2 spaces, never tabs; one bad indent fails the whole file. Use `netplan try` (auto-rollback) on anything remote.
- **`gateway4:` is dead in 2026**, use a `routes:` block with `to: default`.
- **nmcli auto-persists; raw `ip`/`sysctl -w` do not.** Anything set with `ip addr`/`ip route`/`sysctl -w` is RAM-only and dies on reboot, so write the config file too.
- **Next-hop must be directly reachable.** I can only `via` an address on a subnet I already have an interface on.
- **Return path must exist.** Routing gets packets *out*; if the far end has no route back I get one-way traffic. Diagnose with [Tcpdump](../Recon%20Tools/Tcpdump.md).
- **Forwarding isn't the same as reaching unattached subnets.** I also need a route (or NAT) for a subnet I have no NIC on.
- **IPv6 link-local needs `%ifname`**, and IPv6 forwarding is a different sysctl than IPv4.
- **`ping` may be absent** on minimal images; `getent hosts <name>` is a no-install resolve check.

## Docs
- Netplan reference: https://netplan.io/reference
- `ip`(8) and `ip-route`(8): https://man7.org/linux/man-pages/man8/ip.8.html , https://man7.org/linux/man-pages/man8/ip-route.8.html
- Debian `interfaces`(5): https://manpages.debian.org/stable/ifupdown/interfaces.5.en.html
- `nmcli`(1): https://man7.org/linux/man-pages/man1/nmcli.1.html
- Kernel IP sysctl (ip_forward, IPv6 forwarding): https://docs.kernel.org/networking/ip-sysctl.html
- IPv6 addressing (RFC 4291) and doc range (RFC 3849): https://www.rfc-editor.org/rfc/rfc4291 , https://www.rfc-editor.org/rfc/rfc3849

## Related
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Nmap](../Recon%20Tools/Nmap.md)
- [Tcpdump](../Recon%20Tools/Tcpdump.md)
