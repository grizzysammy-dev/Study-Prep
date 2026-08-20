---
tags: [cyber, module1, module3, windows]
jqr: "NTFS permissions with icacls: viewing, grant/deny/remove, recursive /T, /reset, the inheritance flags (OI)(CI)(IO) and /inheritance, plus the GUI Security tab"
---

# icacls and Permissions

`icacls` reads and edits the **NTFS ACL**, meaning who can do what to a file or folder. It's the Windows version of `chmod`/`chown` plus ACLs from [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md), just expressed as per-user entries with inheritance flags. Editing permissions on files I don't own needs **Administrator**.

## Quick reference
```cmd
icacls C:\data                                  :: VIEW the ACL
icacls C:\data /grant labuser:(OI)(CI)M         :: ADD Modify, inherited to files+subfolders
icacls C:\data /deny  labuser:(OI)(CI)W         :: explicit DENY (deny beats allow)
icacls C:\data /remove labuser                  :: remove labuser's entries
icacls C:\data /grant labuser:(OI)(CI)M /T /C   :: apply down the whole tree
icacls C:\data /reset /T /C                     :: wipe explicit ACLs, re-inherit
```
> The same `icacls` command line works in **cmd and PowerShell**, since it's a standalone .exe, so I don't need `Set-Acl`.

## Reading an ACL
An NTFS ACL isn't Linux's three-slot `rwxrwxrwx` (owner/group/other). It's an **ordered guest list**, the DACL (Discretionary Access Control List), where each line is one **ACE** (Access Control Entry) naming a *principal* and the rights it's allowed or denied. There's no fixed number of slots, so I can list twenty different users with twenty different rights if I want. Every principal is really a **SID** (a numeric security ID), and icacls resolves those SIDs to friendly names for me, which is why a deleted account shows up as a raw `S-1-5-...` string.

When I run `icacls C:\data`, each line is one entry:
```
BUILTIN\Administrators:(OI)(CI)(F)
NT AUTHORITY\SYSTEM:(OI)(CI)(F)
labuser:(OI)(CI)(M)
```
Format is `PRINCIPAL:(inheritance flags)(permission)`. So `labuser:(OI)(CI)(M)` reads as "labuser has **Modify**, and it flows to **files** and **subfolders** below."

> **Why deny always wins:** when I touch a file, Windows walks the ACE list, and an explicit **deny** that matches me short-circuits the whole check to "no" before any allow is even considered. It's a deliberate override so a deny is ironclad. Great for "everyone in this group *except* Bob," and dangerous when I deny `Everyone` and lock myself out along with everyone else.

### Permission letters (the "mask")
| Letter | Meaning |
|---|---|
| `F` | Full control |
| `M` | Modify |
| `RX` | Read & execute |
| `R` | Read-only |
| `W` | Write-only |
| `D` | Delete |

### Inheritance flags (go in parentheses **before** the permission)
| Flag | Meaning |
|---|---|
| `(OI)` | Object Inherit, applies to **files** in the folder |
| `(CI)` | Container Inherit, applies to **subfolders** |
| `(IO)` | Inherit Only, the folder itself is unaffected, only its children |

`(OI)(CI)F` means "Full control on this folder, all files, and all subfolders." That's the combo I use most.

## Grant, deny, remove
```cmd
icacls C:\data /grant labuser:(OI)(CI)M      :: ADD Modify (inherited down)
icacls C:\data /grant:r labuser:(OI)(CI)F    :: REPLACE labuser's perms with Full (:r = replace)
icacls C:\data /deny  labuser:(OI)(CI)W      :: explicit DENY write (deny always wins)
icacls C:\data /remove labuser               :: remove ALL allow+deny entries for labuser
icacls C:\data /remove:g labuser             :: remove only the GRANT (allow) entries
icacls C:\data /remove:d labuser             :: remove only the DENY entries
```
(need to actually try this on the lab box, but it matches the docs). Without `:r`, `/grant` **adds to** existing permissions; with `:r` it **replaces** that user's entry. Mixing those two up is the classic icacls mistake.

## Recursive `/T` and continue-on-error `/C`
```cmd
icacls C:\data /grant labuser:(OI)(CI)M /T /C
```
`/T` applies to the folder **and everything already under it**, and `/C` keeps going even if some files error (locked or open files). The distinction that matters: `(OI)(CI)` sets inheritance for *future* children, while `/T` re-stamps the *existing* ones, and I usually want both.

## Inheritance control
```cmd
icacls C:\data /inheritance:e    :: Enable inheritance from the parent
icacls C:\data /inheritance:d    :: Disable + COPY current inherited perms into explicit ones
icacls C:\data /inheritance:r    :: Remove all inherited perms (keep only explicit)
```
`:d` is the safe "stop inheriting but keep what I have" option. `:r` strips inherited entries and can lock people out, so I use it carefully.

## Reset to inherited defaults
```cmd
icacls C:\data /reset /T /C      :: wipe explicit ACLs, re-inherit from parent, recursively
```
The "undo my mess" button: it removes explicit entries and lets the folder inherit cleanly from its parent again.

## Backup / restore / ownership
```cmd
icacls C:\data /save  acl.txt /T       :: save the tree's ACLs to a file
icacls C:\data /restore acl.txt        :: restore them
icacls C:\data /setowner labuser /T    :: change owner (needs admin / SeTakeOwnership)
takeown /F C:\data /R /D Y             :: force-take ownership when even admin is locked out
```
`takeown` is the escape hatch when an ACL denies everyone including admins: take ownership, then re-grant with `icacls`.

> **Why ownership is the escape hatch:** the **owner** of an object can always rewrite its ACL, even when the DACL grants them nothing. Ownership is the meta-permission that sits *above* the guest list. That's the deadlock-breaker by design (an admin can seize a locked-out file), and it's why *who owns a file* matters as much as its ACL. On the blue side, an unexpected owner on a system binary, or a world-writable service executable, is a classic privilege-escalation tell (see [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md)).

## GUI: the Security tab
Right-click the file/folder → **Properties** → **Security** tab → **Edit...** → pick the user/group (or **Add...**) → tick **Allow**/**Deny** → **Apply**.
For inheritance and ownership, hit **Advanced**:
- **Disable/Enable inheritance** (matches `/inheritance:d` / `:e`)
- **Change** the owner at the top (matches `/setowner` / `takeown`)

> **Win11 gotcha:** the right-click menu is compact, so I click **Show more options** (or Shift+F10) if I don't see **Properties** with the full Security tab.

## PowerShell note
The native equivalents are `Get-Acl` / `Set-Acl`, but they're verbose (I'd be building ACL objects by hand). **Calling `icacls.exe` from inside PowerShell is the accepted, simpler method**, and the exact same command line works in both shells. I only reach for `Get-Acl` when I need the ACL as an object to script against.

## What trips me up
- **`:r` means replace, no `:r` means add.** The single most common icacls error I make.
- **Deny beats allow, always.** An explicit `/deny` overrides any grant, including group-inherited ones.
- **`(OI)(CI)` isn't the same as `/T`.** Inheritance flags cover *future* items; `/T` re-applies to *existing* items. I use both to fix a whole tree now and going forward.
- **Share perms are separate from NTFS**, and effective access is the *more restrictive* of the two. I set the share in [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md) and the NTFS ACL here.
- **Locked myself out?** `takeown /F <path> /R` then re-`icacls`.
- Editing ACLs on files I don't own needs **Administrator**.

## References
- icacls: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/icacls
- takeown: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/takeown
- Get-Acl / Set-Acl: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-acl

## Related
- [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [PowerShell Essentials](PowerShell%20Essentials.md)
- [Windows Processes and System Info](Windows%20Processes%20and%20System%20Info.md)
- [Privilege Escalation Concepts](../Knowledge%20Req/Privilege%20Escalation%20Concepts.md)
