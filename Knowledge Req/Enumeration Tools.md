---
tags: [jcu, module3, recon]
jqr: "Module 3 — enumeration & privesc-discovery tooling: enum4linux(-ng), PEASS-ng (linpeas/winPEAS), WindowsEnum, JAWS"
---

# Enumeration Tools

The standard scripts that *find* things for you: SMB/Samba enumeration from the outside (enum4linux), and local privilege-escalation enumeration from a foothold (PEASS-ng, WindowsEnum, JAWS). They **find** the vector — you still exploit it (see [Privilege Escalation Concepts](Privilege%20Escalation%20Concepts.md)).

> 🧪 **Run this on your lab (Kali 2026.2)** — run these only against your own VMs / CTF targets. No live output in the study sandbox; commands and sources verified against current docs, confirm on your box.

## TL;DR

```bash
enum4linux-ng -A 192.168.1.20     # SMB/Samba: users, shares, groups, policy, OS (modern rewrite)
./linpeas.sh                      # Linux local privesc enum (RED/YELLOW = interesting)
winPEASx64.exe                    # Windows local privesc enum
.\jaws-enum.ps1                   # Windows privesc enum, stock PowerShell, no deps
```

## Concept

**Mental model:** enumeration is *casing the building*, automated. These scripts are a tireless clipboard-carrier that walks the target and writes down every unlocked door, every account, every misconfigured lock — then highlights the handful worth trying. They **find** the opening; they don't kick it in (that's the next note). Why they exist: a human checking dozens of privesc conditions by hand takes an hour and still misses things; the script runs every known check in seconds and colour-codes the hits. *(Blue-side bonus: run the same script on your own hosts and that RED/YELLOW output is a free hardening to-do list.)*

Two jobs, two kinds of tool:

- **Remote/service enumeration** — from your Kali box, poke a service to list what it exposes. `enum4linux(-ng)` does this for SMB.
- **Local (post-foothold) enumeration** — after you land a shell, run a script *on the target* that checks dozens of known privesc conditions and highlights the promising ones. That's PEASS-ng (linpeas/winPEAS), WindowsEnum, and JAWS.

All are standalone scripts from official project repos. Get them onto the target with meterpreter `upload`, [SCP](../SSH%20Kali/SCP.md), or a share — then run them. Only ever run tools you fetched from the official source below.

## enum4linux / enum4linux-ng — SMB/Samba enumeration

Enumerates **users, shares, groups, password policy, and OS info** from SMB/Samba over RPC (it wraps `smbclient`, `rpcclient`, `nmblookup`, `net`).

```bash
enum4linux -a 192.168.1.20        # original (Perl): -a = do everything
```
→ The classic one-shot. Older Perl wrapper; noisy but familiar.

```bash
enum4linux-ng -A 192.168.1.20     # next-gen (Python): -A = all, adds JSON/YAML export
```
→ Faster, structured output, actively maintained — **preferred in 2026**.

- **enum4linux (original):** Perl wrapper by Mark Lowe / Portcullis — https://github.com/the-useless-one/enum4linux
- **enum4linux-ng (modern rewrite):** https://github.com/cddmp/enum4linux-ng

→ Pairs directly with the MSF SMB scanners in [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md).

## PEASS-ng — linpeas / winPEAS (local privesc enum)

**PEASS-ng** = "Privilege Escalation Awesome Scripts SUITE, next-gen" — the standard local-enum scripts that highlight likely privesc paths with colour-coded output. Run them *after* getting a foothold.

- **Official repo:** https://github.com/peass-ng/PEASS-ng  (formerly github.com/carlospolop/PEASS-ng). Author: Carlos Polop.

```bash
# Linux target (after upload via meterpreter / scp)
chmod +x linpeas.sh
./linpeas.sh
```
→ **RED/YELLOW** highlights = the most interesting findings. Checks SUID/sudo/cron/capabilities/writable paths.

```text
# Windows target (run from the foothold shell)
winPEASx64.exe
```
→ Windows build variants: `winPEASx64.exe`, `winPEASany.exe`, or the `winPEAS.bat` script. Checks services, unquoted paths, tokens, AlwaysInstallElevated, saved creds, patch level.

## WindowsEnum & JAWS — Windows privesc enum in PowerShell

Both are **PowerShell privilege-escalation enumeration scripts** — the Windows analogue of linpeas, handy when you can't drop winPEAS.

```powershell
# WindowsEnum
.\WindowsEnum.ps1
```
→ PowerShell privesc enum. Source: https://github.com/absolomb/WindowsEnum

```powershell
# JAWS — "Just Another Windows Script"; runs on a stock install, no extra modules
powershell.exe -ExecutionPolicy Bypass -File .\jaws-enum.ps1 -OutputFilename jaws-out.txt
```
→ Built to run on default PowerShell with no dependencies; writes findings to a file. Source: https://github.com/411Hall/JAWS

## Tool-picker cheat

| Situation | Reach for |
|---|---|
| Remote SMB/Samba box, want users/shares/policy | `enum4linux-ng -A` |
| Linux foothold, find privesc | `linpeas.sh` |
| Windows foothold, can drop a binary | `winPEASx64.exe` |
| Windows foothold, binaries blocked / PS only | `WindowsEnum.ps1` or `jaws-enum.ps1` |

## Exam tips & gotchas

- **enum4linux-ng (Python) over enum4linux (Perl)** in 2026 — structured output and still maintained.
- **PEASS repo moved** to `github.com/peass-ng/PEASS-ng` (old `carlospolop` path redirects). Cite the new one.
- **linpeas needs `chmod +x`** after upload; run it and read the RED/YELLOW lines first.
- **JAWS is the "no dependencies" option** — reach for it when the box has a locked-down/stock PowerShell and winPEAS won't run.
- **These tools only enumerate** — they surface the vector; you still perform the escalation (GTFOBins/LOLBAS in [Privilege Escalation Concepts](Privilege%20Escalation%20Concepts.md)).
- **Only download from the official repos above** — never pipe a random script from an untrusted URL onto a target.

## References

- enum4linux-ng — https://github.com/cddmp/enum4linux-ng
- enum4linux (original) — https://github.com/the-useless-one/enum4linux
- PEASS-ng (linpeas / winPEAS) — https://github.com/peass-ng/PEASS-ng
- WindowsEnum — https://github.com/absolomb/WindowsEnum
- JAWS — https://github.com/411Hall/JAWS

## Related

- [Privilege Escalation Concepts](Privilege%20Escalation%20Concepts.md)
- [Meterpreter](../C2%20Frameworks/Metasploit/Meterpreter.md)
- [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)
- [Nmap](../Recon%20Tools/Nmap.md)
