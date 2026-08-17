---
tags: [jcu, module3, recon, networking]
jqr: "Recon with Nmap — host discovery, TCP/UDP + service/version/OS scanning, NSE scripts, and -oA output"
---

# Nmap

The network mapper: it sends crafted packets, reads the replies, and answers four questions — *is the host up, which ports are open, what service/version is behind each, what OS.* This is almost always your first move against a target, and its XML output feeds straight into [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md).

## TL;DR

```bash
sudo nmap -sn 192.168.1.0/24                                    # live-host sweep, no port scan
sudo nmap -p- --min-rate 1000 -T4 -oA allports 192.168.1.20     # find EVERY open TCP port, fast
sudo nmap -sCV -p 22,80,445 -oA deep 192.168.1.20               # version + default scripts on found ports
sudo nmap -sU --top-ports 20 192.168.1.20                       # UDP triage (slow — top ports only)
nmap -Pn 192.168.1.20                                           # target blocks ping? skip discovery
```

- Default scan = **top 1000 TCP ports, NOT all.** Use `-p-` for all 65,535.
- `-sS`, `-sU`, `-O`, and full `-A` need **root** — without it Nmap silently falls back to `-sT` and can't do OS detection.
- Always `-oA <name>` so you can re-query results instead of re-scanning.
- Speed discipline: `-sn` sweep → `-p- -T4 --min-rate 1000` to find ports → `-sCV -p <found>` to go deep. Never `-sCV` all 65k ports under time pressure.

## Concept

Think of a scan as knocking on every door in a building and listening for the reply. Each TCP port is a door, and TCP's own handshake rules dictate the answer: `SYN` → `SYN/ACK` = **open** (someone's home); `SYN` → `RST` = **closed** (the building's there, that door's bolted, nobody behind it); `SYN` → silence = **filtered** (a guard — a firewall — confiscated your knock before it landed). Nmap reads the state without ever walking through the door; that's the whole trick.

From the blue side you *watch* these land on your sensors; here's what the attacker is actually doing. Version detection then *talks* to each open port and matches the banner against a fingerprint database — literally "who are you?" and compare the reply. OS detection guesses from quirks in the target's TCP/IP stack: the standards leave small choices (initial window size, default TTL, TCP option ordering) up to each implementation, so those defaults read like a handwriting sample that gives the OS away. Everything below is just flags to steer those probes.

## Host discovery & target specification

| Command | What it does / output meaning |
|---|---|
| `nmap 192.168.1.20` | Single host. |
| `nmap 192.168.1.20-40` | Range of last octet (.20–.40). |
| `nmap 192.168.1.0/24` | Whole /24 (256 addresses). |
| `sudo nmap -sn 192.168.1.0/24` | **Host discovery only** ("ping scan"), no port scan. Lists which hosts are up. `-sn` is current; old `-sP` is deprecated but aliased. |
| `nmap -Pn 192.168.1.20` | **Skip discovery, treat target as online.** Use when the host blocks ping but you *know* it's there — otherwise Nmap says "host down" and scans nothing. |
| `nmap -iL targets.txt` | Read targets from a file (one host/CIDR per line). |
| `nmap --exclude 192.168.1.1 ...` | Skip specific hosts (e.g. the gateway). |

`-sn` is smart: on a LAN it also fires ARP, and ARP replies can't be firewalled, so local `-sn` finds hosts even when ICMP is blocked.

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `nmap -sn` across a loopback /30 (swap in your real subnet on a live LAN):
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
| `-sS` | SYN ("half-open") | **Yes** | Default when root. Fast + relatively quiet — never finishes the handshake. |
| `-sT` | TCP connect() | No | Full 3-way handshake via the OS. Auto-used when **not** root. Noisier / more logged. |
| `-sU` | UDP | **Yes** | DNS 53, SNMP 161, etc. **Slow** — pair with `--top-ports` or explicit `-p`. |
| `-sA` | TCP ACK | Yes | Maps firewall rules (filtered vs unfiltered) — does *not* find open ports. |
| `-sn` | none | Yes for raw probes | Host discovery only (above). |

> **Why the scan *type* matters:** `-sS` sends the `SYN`, reads the reply, then aborts with a `RST` instead of finishing the handshake — the target's kernel never hands a completed connection up to the application, so app-level logs that only record *established* sessions frequently miss it (a packet-level IDS still sees the SYNs fine). UDP (`-sU`) is slow for the opposite reason: it's connectionless, so an open port usually just stays **silent** — Nmap can't tell "open" from "filtered" without waiting out timeouts and retries, which is exactly why you cap it with `--top-ports`.

## Service / version & OS detection

| Command | Output meaning |
|---|---|
| `nmap -sV 192.168.1.20` | **Version detection** — service *and* version banner per open port (e.g. `22/tcp open ssh OpenSSH 9.6p1`). Works **without** root. |
| `sudo nmap -O 192.168.1.20` | **OS detection** via stack fingerprinting. Needs root and ideally one open + one closed port. |
| `sudo nmap -A 192.168.1.20` | **Aggressive:** `-O` + `-sV` + `-sC` + `--traceroute` in one pass. Loud but information-rich. |

`-sCV` (very common) = default NSE scripts **+** version detection together.

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `nmap -sCV 127.0.0.1` against a local Python `http.server` (the `-sC` default scripts add the `http-title` / `http-server-header` lines under the version column):
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
Read it top-down: only `8080/tcp` is **open**; the version column IDs it as Python's SimpleHTTPServer 0.6 on 3.11.15. `4444/tcp closed krb524` is just Nmap naming the port from `/etc/services` — the state (`closed`), not the guessed service name, is what matters.

> 🧪 **Run this on your lab** — verified against current docs, confirm on your box: `sudo nmap -O 192.168.1.20` and `sudo nmap -A 192.168.1.20` need root + a real remote target for a confident OS guess (loopback won't fingerprint).

## Port specification & timing

| Flag | Meaning |
|---|---|
| `-p 22,80,443` / `-p 1-1024` | Specific ports / range. |
| `-p-` | **All 65,535 TCP ports** — the thorough sweep. |
| `-p U:53,T:80` | Mix UDP + TCP (needs `-sU -sS`). |
| `--top-ports 100` | The N most common ports (frequency data). Fast triage. |
| `-F` | Fast = top 100. *(no `-p`)* = top 1000. |

Timing: `-T3` is the default; **`-T4` is the right call on a fast lab/LAN** (faster, still reliable). `-T5` (insane) can drop results on lossy links; `-T0/-T1` are IDS-evasion slow — not for a timed screen. Reach for `--min-rate <pps>` / `--max-rate` when you want finer control than the templates.

## NSE — the Nmap Scripting Engine (`--script`, `-sC`)

Lua scripts for enumeration, brute-forcing, and vuln checks. Live in `/usr/share/nmap/scripts/`, grouped into categories.

> **Why it exists:** a bare port scan only tells you a door is open — the next question is always "so what's behind it?" NSE automates that follow-up (enumerate SMB shares, test default creds, check a specific CVE) so discovery and light interrogation happen in the same pass, turning the port scanner into an enumeration engine.

| Command | Meaning |
|---|---|
| `nmap -sC 192.168.1.20` | Run the **default** script set (`--script=default`, safe/discovery). Included in `-A`. |
| `nmap --script vuln 192.168.1.20` | Whole **vuln** category (known CVEs). Intrusive — get authorization. |
| `nmap --script smb-enum-shares,smb-enum-users -p 445 192.168.1.20` | Enumerate SMB shares + users (classic Windows recon). |
| `nmap --script "http-* and not brute" -p 80 192.168.1.20` | Boolean selection by name/category. |

Categories: `auth, broadcast, brute, default, discovery, dos, exploit, external, fuzzer, intrusive, malware, safe, version, vuln`. Helpers: `nmap --script-help <name>`, `sudo nmap --script-updatedb`.

## Output formats

| Flag | Format | Why |
|---|---|---|
| `-oN file.nmap` | Normal (human-readable) | Read it back later. |
| `-oX file.xml` | XML | Feed to reporting or Metasploit `db_import`. |
| `-oG file.gnmap` | Grepable (one host/line) | `grep`/`awk` for open ports fast. |
| `-oA basename` | **All three at once** | **Use by default** — you never regret having every format. |

Example: `sudo nmap -sCV -p- -oA target_full 192.168.1.20` writes `target_full.nmap/.xml/.gnmap`.

## Exam tips & gotchas

- **Root matters:** `-sS`, `-sU`, `-O`, full `-A` need `sudo`. No root → auto `-sT`, no OS detection.
- **Default is 1000 ports, not all.** No `-p-` → you miss high-numbered services. Say so if asked.
- **`-Pn` is your friend** when a host "seems down" — hardened/Windows boxes routinely drop ICMP.
- **UDP is slow and lies** (`open|filtered`). Never `-sU -p-` under the clock; use `--top-ports`.
- **`-A` is loud** and can crash fragile services (printers, ICS). Fine in a lab, reckless on real fragile kit.
- **Save with `-oA`** every time so you can re-query without re-scanning.
- **Bennieston tutorial caveat:** great for *concepts* but written for Nmap 4.11 (2006–2009) — it shows the old `-sP` (now `-sn`) and predates NSE. Trust `nmap.org/book` for current syntax.

## References

- Reference guide / man page: https://nmap.org/book/man.html
- Host discovery: https://nmap.org/book/man-host-discovery.html · Port-scan techniques: https://nmap.org/book/man-port-scanning-techniques.html
- NSE: https://nmap.org/book/nse.html · Script docs: https://nmap.org/nsedoc/
- Bennieston tutorial (JQR-named — dated to Nmap 4.11, uses old `-sP`): https://nmap.org/bennieston-tutorial/

## Related

- [Netcat](Netcat.md)
- [Tcpdump](Tcpdump.md)
- [Enumeration Tools](../Knowledge%20Req/Enumeration%20Tools.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
