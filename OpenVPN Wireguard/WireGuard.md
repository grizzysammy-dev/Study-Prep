---
tags: [jcu, module3, recon, networking]
jqr: "Encrypted tunneling — build and verify a minimal WireGuard tunnel between two lab peers (wg0.conf, wg-quick up, wg show)"
---

# WireGuard

WireGuard is a **modern, minimal** VPN that lives **in the Linux kernel** (mainline since 5.6). It's ~4k lines vs OpenVPN's hundreds of thousands, uses fixed modern crypto (Curve25519, ChaCha20-Poly1305 — no cipher negotiation to misconfigure), and is **peer-to-peer**: there's no "server/client" in the protocol, just **peers** identified by their **public key**. UDP-only, fast to stand up, and typically lighter to run than [OpenVPN](OpenVPN.md).

## TL;DR

```bash
sudo apt install wireguard                     # official distro repo
umask 077; wg genkey | tee privatekey | wg pubkey > publickey   # run on EACH peer
# /etc/wireguard/wg0.conf :  [Interface] = THIS box, [Peer] = the OTHER box
sudo wg-quick up wg0                           # on BOTH peers
sudo wg show                                   # handshake + transfer counters
ping 10.9.0.2                                  # send first packet, THEN re-check wg show
```

- **PrivateKey = this host's; Peer PublicKey = the other host's.** Swapping them is the classic failure.
- **`AllowedIPs`** is a routing + access-control filter, **not** a hint — mismatch = silent black-hole.
- WireGuard is **lazy**: no handshake appears until the **first packet** is sent — `ping`, then re-check.
- Both `ListenPort`s and `Endpoint`s must line up; config is `chmod 600`.

## Concept

- **Identity is a public key, full stop.** No username, no session login, no "server." A packet either carries a valid handshake from a key you've listed as a peer, or WireGuard ignores it entirely — think of a bouncer working a guest list of public keys rather than checking IDs at a desk. That's why it's a *virtual NIC* (`wg0`) that quietly appears once configured, not a service you log into.
- Each peer has a **keypair**. You put **your own private key** in *your* config and the **peer's public key** in the `[Peer]` block — never the reverse. That single swap is the most common failure.
- **"Cryptokey routing":** `AllowedIPs` binds a set of tunnel IPs to a peer. Inbound packets whose source isn't in a peer's `AllowedIPs` are **dropped**; only destinations inside it get **routed** to that peer. It is access-control *and* the routing table in one field — not a preference.
- On the wire it's **UDP-only and silent** — because it answers *only* a correctly-authenticated handshake from a known key, to everyone else the port looks dead (no banner, no reset, nothing for a scanner to grab), which makes it stealthier than a TLS VPN. For a blue-teamer the *presence* of an unexpected `wg0` interface or UDP peer is itself the signal.

## Install (official distro repo)

```bash
sudo apt update && sudo apt install wireguard
```
→ Installs the `wg` / `wg-quick` userspace tools; the kernel module ships with modern kernels. On kernels older than 5.6 you'd need `wireguard-dkms` — not needed on 2026 distros, nothing to compile. That the data path lives *in the kernel* is why WireGuard is quick: encrypted packets are handled in-place, without copying each one out to a userspace daemon the way OpenVPN must.

## Generate keys (on EACH peer)

```bash
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
```
→ `wg genkey` makes a private key; `tee` saves it to `privatekey` while piping it into `wg pubkey`, which derives the matching `publickey`. Run this **separately on hostA and on hostB** — two keypairs total. `umask 077` first so the private key isn't world-readable.

## Config for BOTH peers — `/etc/wireguard/wg0.conf`

Tunnel subnet `10.9.0.0/24`; underlay = the real lab LAN.

> 🧪 **Run this on your lab** — verified against current docs, confirm on your box.

**hostA — `/etc/wireguard/wg0.conf`:**
```ini
[Interface]
Address    = 10.9.0.1/24
PrivateKey = <hostA-privatekey>
ListenPort = 51820

[Peer]
PublicKey  = <hostB-publickey>
AllowedIPs = 10.9.0.2/32
Endpoint   = 192.168.1.20:51820
```

**hostB — `/etc/wireguard/wg0.conf`:**
```ini
[Interface]
Address    = 10.9.0.2/24
PrivateKey = <hostB-privatekey>
ListenPort = 51820

[Peer]
PublicKey  = <hostA-publickey>
AllowedIPs = 10.9.0.1/32
Endpoint   = 192.168.1.10:51820
```
→ `[Interface]` = *this* box's tunnel IP, private key, and UDP listen port. `[Peer]` = the *other* box's public key, which tunnel IPs may arrive from / be sent to it (`AllowedIPs`), and where to reach it on the underlay (`Endpoint`). For a point-to-point lab, each side lists the *peer's* tunnel `/32`. `chmod 600 /etc/wireguard/wg0.conf`.

## Bring up and verify

> 🧪 **Run this on your lab** — needs two peers + root + the kernel module; confirm on your box.
```bash
sudo wg-quick up wg0     # on BOTH peers
sudo wg show             # inspect handshake + transfer counters
ip a show wg0            # wg0 exists with its tunnel IP
ping 10.9.0.2            # from hostA -> hostB across the tunnel
```
→ `wg-quick up wg0` reads `/etc/wireguard/wg0.conf`, creates the `wg0` interface, sets the address, and installs routes for the `AllowedIPs`. `wg show` prints each peer and — once traffic flows — a **`latest handshake`** line plus rising `transfer` counters, the proof it's working.
- **Lazy handshake:** `wg show` may list a peer with *no* handshake until the first packet — WireGuard keeps no idle connection warm, so it only runs the (sub-millisecond) handshake when there's actually traffic to carry. `ping` the peer, then re-check.
- Persist across reboot: `sudo systemctl enable wg-quick@wg0`.
- No handshake ever? Firewall is dropping **UDP/51820** (see [iptables](../IP%20Tables%20CentOS/iptables.md)), the `Endpoint` is wrong, or the public keys are swapped. If one side is behind NAT, add `PersistentKeepalive = 25` to its `[Peer]` block so the mapping stays open.
- To route a whole **subnet** through a peer, widen its `AllowedIPs` (e.g. `172.16.5.0/24`) and enable `net.ipv4.ip_forward=1` — see [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md).

## Exam tips & gotchas

- **PrivateKey = yours; Peer PublicKey = theirs.** Never swap them.
- **`AllowedIPs` is a routing/ACL filter**, not a preference — a wrong value silently black-holes traffic.
- **The handshake is lazy** — send a packet (`ping`) before you judge `wg show`.
- **Both `ListenPort`s and `Endpoint`s must line up**; keep the config at `600`.
- No handshake = **UDP/51820 firewalled**, wrong `Endpoint`, or key mix-up; behind NAT -> `PersistentKeepalive = 25`.
- Minimal, fast, in-kernel — contrast with [OpenVPN](OpenVPN.md) (TLS, userspace, more knobs but heavier).

## References

- WireGuard install + quickstart — https://www.wireguard.com/install/ · https://www.wireguard.com/quickstart/
- `wg(8)` / `wg-quick(8)` man pages — https://git.zx2c4.com/wireguard-tools/about/

## Related

- [OpenVPN](OpenVPN.md)
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
