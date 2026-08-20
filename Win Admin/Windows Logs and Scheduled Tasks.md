---
tags: [cyber, module1, module3, windows]
jqr: "Event Viewer log categories (Application/Security/System/Setup/Forwarded), the key logon IDs 4624/4625, reading logs with wevtutil and Get-WinEvent, and scheduling tasks with schtasks, Register-ScheduledTask, and taskschd.msc"
---

# Windows Logs and Scheduled Tasks

Two defender staples in one note: **where Windows records what happened** (Event Viewer plus the CLI readers), and **how work gets scheduled to run later**, which is both a legit admin task and a common persistence trick. This is the Windows counterpart to [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md) and [cron](../Linux%20Admin/cron.md).

## Quick reference
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625 } -MaxEvents 20   # failed logons
Get-WinEvent -LogName Security -MaxEvents 10                                    # newest Security events
```
```cmd
wevtutil qe Security /c:5 /rd:true /f:text     :: last 5 Security events, newest first, as text
schtasks /create /sc daily /tn "LabBackup" /tr "C:\scripts\backup.bat" /st 09:00
schtasks /query /tn "LabBackup" /v /fo list    :: inspect a task
```
> Key logon IDs: **4624** logon success · **4625** logon **failure** · **4634** logoff · **4672** admin privileges assigned · **4720** user created · **4740** account locked out · **4688** new process · **4698** scheduled task created.

## Why these two live together
Two ideas in one note, because they meet on the defensive side.
- **Logs** are Windows' audit trail. The GUI is **Event Viewer**, but the muscle is the CLI (`wevtutil`, `Get-WinEvent`) because I can filter by **Event ID** and time instead of scrolling forever. Each event carries a numeric **ID**, and memorising a handful (below) tells me *what happened* without reading any prose.
- **Scheduled tasks** run a program **later or on a schedule** (the Windows `cron`). They're a normal admin tool, but since a task can silently re-launch a payload at every logon, they're also a favourite **persistence** mechanism. Creating them and *auditing* them are two sides of the same skill.

Both sit right at the intersection of "admin task" and "hunt for evil," which is exactly the angle the JQR takes.

> **Why I filter by ID, not by keyword:** a Windows event isn't a line of free text like a Linux syslog message, it's a **structured record** written to a binary `.evtx` store by the Event Log service. Each *provider* (the auditing subsystem, a service, an app) emits events stamped with a numeric **Event ID** plus typed fields (account, source IP, logon type). The ID is a stable, language-independent fact: `4625` means "a logon failed" whether the box runs in English or Japanese, so the ID *is* my query surface. Hunting is "give me every 4625 in the last hour," not "grep for the word *failed*."

## Part 1: Windows logs (Event Viewer)
I open it with **`eventvwr.msc`** (Win+R). The logs sit under *Windows Logs* and *Applications and Services Logs*.

### The main "Windows Logs" categories
| Log | What it contains | Why you care (defensive) |
|---|---|---|
| **Security** | Audit Success/Failure: logons, privilege use, account & policy changes, object access | The #1 hunting log. IDs **4624/4625** logon success/fail, **4672** admin rights, **4720** user created, **4740** lockout, **4688** new process |
| **System** | OS/kernel: drivers, services starting/stopping, hardware, boot/shutdown, time changes | Service crashes, driver faults, unexpected reboots, service tampering (**7045** new service) |
| **Application** | Events from installed apps & OS components: crashes/hangs, .NET errors, MSI installs | App failures, Error/Warning triage |
| **Setup** | Feature/role install, Windows Update servicing, domain-join | Patch/servicing history, install failures |
| **Forwarded Events** | Events **collected from other machines** via Windows Event Forwarding (WEF) | The central collector's inbox on a log-collector box |

The deeper per-app logs (**PowerShell Operational**, **Sysmon**, **TaskScheduler**) live under *Applications and Services Logs*.

### Read logs: cmd (`wevtutil`)
```cmd
wevtutil el                                               :: enumerate every log name
wevtutil qe Security /c:5 /rd:true /f:text                :: query last 5 Security events, newest first, text
wevtutil qe System /q:"*[System[(EventID=7040)]]" /f:text :: filter by Event ID with XPath
wevtutil gl Security                                      :: show a log's config (size, retention)
```
`/c` is count, `/rd:true` is reverse (newest first), `/f:text` is human-readable.

### Read logs: PowerShell (`Get-WinEvent`, modern)
```powershell
Get-WinEvent -LogName Security -MaxEvents 10
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625 } -MaxEvents 20            # failed logons
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-24) }
Get-WinEvent -ListLog *                                                                 # list logs
```
(need to run this on the lab box, but it lines up with the docs). `Get-WinEvent` reads **both** classic and new logs and is way faster to filter than clicking around in the GUI.

### Legacy reader (`Get-EventLog`)
```powershell
Get-EventLog -LogName System -Newest 10
Get-EventLog -LogName Security -EntryType FailureAudit -Newest 20
```
Still present, but **classic logs only**, so it can't read the newer "Applications and Services" logs. I stick with `Get-WinEvent`.

> **Gotcha:** reading the **Security** log needs an **elevated** shell. (Why: it's the audit trail of the security subsystem itself, the record of what LSASS wrote about logons and privilege use, so reading it is a privileged act, unlike Application/System which any user can browse.)

## Part 2: Scheduled tasks
### cmd: `schtasks`
```cmd
:: Run a program every day at 09:00
schtasks /create /sc daily /tn "LabBackup" /tr "C:\scripts\backup.bat" /st 09:00

:: Other schedules: /sc minute|hourly|daily|weekly|monthly|onlogon|onstart|onidle
schtasks /create /sc weekly /d MON /tn "WeeklyScan" /tr "C:\scripts\scan.bat" /st 18:00

:: Run as SYSTEM with highest privileges (admin)
schtasks /create /sc daily /tn "SysJob" /tr "C:\scripts\job.bat" /st 02:00 /ru SYSTEM /rl highest

schtasks /query /tn "LabBackup" /v /fo list   :: inspect the task
schtasks /run   /tn "LabBackup"                :: run it now
schtasks /change /tn "LabBackup" /st 07:30     :: change start time
schtasks /delete /tn "LabBackup" /f            :: delete
```
`/sc` is schedule type, `/tn` the task name, `/tr` the program, `/st` the start time, `/ru` the run-as account, `/rl` the run level.

### PowerShell: `Register-ScheduledTask`
```powershell
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
$action  = New-ScheduledTaskAction  -Execute 'C:\scripts\backup.bat'
Register-ScheduledTask -TaskName 'LabBackup' -Trigger $trigger -Action $action `
    -RunLevel Highest -User 'SYSTEM' -Description 'Daily lab backup'

Get-ScheduledTask     -TaskName 'LabBackup'
Start-ScheduledTask   -TaskName 'LabBackup'
Unregister-ScheduledTask -TaskName 'LabBackup' -Confirm:$false
```
Build a **trigger** (when) and an **action** (what), then `Register` them under a name. Same three ideas as a cron line, just split into objects.

### GUI: Task Scheduler (`taskschd.msc`)
Win+R → **`taskschd.msc`** → right pane **Create Basic Task...** → name → pick a **Trigger** (Daily/Weekly/At log on) → **Action** = *Start a program* → browse the script → **Finish**.
I use **Create Task...** (not Basic) for *"Run whether user is logged on or not"* and *"Run with highest privileges."*

## Defensive angle: tasks as persistence
Scheduled tasks are a top **persistence** technique (MITRE ATT&CK **T1053.005**): an attacker plants a task that re-launches their payload at logon or on a timer. So when I'm hunting:

> **Why tasks are prime persistence:** they hit all three things an attacker wants at once: **durability** (the registration survives reboots), **privilege** (a task can run as SYSTEM), and **legitimacy** (Task Scheduler is a normal Windows service, so one more task blends in among hundreds of benign ones). The Scheduler faithfully re-launches whatever got registered, no questions asked, which is ideal for backups and just as ideal for a backdoor.

- audit **new tasks** via Security **Event ID 4698** (scheduled task created),
- list what's already there with `Get-ScheduledTask | Where State -ne 'Disabled'` or `schtasks /query /fo list /v`,
- and eyeball the **Actions**: a task running from `C:\Users\...\AppData\Temp` or launching `powershell -enc ...` is a red flag.

## What I keep forgetting
- **The Security log needs elevation** to read. No output usually just means a non-admin shell.
- **`Get-WinEvent` over `Get-EventLog`**, since the older one can't see modern logs.
- **Memorise 4624 vs 4625** (success vs failure), the most-asked IDs. **4672** is admin logon, **4688** is process created, **4698** is task created. A 4624 also carries a **logon type**: 2 is interactive at the keyboard, 3 is network/SMB, 10 is remote-interactive/RDP. The type is how I tell "someone sat down at the console" from "someone hit it over the wire," so PsExec shows up as type 3.
- **SYSTEM and "run whether logged on or not" tasks need an elevated creator.**
- **`/f:text` and `/rd:true`** make `wevtutil` readable and newest-first. Without them the raw XML and ordering are painful.
- Filter with `-FilterHashtable`, not `Where-Object` after the fact. It's far faster on big logs.

## References
- wevtutil: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil
- Get-WinEvent: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent
- schtasks: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks
- Windows security audit events (4624/4625 etc.): https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4624
- MITRE ATT&CK T1053.005 (Scheduled Task): https://attack.mitre.org/techniques/T1053/005/

## Related
- [Logs and journalctl](../Linux%20Admin/Logs%20and%20journalctl.md)
- [cron](../Linux%20Admin/cron.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [PsExec and Sysinternals](PsExec%20and%20Sysinternals.md)
- [Cyber Kill Chain](../Knowledge%20Req/Cyber%20Kill%20Chain.md)
