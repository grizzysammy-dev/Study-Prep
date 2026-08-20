---
tags: [cyber, module3, linux]
jqr: "Module 3 - read and triage Linux logs: journalctl, /var/log, dmesg, syslog/rsyslog, wtmp/btmp/auth"
---

# Logs and journalctl

This is where Linux writes down what happened and how I read it when I'm under time pressure. As a defender this is home turf for me, but the exam box might be RHEL, so I need both filename sets in my head.

## The quick set
```bash
journalctl -xe                  # newest events + explanation text — the "why did it fail" combo
journalctl -u ssh -b            # one service (ssh), this boot only
journalctl -p err               # priority error and worse (0..3)
journalctl -k                   # kernel messages (= dmesg)
dmesg -T                        # kernel ring buffer, human timestamps
last / lastb                    # successful / FAILED logins (wtmp / btmp)
```
- **Debian/Ubuntu:** auth → `/var/log/auth.log`, general → `/var/log/syslog`.
- **RHEL/CentOS:** auth → `/var/log/secure`, general → `/var/log/messages`.

## How Linux stores logs
Modern Linux keeps a **binary journal** (owned by `systemd-journald`) that I query with `journalctl`, never `cat`. Alongside it, the classic text logs still live under `/var/log/`. A few login records (`wtmp`, `btmp`, `lastlog`) are also binary and need their own reader tools. So it's the same events reached three ways: the journal (query tool), text files (`less`/`grep`), and binary login logs (`last`/`lastb`).

Why binary at all: each journal entry isn't a line of text, it's a bundle of structured fields (unit, PID, priority, boot ID, timestamp, and more). That's what lets `journalctl` filter instantly by any of them (`-u ssh`, `-p err`, `-b -1`) the way a database does, instead of me grepping raw strings. The trade is I can't `cat` it, but I rarely need to. One blue-team caveat: this journal lives on the box, so whoever owns the box can also edit it, which is exactly why you ship a copy off-host (see rsyslog, below).

## journalctl (look here first)
```bash
journalctl                      # everything, oldest first (opens a pager — q to quit)
journalctl -e                   # jump to the END (newest) — most useful default
journalctl -f                   # FOLLOW live, like tail -f
journalctl -r                   # reverse: newest first
journalctl -b                   # only THIS boot
journalctl -b -1                # the PREVIOUS boot (-2 = two boots ago)
journalctl --list-boots         # every recorded boot with an index
journalctl -p err               # priority ERROR and worse
journalctl -p warning..err      # a priority RANGE
journalctl -u ssh               # only the ssh.service unit (-u = unit)
journalctl -u ssh -b            # ssh unit, this boot only
journalctl -xe                  # end (e) + explanation text (x) — classic failure triage
journalctl --since "1 hour ago"              # relative time works
journalctl --since today                     # since midnight
journalctl --since "-30 min" --until "now"   # a window
journalctl -k                   # KERNEL messages only (like dmesg)
journalctl _PID=1               # filter by a field (PID 1 = systemd)
```
`-u` scopes to one service, `-b` to one boot, `-p` to a severity floor, `-k` to the kernel, and I can stack them: `journalctl -u ssh -b -p err`.

Priority numbers for `-p`, lowest = most severe: `0 emerg, 1 alert, 2 crit, 3 err, 4 warning, 5 notice, 6 info, 7 debug`. So `-p err` is levels 0-3.

Reading `-xe`: each line is `TIMESTAMP HOST unit[PID]: message`, and the `x` adds `Subject:` / `Defined-By: systemd` hint lines explaining a failure and sometimes the fix.

Quick reminder to myself: the journal can be **volatile** (RAM only, wiped at reboot) if `/var/log/journal/` doesn't exist. Make it persistent with `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`, and check size with `journalctl --disk-usage`.

## Text logs under /var/log
Look around with `ls -lt /var/log` (newest first).

| Contains | Debian/Ubuntu | RHEL/CentOS | Read with |
|---|---|---|---|
| Auth / logins / sudo / ssh | `/var/log/auth.log` | `/var/log/secure` | `less`, `grep` |
| General system messages | `/var/log/syslog` | `/var/log/messages` | `less`, `grep` |
| Kernel (persisted) | `/var/log/kern.log` | (in `messages`) | `less`, `grep` |
| Successful logins (binary) | `/var/log/wtmp` | `/var/log/wtmp` | `last` |
| Failed logins (binary) | `/var/log/btmp` | `/var/log/btmp` | `lastb` |
| Last login per user (binary) | `/var/log/lastlog` | `/var/log/lastlog` | `lastlog` |
| Package manager | `/var/log/apt/` | `/var/log/dnf.log` | `less` |
| Boot | `/var/log/boot.log` | `/var/log/boot.log` | `less` |

The Debian vs RHEL split is the thing they love to test: auth events are `auth.log` (Debian) vs `secure` (RHEL); general messages are `syslog` (Debian) vs `messages` (RHEL). Same information, different filenames. Minimal installs may have *only* the journal, so if a file is missing I just fall back to `journalctl`.

Searching logs is a `grep` job. See [Files Search and Permissions](Files%20Search%20and%20Permissions.md) for `grep -rin`.

## dmesg (kernel ring buffer)
Prints the **kernel's** messages: hardware detection, disks, USB plug/unplug, OOM kills, driver errors. My go-to for "did the OS actually see my new disk/NIC?"

The "ring buffer" bit matters: it's a fixed-size chunk of kernel memory that the kernel scribbles events into and wraps around when full, so newest overwrites oldest. That makes `dmesg` a live window, not an archive; anything worth keeping gets copied to disk (the journal, `kern.log`) precisely because the buffer itself forgets. It's also why very early boot messages may have already scrolled off by the time I look.
```bash
sudo dmesg                # may need root on hardened systems
dmesg -T                  # human Timestamps (default is seconds-since-boot)
dmesg -w                  # Wait/follow live
dmesg --level=err,warn    # only errors and warnings
dmesg | grep -i sd        # find disk (sdX) events
```
`journalctl -k` is the journal equivalent, and `journalctl -k -b -1` shows the *previous* boot's kernel log, which is great for "why did it crash?".

## syslog / rsyslog
**syslog** is the decades-old standard for handing log messages to a collector, sorted by *facility* (auth, cron, mail, kern...) and *severity*. The daemon implementing it on most distros is **`rsyslog`**, and it writes the `/var/log/*.log` files.
- Config: **`/etc/rsyslog.conf`** and drop-ins in **`/etc/rsyslog.d/*.conf`**.
- A line like `auth,authpriv.*   /var/log/auth.log` means "send auth facility, all severities, to that file."
- Service control: `sudo systemctl status rsyslog` / `restart rsyslog`.
- On journald-only systems rsyslog may be absent; the journal does the same job.

rsyslog can also **forward logs over the network** (port **514**) to a central log server. That whole setup, templates, TCP vs UDP, TLS, the receiver side, lives in [rsyslog Remote Logging](rsyslog%20Remote%20Logging.md).

## Who logged in: wtmp, btmp, auth
These are binary files, so don't `cat` them, use their readers:
```bash
last                 # /var/log/wtmp -> successful logins + reboots, newest first
last -a              # show remote hostname/IP in the last column
last reboot          # just reboots (uptime history)
last -n 20           # last 20 entries
sudo lastb           # /var/log/btmp -> FAILED logins — spot brute force (needs sudo)
sudo lastb -a
lastlog              # /var/log/lastlog -> most recent login time for EVERY account
```
Reading `last`: the columns are `user`, `tty/pts`, `from-host`, the start and end times, then `(duration)`. `pts/0` is a network/pseudo terminal (ssh); `tty1` is a physical console; `still logged in` means active right now. For *current* sessions I use `who` (live) and `w` (live + what they're running); `last`/`lastb` are the historical record.

Reading `lastb`: same layout, every row a *failed* attempt, so repeated rows from one IP against `ssh` is a brute-force. Correlate with `/var/log/auth.log` (Debian) or `/var/log/secure` (RHEL): `sudo grep -i "failed password" /var/log/auth.log`.

## What I keep forgetting
- First move on any box: `journalctl -xe`, then `journalctl -u <service> -b` for the thing I actually care about.
- If a `/var/log` file "doesn't exist," I'm probably on the *other* distro family or a journald-only minimal install, so pivot to `journalctl`.
- `journalctl -p err` uses the **numeric** priority floor (0-3), not the word on each line.
- `lastb` needs **sudo**, and `btmp` is often absent until the first failed login gets recorded.
- Don't `cat` `wtmp`/`btmp`/`lastlog`; they're binary and print garbage. Use `last`/`lastb`/`lastlog`.
- A journal that resets every reboot means `/var/log/journal/` is missing, so create it for persistence.

## Docs
- `man 1 journalctl`, `man 8 systemd-journald`
- `man 1 dmesg`, `man 1 last`, `man 8 lastlog`
- rsyslog docs: https://www.rsyslog.com/doc/
- systemd journal: https://www.freedesktop.org/software/systemd/man/journalctl.html

## Related
- [rsyslog Remote Logging](rsyslog%20Remote%20Logging.md)
- [Processes and systemd](Processes%20and%20systemd.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
