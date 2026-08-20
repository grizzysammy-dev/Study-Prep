---
tags: [cyber, module3, recon, networking]
jqr: "Awareness of HTTP/WebSocket tunneling (Chisel): the client/server model, when it's used, and how a defender detects it"
---

# Chisel

Chisel is an open-source, single-binary (Go) tool that tunnels **TCP/UDP over HTTP**. The transport is a **WebSocket over HTTP/HTTPS**, with the tunnel itself secured by SSH-style crypto inside. I'm keeping this **awareness-level** (what it is, when someone reaches for it, and the part I actually care about as a defender, how to spot it), not a weaponisation walkthrough. Official project: `github.com/jpillora/chisel`.

## The short version

- What it is: a TCP/UDP tunnel wrapped in ordinary-looking **HTTP/WebSocket**, so it slips through segments that allow *only* web ports (80/443).
- Model: `chisel server` is the relay/rendezvous (listens on an HTTP(S) port, can offer a SOCKS5 exit, can require auth); `chisel client` dials *out* to it over HTTP/WebSocket and declares which ports or SOCKS proxy to tunnel. It auto-reconnects with backoff.
- When: last resort. A normal [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) forward or a VPN can't get out, but HTTP can.
- Detection tell (the point for me): an "HTTP" connection that's **long-lived**, carries steady **bidirectional** volume, holds a persistent **WebSocket upgrade**, and never looks like real page-fetch browsing.

## What's really going on

- Tunnelling is just encapsulation: wrap protocol X inside protocol Y so X can cross a network that would otherwise block it. I picture sealing the traffic in an envelope addressed like ordinary web mail, and the mailroom (the perimeter proxy) forwards it because all it inspects is the outside of the envelope. Chisel's outer wrapper is **HTTP/WebSocket**, the one thing perimeter proxies are most likely to permit. Lining up the wrappers helps: [OpenVPN](../OpenVPN%20Wireguard/OpenVPN.md) is IP-in-TLS, [WireGuard](../OpenVPN%20Wireguard/WireGuard.md) is IP-in-UDP, SSH forwards are TCP-in-SSH, and Chisel is TCP/UDP-in-HTTP.
- Why WebSocket specifically: plain HTTP is one request, one response, then done, which is useless as a tunnel. A WebSocket *begins* as a normal HTTP request but asks to **upgrade** into a persistent, two-way channel that stays open, exactly the long-lived bidirectional pipe a tunnel needs. Here's the catch, and the gift to the defender: the very feature that makes it work, a persistent, high-volume, two-way "HTTP" session, is what makes it stand out from real browsing. That's the whole basis of the detection section below.
- It's the tool of choice for **pivoting** through tight egress filtering, including **reverse** tunnels (connection dialed client -> server, traffic flowing the other way) to reach a host with no inbound access, see [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md).

## Client/server model (conceptual)

- **Server** (`chisel server`): listens on an HTTP(S) port on a host both sides can see; acts as the relay, optionally offering a SOCKS5 exit and requiring auth.
- **Client** (`chisel client`): connects *out* to that server over HTTP/WebSocket and declares which local↔remote port pairs (or a SOCKS proxy) to tunnel; auto-reconnects with backoff.
- Because everything's wrapped in ordinary-looking HTTP, it slips through firewalls and proxies that only permit web traffic, including via **reverse** tunnels to reach a host that has no inbound path of its own.

If I practice with this on the lab, Chisel is **not** in the base distro repos. I'd take the signed release binary from the official project (`github.com/jpillora/chisel`) and only run it on my own authorised VMs. Never pipe a tunnel binary from a random mirror.

## Detection, the point for a blue-teamer

These tunnels **are detectable**, but the tell is **behavioural, not port-based**:

- An **"HTTP" connection that is unusually long-lived** and carries steady bidirectional volume (real page fetches are short and bursty).
- A persistent **WebSocket upgrade** (`Connection: Upgrade` / `Upgrade: websocket`) that never returns to normal request/response browsing.
- Talks to an **odd or unexpected endpoint**, not a CDN, not a known business destination.
- **Never resembles real browsing**, no mix of asset fetches, referers, or human think-time.

What I'd do: flag long-duration keep-alive HTTP/WebSocket sessions, especially **outbound to non-CDN or non-business destinations**, and correlate with **process and parent** info on the host (a web server or browser spawning a persistent outbound tunnel is suspicious). Controls that terminate or inspect TLS, or that baseline egress, make this far easier, see [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md).

## What to remember

- Chisel is a **last resort**, only when *only* HTTP(S) is allowed through. Otherwise an SSH `-D`/`-L` or a VPN is simpler and quieter.
- The wrapper is **HTTP/WebSocket**; the giveaway is **duration plus bidirectional volume plus a persistent upgrade**, not any specific port.
- **Reverse** tunnels let a no-inbound host be reached, so watch *outbound*, not just inbound.
- Get it from the **official project** (`github.com/jpillora/chisel`); it's not in distro repos, so never curl a tunnel binary from an unofficial source.
- Blue-team framing: **presence plus persistence** is the signal, so I baseline what "normal" web egress looks like and let the anomaly stand out.

## References

- Chisel, official project: https://github.com/jpillora/chisel
- MITRE ATT&CK, Protocol Tunneling (T1572): https://attack.mitre.org/techniques/T1572/
- MITRE ATT&CK, Application Layer Protocol: Web Protocols (T1071.001): https://attack.mitre.org/techniques/T1071/001/

## Related

- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [WireGuard](../OpenVPN%20Wireguard/WireGuard.md)
- [OpenVPN](../OpenVPN%20Wireguard/OpenVPN.md)
- [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md)
