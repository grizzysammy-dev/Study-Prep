---
tags: [cyber, module1, module3, windows]
jqr: "PowerShell versions of the admin tasks: the verb-noun cmdlet model, Get-LocalUser/New-LocalUser, Get/New-LocalGroup, Get/New-SmbShare, Get/Set-Content, Get-Process/Stop-Process, and execution policy"
---

# PowerShell Essentials

PowerShell is the modern Windows shell, and it's the "other half" of every `net`/`cmd` task the JQR pairs up. This is my running list of the cmdlets that map 1:1 to the classic commands, plus the two things that always trip me up: the **verb-noun** model and **execution policy**. The cmd equivalents live in [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md).

## Quick reference
```powershell
Get-LocalUser ; New-LocalUser -Name labuser -Password $pw   # users
Get-LocalGroup ; Add-LocalGroupMember Administrators labuser # groups
Get-SmbShare ; New-SmbShare -Name data -Path C:\data -FullAccess labuser  # shares
Get-Content file.txt ; Set-Content file.txt "text"          # read / write
Get-Process ; Stop-Process -Name notepad -Force             # processes
Get-Command *user* ; Get-Help New-LocalUser -Examples       # discover anything
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass  # let a .ps1 run this session
```

## How PowerShell thinks: verb-noun, objects, discovery
Every cmdlet is **`Verb-Noun`**: `Get-`, `New-`, `Set-`, `Remove-`, `Start-`, `Stop-`. Once I know the noun (`LocalUser`, `SmbShare`, `Process`, `Service`, `NetFirewallRule`) I can usually guess the whole family. That's the real point of it: I'm not memorising 200 tool names, just about 8 verbs.

> **Why the naming is so rigid:** PowerShell enforces a fixed list of ~100 *approved verbs*, so module authors can't invent `Make-`/`Fetch-`/`Nuke-`. Every well-behaved command reads the same way as a result, and `Get-Verb` lists them all. The predictability is a designed feature, not bureaucracy. It's what lets me guess a cmdlet I've never seen.

Unlike cmd, cmdlets return **objects**, not text. So I pipe into `Select-Object`, `Where-Object`, `Sort-Object`, `Format-List/Table` instead of parsing strings:
```powershell
Get-Process | Where-Object CPU -gt 10 | Sort-Object CPU -Descending | Select-Object -First 5
```
That's "the 5 top-CPU processes," and I never touched grep or awk.

> **The real cmd-vs-PowerShell difference:** cmd tools print *text*, so the next tool in the pipe has to re-parse those characters (that's where `findstr`, `for /f`, and brittle column-counting come from). PowerShell passes the actual **.NET objects** down the pipe, live records with named properties like `CPU` and `Id`. I'm not scraping a printout, I'm handing off a spreadsheet and asking for a column by name. That's why `Where-Object CPU -gt 10` just works and never breaks when the display formatting changes.

**Three discovery cmdlets that make PowerShell self-documenting:**
```powershell
Get-Command *firewall*                 # find cmdlets by keyword
Get-Help New-LocalUser -Examples       # worked examples for any cmdlet
Get-Member                             # (piped) list an object's properties/methods
```
(worth running on the lab box, but it matches the docs). If I blank on a cmdlet name under exam pressure, `Get-Command *<noun>*` will dig it up.

## Shells & how to launch
- **`powershell.exe`** is Windows PowerShell 5.1, always present on Windows 11.
- **`pwsh`** is PowerShell 7+ (cross-platform), if it's installed. It also lives in **Windows Terminal**.
- Elevate it the same way as cmd (Win+X then *Terminal (Admin)*, or right-click and **Run as administrator**). Changing users, services, firewall, or IPs all need elevation.

## Users (`*-LocalUser`)
```powershell
Get-LocalUser                                                   # list all
Get-LocalUser labuser | Format-List *                           # full detail
$pw = ConvertTo-SecureString 'Pass123!' -AsPlainText -Force     # build a SecureString
New-LocalUser -Name labuser -Password $pw -FullName 'Lab User'  # create
Disable-LocalUser -Name labuser                                 # disable
Remove-LocalUser  -Name labuser                                 # delete
```
The one non-obvious step: the password has to be a **SecureString**, so I build `$pw` first with `ConvertTo-SecureString`. The cmd version is `net user labuser Pass123! /add`.

> **Why a SecureString:** the cmdlet refuses a plain string on purpose. A SecureString keeps the password encrypted in memory and off the screen, instead of leaving `Pass123!` sitting in scrollback and history the way the `net user` form does. It's friction with a point, and the `-AsPlainText -Force` I use to build it is me explicitly overriding that guard for lab convenience.

## Groups (`*-LocalGroup(Member)`)
```powershell
Get-LocalGroup                                    # list groups
Get-LocalGroupMember -Group Administrators         # who is admin
New-LocalGroup -Name labgroup                      # create
Add-LocalGroupMember    -Group Administrators -Member labuser
Remove-LocalGroupMember -Group Administrators -Member labuser
```

## Shares (`*-SmbShare`)
```powershell
Get-SmbShare                                               # list shares
Get-SmbShareAccess -Name data                              # share-level ACL
New-SmbShare -Name data -Path C:\data -FullAccess labuser  # create (Full)
New-SmbShare -Name data -Path C:\data -ReadAccess Everyone # create (Read)
Remove-SmbShare -Name data -Force                          # delete
Get-SmbSession                                             # inbound client sessions
```
`-FullAccess` / `-ReadAccess` / `-ChangeAccess` set the **share** permission, and NTFS (see [icacls and Permissions](icacls%20and%20Permissions.md)) still applies on top.

## Files (`Get-Content` / `Set-Content` / `Add-Content`)
```powershell
Get-ChildItem C:\ -Recurse -Filter *.txt -ErrorAction SilentlyContinue  # find files
Get-Content file.txt                         # read whole file (= type)
Get-Content file.txt -Tail 10                # last 10 lines (= tail)
New-Item file.txt -ItemType File             # create empty file
Set-Content file.txt "hello"                 # write/overwrite content
Add-Content file.txt "another line"          # append
```
`Get-Content`/`Set-Content` are the read/write pair, and `Add-Content` appends. `-ErrorAction SilentlyContinue` hides the "access denied" noise when I recurse system trees.

## Processes & services (cross-note)
```powershell
Get-Process                                  # all processes
Get-Process -Name notepad                    # filter
Stop-Process -Name notepad -Force            # kill by name
Get-Service ; Start-Service Spooler ; Stop-Service Spooler -Force
```
The full process/kill/where-it-runs-from coverage is in [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md), and services also show up in [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md).

## Execution policy: why my `.ps1` won't run
Typing cmdlets one at a time is **never** blocked. Running a saved **script file** (`.ps1`) can be, with *"running scripts is disabled on this system."* That's execution policy, a safety default, not a permissions error.

> **Why it exists, and what it is *not*:** execution policy is a guardrail against *accidentally* running a `.ps1` I didn't mean to, nothing more. Microsoft is explicit that it's **not a security control**: the same session can bypass it in one breath (`-ExecutionPolicy Bypass`, or just paste the script's contents). So on the blue side, "we set execution policy to Restricted" stops honest mistakes, not a determined attacker, which is exactly why offensive tooling reaches for `-enc`/`Bypass` and doesn't even slow down.
```powershell
Get-ExecutionPolicy -List                                  # see policy per scope
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass # allow scripts THIS session only
powershell.exe -ExecutionPolicy Bypass -File .\script.ps1  # or one-shot at launch
```
I **prefer `-Scope Process`** (or the per-launch `-File` form): it lasts only for the current window and needs no admin, so I'm not weakening the machine's default. Avoid `Set-ExecutionPolicy Unrestricted` machine-wide.

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

## Stuff that trips me up
- **The password must be a SecureString** for `New-LocalUser`, so I build `$pw` with `ConvertTo-SecureString ... -AsPlainText -Force` first or the cmdlet errors out.
- **Execution policy isn't permissions.** "Scripts disabled" blocks `.ps1` files, not interactive cmdlets, so I fix it with `-Scope Process` instead of reaching for admin.
- **Objects, not text:** filter with `Where-Object`/`Select-Object`, don't try to `findstr` the output.
- **Verb-noun guessing works:** if I'm unsure of a name, `Get-Command *<noun>*`, then `Get-Help <name> -Examples`.
- **There are two PowerShells:** 5.1 (`powershell`) is always there; 7 (`pwsh`) might not be. Everything here works in both.
- Plenty of admin nouns (`SmbShare`, `NetFirewallRule`, `NetIPAddress`, `ScheduledTask`) still need an **elevated** shell before they'll change anything.

## References
- PowerShell docs: https://learn.microsoft.com/en-us/powershell/
- Local Accounts module (Get/New-LocalUser): https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/
- SmbShare module: https://learn.microsoft.com/en-us/powershell/module/smbshare/
- about_Execution_Policies: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies

## Related
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [icacls and Permissions](icacls%20and%20Permissions.md)
- [Windows Logs and Scheduled Tasks](Windows%20Logs%20and%20Scheduled%20Tasks.md)
- [Metasploit Workflow](../C2%20Frameworks/Metasploit/Metasploit%20Workflow.md)
