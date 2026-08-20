---
tags: [cyber, module3, recon, networking]
jqr: "My Nmap recon reference: host discovery, TCP/UDP and service/version/OS scanning, NSE scripts, and -oA output"
---

# Nmap

Nmap is the network mapper. It fires crafted packets at a target, reads what comes back, and answers the four things I care about up front: is the host up, which ports are open, what service and version sits behind each one, and what OS it's running. It's almost always my first move against a box, and the XML output drops straight into [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md).

## The commands I reach for

```bash
sudo nmap -sn 192.168.1.0/24                                    # live-host sweep, no port scan
sudo nmap -p- --min-rate 1000 -T4 -oA allports 192.168.1.20     # find EVERY open TCP port, fast
sudo nmap -sCV -p 22,80,445 -oA deep 192.168.1.20               # version + default scripts on found ports
sudo nmap -sU --top-ports 20 192.168.1.20                       # UDP triage (slow — top ports only)
nmap -Pn 192.168.1.20                                           # target blocks ping? skip discovery
```

- The default scan only hits the **top 1000 TCP ports**, not everything. I need `-p-` for the full 65,535.
- `-sS`, `-sU`, `-O`, and full `-A` all want **root**. Without it Nmap quietly drops to `-sT` and can't do OS detection, which has caught me out before.
- Always `-oA <name>` so I can re-query the results later instead of re-scanning.
- My usual rhythm: `-sn` sweep to find hosts, then `-p- -T4 --min-rate 1000` to find open ports, then `-sCV -p <found>` to dig into just those. Never `-sCV` across all 65k ports when the clock is running.

## What it's actually doing

The way I picture a scan: knocking on every door in a building and listening for what comes back. Each TCP port is a door, and TCP's own handshake rules decide the answer. Send a `SYN`, get a `SYN/ACK` back, that's **open** (someone's home). Get a `RST`, that's **closed** (building's there, that door's bolted, nobody behind it). Get silence, that's **filtered**, meaning a guard (a firewall) grabbed my knock before it landed. Nmap reads that state without ever walking through the door, and that's the whole trick.

I'm used to watching these land on sensors from the blue side, so it helps to see what the attacker is actually doing here. Version detection goes further and *talks* to each open port, matching the banner against a fingerprint database. It's literally asking "who are you?" and comparing the reply. OS detection guesses from quirks in the target's TCP/IP stack: the standards leave small choices up to each implementation (initial window size, default TTL, TCP option ordering), so those defaults end up reading like a handwriting sample that gives the OS away. Everything below is just flags to steer those probes.

## Host discovery & target specification

| Command | What it does / output meaning |
|---|---|
| `nmap 192.168.1.20` | Single host. |
| `nmap 192.168.1.20-40` | Range of last octet (.20 to .40). |
| `nmap 192.168.1.0/24` | Whole /24 (256 addresses). |
| `sudo nmap -sn 192.168.1.0/24` | **Host discovery only** ("ping scan"), no port scan. Lists which hosts are up. `-sn` is current; old `-sP` is deprecated but aliased. |
| `nmap -Pn 192.168.1.20` | **Skip discovery, treat target as online.** Use when the host blocks ping but you *know* it's there. Otherwise Nmap says "host down" and scans nothing. |
| `nmap -iL targets.txt` | Read targets from a file (one host/CIDR per line). |
| `nmap --exclude 192.168.1.1 ...` | Skip specific hosts (e.g. the gateway). |

One thing I like about `-sn`: on a LAN it also fires ARP, and ARP replies can't be firewalled, so a local `-sn` still finds hosts even when ICMP is blocked.

Ran `nmap -sn` across a loopback /30 on Ubuntu 24.04 (swap in your real subnet on a live LAN) and got:
```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-08-17 04:02 UTC
Nmap scan report for 127.0.0.0
Host is up.
Nmap scan report for localhost (127.0.0.1)
Host is up.
Nmap scan report for 127.0.0.2
Host is up.
Nmap scan report for 127.0.0.3
Host is up.
Nmap done: 4 IP addresses (4 hosts up) scanned in 0.00 seconds
```

## Scan types (how it probes ports)

| Flag | Name | Root? | When to use |
|---|---|---|---|
| `-sS` | SYN ("half-open") | **Yes** | Default when root. Fast and relatively quiet since it never finishes the handshake. |
| `-sT` | TCP connect() | No | Full 3-way handshake via the OS. Auto-used when **not** root. Noisier / more logged. |
| `-sU` | UDP | **Yes** | DNS 53, SNMP 161, etc. **Slow**, so pair with `--top-ports` or explicit `-p`. |
| `-sA` | TCP ACK | Yes | Maps firewall rules (filtered vs unfiltered). Doesn't find open ports. |
| `-sn` | none | Yes for raw probes | Host discovery only (above). |

The scan *type* matters more than it looks. `-sS` sends the `SYN`, reads the reply, then aborts with a `RST` instead of finishing the handshake, so the target's kernel never hands a completed connection up to the application. App-level logs that only record *established* sessions frequently miss it (a packet-level IDS still sees the SYNs fine). UDP (`-sU`) is slow for the opposite reason: it's connectionless, so an open port usually just stays **silent**, and Nmap can't tell "open" from "filtered" without waiting out timeouts and retries. That's exactly why I cap it with `--top-ports`.

## Service / version & OS detection

| Command | Output meaning |
|---|---|
| `nmap -sV 192.168.1.20` | **Version detection**: service *and* version banner per open port (e.g. `22/tcp open ssh OpenSSH 9.6p1`). Works **without** root. |
| `sudo nmap -O 192.168.1.20` | **OS detection** via stack fingerprinting. Needs root and ideally one open + one closed port. |
| `sudo nmap -A 192.168.1.20` | **Aggressive:** `-O` + `-sV` + `-sC` + `--traceroute` in one pass. Loud but information-rich. |

`-sCV` is the combo I use constantly: default NSE scripts **plus** version detection together.

I ran `nmap -sCV 127.0.0.1` against a local Python `http.server` on Ubuntu 24.04 (the `-sC` default scripts are what add the `http-title` and `http-server-header` lines under the version column):
```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-08-17 04:02 UTC
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000094s latency).

PORT     STATE  SERVICE VERSION
22/tcp   closed ssh
80/tcp   closed http
4444/tcp closed krb524
8080/tcp open   http    SimpleHTTPServer 0.6 (Python 3.11.15)
|_http-title: Directory listing for /
|_http-server-header: SimpleHTTP/0.6 Python/3.11.15

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 7.35 seconds
```
Reading it top-down, only `8080/tcp` is **open**, and the version column IDs it as Python's SimpleHTTPServer 0.6 on 3.11.15. That `4444/tcp closed krb524` line is just Nmap naming the port from `/etc/services`; what matters is the state (`closed`), not the service name it guessed.

Still need to try this one on the lab box: `sudo nmap -O 192.168.1.20` and `sudo nmap -A 192.168.1.20` need root and a real remote target for a confident OS guess (loopback won't fingerprint).

## Port specification & timing

| Flag | Meaning |
|---|---|
| `-p 22,80,443` / `-p 1-1024` | Specific ports / range. |
| `-p-` | **All 65,535 TCP ports**, the thorough sweep. |
| `-p U:53,T:80` | Mix UDP + TCP (needs `-sU -sS`). |
| `--top-ports 100` | The N most common ports (frequency data). Fast triage. |
| `-F` | Fast = top 100. *(no `-p`)* = top 1000. |

On timing, `-T3` is the default but **`-T4` is what I use on a fast lab or LAN** (quicker, still reliable). `-T5` (insane) can drop results on lossy links, and `-T0`/`-T1` are the slow IDS-evasion templates, no good under a timed screen. When I want finer control than the templates give me there's `--min-rate <pps>` and `--max-rate`.

## NSE, the Nmap Scripting Engine (`--script`, `-sC`)

Lua scripts for enumeration, brute-forcing, and vuln checks. They live in `/usr/share/nmap/scripts/`, grouped into categories.

Why it exists: a bare port scan only tells me a door is open, and the next question is always "so what's behind it?" NSE automates that follow-up (enumerate SMB shares, test default creds, check a specific CVE) so discovery and light interrogation happen in the same pass. That's what turns the port scanner into an enumeration engine.

| Command | Meaning |
|---|---|
| `nmap -sC 192.168.1.20` | Run the **default** script set (`--script=default`, safe/discovery). Included in `-A`. |
| `nmap --script vuln 192.168.1.20` | Whole **vuln** category (known CVEs). Intrusive, so get authorization. |
| `nmap --script smb-enum-shares,smb-enum-users -p 445 192.168.1.20` | Enumerate SMB shares + users (classic Windows recon). |
| `nmap --script "http-* and not brute" -p 80 192.168.1.20` | Boolean selection by name/category. |

Categories: `auth, broadcast, brute, default, discovery, dos, exploit, external, fuzzer, intrusive, malware, safe, version, vuln`. Helpers: `nmap --script-help <name>`, `sudo nmap --script-updatedb`.

## Output formats

| Flag | Format | Why |
|---|---|---|
| `-oN file.nmap` | Normal (human-readable) | Read it back later. |
| `-oX file.xml` | XML | Feed to reporting or Metasploit `db_import`. |
| `-oG file.gnmap` | Grepable (one host/line) | `grep`/`awk` for open ports fast. |
| `-oA basename` | **All three at once** | **Use by default**, I never regret having every format. |

Example: `sudo nmap -sCV -p- -oA target_full 192.168.1.20` writes `target_full.nmap/.xml/.gnmap`.

## Gotchas that bite me

- Root matters: `-sS`, `-sU`, `-O`, and full `-A` need `sudo`. No root means auto `-sT` and no OS detection.
- Default is 1000 ports, not all of them. Skip `-p-` and I miss the high-numbered services, so I say so if I'm asked.
- `-Pn` is the one that saves me when a host "seems down"; hardened and Windows boxes drop ICMP all the time.
- UDP is slow and it lies (`open|filtered`). Never `-sU -p-` under the clock, use `--top-ports`.
- `-A` is loud and can crash fragile services (printers, ICS). Fine in a lab, reckless on real fragile kit.
- Save with `-oA` every time so I can re-query without re-scanning.
- Bennieston tutorial caveat: great for the *concepts* but written for Nmap 4.11 (2006 to 2009). It shows the old `-sP` (now `-sn`) and predates NSE, so I trust `nmap.org/book` for current syntax.

## References

- Reference guide / man page: https://nmap.org/book/man.html
- Host discovery: https://nmap.org/book/man-host-discovery.html · Port-scan techniques: https://nmap.org/book/man-port-scanning-techniques.html
- NSE: https://nmap.org/book/nse.html · Script docs: https://nmap.org/nsedoc/
- Bennieston tutorial (JQR-named, dated to Nmap 4.11, uses old `-sP`): https://nmap.org/bennieston-tutorial/

## Related

- [Netcat](Netcat.md)
- [Tcpdump](Tcpdump.md)
- [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
