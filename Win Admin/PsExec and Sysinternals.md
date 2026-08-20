---
tags: [cyber, module3, windows]
jqr: "PsExec (Sysinternals): the official download, remote command execution, -s to run as SYSTEM, -c to copy-and-run, and understanding why EDR flags it plus its legitimate admin/IR use"
---

# PsExec and Sysinternals

**PsExec** is a real Microsoft **Sysinternals** tool that runs a program on a remote Windows box. It's a standard remote-admin and incident-response utility, and because attackers abuse the exact same capability, it's also one my EDR will flag. The point for me is knowing it from the defender's side: what it looks like on the wire and in the logs. The attacker-side lateral movement with the same technique is in [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md).

## The commands I reach for
```cmd
psexec \\192.168.1.20 -u labuser -p Pass123! cmd      :: interactive shell on the remote box
psexec \\192.168.1.20 -u labuser ipconfig /all         :: one command remotely (omit -p to be prompted)
psexec -i -s cmd                                       :: SYSTEM shell on the LOCAL box
psexec \\192.168.1.20 -u labuser -c C:\tools\collect.exe  :: copy a local exe over, then run it
```
> **Official download only:** `https://download.sysinternals.com/files/PSTools.zip` (current PsExec is **v2.43**). I never grab it from a random mirror.

## How it works
Point PsExec at `\\host` and it:
1. connects to the target's **`ADMIN$`** share (so it needs File & Printer Sharing on and **admin credentials** on the target),
2. drops a small service binary and registers a temporary **service**,
3. runs my program (piping stdin/stdout back to me), then
4. removes the service and cleans up.

That "install a service over SMB to run code" pattern is exactly what makes it powerful for admins **and** noisy for defenders, since it lights up as service-creation events. On the first run I add `-accepteula` to clear the licence dialog.

> **Why it needs admin creds (this isn't a vuln):** `ADMIN$` is a hidden share auto-mapped to `C:\Windows` that only local admins can open. PsExec's whole trust model is "if you can already write to `ADMIN$`, you're already admin on this box, so running code is fair game." Nothing is being *escalated*, it's just spending admin rights I had to prove up front.

> **Why a service, and why that yields SYSTEM:** to launch a process in another account's context on a remote box, you hand the job to the target's **Service Control Manager**, and services start as **LocalSystem (SYSTEM)** by default, the machine's own account, which sits *above* Administrator locally. So `-s` isn't impersonation; the SCM is genuinely running the binary as itself. The stdin/stdout relay rides back over a **named pipe** (`\PIPE\PSEXESVC`) on the same SMB connection, which is exactly the artifact that surfaces in the logs below.

> The broader **Sysinternals** suite (Process Explorer, Autoruns, Procmon, PsList, and so on) is a set of free Microsoft diagnostic tools from the same source, all under `https://learn.microsoft.com/sysinternals`.

## Get it (official only)
- Suite ZIP: `https://download.sysinternals.com/files/PSTools.zip`
- Run live over SMB: `\\live.sysinternals.com\tools\psexec.exe`

## Core syntax
```cmd
psexec \\192.168.1.20 -u labuser -p Pass123! cmd
```
Opens an interactive **cmd** on `192.168.1.20`. **Omit `-p`** to get prompted for the password instead of putting it on the command line (safer, see the gotchas).

## Key switches
| Switch | Meaning |
|---|---|
| `\\host` | target computer (or `@list.txt` for many) |
| `-u` / `-p` | username / password on the target |
| `-s` | run as **SYSTEM** (LocalSystem), the highest local account |
| `-c` | **copy** the named local exe to the target, then run it |
| `-f` / `-v` | with `-c`: force overwrite / copy only if newer |
| `-i [session]` | run **interactively** on the target's desktop |
| `-d` | don't wait, launch and return immediately |
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
(want to run this on the lab box, but it matches the docs). `psexec -i -s cmd` giving a `whoami` of `nt authority\system` is the quickest way to watch the `-s` flag work.

## Legitimate use vs why EDR flags it
- **Legit:** remote administration, pushing a fix or collection tool to a host, getting a SYSTEM shell to reach SYSTEM-only files, mass-running a command across `@hosts.txt`.
- **Why it's flagged:** the same "auth to `ADMIN$`, create a service, run code as SYSTEM" flow is a textbook **lateral-movement** technique (MITRE ATT&CK **T1569.002 Service Execution** / **T1021.002 SMB Admin Shares**). In a lab that alert is expected; on production, expect it to page the SOC.
- **Defensive detections:** Security **4624 type 3** (network logon) + **4672** (admin privileges) from a remote host, System **7045** (new service installed) with a short random service name, and the `PSEXESVC` service/binary artefact.

> **Why the *combination* is the signature:** any one of these is ordinary on its own, since network logons and service installs happen all day. What flags PsExec is the tight *sequence from one remote source*: a type-3 network logon, admin rights assigned, then a brand-new service with a random-looking name installed seconds later. Defenders hunt the pattern, not the single event, which is also why renaming `PSEXESVC` doesn't hide you.

## Modern alternative: PowerShell Remoting
Does the same job over **WinRM** and is generally cleaner and better-logged:
```powershell
Enable-PSRemoting                                              # on the target, once
Enter-PSSession -ComputerName 192.168.1.20 -Credential labuser # interactive
Invoke-Command -ComputerName 192.168.1.20 -ScriptBlock { ipconfig /all }
```
If the box already has WinRM, I prefer PS Remoting. I reach for PsExec when WinRM is off, or when I specifically need `-s`/`-i`.

> **Why WinRM is cleaner:** it's a purpose-built remote-management channel, authenticated, encrypted, and logged as management activity, so it doesn't drop a service binary or register a temporary service the way PsExec has to. Less on-disk artifact, more native logging. PsExec only wins when WinRM isn't enabled, or when I need the SYSTEM/desktop interaction (`-s`/`-i`) that Remoting won't hand me.

## Gotchas & things to remember
- **Download source matters:** official Sysinternals URL only. Citing a random download in a screening is a red flag against me.
- **Needs `ADMIN$` reachable plus admin creds on the target** and File & Printer Sharing on. "Access denied" usually means one of those, not a PsExec bug.
- **`-p` leaks the password** into history and logs, so I omit it and get prompted.
- **`-s` is SYSTEM**, `-i` interacts with the desktop, and `psexec -i -s cmd` is the local "become SYSTEM" one-liner.
- **Expect AV/EDR alerts.** It's dual-use, so that's a feature to understand, not a malfunction.

## References
- PsExec (Sysinternals): https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
- Sysinternals suite: https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite
- MITRE ATT&CK T1569.002 (Service Execution): https://attack.mitre.org/techniques/T1569/002/
- MITRE ATT&CK T1021.002 (SMB/Windows Admin Shares): https://attack.mitre.org/techniques/T1021/002/

## Related
- [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
- [Windows Logs and Scheduled Tasks](Windows%20Logs%20and%20Scheduled%20Tasks.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md)
