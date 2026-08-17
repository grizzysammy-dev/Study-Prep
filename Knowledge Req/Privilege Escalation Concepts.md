---
tags: [jcu, module2, privesc]
jqr: "Module 2 — exploitation vs privilege escalation; vertical/horizontal; Linux & Windows privesc vectors; GTFOBins/LOLBAS toolset map"
---

# Privilege Escalation Concepts

The conceptual half of Module 2: what privilege escalation *is*, how it differs from exploitation, the common Linux and Windows vectors, and which reference/tool goes with each. Defensive-aware — knowing the vector is how you close it.

> 🧪 **Run this on your lab (Kali 2026.2)** — the quick-check commands run on your own VMs / CTF targets. No live output in the study sandbox; verified against current docs, confirm on your box.

## TL;DR

- **Exploitation** = getting *in* (initial code execution). **Privesc** = getting *higher* once inside.
- **Vertical** = lower → higher privilege (user → root/SYSTEM). **Horizontal** = same level, different account.
- **Linux quick checks:** `sudo -l`, `find / -perm -4000 -type f 2>/dev/null`, `getcap -r / 2>/dev/null` → look up the binary on **GTFOBins**.
- **Windows quick checks:** `whoami /priv` (SeImpersonate?), unquoted service paths, weak service perms → **LOLBAS**.
- **Find vectors with** [Enumeration Tools](Enumeration%20Tools.md); **escalate**, then loot.

## Concept

**Mental model:** exploitation gets you *through the front door* — you're now inside as a guest. Privilege escalation is finding the *master key* that turns a guest into the building manager. **Vertical** privesc is becoming the manager (more power); **horizontal** privesc is pocketing another guest's room key (same power, someone else's stuff). Attackers almost always chain them: exploit once to get in, then privesc to actually own the box.

- **Exploitation** — abusing a vulnerability or misconfiguration to gain **initial** unauthorized code execution or access (the "foothold").
- **Privilege escalation (privesc)** — increasing your access level *after* the foothold:
  - **Vertical** — lower → higher privilege (standard user → **root** / **SYSTEM** / Administrator). The usual goal.
  - **Horizontal** — same privilege level, **different account** (user A → user B) to reach that user's data or access.

You typically exploit *once* to get in, then privesc to own the box. Metasploit and its payload ([Meterpreter](../C2%20Frameworks/Metasploit/Meterpreter.md)) help with both; dedicated enum scripts ([Enumeration Tools](Enumeration%20Tools.md)) find the privesc path.

## Common Linux privesc vectors

| Vector | Quick check | Idea |
|---|---|---|
| **SUID binaries** | `find / -perm -4000 -type f 2>/dev/null` | Binary runs as its owner (often root) → abuse to run commands as root |
| **sudo misconfig** | `sudo -l` | Allowed commands may be abusable to spawn a root shell |
| **Cron jobs** | `cat /etc/crontab`; look for writable scripts | Writable script run by root → inject commands (see [cron](../Linux%20Admin/cron.md)) |
| **Capabilities** | `getcap -r / 2>/dev/null` | e.g. `cap_setuid` on a binary → root |
| **Kernel exploits** | `uname -a` vs known CVEs | Last resort; can crash the box |

> **Why SUID is the crown jewel:** a SUID binary runs with the privileges of its *owner*, not whoever launched it. So a root-owned SUID program that can be coaxed into running an arbitrary command (e.g. a text editor's shell escape) executes *your* command as root. The enum script finds the SUID bit; GTFOBins tells you the escape.

> [!tip] GTFOBins — https://gtfobins.github.io/
> Lookup table of how to abuse a specific **SUID / sudo / capability** binary (`find`, `vim`, `less`, `python`, ...) to break out to a shell or escalate. If `sudo -l` shows a binary, check GTFOBins for the exact escape. File permissions matter here — cross-reference [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md).

## Common Windows privesc vectors

| Vector | Idea |
|---|---|
| **Unquoted service paths** | Service path with spaces + no quotes + a writable folder → drop an exe that runs as the service account |
| **Weak service permissions** | You can reconfigure a service's binPath → point it at your payload |
| **Token impersonation** | Hold `SeImpersonatePrivilege` (common on service accounts) → "Potato" attacks impersonate SYSTEM. Check with `whoami /priv` |
| **AlwaysInstallElevated** | Registry misconfig → any `.msi` installs as SYSTEM |
| **DLL hijacking / saved creds** | App loads a DLL from a writable path; stored creds in registry / `cmdkey` |

> [!tip] LOLBAS — https://lolbas-project.github.io/
> The Windows analogue of GTFOBins — legitimate, signed "living off the land" binaries abused for execution or bypass. Pair with [icacls and Permissions](../Win%20Admin/icacls%20and%20Permissions.md) to judge whether a service path/folder is actually writable.

## Toolset map — which tool for which phase

| Phase | Tools |
|---|---|
| Recon / enum | [Nmap](../Recon%20Tools/Nmap.md) / `db_nmap`, enum4linux(-ng), MSF scanners, WindowsEnum / JAWS |
| Exploitation | **Metasploit** ([Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)), **Exploit-DB / searchsploit**, **MSFvenom** payloads |
| Post / privesc enum | **PEASS-ng** (linpeas / winPEAS), meterpreter `getsystem` / `getprivs` |
| Privesc reference | **GTFOBins** (Linux), **LOLBAS** (Windows) |

→ `searchsploit <term>` (offline Exploit-DB search, ships in Kali) finds a PoC when no MSF module exists; `searchsploit -m <edb-id>` mirrors a copy locally. Many MSF modules originate from Exploit-DB PoCs.

## Defensive notes (know the fix, not just the attack)

- **SUID/sudo:** audit `find / -perm -4000`, keep `sudoers` least-privilege, avoid shell-escapable binaries in `NOPASSWD` rules.
- **Unquoted service paths:** quote every service `ImagePath`; deny write on `Program Files` subfolders.
- **Token abuse:** limit which service accounts hold `SeImpersonatePrivilege`; patch (many Potato variants are patched).
- **AlwaysInstallElevated:** ensure the two registry keys are `0` via GPO.
- Enumeration scripts are dual-use: run PEASS on your *own* hosts as a hardening audit.

## Exam tips & gotchas

- **Exploitation vs privesc is a definitions question** — exploitation = initial access; privesc = raising privilege after. Don't blur them.
- **Vertical vs horizontal** — vertical changes *level* (user→root), horizontal changes *account* at the same level.
- **First move on any foothold:** Linux → `sudo -l` and `id`; Windows → `whoami /priv` and `whoami /groups`.
- **GTFOBins = Linux binary abuse; LOLBAS = Windows binary abuse.** Don't mix them up.
- **Enumerate before you exploit** — burning random kernel exploits can crash the target; let [Enumeration Tools](Enumeration%20Tools.md) point you first.
- **PsExec/pass-the-hash is lateral movement, not privesc** — it reuses admin creds you already hold (see [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)).

## References

- GTFOBins (Linux SUID/sudo/capability abuse) — https://gtfobins.github.io/
- LOLBAS (Windows living-off-the-land binaries) — https://lolbas-project.github.io/
- HackTricks — Linux privilege escalation — https://book.hacktricks.xyz/linux-hardening/privilege-escalation
- HackTricks — Windows local privilege escalation — https://book.hacktricks.xyz/windows-hardening/windows-local-privilege-escalation
- MITRE ATT&CK — Privilege Escalation (TA0004) — https://attack.mitre.org/tactics/TA0004/
- MITRE ATT&CK — Access Token Manipulation (T1134) — https://attack.mitre.org/techniques/T1134/

## Related

- [Meterpreter](../C2%20Frameworks/Metasploit/Meterpreter.md)
- [Enumeration Tools](Enumeration%20Tools.md)
- [Common Software Vulnerabilities](Common%20Software%20Vulnerabilities.md)
- [Pivoting and Tunneling](Pivoting%20and%20Tunneling.md)
- [icacls and Permissions](../Win%20Admin/icacls%20and%20Permissions.md)
