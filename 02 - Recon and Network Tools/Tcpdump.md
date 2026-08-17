---
tags: [jcu, module3, recon, networking]
jqr: "Tcpdump — packet capture with BPF filters, read payloads, prove cleartext vs encrypted, write/read pcap (-w/-r), and troubleshoot connectivity"
---

# Tcpdump

Tcpdump puts the NIC in promiscuous mode and prints (or saves) packets matching a **BPF filter**. It answers *is traffic actually flowing, to/from whom, on what port, and what's in the payload.* It's how you prove a scan reached the target and how you prove a protocol is cleartext. Capture needs **root** — prefix `sudo`.

## TL;DR

```bash
sudo tcpdump -D                                       # list capturable interfaces
sudo tcpdump -ni eth0 host 192.168.1.20               # -n no DNS, -i iface; filter goes LAST
sudo tcpdump -ni eth0 -A 'tcp port 80'                # -A = ASCII payload (read HTTP in the clear)
sudo tcpdump -ni eth0 -w cap.pcap 'tcp port 4444'     # -w writes a binary pcap (open in Wireshark)
tcpdump -nr cap.pcap                                  # -r reads it back (no root needed to read)
```

- **Always `-n`** (or `-nn`) so DNS lookups don't slow you or tip off a blue team.
- **Filter or drown** — on a busy link an unfiltered capture scrolls too fast to read.
- **Quote filters with `()`** and put the filter **after** the flags.
- `-w` output is binary — don't `cat` it; open with `-r` or Wireshark.

## Concept

Every conversation on a network is a stream of packets: headers (who/where/which port/flags) plus a payload (the actual data). Tcpdump is a tap that copies packets off the wire and shows you those fields. Two caveats that trip people up: you only see traffic **on-path** (on a switched LAN that's mostly just your own box unless you're at a SPAN port/tap), and the payload is only readable if the *application* didn't encrypt it — tcpdump adds no decryption. That second point is the entire cleartext demo below.

## Capture basics

| Command | Meaning |
|---|---|
| `sudo tcpdump -D` | List interfaces you can capture on. |
| `sudo tcpdump -i eth0` | Capture on `eth0`. `-i any` = all interfaces. |
| `sudo tcpdump -ni eth0` | `-n` don't resolve DNS; `-nn` also skips port-name lookups. |
| `sudo tcpdump -i eth0 -c 100` | Stop after 100 packets. |
| `sudo tcpdump -i eth0 -v`/`-vv` | More verbosity (TTL, IP id, options). |
| `sudo tcpdump -i eth0 -s 0` | Full-packet snaplen. Modern tcpdump already defaults to full; `-s 0` fixes truncation on old builds. |

Pick the interface deliberately — capturing on the wrong NIC/VLAN is the #1 reason you "see nothing." See [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md) for finding the right one.

## BPF filters — choose what to capture

Filters go at the **end**, after options.

| Filter | Captures |
|---|---|
| `host 192.168.1.20` | Anything to/from that IP. |
| `src 192.168.1.10` / `dst 192.168.1.20` | Only source / only destination. |
| `port 80` · `src port 22` · `dst port 445` | Port, optionally directional. |
| `portrange 1-1024` | A range of ports. |
| `tcp` / `udp` / `icmp` / `arp` | By protocol. |
| `net 192.168.1.0/24` | A whole subnet. |
| `tcp and port 443` · `port 80 or port 443` · `... and not port 22` | Combine with `and` / `or` / `not`. |
| `'tcp port 80 and (src 192.168.1.10 or dst 192.168.1.10)'` | Group with parens — **quote the whole filter** so the shell doesn't eat the `()`. |

```bash
sudo tcpdump -ni eth0 host 192.168.1.10 and host 192.168.1.20   # everything between two hosts
sudo tcpdump -ni eth0 icmp                                       # watch pings / traceroute
```

## Seeing the payload (`-A`, `-X`)

| Flag | Shows |
|---|---|
| `-A` | Payload as ASCII (great for HTTP and plaintext protocols). |
| `-X` | Hex + ASCII side by side. |
| `-XX` | Same, including the link-layer (Ethernet) header. |

```bash
sudo tcpdump -ni eth0 -A 'tcp port 80'   # → literally read GET requests, Host: headers, HTML
```

## Prove netcat is UNENCRYPTED (the core exercise)

Three roles: a plaintext [Netcat](Netcat.md) listener, a client that sends a secret, and tcpdump watching with `-A`. The captured payload equals exactly what was typed.

```bash
# 1) TARGET (192.168.1.20): nc -lvnp 4444
# 2) CAPTURE (either host): sudo tcpdump -ni eth0 -A 'tcp port 4444'
# 3) ATTACKER (192.168.1.10): nc -nv 192.168.1.20 4444   (then type the secret)
```

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `nc` listener on 4444, `tcpdump -A` on loopback. The secret is right there in the clear:
```
--- what the listener received ---
PASSWORD=SuperSecret123 sent over netcat
--- what tcpdump saw on the wire (note cleartext) ---
gD'.gD'.PASSWORD=SuperSecret123 sent over netcat

04:02:18.984271 IP 127.0.0.1.4444 > 127.0.0.1.43044: Flags [.], ack 42, win 64, options [nop,nop,TS val 1732519726 ecr 1732519726], length 0
```
The `gD'.` bytes are captured TCP/framing noise; `PASSWORD=SuperSecret123` is the payload, unencrypted on the wire. **Lesson: the network encrypts nothing — the application must.** Swap the endpoints for `ncat --ssl` and the same capture shows a TLS handshake then gibberish. Same reason [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md), HTTPS, and VPNs exist while Telnet/FTP/HTTP don't protect you.

## Write and read pcap (`-w` / `-r`)

```bash
sudo tcpdump -ni eth0 -w /tmp/cap.pcap 'tcp port 9999'   # capture to a binary file
tcpdump -nr /tmp/cap.pcap                                # replay it later (no root to read)
```
→ `-w` saves raw packets for Wireshark or a teammate; `-r` reads them back. You can also stream with `-w -` piped to another tool.

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `tcpdump -n -r /tmp/cap.pcap | head -4`, a captured TCP session replayed from disk:
```
04:03:54.028733 IP 127.0.0.1.59942 > 127.0.0.1.9999: Flags [S], seq 3037408872, win 65495, options [mss 65495,sackOK,TS val 1732614771 ecr 0,nop,wscale 10], length 0
04:03:54.028834 IP 127.0.0.1.9999 > 127.0.0.1.59942: Flags [S.], seq 1947781163, ack 3037408873, win 65483, options [mss 65495,sackOK,TS val 1732614771 ecr 1732614771,nop,wscale 10], length 0
04:03:54.028846 IP 127.0.0.1.59942 > 127.0.0.1.9999: Flags [.], ack 1, win 64, options [nop,nop,TS val 1732614771 ecr 1732614771], length 0
04:03:54.028935 IP 127.0.0.1.59942 > 127.0.0.1.9999: Flags [P.], seq 1:12, ack 1, win 64, options [nop,nop,TS val 1732614771 ecr 1732614771], length 11
```
This is the **TCP 3-way handshake** captured live: `[S]` (SYN) → `[S.]` (SYN/ACK) → `[.]` (ACK), then `[P.]` (PSH/ACK, `length 11`) carries the first 11 bytes of data. Reading these flags is how you tell an open port (SYN → SYN/ACK) from a closed one (SYN → `[R.]` reset).

## Confirm the listener / see connections

Before blaming the network, confirm the service is actually bound and watch who's connected with `ss -tulpn` (`-t` TCP, `-u` UDP, `-l` listening, `-p` process, `-n` numeric). Deeper coverage in [Processes and systemd](../03%20-%20Linux%20Skills/Processes%20and%20systemd.md).

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `ss -tulpn`, listening sockets and their owning process:
```
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
tcp   LISTEN 0      128          0.0.0.0:2025       0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2024       0.0.0.0:*
tcp   LISTEN 0      512        127.0.0.1:42569      0.0.0.0:*    users:(("claude",pid=461,fd=13))
tcp   LISTEN 0      4096       127.0.0.1:34007      0.0.0.0:*    users:(("environment-man",pid=473,fd=13))
tcp   LISTEN 0      5            0.0.0.0:8080       0.0.0.0:*    users:(("python3",pid=12539,fd=3))
```
The **Local Address** is the exposure read: `0.0.0.0:8080` = bound to **all interfaces, reachable from the network** (here it's the python3 process); `127.0.0.1:42569` = **localhost only**, not network-facing. `-p` only shows *other users'* process names when you're **root**.

## Troubleshoot connectivity (the method)

Watch for the sender's SYNs on the target, then interpret:

```bash
sudo tcpdump -ni eth0 'tcp port 22 and host 192.168.1.10'
```
- **SYN in, SYN/ACK out** → reachable, port open, both directions work.
- **SYN in, RST out** → reached the host, but the **port is closed** (nothing listening).
- **SYN in, no reply** → a **local firewall** is dropping it (check [iptables](../03%20-%20Linux%20Skills/iptables.md)).
- **No SYN arrives at all** → the break is **upstream** (routing, an in-path firewall, wrong interface/VLAN, ARP). Move the capture toward the sender to find where packets stop.
- Watch **ARP** to confirm layer-2 resolution on the LAN; watch **ICMP** for "unreachable" messages that explain drops.

→ Tcpdump beats guessing because it shows ground truth at each hop, so you can localize whether the break is the app, the host firewall, or the network.

## Exam tips & gotchas

- **Needs root** to capture (raw sockets). Reading a pcap with `-r` does not.
- **Always `-n`/`-nn`** — kills slow DNS lookups and noisy output.
- **Filter, or drown.** Scope every capture with `host`/`port` on a busy link.
- **Quote filters containing `()`** and put them **after** the flags.
- **`-w` is binary pcap** — open with `-r`/Wireshark, never `cat`.
- **On-path only.** A captured "nothing" may just mean you're not in the traffic's path (switched network, wrong SPAN/tap).
- **Truncated payloads?** Add `-s 0` on old builds.

## References

- Daniel Miessler, "A tcpdump Tutorial with Examples" (JQR-named; URL now `/blog/tcpdump`): https://danielmiessler.com/blog/tcpdump
- Official man page: https://www.tcpdump.org/manpages/tcpdump.1.html
- pcap-filter (BPF syntax): https://www.tcpdump.org/manpages/pcap-filter.7.html
- `ss(8)`: https://man7.org/linux/man-pages/man8/ss.8.html

## Related

- [Nmap](Nmap.md)
- [Netcat](Netcat.md)
- [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md)
- [Processes and systemd](../03%20-%20Linux%20Skills/Processes%20and%20systemd.md)
- [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
