---
tags: [cyber, module1, module3, windows]
jqr: "PowerShell equivalents for admin tasks: verb-noun cmdlet model; Get-LocalUser/New-LocalUser, Get/New-LocalGroup, Get/New-SmbShare, Get/Set-Content, Get-Process/Stop-Process, execution policy"
---

# PowerShell Essentials

PowerShell is the modern Windows shell and the "other half" of every `net`/`cmd` task the JQR pairs. This note gives Sam the cmdlets that map 1:1 to the classic commands, plus the two concepts that trip people up: the **verb-noun** model and **execution policy**. cmd equivalents live in [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md).

## TL;DR
```powershell
Get-LocalUser ; New-LocalUser -Name labuser -Password $pw   # users
Get-LocalGroup ; Add-LocalGroupMember Administrators labuser # groups
Get-SmbShare ; New-SmbShare -Name data -Path C:\data -FullAccess labuser  # shares
Get-Content file.txt ; Set-Content file.txt "text"          # read / write
Get-Process ; Stop-Process -Name notepad -Force             # processes
Get-Command *user* ; Get-Help New-LocalUser -Examples       # discover anything
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass  # let a .ps1 run this session
```

## Concept — verb-noun, objects, discovery
Every cmdlet is **`Verb-Noun`**: `Get-`, `New-`, `Set-`, `Remove-`, `Start-`, `Stop-`. Once you know the noun (`LocalUser`, `SmbShare`, `Process`, `Service`, `NetFirewallRule`) you can usually guess the whole family. That regularity is the point — you don't memorise 200 tool names, you memorise ~8 verbs.

> **Why the naming is so rigid:** PowerShell enforces a fixed list of ~100 *approved verbs*, so module authors can't invent `Make-`/`Fetch-`/`Nuke-`. Every well-behaved command therefore reads the same way and `Get-Verb` lists them all. The predictability is a designed feature, not bureaucracy — it's what lets you guess a cmdlet you've never seen.

Unlike cmd, cmdlets return **objects**, not text. So you pipe into `Select-Object`, `Where-Object`, `Sort-Object`, `Format-List/Table` instead of parsing strings:
```powershell
Get-Process | Where-Object CPU -gt 10 | Sort-Object CPU -Descending | Select-Object -First 5
```
→ "the 5 top-CPU processes" — no grep/awk needed.

> **Why it works — the real cmd-vs-PowerShell difference:** cmd tools print *text*, so the next tool in the pipe has to re-parse those characters (hence `findstr`, `for /f`, brittle column-counting). PowerShell passes the actual **.NET objects** down the pipe — live records with named properties like `CPU` and `Id`. You're not scraping a printout, you're handing off a spreadsheet and asking for a column by name. That's why `Where-Object CPU -gt 10` just works and never breaks when the display formatting changes.

**Three discovery cmdlets that make PowerShell self-documenting:**
```powershell
Get-Command *firewall*                 # find cmdlets by keyword
Get-Help New-LocalUser -Examples       # worked examples for any cmdlet
Get-Member                             # (piped) list an object's properties/methods
```
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. If you forget a cmdlet name under exam pressure, `Get-Command *<noun>*` will find it.

## Shells & how to launch
- **`powershell.exe`** — Windows PowerShell 5.1, always present on Windows 11.
- **`pwsh`** — PowerShell 7+ (cross-platform), if installed. Also lives in **Windows Terminal**.
- Elevate the same way as cmd: Win+X → *Terminal (Admin)*, or right-click → **Run as administrator**. Changing users/services/firewall/IPs needs elevation.

## Users — `*-LocalUser`
```powershell
Get-LocalUser                                                   # list all
Get-LocalUser labuser | Format-List *                           # full detail
$pw = ConvertTo-SecureString 'Pass123!' -AsPlainText -Force     # build a SecureString
New-LocalUser -Name labuser -Password $pw -FullName 'Lab User'  # create
Disable-LocalUser -Name labuser                                 # disable
Remove-LocalUser  -Name labuser                                 # delete
```
→ The one non-obvious step: the password must be a **SecureString**, so build `$pw` first with `ConvertTo-SecureString`. cmd version: `net user labuser Pass123! /add`.

> **Why a SecureString:** the cmdlet refuses a plain string on purpose — a SecureString keeps the password encrypted in memory and off your screen, instead of leaving `Pass123!` sitting in scrollback and history the way the `net user` form does. It's friction with a point; the `-AsPlainText -Force` you use to build it is you explicitly overriding that guard for lab convenience.

## Groups — `*-LocalGroup(Member)`
```powershell
Get-LocalGroup                                    # list groups
Get-LocalGroupMember -Group Administrators         # who is admin
New-LocalGroup -Name labgroup                      # create
Add-LocalGroupMember    -Group Administrators -Member labuser
Remove-LocalGroupMember -Group Administrators -Member labuser
```

## Shares — `*-SmbShare`
```powershell
Get-SmbShare                                               # list shares
Get-SmbShareAccess -Name data                              # share-level ACL
New-SmbShare -Name data -Path C:\data -FullAccess labuser  # create (Full)
New-SmbShare -Name data -Path C:\data -ReadAccess Everyone # create (Read)
Remove-SmbShare -Name data -Force                          # delete
Get-SmbSession                                             # inbound client sessions
```
→ `-FullAccess` / `-ReadAccess` / `-ChangeAccess` set the **share** permission; NTFS (see [icacls and Permissions](icacls%20and%20Permissions.md)) still applies on top.

## Files — `Get-Content` / `Set-Content` / `Add-Content`
```powershell
Get-ChildItem C:\ -Recurse -Filter *.txt -ErrorAction SilentlyContinue  # find files
Get-Content file.txt                         # read whole file (= type)
Get-Content file.txt -Tail 10                # last 10 lines (= tail)
New-Item file.txt -ItemType File             # create empty file
Set-Content file.txt "hello"                 # write/overwrite content
Add-Content file.txt "another line"          # append
```
→ `Get-Content`/`Set-Content` are the read/write pair; `Add-Content` appends. `-ErrorAction SilentlyContinue` hides "access denied" noise when recursing system trees.

## Processes & services (cross-note)
```powershell
Get-Process                                  # all processes
Get-Process -Name notepad                    # filter
Stop-Process -Name notepad -Force            # kill by name
Get-Service ; Start-Service Spooler ; Stop-Service Spooler -Force
```
→ Full process/kill/where-it-runs-from coverage is in [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md); services also appear in [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md).

## Execution policy — why your `.ps1` won't run
Typing cmdlets one at a time is **never** blocked. Running a saved **script file** (`.ps1`) can be, with *"running scripts is disabled on this system."* That's execution policy, a safety default — not a permissions error.

> **Why it exists, and what it is *not*:** execution policy is a guardrail against *accidentally* running a `.ps1` you didn't mean to — nothing more. Microsoft is explicit that it is **not a security control**: the same session can bypass it in one breath (`-ExecutionPolicy Bypass`, or just paste the script's contents). So on the blue side, "we set execution policy to Restricted" stops honest mistakes, not a determined attacker — which is exactly why offensive tooling reaches for `-enc`/`Bypass` and doesn't even slow down.
```powershell
Get-ExecutionPolicy -List                                  # see policy per scope
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass # allow scripts THIS session only
powershell.exe -ExecutionPolicy Bypass -File .\script.ps1  # or one-shot at launch
```
→ **Prefer `-Scope Process`** (or the per-launch `-File` form): it lasts only for the current window and needs no admin, so you're not weakening the machine's default. Avoid `Set-ExecutionPolicy Unrestricted` machine-wide.

## Cmdlet ⇄ cmd cheat table
| Task | PowerShell | cmd.exe |
|---|---|---|
| List users | `Get-LocalUser` | `net user` |
| Create user | `New-LocalUser labuser -Password $pw` | `net user labuser Pass123! /add` |
| Add to group | `Add-LocalGroupMember Administrators labuser` | `net localgroup Administrators labuser /add` |
| List shares | `Get-SmbShare` | `net share` |
| Create share | `New-SmbShare -Name data -Path C:\data -FullAccess labuser` | `net share data=C:\data /GRANT:labuser,FULL` |
| Read file | `Get-Content f.txt` | `type f.txt` |
| Kill process | `Stop-Process -Name notepad -Force` | `taskkill /IM notepad.exe /F` |
| List services | `Get-Service` | `net start` |

## Exam tips & gotchas
- **Password must be a SecureString** for `New-LocalUser` — build `$pw` with `ConvertTo-SecureString ... -AsPlainText -Force` first, or the cmdlet errors.
- **Execution policy ≠ permissions.** "Scripts disabled" blocks `.ps1` files, not interactive cmdlets. Fix with `-Scope Process`, don't reach for admin.
- **Objects, not text:** filter with `Where-Object`/`Select-Object`, don't try to `findstr` the output.
- **Verb-noun guessing works:** unsure of a name? `Get-Command *<noun>*`, then `Get-Help <name> -Examples`.
- **Two PowerShells:** 5.1 (`powershell`) is always there; 7 (`pwsh`) may not be. Answers here work in both.
- Many admin nouns (`SmbShare`, `NetFirewallRule`, `NetIPAddress`, `ScheduledTask`) still need an **elevated** shell to change.

## References
- PowerShell docs — https://learn.microsoft.com/en-us/powershell/
- Local Accounts module (Get/New-LocalUser) — https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/
- SmbShare module — https://learn.microsoft.com/en-us/powershell/module/smbshare/
- about_Execution_Policies — https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies

## Related
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [icacls and Permissions](icacls%20and%20Permissions.md)
- [Windows Logs and Scheduled Tasks](Windows%20Logs%20and%20Scheduled%20Tasks.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
