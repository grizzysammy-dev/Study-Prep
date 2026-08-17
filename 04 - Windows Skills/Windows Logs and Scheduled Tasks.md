---
tags: [jcu, module1, module3, windows]
jqr: "Event Viewer log categories (Application/Security/System/Setup/Forwarded); key logon IDs 4624/4625; read logs with wevtutil and Get-WinEvent; schedule tasks with schtasks, Register-ScheduledTask, taskschd.msc"
---

# Windows Logs and Scheduled Tasks

Two defender staples: **where Windows records what happened** (Event Viewer + the CLI readers) and **how work gets scheduled to run later** — which is both a legit admin task and a common persistence trick. This is the Windows counterpart to [Logs and journalctl](../03%20-%20Linux%20Skills/Logs%20and%20journalctl.md) and [cron](../03%20-%20Linux%20Skills/cron.md).

## TL;DR
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

## Concept
Two ideas, one note, because they meet on the defensive side:
- **Logs** are Windows' audit trail. The GUI is **Event Viewer**; the muscle is the CLI (`wevtutil`, `Get-WinEvent`) because you can filter by **Event ID** and time instead of scrolling. Each event has a numeric **ID** — memorising a handful (below) tells you *what happened* without reading prose.
- **Scheduled tasks** run a program **later or on a schedule** (the Windows `cron`). They're a normal admin tool, but because a task can silently re-launch a payload at every logon, they're also a favourite **persistence** mechanism — so creating them and *auditing* them are two sides of the same skill.

Both live at the intersection of "admin task" and "hunt for evil," which is exactly the JQR's angle.

## Part 1 — Windows logs (Event Viewer)
Open with **`eventvwr.msc`** (Win+R). Logs sit under *Windows Logs* and *Applications and Services Logs*.

### The main "Windows Logs" categories
| Log | What it contains | Why you care (defensive) |
|---|---|---|
| **Security** | Audit Success/Failure: logons, privilege use, account & policy changes, object access | The #1 hunting log. IDs **4624/4625** logon success/fail, **4672** admin rights, **4720** user created, **4740** lockout, **4688** new process |
| **System** | OS/kernel: drivers, services starting/stopping, hardware, boot/shutdown, time changes | Service crashes, driver faults, unexpected reboots, service tampering (**7045** new service) |
| **Application** | Events from installed apps & OS components: crashes/hangs, .NET errors, MSI installs | App failures, Error/Warning triage |
| **Setup** | Feature/role install, Windows Update servicing, domain-join | Patch/servicing history, install failures |
| **Forwarded Events** | Events **collected from other machines** via Windows Event Forwarding (WEF) | The central collector's inbox on a log-collector box |

→ Deeper per-app logs (**PowerShell Operational**, **Sysmon**, **TaskScheduler**) live under *Applications and Services Logs*.

### Read logs — cmd (`wevtutil`)
```cmd
wevtutil el                                               :: enumerate every log name
wevtutil qe Security /c:5 /rd:true /f:text                :: query last 5 Security events, newest first, text
wevtutil qe System /q:"*[System[(EventID=7040)]]" /f:text :: filter by Event ID with XPath
wevtutil gl Security                                      :: show a log's config (size, retention)
```
→ `/c` = count, `/rd:true` = reverse (newest first), `/f:text` = human-readable.

### Read logs — PowerShell (`Get-WinEvent`, modern)
```powershell
Get-WinEvent -LogName Security -MaxEvents 10
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625 } -MaxEvents 20            # failed logons
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-24) }
Get-WinEvent -ListLog *                                                                 # list logs
```
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. `Get-WinEvent` reads **both** classic and new logs and is far faster to filter than clicking in the GUI.

### Legacy reader (`Get-EventLog`)
```powershell
Get-EventLog -LogName System -Newest 10
Get-EventLog -LogName Security -EntryType FailureAudit -Newest 20
```
→ Still present, but **classic logs only** — it can't read the newer "Applications and Services" logs. Prefer `Get-WinEvent`.

> **Gotcha:** reading the **Security** log needs an **elevated** shell.

## Part 2 — Scheduled tasks
### cmd — `schtasks`
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
→ `/sc` = schedule type, `/tn` = task name, `/tr` = program, `/st` = start time, `/ru` = run-as account, `/rl` = run level.

### PowerShell — `Register-ScheduledTask`
```powershell
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
$action  = New-ScheduledTaskAction  -Execute 'C:\scripts\backup.bat'
Register-ScheduledTask -TaskName 'LabBackup' -Trigger $trigger -Action $action `
    -RunLevel Highest -User 'SYSTEM' -Description 'Daily lab backup'

Get-ScheduledTask     -TaskName 'LabBackup'
Start-ScheduledTask   -TaskName 'LabBackup'
Unregister-ScheduledTask -TaskName 'LabBackup' -Confirm:$false
```
→ Build a **trigger** (when) and an **action** (what), then `Register` them under a name. Same three ideas as a cron line, just split into objects.

### GUI — Task Scheduler (`taskschd.msc`)
Win+R → **`taskschd.msc`** → right pane **Create Basic Task…** → name → pick a **Trigger** (Daily/Weekly/At log on) → **Action** = *Start a program* → browse the script → **Finish**.
→ Use **Create Task…** (not Basic) for *"Run whether user is logged on or not"* and *"Run with highest privileges."*

## Defensive angle — tasks as persistence
Scheduled tasks are a top **persistence** technique (MITRE ATT&CK **T1053.005**): an attacker plants a task that re-launches their payload at logon or on a timer. So when hunting:
- audit **new tasks** via Security **Event ID 4698** (scheduled task created),
- list what exists: `Get-ScheduledTask | Where State -ne 'Disabled'` or `schtasks /query /fo list /v`,
- eyeball the **Actions** — a task running from `C:\Users\...\AppData\Temp` or launching `powershell -enc ...` is a red flag.

## Exam tips & gotchas
- **Security log needs elevation** to read — no output usually means non-admin shell.
- **`Get-WinEvent` over `Get-EventLog`** — the latter can't see modern logs.
- **Memorise 4624 vs 4625** (success vs failure) — the most-asked IDs; **4672** = admin logon, **4688** = process created, **4698** = task created.
- **SYSTEM / "run whether logged on or not" tasks need an elevated creator.**
- **`/f:text` and `/rd:true`** make `wevtutil` readable and newest-first — without them the raw XML/order is painful.
- Filter with `-FilterHashtable`, not `Where-Object` after the fact — it's far faster on big logs.

## References
- wevtutil — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil
- Get-WinEvent — https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent
- schtasks — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks
- Windows security audit events (4624/4625 etc.) — https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4624
- MITRE ATT&CK T1053.005 (Scheduled Task) — https://attack.mitre.org/techniques/T1053/005/

## Related
- [Logs and journalctl](../03%20-%20Linux%20Skills/Logs%20and%20journalctl.md)
- [cron](../03%20-%20Linux%20Skills/cron.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [PsExec and Sysinternals](PsExec%20and%20Sysinternals.md)
- [Cyber Kill Chain](../06%20-%20Knowledge%20Requirements/Cyber%20Kill%20Chain.md)
