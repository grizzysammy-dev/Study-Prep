---
tags: [jcu, module1, module3, windows]
jqr: "Processes: tasklist/taskkill and Get-Process/Stop-Process; find where a process runs from (Get-CimInstance Win32_Process ExecutablePath; wmic removed 2026); systeminfo/Get-ComputerInfo; map a network drive; GUI file manipulation"
---

# Windows Processes and System Info

Listing processes, **killing** them, finding **where a process runs from on disk** (the defensive money question), pulling **system info**, mapping a **network drive**, and the File Explorer GUI tricks. Windows counterpart to [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md).

## TL;DR
```cmd
tasklist                                :: list processes (Name, PID, Session, Mem)
taskkill /IM notepad.exe /F             :: kill by image name, force
taskkill /PID 4321 /T /F                :: kill a PID and its child tree
systeminfo                              :: OS build, uptime, hotfixes, RAM, NICs, domain
```
```powershell
Get-Process | Select Name, Id, Path                       # process + executable path
Get-CimInstance Win32_Process | Select Name, ProcessId, ExecutablePath, CommandLine
Stop-Process -Name notepad -Force
```
> **2026:** `wmic.exe` is **removed** — use `Get-CimInstance` for `ExecutablePath`/`CommandLine`. WMI itself still works; only the old wrapper is gone.

## Concept
Every running program is a **process** with three things you care about as a defender:
- a **PID** (process id) — the unique number you kill by,
- an **image name** (`notepad.exe`) — the on-disk file it was launched from, and
- an **executable path** — *where* that file lives on disk.

That last one is the tell. Legit Windows binaries live in `C:\Windows\System32`; the same-named process running out of `C:\Users\...\AppData\Temp` is how masquerading malware hides. `tasklist`/`Get-Process` show the first two easily; the **path and the launch command line** need `Get-CimInstance Win32_Process` (the 2026 replacement for the retired `wmic`). Pair that with a quick **`systeminfo`** to fingerprint the host and you can triage an unfamiliar machine in two commands.

> **Why the path beats the name:** a process name is just the filename of the image it loaded — trivially faked, since anyone can name a binary `svchost.exe`. The **full path** (and its digital signature) is what's hard to fake: the real `svchost.exe` is a signed file in `C:\Windows\System32`, so a `svchost.exe` running from a user's Temp folder is that name wearing a disguise. Under the hood a process is an isolated block of memory plus a **security token** — the account and privileges it runs as — and one or more threads; the PID is just the kernel's handle to that bundle.

## List running processes
```cmd
tasklist                                  :: all processes
tasklist /v                               :: verbose (adds user + window title)
tasklist /svc                             :: which services run inside each process
tasklist /fi "imagename eq notepad.exe"   :: filter by image name
tasklist /m                               :: modules (DLLs) loaded per process
```
```powershell
Get-Process                                        # all processes
Get-Process -Name notepad                          # filter by name
Get-Process | Sort CPU -Descending | Select -First 10   # top CPU
```
→ `tasklist /svc` is great for triage — it tells you which service is hiding inside a shared `svchost.exe`. *(Windows packs many services into a handful of shared `svchost.exe` host processes to save resources, so one `svchost` PID can be running a dozen services at once — `/svc` is how you see which ones.)*

## Where a process runs from (executable path)
The defensively important one: a `svchost.exe` running from `C:\Users\...\Temp` instead of `C:\Windows\System32` is a red flag.
```cmd
tasklist /m                                         :: DLLs loaded per process
:: LEGACY (wmic removed in 2026 — shown only because older JQRs name it):
wmic process get Name,ExecutablePath,ProcessId
```
```powershell
# PREFERRED in 2026:
Get-Process | Select-Object Name, Id, Path
Get-CimInstance Win32_Process | Select-Object Name, ProcessId, ExecutablePath
# Include the full launch command line (best single triage view):
Get-CimInstance Win32_Process | Select-Object Name, ProcessId, CommandLine
Get-CimInstance Win32_Process -Filter "Name='notepad.exe'" | Select Name, ExecutablePath, CommandLine
```
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. `Get-CimInstance Win32_Process` with `ExecutablePath` **and** `CommandLine` is the answer to "where did this run from and how was it launched."

> **Gotchas:** `wmic` no longer exists on 2026 Windows 11 — write `Get-CimInstance` as the real answer (add the `wmic` line only if an older exam explicitly accepts it). `Get-Process ... Path` may show **blank** for protected/system processes unless the shell is **elevated**.

> **What WMI/CIM actually is:** picture a built-in **database describing the whole machine** — processes, services, disks, patches, NICs — that you query like a data source. `wmic` was the old command-line wrapper over it (now removed); `Get-CimInstance` is the modern client to the *same* repository. `Win32_Process` is effectively "the processes table," so asking it for `ExecutablePath`/`CommandLine` is a query — which is why it surfaces fields `tasklist` never shows.

## Kill processes
```cmd
taskkill /PID 4321 /F              :: kill by PID, force
taskkill /IM notepad.exe /F        :: kill by image name (all copies), force
taskkill /IM chrome.exe /T /F      :: /T also kills the child tree
```
```powershell
Stop-Process -Id 4321 -Force
Stop-Process -Name notepad -Force
Get-Process chrome | Stop-Process -Force
```
→ `/F` = force, `/IM` = image name, `/PID` = process id, `/T` = whole tree. Killing by `/IM` hits every copy — use a PID to be surgical.

## System info
```cmd
systeminfo        :: OS build, install date, uptime, hotfixes, RAM, NICs, domain
hostname          :: just the computer name
ver               :: Windows version string
```
```powershell
Get-ComputerInfo                                       # very detailed object
Get-ComputerInfo | Select OsName, OsVersion, CsName, WindowsProductName
systeminfo                                             # also runs fine in PowerShell
```
→ GUI equivalent: **`msinfo32`**. `systeminfo` is the fast "what OS/patch level/domain is this" check; **Gotcha:** `Get-ComputerInfo` is thorough but takes a few seconds — that's normal, not a hang.

## Map a network drive
### cmd
```cmd
net use Z: \\192.168.1.20\data /user:labuser Pass123!             :: map Z: to the share
net use Z: \\192.168.1.20\data /user:labuser * /persistent:yes   :: prompt pwd, reconnect at logon
net use Z: /delete                                               :: unmap
```
→ `/persistent:yes` reconnects the drive at each logon.

### PowerShell
```powershell
# Session-only (disappears when the shell closes):
New-PSDrive -Name Z -PSProvider FileSystem -Root \\192.168.1.20\data -Credential (Get-Credential)
# Persistent (survives reboot, shows in File Explorer like net use):
New-PSDrive -Name Z -PSProvider FileSystem -Root \\192.168.1.20\data -Persist -Credential (Get-Credential)
Remove-PSDrive -Name Z                                    # unmap
```
> **Gotcha:** plain `New-PSDrive` (no `-Persist`) only exists inside that PowerShell session — it won't show in Explorer or survive a reboot. Use **`-Persist`** for a real mapped drive. *(Why: a mapped drive is a saved SMB client session; `-Persist` writes it to the registry so Windows rebuilds it at logon, whereas a session-only drive lives in RAM and dies with the shell — the same in-memory-vs-saved split as `route` vs `route -p`.)*

### GUI (File Explorer)
1. **File Explorer** → **This PC** (left pane).
2. Toolbar → **`...` (See more)** → **Map network drive** (Win11 24H2+). *(Older builds: Computer tab → Map network drive.)*
3. Pick a **Drive** letter (`Z:`), enter **Folder** `\\192.168.1.20\data`.
4. Tick **Reconnect at sign-in** and **Connect using different credentials** → **Finish** → enter `labuser` / `Pass123!`.

## GUI file manipulation (Win11 File Explorer)
- **Create a file:** right-click empty space → **New** → **Text Document** → name it → Enter.
- **Show file extensions:** toolbar **View** → **Show** → tick **File name extensions**. *(Or Options → **View** tab → untick "Hide extensions for known file types".)*
- **Show hidden files:** **View** → **Show** → tick **Hidden items**.
- **Change permissions:** right-click file → **Properties** → **Security** tab → **Edit…** → tick Allow/Deny (details in [icacls and Permissions](icacls%20and%20Permissions.md)).
- **Share a directory:** right-click folder → **Properties** → **Sharing** tab → **Advanced Sharing…** → tick **Share this folder** → set **Share name** (`data`) → **Permissions**. Remember NTFS (Security) perms also apply — effective access is the **more restrictive** of share vs NTFS.

> **Win11 context-menu gotcha:** Windows 11 shows a **compact** right-click menu first. If the option you want isn't there, click **Show more options** (or Shift+F10) for the full classic menu.

## Exam tips & gotchas
- **`wmic` is gone in 2026** — `Get-CimInstance Win32_Process` is the executable-path/command-line answer.
- **Blank process Path?** Elevate the shell — protected/system process paths are hidden otherwise.
- **`/IM` kills every copy; `/PID` is surgical.** Add `/T` to take out child processes too.
- **`New-PSDrive` needs `-Persist`** to behave like `net use` — otherwise it's session-only.
- **`Get-ComputerInfo` is slow** (a few seconds) by design.
- **Share vs NTFS** effective-access = the more restrictive layer, in both CLI and GUI.

## References
- tasklist — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tasklist
- taskkill — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/taskkill
- Get-CimInstance — https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance
- WMIC removal from Windows — https://support.microsoft.com/en-us/servicing/os/windows/docs/2025/09/windows-management-instrumentation-command-line-wmic-removal-from-windows
- systeminfo — https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/systeminfo

## Related
- [Processes and systemd](../Linux%20Admin/Processes%20and%20systemd.md)
- [PowerShell Essentials](PowerShell%20Essentials.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [icacls and Permissions](icacls%20and%20Permissions.md)
- [Windows Logs and Scheduled Tasks](Windows%20Logs%20and%20Scheduled%20Tasks.md)
