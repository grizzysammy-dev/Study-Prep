---
tags: [jcu, module3, linux]
jqr: "Module 3 — the Filesystem Hierarchy Standard (key top-level dirs), man page sections, and which/type/whereis"
---

# Linux Filesystem (FHS)

Where things live on a Linux box — one tree hanging off `/`, no drive letters. Plus how to read the manual by section and how to find where a command actually runs from. Common exam question: "which directory holds X?"

## TL;DR
| Path | What lives there |
|---|---|
| **`/etc`** | System-wide **config** (`/etc/passwd`, `/etc/fstab`, `/etc/ssh/`) |
| **`/var`** | **Variable** data that grows — **`/var/log`**, spool, caches, `/var/www` |
| **`/home`** / **`/root`** | Users' homes / the **root** user's home (not `/`) |
| **`/bin` `/sbin`** | Essential user / admin commands |
| **`/usr/bin` `/usr/sbin`** | The bulk of distro programs / non-essential admin |
| **`/opt`** | Self-contained **third-party** bundles |
| **`/tmp` `/dev` `/proc` `/boot` `/lib`** | Temp (wiped) / device files / live kernel info / boot+GRUB / shared libs |
```bash
man 5 fstab      # section-5 (file format) page      man 7 hier = the whole FHS
which python3     # path of the binary that would run
type -a python3   # is it a file, builtin, alias, or function? (all matches)
```

## Concept
Linux follows the **Filesystem Hierarchy Standard (FHS)**: everything hangs off a single root **`/`**. There are no `C:`/`D:` drives — extra disks and shares are **mounted** onto directories inside the one tree (see [Disks Mounts and fstab](Disks%20Mounts%20and%20fstab.md)). `man 7 hier` documents the whole layout.

## Key top-level directories
| Path | What lives there |
|---|---|
| **`/`** | The root of everything |
| **`/etc`** | **System-wide config files** (text): `/etc/passwd`, `/etc/fstab`, `/etc/ssh/`, `/etc/apt/` |
| **`/home`** | Regular users' home directories (`/home/sam`) |
| **`/root`** | The **root** user's home (NOT `/`) |
| **`/var`** | **Variable** data that grows: **`/var/log`** (logs), mail, spool, caches, `/var/www` |
| **`/tmp`** | Temporary files, world-writable, **wiped on reboot** |
| **`/proc`** | Virtual FS — live **kernel/process** info (`/proc/cpuinfo`, `/proc/<pid>/`); not real disk files |
| **`/sys`** | Virtual FS — kernel/device tree (tweak hardware settings) |
| **`/dev`** | **Device files**: `/dev/sda` (disk), `/dev/null`, `/dev/random`, `/dev/tty` |
| **`/boot`** | Kernel (`vmlinuz`), initramfs, and **GRUB** files needed to boot |
| **`/lib`, `/lib64`** | Shared libraries + kernel modules (on modern distros a symlink into `/usr/lib`) |
| **`/mnt`** | Spot to **manually mount** things temporarily |
| **`/media`** | Auto-mounted **removable** media (USB, CD) |
| **`/srv`** | Data served by the box (web/ftp roots) |
| **`/run`** | Runtime state since boot (PIDs, sockets); tmpfs in RAM |

## Where binaries live — a common exam question
| Path | Contains |
|---|---|
| **`/bin`** | **Essential user commands** (`ls`, `cp`, `cat`) — needed even in single-user/repair |
| **`/sbin`** | **Essential system/admin** commands (`fdisk`, `ip`, `mount`, `reboot`) — mostly root |
| **`/usr/bin`** | The **bulk of user programs** installed by the distro (most commands are here) |
| **`/usr/sbin`** | Non-essential **admin** programs (daemons, `useradd`, `sshd`) |
| **`/usr/local/bin`** | Programs **you/the admin installed locally** — kept separate, earlier in `$PATH` so your version wins |
| **`/usr/local/sbin`** | Locally-installed admin programs |
| **`/opt`** | **Optional / self-contained third-party** software as a whole bundle (`/opt/google/chrome`), each app in its own subdir |

> **Modern note (`/usr` merge):** on current distros `/bin → /usr/bin`, `/sbin → /usr/sbin`, `/lib → /usr/lib` are **symlinks** — the historical split is preserved by name but physically unified under `/usr`. Mental model still holds: **`/bin` `/sbin`** = essential base, **`/usr/bin` `/usr/sbin`** = the main distro set, **`/usr/local/*`** = what *you* added, **`/opt`** = big self-contained third-party bundles.

## man pages — the 8 section numbers
```bash
man ls              # the manual for ls
man 5 passwd        # section-5 (FILE format) page for "passwd" = the FILE /etc/passwd
man passwd          # no number -> LOWEST-numbered section (here 1, the command)
man -k network      # KEYWORD search across all pages (= apropos network)
man -f passwd       # short description + which sections exist (= whatis passwd)
```
Inside a page (it opens in `less`): **`/word`** search, **`n`**/`N` next/prev, **Space**/`b` page down/up, **`g`**/`G` top/bottom, **`q`** quit.

| # | Contains | Example |
|---|---|---|
| **1** | User commands | `man 1 ls` |
| **2** | System calls (kernel) | `man 2 open` |
| **3** | Library functions (C) | `man 3 printf` |
| **4** | Devices / special files (`/dev`) | `man 4 null` |
| **5** | File formats & config files | `man 5 fstab`, `man 5 passwd` |
| **6** | Games & screensavers | `man 6 sl` |
| **7** | Miscellany / overviews / conventions | `man 7 signal`, `man 7 hier` |
| **8** | System administration commands (root) | `man 8 mount`, `man 8 fdisk` |

> **Why the number matters:** some names exist in several sections. `passwd` is both the **command** (`man 1 passwd`) and the **file** `/etc/passwd` (`man 5 passwd`). `man 7 hier` documents this whole filesystem layout. Admin tools cluster in **section 8**.

## Where does a command run from? which / type / whereis
```bash
which python3        # the PATH to the executable that would run (first match in $PATH)
type python3         # richer: file, shell BUILTIN, alias, or function?
type -a python3      # ALL matches, in priority order
command -v python3   # POSIX-portable "which" — best for scripts
whereis python3      # binary + source + MAN PAGE locations for the name
compgen -c | grep -i net   # list every command, filtered — discover related tools
```
- **`which`** — "where's the binary?" (path only).
- **`type`** — "what *is* this name?" — catches the trap where a **builtin or alias** (e.g. `type cd`, `type ll`) runs instead of a file; `which` misses that.
- **`command -v`** — the script-safe version of which/type.
- **`whereis`** — binary + man page + source; handy to find a tool's docs.
- **`compgen -c`** — enumerate all commands (recon: what's installed to pivot to).

## Exam tips & gotchas
- **Config → `/etc`, logs → `/var/log`, temp (wiped) → `/tmp`, device files → `/dev`, live kernel/process info → `/proc`.** These five are the most-asked.
- **`/root` is root's home, not `/`.** Easy trap.
- Essential commands in **`/bin` `/sbin`**; the bulk in **`/usr/bin` `/usr/sbin`**; *your* installs in **`/usr/local/*`**; vendor bundles in **`/opt`**.
- On modern distros `/bin`, `/sbin`, `/lib` are **symlinks into `/usr`** — don't be surprised.
- **`man 5 <name>`** for a config-file format, **`man 8 <name>`** for an admin tool; `man 7 hier` is the FHS itself.
- Use **`type`** (not just `which`) when a command behaves oddly — it reveals aliases/builtins.

## References
- FHS 3.0 spec: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
- `man 7 hier`, `man 1 man`, `man 1 which`, `man 1 type` (bash builtin), `man 1 whereis`

## Related
- [Package Management](Package%20Management.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
- [Disks Mounts and fstab](Disks%20Mounts%20and%20fstab.md)
- [Logs and journalctl](Logs%20and%20journalctl.md)
