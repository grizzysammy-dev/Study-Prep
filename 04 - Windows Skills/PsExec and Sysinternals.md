---
tags: [jcu, module3, windows]
jqr: "PsExec (Sysinternals): official download; remote command execution; -s run as SYSTEM; -c copy-and-run; understand why EDR flags it and its legitimate admin/IR use"
---

# PsExec and Sysinternals

**PsExec** is a genuine Microsoft **Sysinternals** tool that runs a program on a remote Windows box. It's a standard remote-admin and incident-response utility — and, because attackers abuse the same capability, one your EDR will flag. Knowing it from the defender's side (what it looks like on the wire and in logs) is the point. Attacker-side lateral movement with the same technique is in [SMB PsExec and DCOM](../05%20-%20Metasploit%20and%20Exploitation/SMB%20PsExec%20and%20DCOM.md).

## TL;DR
```cmd
psexec \\192.168.1.20 -u labuser -p Pass123! cmd      :: interactive shell on the remote box
psexec \\192.168.1.20 -u labuser ipconfig /all         :: one command remotely (omit -p to be prompted)
psexec -i -s cmd                                       :: SYSTEM shell on the LOCAL box
psexec \\192.168.1.20 -u labuser -c C:\tools\collect.exe  :: copy a local exe over, then run it
```
> **Official download only:** `https://download.sysinternals.com/files/PSTools.zip` (current PsExec **v2.43**). Never grab it from a random mirror.

## Concept — how it works
Point PsExec at `\\host` and it:
1. connects to the target's **`ADMIN$`** share (so it needs File & Printer Sharing on and **admin credentials** on the target),
2. drops a small service binary and registers a temporary **service**,
3. runs your program (piping stdin/stdout back to you), then
4. removes the service and cleans up.

That "install a service over SMB to run code" pattern is exactly what makes it powerful for admins **and** noisy for defenders — it lights up as service-creation events. First run adds `-accepteula` to clear the licence dialog.

> The broader **Sysinternals** suite (Process Explorer, Autoruns, Procmon, PsList, etc.) is a set of free Microsoft diagnostic tools from the same source — all under `https://learn.microsoft.com/sysinternals`.

## Get it (official only)
- Suite ZIP: `https://download.sysinternals.com/files/PSTools.zip`
- Run live over SMB: `\\live.sysinternals.com\tools\psexec.exe`

## Core syntax
```cmd
psexec \\192.168.1.20 -u labuser -p Pass123! cmd
```
→ Opens an interactive **cmd** on `192.168.1.20`. **Omit `-p`** to be prompted for the password instead of putting it on the command line (safer — see gotchas).

## Key switches
| Switch | Meaning |
|---|---|
| `\\host` | target computer (or `@list.txt` for many) |
| `-u` / `-p` | username / password on the target |
| `-s` | run as **SYSTEM** (LocalSystem) — highest local account |
| `-c` | **copy** the named local exe to the target, then run it |
| `-f` / `-v` | with `-c`: force overwrite / copy only if newer |
| `-i [session]` | run **interactively** on the target's desktop |
| `-d` | don't wait — launch and return immediately |
| `-accepteula` | auto-accept the EULA (first run) |

## Common examples
```cmd
:: Run one command remotely and see the output
psexec \\192.168.1.20 -u labuser -p Pass123! ipconfig /all

:: Get a SYSTEM-level shell on the LOCAL machine (troubleshooting / accessing SYSTEM-only paths)
psexec -i -s cmd

:: Copy a local collection tool to the target and run it there
psexec \\192.168.1.20 -u labuser -p Pass123! -c C:\tools\collect.exe

:: Fire-and-forget an install on the remote box
psexec \\192.168.1.20 -u labuser -p Pass123! -d -c setup.exe /quiet
```
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. `psexec -i -s cmd` giving a `whoami` of `nt authority\system` is the quickest way to see the `-s` flag work.

## Legitimate use vs why EDR flags it
- **Legit:** remote administration, pushing a fix or collection tool to a host, getting a SYSTEM shell to reach SYSTEM-only files, mass-running a command across `@hosts.txt`.
- **Why it's flagged:** the same "auth to `ADMIN$`, create a service, run code as SYSTEM" flow is a textbook **lateral-movement** technique (MITRE ATT&CK **T1569.002 Service Execution** / **T1021.002 SMB Admin Shares**). In a lab that alert is expected; on production, expect it to page the SOC.
- **Defensive detections:** Security **4624 type 3** (network logon) + **4672** (admin privileges) from a remote host, System **7045** (new service installed) with a short random service name, and the `PSEXESVC` service/binary artefact.

## Modern alternative — PowerShell Remoting
Does the same job over **WinRM** and is generally cleaner/logged:
```powershell
Enable-PSRemoting                                              # on the target, once
Enter-PSSession -ComputerName 192.168.1.20 -Credential labuser # interactive
Invoke-Command -ComputerName 192.168.1.20 -ScriptBlock { ipconfig /all }
```
→ If the box already has WinRM, prefer PS Remoting; reach for PsExec when WinRM is off or you specifically need `-s`/`-i`.

## Exam tips & gotchas
- **Download source matters:** official Sysinternals URL only. Citing a random download in a screening is a red flag against you.
- **Needs `ADMIN$` reachable + admin creds on the target** and File & Printer Sharing on — "access denied" usually means one of those, not a PsExec bug.
- **`-p` leaks the password** into history/logs — omit it to be prompted.
- **`-s` = SYSTEM**, `-i` = interact with the desktop; `psexec -i -s cmd` is the local "become SYSTEM" one-liner.
- **Expect AV/EDR alerts** — it's dual-use. That's a feature to understand, not a malfunction.

## References
- PsExec (Sysinternals) — https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
- Sysinternals suite — https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite
- MITRE ATT&CK T1569.002 (Service Execution) — https://attack.mitre.org/techniques/T1569/002/
- MITRE ATT&CK T1021.002 (SMB/Windows Admin Shares) — https://attack.mitre.org/techniques/T1021/002/

## Related
- [SMB PsExec and DCOM](../05%20-%20Metasploit%20and%20Exploitation/SMB%20PsExec%20and%20DCOM.md)
- [Metasploit Workflow](../05%20-%20Metasploit%20and%20Exploitation/Metasploit%20Workflow.md)
- [Windows Logs and Scheduled Tasks](Windows%20Logs%20and%20Scheduled%20Tasks.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [Privilege Escalation Concepts](../05%20-%20Metasploit%20and%20Exploitation/Privilege%20Escalation%20Concepts.md)
