---
tags: [jcu, module1, module3, windows]
jqr: "Windows CLI (cmd.exe): full net command family (user/localgroup/share/use/view/accounts/start/stop/session/statistics); list & create local users, groups, shares; CLI file tasks (find/read/create/permissions)"
---

# Windows CLI and net Commands

The `net` family is the fastest way to read and change local **users, groups, shares, and services** from `cmd.exe`. If the exam says "from the command line, create a user / list the shares / stop a service," this note is the answer. PowerShell equivalents are shown inline; the fuller PowerShell treatment lives in [PowerShell Essentials](PowerShell%20Essentials.md).

## TL;DR
```cmd
net user                                 :: list local users
net user labuser Pass123! /add           :: create a user            (admin)
net localgroup Administrators labuser /add  :: add user to a group   (admin)
net share data=C:\data /GRANT:labuser,FULL  :: create a share        (admin)
net share                                :: list shares
net start / net stop <ServiceShortName>  :: start / stop a service   (admin)
net view \\192.168.1.20                  :: list a host's shares
```
> If a `net` change "runs" but nothing happens and you see **"Access is denied"** or **"requires elevation"** — you forgot to **Run as administrator**.

## Concept
`cmd.exe` is the classic Command Prompt (Start → type `cmd`). `net.exe` is a single built-in tool with sub-commands (`net user`, `net share`, …) that talk to the local Security Account Manager and the Server/Workstation services.

Think of `net` as **one remote control with buttons for three different boxes.** `net user`/`net localgroup`/`net accounts` press buttons on the **SAM** — the *Security Account Manager*, the local account database holding every local user, group, and the password policy (Windows' rough equivalent of `/etc/passwd` + `/etc/shadow`, stored as a protected registry hive). `net share`/`net session`/`net view`/`net use` drive the **SMB services**: the *Server* service (LanmanServer) publishes folders and tracks who's connected **in**, the *Workstation* service (LanmanWorkstation) is the client that reaches **out** to other hosts. `net start`/`net stop` talk to the *Service Control Manager*. One tool, three subsystems — which is why the sub-commands feel unrelated.

Two rules cover almost everything:
- **Listing** things (no target changes) usually works from a normal prompt.
- **Creating / deleting / starting / stopping** needs an **elevated** prompt: Win+X → *Terminal (Admin)*, or right-click cmd → **Run as administrator**.
- Any sub-command's syntax → append `/?`, e.g. `net user /?`.

> **Why elevation is the dividing line:** UAC hands even an admin account *two* tokens — a filtered "standard user" token for everyday work and the full-power token only when you explicitly elevate. A normal prompt runs on the filtered token, which can *read* the SAM and service list but can't *write* to them. That's why listing works but `/add` throws "Access is denied" until you Run as administrator.

## `net user` — local accounts
```cmd
net user                                 :: list all local users
net user labuser                         :: detail for one user (groups, last logon, expiry)
net user labuser Pass123! /add           :: CREATE user with a password        (admin)
net user labuser * /add                  :: CREATE user, prompt for hidden password (admin)
net user labuser /delete                 :: DELETE user                        (admin)
net user labuser /active:no              :: disable the account
```
→ `net user <name>` alone is the quick "who is this account and what groups is it in" check.

**PowerShell equivalent:**
```powershell
Get-LocalUser                                                   # list
Get-LocalUser labuser | Format-List *                           # detail
$pw = ConvertTo-SecureString 'Pass123!' -AsPlainText -Force
New-LocalUser -Name labuser -Password $pw -FullName 'Lab User'  # create
Remove-LocalUser -Name labuser                                  # delete
```

> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. On a domain-joined/hardened host, `/add` can fail with *"password does not meet complexity requirements"*: use 8+ chars with 3 of 4 classes (upper/lower/digit/symbol) — `Pass123!` qualifies.

## `net localgroup` — local groups
```cmd
net localgroup                                 :: list all local groups
net localgroup Administrators                  :: list MEMBERS of a group
net localgroup labgroup /add                   :: CREATE a group                 (admin)
net localgroup Administrators labuser /add     :: ADD labuser to Administrators   (admin)
net localgroup Administrators labuser /delete  :: remove a member                 (admin)
```
→ `net localgroup Administrators` is the one to memorise — it answers "who has admin on this box?"

> **Why groups matter:** Windows rarely grants power to a user directly — it grants rights to a *group* and drops users into it. "Being an admin" literally means "your account is a member of `Administrators`." Add someone there and they inherit every right the group holds, instantly. That's why it's the first place both admins and attackers look, and why one sneaky `/add` is a complete privilege grant.

**PowerShell equivalent:**
```powershell
Get-LocalGroup                                 # list groups
Get-LocalGroupMember -Group Administrators     # list members
New-LocalGroup -Name labgroup                  # create group
Add-LocalGroupMember -Group Administrators -Member labuser
Remove-LocalGroupMember -Group Administrators -Member labuser
```

## `net share` — shared folders
```cmd
net share                                     :: list all shares on THIS machine
net share data                                :: detail for share "data"
net share data=C:\data /GRANT:labuser,FULL    :: CREATE share, grant labuser Full   (admin)
net share data=C:\data /GRANT:Everyone,READ   :: CREATE share, Everyone read-only    (admin)
net share data /delete                        :: stop sharing                        (admin)
```
→ `/GRANT:<user>,<READ|CHANGE|FULL>` sets the **share-level** permission only. NTFS permissions (see [icacls and Permissions](icacls%20and%20Permissions.md)) still apply on top, and the **more restrictive of the two wins**.

> **What a share actually is:** the *Server* service advertising a local folder over SMB (TCP 445) under a name, so a remote machine can reach `C:\data` as `\\thisbox\data` without knowing the real path. Share name and disk path are decoupled on purpose — `data` can point anywhere, and hiding the path is half the point of the built-in `$` admin shares (`C$`, `ADMIN$`) that [PsExec](PsExec%20and%20Sysinternals.md) rides.

**PowerShell equivalent (SMB module):**
```powershell
Get-SmbShare                                               # list
New-SmbShare -Name data -Path C:\data -FullAccess labuser  # create
New-SmbShare -Name data -Path C:\data -ReadAccess Everyone
Remove-SmbShare -Name data                                 # delete
```

## `net use` — map / disconnect a network drive
```cmd
net use                                                :: list current drive mappings
net use Z: \\192.168.1.20\data /user:labuser Pass123!  :: map drive Z:
net use Z: \\192.168.1.20\data /user:labuser * /persistent:yes  :: prompt pwd, reconnect at logon
net use Z: /delete                                     :: unmap one
net use * /delete                                      :: unmap all
```
→ `/persistent:yes` re-attaches the drive at every logon. Full drive-mapping coverage (cmd + PowerShell + GUI) is in [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md).

> **Why it works:** a mapped drive is just a saved **SMB session** the Workstation service holds open to `\\host\share` — the drive letter is a convenient local alias for that client connection. `/persistent:yes` writes the mapping down so it's rebuilt at each logon; without it the session dies with the window.

## `net view` — browse machines and their shares
```cmd
net view                       :: list computers in the workgroup/domain (browser-dependent)
net view \\192.168.1.20        :: list the SHARES offered by that host
net view /all \\192.168.1.20   :: include admin$ / hidden ($) shares
```
→ Point it at a host to enumerate shares before you `net use` one.

> **Gotcha:** plain `net view` relies on legacy Computer Browser/SMBv1 discovery and is often **empty** on modern networks — that's normal, not a failure. Targeting a host directly (`net view \\192.168.1.20`) still works.

## `net accounts` — password & lockout policy
```cmd
net accounts                              :: show current password/lockout policy
net accounts /minpwlen:12                 :: min password length                 (admin)
net accounts /maxpwage:90 /minpwage:1     :: password age in days                (admin)
net accounts /uniquepw:5                  :: remember last 5 passwords            (admin)
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15
```
→ There is no single PowerShell cmdlet for this — `net accounts` is the exam answer for a quick read; deeper changes go through `secedit` / Group Policy.

## `net start` / `net stop` — services
```cmd
net start                :: list all RUNNING services
net start Spooler        :: start the Print Spooler service     (admin)
net stop Spooler         :: stop it                             (admin)
net stop Spooler /y      :: stop it + dependents, no prompt
```
→ Use the service **short name** (`Spooler`), not the display name ("Print Spooler"). Find short names with `sc query` or `Get-Service`.

**PowerShell equivalent:**
```powershell
Get-Service                          # list all services + status
Start-Service   -Name Spooler
Stop-Service    -Name Spooler -Force
Restart-Service -Name Spooler
```

## `net session` — who is connected TO this machine
```cmd
net session                          :: list inbound SMB sessions (needs admin + Server svc)
net session \\192.168.1.20 /delete   :: disconnect a specific client
```
→ Defensive use: see which clients currently hold an SMB session to this box. PowerShell equivalent: `Get-SmbSession`.

## `net statistics` — SMB counters since boot
```cmd
net statistics workstation   :: outbound (client) SMB stats
net statistics server        :: inbound (server) stats: sessions, files opened, errors
net stats srv                :: short form of "server"
```
→ Handy for spotting permission errors / failed logons and how hard this box is being used as a file server.

## CLI file tasks (cmd)
| Task | cmd.exe | one-liner |
|---|---|---|
| **Find a file** | `dir /s /b C:\*.txt` | recurse subfolders, bare paths only |
| | `where /r C:\ notepad.exe` | search a tree for a named file/exe |
| **Read a file** | `type file.txt` | dump whole file to screen |
| | `more file.txt` | page through a long file |
| **Create (empty)** | `type nul > file.txt` | a **truly empty** file |
| **Create (with text)** | `echo hello> file.txt` | one line of content |
| **Append** | `echo more>> file.txt` | add a line to the end |
| **Change perms** | `icacls file.txt /grant labuser:M` | grant Modify (see [icacls and Permissions](icacls%20and%20Permissions.md)) |

→ `dir /b` = bare names only, `/s` = recurse. `echo. > f` writes a file containing a **blank line**; `type nul > f` writes a **zero-byte** file — know the difference. PowerShell versions (`Get-ChildItem`, `Get-Content`, `Set-Content`) are in [PowerShell Essentials](PowerShell%20Essentials.md).

## Quick create table (both shells)
| Task | cmd.exe | PowerShell |
|---|---|---|
| List users | `net user` | `Get-LocalUser` |
| Create user | `net user labuser Pass123! /add` | `New-LocalUser labuser -Password $pw` |
| List groups | `net localgroup` | `Get-LocalGroup` |
| Add to group | `net localgroup Administrators labuser /add` | `Add-LocalGroupMember Administrators labuser` |
| List shares | `net share` | `Get-SmbShare` |
| Create share | `net share data=C:\data /GRANT:labuser,FULL` | `New-SmbShare -Name data -Path C:\data -FullAccess labuser` |

## Exam tips & gotchas
- **Elevation is the #1 trap.** Listing works unelevated; creating/deleting/starting/stopping does not. "Access is denied" = open an Admin prompt.
- **Service name vs display name:** `net stop` wants the short name (`Spooler`), not "Print Spooler".
- **Share vs NTFS perms are separate layers** — effective access is the *more restrictive*. Setting `/GRANT:Everyone,FULL` on the share does nothing if NTFS still denies the user.
- **`net view` blank ≠ broken** — modern networks disable legacy browsing; target the host by name/IP.
- **Password complexity** rejects weak passwords on hardened hosts; `Pass123!` meets the 3-of-4 rule.
- The trailing `::` in these blocks is a comment for readability — paste the command part, not the note.

## References
- net commands on operating systems — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/net-commands-on-operating-systems
- net user — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/net-user
- net share — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/net-share
- net localgroup — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/net-localgroup

## Related
- [PowerShell Essentials](PowerShell%20Essentials.md)
- [icacls and Permissions](icacls%20and%20Permissions.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [SMB PsExec and DCOM](../C2%20Frameworks/Metasploit/SMB%20PsExec%20and%20DCOM.md)
- [PsExec and Sysinternals](PsExec%20and%20Sysinternals.md)
