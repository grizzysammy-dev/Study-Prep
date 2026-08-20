---
tags: [cyber, module3, recon, networking]
jqr: "Encrypted tunneling: build and verify a static-key point-to-point OpenVPN tunnel between two lab VMs"
---

# OpenVPN

OpenVPN is a **TLS-based VPN** that runs in userspace and creates a virtual network interface (`tun` for routed/IP-layer, `tap` for bridged/Ethernet-layer). Once it's up I route normally, because it's a network adapter, not a per-app hole like an [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) forward. For a two-VM lab the simplest form is a **static-key (pre-shared-key) point-to-point tunnel**: no certificate authority, one shared secret, one `tun` link between hostA and hostB.

## The setup, start to finish

```bash
sudo apt install openvpn                        # official distro repo (2.6)
openvpn --genkey secret static.key              # 2.6 syntax; copy to BOTH VMs, chmod 600
# hostA server.conf:  ifconfig 10.8.0.1 10.8.0.2   (MY tun IP first, PEER's second)
# hostB client.conf:  ifconfig 10.8.0.2 10.8.0.1   (REVERSED) + remote 192.168.1.10
sudo openvpn --config /etc/openvpn/server.conf  # hostA  (or: systemctl start openvpn@server)
sudo openvpn --config /etc/openvpn/client.conf  # hostB
ip a show tun0 ; ping 10.8.0.2                  # verify: tun0 exists + peer answers
```

- The `ifconfig` addresses flip between server and client: *my* tunnel IP first, *peer's* second.
- `--genkey secret <file>` is the 2.6 syntax (`--genkey --secret` is deprecated).
- Look for **`Initialization Sequence Completed`** in the log; that's the "it works" line.
- `proto` and `port` must match on both ends; only the client needs `remote`.

## What a VPN actually gives me

- What a VPN actually hands me: a whole virtual network card (`tun0`) with its own IP, not a single per-app hole like an SSH `-L` forward. Once it's up I just *route* to a tunnel IP, and the kernel hands that packet to the OpenVPN process, which encrypts it and ships it to the peer, where it's decrypted and injected as if it had arrived locally. `tun` carries IP packets (layer 3, what I want here); `tap` carries raw Ethernet frames (layer 2, for bridging).
- Static-key mode has no perfect forward secrecy and is deprecated in OpenVPN 2.6. One fixed key encrypts every session forever, so if it ever leaks, all the traffic anyone captured in the past decrypts too. That's exactly what forward secrecy prevents: TLS and certs negotiate a fresh ephemeral key per session, so a later key compromise can't retro-decrypt old recordings. It's fine for an isolated lab to learn the mechanics, but **not** for production (that uses TLS and certificates, or `--peer-fingerprint`). [WireGuard](WireGuard.md) is the modern minimal alternative.
- Whoever holds `static.key` can join the tunnel, so I treat it like a password. Move it between VMs over a secure channel ([SCP](../SSH%20Kali/SCP.md)), never in the clear, and `chmod 600` it on both.
- The tunnel gets its **own IP subnet** (here `10.8.0.0`) laid over the real lab LAN (the "underlay"). Traffic addressed to a tunnel IP is encrypted and carried inside UDP to the peer's real address.

## Install (official distro repo)

```bash
sudo apt update && sudo apt install openvpn
```
Installs OpenVPN 2.6 from the distro repo. The `tun` kernel module and `/dev/net/tun` have to be available. They are on standard VM kernels, though some minimal containers strip them (`sudo modprobe tun`).

## Generate the shared static key (once)

```bash
openvpn --genkey secret static.key
```
Writes a random pre-shared key to `static.key`. The **2.6 syntax is `--genkey secret <file>`** (subcommand form); the old `openvpn --genkey --secret static.key` still works but is deprecated, so don't be surprised to see it in old guides. Copy `static.key` to the **other** VM over a secure channel and `chmod 600` it on both.

## hostA config (server side), `192.168.1.10`

Haven't stood this up on the lab yet, this is the config:
```conf
# /etc/openvpn/server.conf   (on hostA)
dev tun
ifconfig 10.8.0.1 10.8.0.2      # MY tunnel IP first, PEER's second
secret static.key
proto udp
port 1194
```

## hostB config (client side), `192.168.1.20`

Same idea, for the other box:
```conf
# /etc/openvpn/client.conf   (on hostB)
dev tun
remote 192.168.1.10             # hostA's real (underlay) address
ifconfig 10.8.0.2 10.8.0.1      # addresses REVERSED vs the server
secret static.key
proto udp
port 1194
```
The addresses flip: each side lists **its own** tunnel IP first, the **peer's** second. Server is `ifconfig 10.8.0.1 10.8.0.2`, client is `ifconfig 10.8.0.2 10.8.0.1`. Get this backwards and the tunnel comes up but nothing routes. `proto` and `port` must match on both ends; only the client needs `remote`.

## Bring it up and verify

This part needs two VMs, root, and the `tun` device, so it's still a to-do on the lab:
```bash
# Foreground (watch the handshake) — run on BOTH VMs, each with its own conf:
sudo openvpn --config /etc/openvpn/server.conf     # on hostA
sudo openvpn --config /etc/openvpn/client.conf     # on hostB

# Or as a managed service (systemd reads /etc/openvpn/*.conf):
sudo systemctl start openvpn@server                # on hostA
sudo systemctl start openvpn@client                # on hostB
```
Verify:
```bash
ip a show tun0        # tun0 exists: 10.8.0.1 (hostA) / 10.8.0.2 (hostB)
ping 10.8.0.2         # from hostA -> reaches hostB across the tunnel
ping 10.8.0.1         # from hostB -> reaches hostA
```
Each `openvpn` process creates `tun0` and completes the UDP handshake, and a successful `ping` of the peer's **tunnel** IP proves the encrypted link is carrying traffic.
- The log line **`Initialization Sequence Completed`** means success.
- If it hangs: a firewall is dropping **UDP/1194** (open it on hostA, see [iptables](../IP%20Tables%20CentOS/iptables.md)), the key doesn't match, or the `tun` module isn't loaded (`sudo modprobe tun`).
- To route a whole **subnet** across the tunnel (not just ping the peer) I'd add `route` statements and enable `net.ipv4.ip_forward=1`, see [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md).

## The mistakes I watch for

- The `ifconfig` addresses flip server vs client, the number one static-key mistake.
- `--genkey secret file` (2.6) vs the deprecated `--genkey --secret file`.
- `proto` and `port` must match on both ends; only the client carries `remote`.
- `Initialization Sequence Completed` is the log line that means "up."
- Hang = **UDP/1194 firewalled**, key mismatch, or missing `tun` module (`modprobe tun`).
- Static key means **no PFS and deprecated**, so lab-only for learning; production is TLS and certs. I prefer [WireGuard](WireGuard.md) for a minimal modern tunnel.

## References

- OpenVPN community HOWTO + Static Key Mini-HOWTO: https://openvpn.net/community-resources/how-to/
- `openvpn(8)` reference manual (2.6): https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/

## Related

- [WireGuard](WireGuard.md)
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
