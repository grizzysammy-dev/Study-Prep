---
tags: [cyber, module2, knowledge, networking]
jqr: "Define pivoting and tunneling, distinguish them, and describe when to use SSH, iptables, OpenVPN, WireGuard, and Chisel."
---

# Pivoting and Tunneling

This is the concept/terminology framing the JQR wants: what **pivoting** and **tunneling** are, how they differ, and which tool I reach for. I'm keeping it conceptual on purpose, the hands-on mechanics live in the tool notes I link out to.

## The one-liner
- **Pivoting** = using a **compromised host as a relay** to reach networks I can't touch directly. It's about **routing / reach**. (The "where.")
- **Tunneling** = **encapsulating one protocol inside another** to move traffic through or around controls. It's about **transport / evasion / confidentiality**. (The "how it gets there.")
- **Port forwarding** (local `-L` / remote `-R` / dynamic-SOCKS `-D`) is the common building block of both.
- Tool picker: **SSH** = fast ad-hoc forwards · **iptables** = OS-level relay on a Linux foothold · **OpenVPN/WireGuard** = full virtual-network links (WireGuard leaner/faster) · **Chisel** = tunnel over HTTP when only web egress is allowed.

## What's actually going on
Two different problems that keep getting lumped together.

**Pivoting** turns one foothold into access to a segmented network. Say I land on a DMZ web server that can talk to an internal VLAN I can't reach from my own box. I route my traffic *through* that server to reach the internal hosts. The way I think of it: the compromised host is a corrupted courier, it can walk into the restricted wing I'm barred from, so I hand it my messages and it carries them in and out. It's the mechanism behind lateral movement, and it's exactly the "Through" arc the Unified Kill Chain adds (see [Cyber Kill Chain](Cyber%20Kill%20Chain.md)). Pivoting is about **reachability**.

**Tunneling** wraps traffic of one protocol inside another so it survives a hostile path. This one's smuggling: put my letter inside an official-looking envelope the mail inspector waves through, and what's really inside never shows. Wrapping arbitrary TCP inside SSH, or inside HTTPS, lets it pass a firewall/proxy/IDS that would otherwise block or read it. Tunneling gives me **transport, evasion, and confidentiality**, because the encapsulating protocol both hides and protects the inner traffic. (On why the *encapsulation* matters: raw protocols like netcat travel in cleartext, and a tunnel is what makes the same bytes private and firewall-passable, contrast the cleartext capture in [Netcat](../Recon%20Tools/Netcat.md).)

The clean split I keep in my head: pivoting is the "where" (which network I reach), tunneling is the "how the traffic gets there" (through what, and hidden how). Usually I'm doing both at once, pivot through a host **and** tunnel the traffic to get it past controls.

Blue-side note to self: pivoting shows up as unexpected **east-west** traffic, a DMZ box suddenly talking to internal hosts it never spoke to before. Tunneling shows up as a **protocol in the wrong place**, SSH-shaped bytes over 443, or a suspicious volume of DNS carrying more than DNS should. Segmentation and egress filtering are the controls that bite here, which is the same reason those controls exist.

## Which tool for which job

| Tool | Role | Reach for it when... |
|---|---|---|
| **SSH** | Port forwarding: local (`-L`), remote (`-R`), dynamic SOCKS (`-D`); jump hosts via `ProxyJump`. | You have SSH creds/keys on a host - quick, encrypted, ubiquitous. **The default pivot.** → [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) |
| **iptables** | Linux netfilter - NAT / `REDIRECT` / `MASQUERADE`, forwarding rules. | You're on a compromised Linux router/gateway and need **OS-level packet forwarding/relay**, not an app tunnel. → [iptables](../IP%20Tables%20CentOS/iptables.md) |
| **OpenVPN** | Full TLS-based VPN tunnel (routed or bridged). | You need a **stable, full-subnet** virtual link - many hosts/protocols - and can tolerate its heavier footprint. → [OpenVPN](../OpenVPN%20Wireguard/OpenVPN.md) |
| **WireGuard** | Modern, lean UDP VPN (small codebase, strong crypto). | You want a **low-latency, low-overhead persistent** VPN pivot; simpler and faster than OpenVPN. → [WireGuard](../OpenVPN%20Wireguard/WireGuard.md) |
| **Chisel** | TCP/UDP tunnel over **HTTP/WebSocket**, single Go binary, built-in SOCKS5. | Egress is **locked to web/HTTP(S)** - you need a portable client/server to punch through a restrictive firewall. → [Chisel](../SSH%20Kali/Chisel.md) |

Framing line to quote: *SSH = fast ad-hoc forwards; iptables = OS-level relay on a Linux foothold; OpenVPN/WireGuard = full virtual-network links (WireGuard leaner/faster); Chisel = firewall-evasive tunneling over HTTP when only web egress is allowed.*

## A jump-host pivot, concretely
A **jump host / bastion** is the simplest pivot: instead of connecting straight to an internal target, SSH routes me *through* an intermediate box with `ProxyJump`. Here the client is set up to reach `internal-web` **through** `bastion`, so one hop quietly becomes two.

When I ran this on Ubuntu 24.04 (2026) I got:
```
$ cat ~/.ssh/config
Host bastion
    HostName 10.10.10.5
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519

Host internal-web
    HostName 172.16.0.20
    User sam
    ProxyJump bastion
    IdentityFile ~/.ssh/id_ed25519

$ ssh -G internal-web | grep -Ei 'proxyjump|hostname|user |port '
user sam
hostname 172.16.0.20
port 22
proxyjump bastion
```
So `ssh -G` prints the *effective* parsed config, and connecting to `internal-web` will first transit `bastion` (`10.10.10.5`). That `ProxyJump` line **is** the pivot. Full mechanics (and the `-L`/`-R`/`-D` forwarding) live in [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md).

## Stuff I keep straight
- **Pivoting vs tunneling** is the definitional trap: pivoting = reach/routing through a host, tunneling = encapsulation for transport/evasion. Don't merge them.
- **Local (`-L`) vs remote (`-R`) forward:** `-L` opens a port on *my* side to reach *their* side; `-R` opens a port on *their* side to reach *mine* (the classic reverse/callback for locked-down egress). `-D` gives me a **SOCKS** proxy for dynamic, any-port pivoting.
- **Chisel's whole point is egress restriction**, so I pick it when only 80/443 (web/proxy) leaves the network.
- **WireGuard vs OpenVPN:** if the question is "leaner/faster/smaller codebase," it's **WireGuard**; "mature, feature-heavy, TLS-based" is **OpenVPN**.
- Keep it authorized: pivoting/tunneling only inside my own lab, a CTF, or an engagement I'm scoped for.

## Sources
- Red Team / offensive tunneling reference, HackTricks *Tunneling and Port Forwarding*: https://book.hacktricks.xyz/generic-methodologies-and-resources/tunneling-and-port-forwarding
- OpenSSH `ssh_config` (ProxyJump, LocalForward, RemoteForward, DynamicForward): https://man.openbsd.org/ssh_config
- Chisel (jpillora): https://github.com/jpillora/chisel
- WireGuard: https://www.wireguard.com · OpenVPN: https://openvpn.net/community-resources/

## Related
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Chisel](../SSH%20Kali/Chisel.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [WireGuard](../OpenVPN%20Wireguard/WireGuard.md)
- [OpenVPN](../OpenVPN%20Wireguard/OpenVPN.md)
