---
tags: [cyber, module3, linux]
jqr: "Module 3 — inspect/kill processes (top/htop/ps, signals) and manage services with systemd/systemctl"
---

# Processes and systemd

Seeing what's running, killing it cleanly, and controlling the services systemd starts at boot. Includes the one-liner that ties a listening port back to the process behind it.

## TL;DR
```bash
top                             # live process view (P=sort CPU, M=sort mem, k=kill, q=quit)
ps aux | grep sshd              # snapshot: find a process (BSD style)
kill 1234                       # polite SIGTERM (15); kill -9 1234 = force SIGKILL
pkill -f "python app.py"        # kill by matching the full command line
sudo systemctl enable --now nginx   # start now AND at every boot
systemctl status nginx          # running? enabled? recent logs, PID, memory
sudo systemctl daemon-reload    # after creating/editing any unit file
sudo ss -tulpn                  # every listening port + the program that owns it
```
- **enable ≠ start.** `enable` = future boots; `start` = right now. `enable --now` = both.
- **SIGTERM (15) before SIGKILL (9).** Give the app a chance to clean up first.

## Concept
A **process** is a running program with a PID; every process has a parent (PPID) — trace the tree back and you reach **PID 1 = systemd**. **systemd** is the modern **init system** (first process the kernel starts) *and* **service manager**: it boots the machine, starts/stops background services (**units**), tracks dependencies/ordering, and owns the journal ([Logs and journalctl](Logs%20and%20journalctl.md)). You drive it with **`systemctl`**. *A "unit" is just systemd's noun for anything it manages — a service, a timer, a socket, a mounted disk — each described by a small declarative text file that says what to run and what it depends on.*

## top — live view (always installed)
```bash
top
```
**Header:** `load average: 0.15, 0.10, 0.05` = run-queue over **1/5/15 min** (compare to core count via `nproc`; load ≈ cores = fully busy). `%Cpu(s)`: `us` user, `sy` kernel, `id` idle, `wa` **I/O wait** (high = disk bottleneck), `st` stolen (VMs). `MiB Mem`/`MiB Swap`: heavy **swap** = RAM pressure.

**Per-process columns:** `PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND`.
- `RES` = **real RAM** used (the number that matters). `VIRT` = virtual (usually huge, ignore).
- `S` = state: **R**unning, **S**leeping, **D** uninterruptible sleep (stuck on I/O), **Z** zombie, **T** stopped.
- `%CPU` can exceed 100% (per-core; 200% = two full cores).

**Keys inside top:** `P` sort by CPU, `M` by memory, `k` kill a PID, `1` show each core, `u` filter by user, `q` quit.

## htop — nicer (install it)
```bash
sudo apt install htop        # or dnf install htop
htop
```
→ Same data, colored per-core bars, scrollable, mouse. **F3** search, **F4** filter, **F5** tree, **F6** sort, **F9** kill, **F10** quit. Preferred when available.

## ps — one-shot snapshot (scriptable)
```bash
ps aux               # BSD style: EVERY process, all users, %CPU/%MEM
ps -ef               # UNIX style: every process, with PPID (parent)
ps aux | grep sshd   # find a process (or: pgrep -a sshd)
ps -ef --forest      # tree of parent/child relationships
ps -u sam            # only user sam's processes
ps -eo pid,ppid,user,%cpu,%mem,stat,cmd --sort=-%cpu | head   # custom cols, top CPU first
```
- **`ps aux`**: `USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND` — `RSS` = real RAM (KB), `STAT` = state (`+` foreground, `s` session leader).
- **`ps -ef`**: `UID PID PPID C STIME TTY TIME CMD` — note **`PPID`** for tracing what spawned what.
> **Remember both spellings:** `ps aux` (no dash, BSD) and `ps -ef` (dash, UNIX) — same goal. `top`/`htop` = live; `ps` = a frozen snapshot you can pipe.

## Kill processes — it's really "send a signal"
- **`SIGTERM` (15)** — "please terminate," the **polite default**; lets the app flush files/close sockets. Try first.
- **`SIGKILL` (9)** — "die now," kernel force-kill, **cannot be caught**. Last resort; risks data loss.
- **`SIGHUP` (1)** often = "reload config"; `SIGSTOP`/`SIGCONT` pause/resume.
> **Why `-9` is the nuclear option:** a signal is just the kernel tapping a process on the shoulder. Most signals — SIGTERM included — can be *caught*: the program registers a handler and gets a moment to flush buffers and close sockets before exiting. **SIGKILL is carried out by the kernel itself**; the process never runs another instruction, so there's no chance to clean up — reliable, but that's exactly why it can leave half-written files. And a process in state **`D`** is asleep *inside* a kernel call, so it can't receive anything until that I/O returns — which is why even `-9` "won't kill it."
```bash
kill 1234              # SIGTERM (15) to PID 1234 — polite default
kill -15 1234          # explicit SIGTERM
kill -9 1234           # SIGKILL — force (only if TERM failed)
kill -l                # list all signal names/numbers
killall firefox        # kill ALL processes by exact NAME (SIGTERM default)
killall -9 firefox     # force-kill them all
pkill -f "python app.py"   # match the full command line (-f), not just the name
pkill -u sam           # kill all of user sam's processes
pgrep -af sshd         # FIND matching PIDs first — look before you leap
```
**Typical flow:** `kill PID` → wait a few seconds → still there? → `kill -9 PID`.
> **Gotchas:** always **15 before 9** — `-9` gives no chance to save and can corrupt files. A process in state **`D`** (uninterruptible I/O) **won't die even with -9** until the I/O completes. `killall` matches by name (be sure it's right); `pkill -f` matches the command line (verify with `pgrep -af` first).

## systemctl — control services
```bash
sudo systemctl start  nginx      # start now
sudo systemctl stop   nginx      # stop now
sudo systemctl restart nginx     # stop + start (blunt config reload)
sudo systemctl reload nginx      # re-read config WITHOUT dropping connections (if supported)
sudo systemctl enable nginx      # start automatically AT BOOT (creates a symlink)
sudo systemctl disable nginx     # do NOT start at boot
sudo systemctl enable --now nginx  # enable AND start in one shot
systemctl status nginx           # running? recent logs, PID, memory, enabled state
systemctl is-active nginx        # -> active / inactive   (scriptable)
systemctl is-enabled nginx       # -> enabled / disabled
systemctl list-units --type=service          # all loaded services
systemctl list-unit-files --state=enabled    # everything set to start at boot
systemctl --failed               # units that FAILED (great triage command)
```
> **enable ≠ start.** `enable` = every boot (future); `start` = this instant (now). `enable --now` does both; mirror for off is `disable` (future) vs `stop` (now).

**Reading `status`:** `Active: active (running)` = up; `active (exited)` = a one-shot that finished OK; `failed` = crashed (scroll the log lines, or `journalctl -u nginx -e`). `Loaded: … ; enabled` tells you the boot setting.

**Where unit files live (precedence high → low):**
| Location | Purpose |
|---|---|
| **`/etc/systemd/system/`** | **Admin/local** units + overrides — **highest priority**, put your own here |
| **`/run/systemd/system/`** | Runtime-generated units (volatile) |
| **`/lib/systemd/system/`**, **`/usr/lib/systemd/system/`** | **Package-shipped** units — don't edit (vendor-owned; `/lib` is a symlink to `/usr/lib`) |

**`daemon-reload` — the must-remember step:**
```bash
sudo systemctl daemon-reload     # re-read unit files AFTER you create/edit one
```
> **Gotcha:** whenever you add or edit a `.service` file, run **`daemon-reload`** first, *then* `restart`/`start` — skip it and systemd keeps the old definition. To customise a vendor unit safely use `sudo systemctl edit nginx` (writes an override in `/etc/systemd/system/…`) instead of editing files under `/usr/lib`.

## What's listening? ss -tulpn
When triaging a service, you want the reverse of "is it running?" — "what port is open, and which process owns it?" **`ss`** (from `iproute2`, the modern `netstat`) answers with the flag block **`-tulpn`**:
- **`t`** TCP · **`u`** UDP · **`l`** listening only · **`p`** owning **process/PID** (needs sudo for other users) · **`n`** numeric (`:22` not `:ssh`, no DNS).

```bash
sudo ss -tulpn            # THE command: listening sockets + owning program
sudo ss -tulpn | grep :443   # who's on port 443?
```

> ✅ **Tested output** (Ubuntu 24.04, 2026):
```
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      128          0.0.0.0:2025       0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2024       0.0.0.0:*
tcp   LISTEN 0      512        127.0.0.1:42569      0.0.0.0:*    users:(("claude",pid=461,fd=13))
tcp   LISTEN 0      4096       127.0.0.1:34007      0.0.0.0:*    users:(("environment-man",pid=473,fd=13))
tcp   LISTEN 0      5            0.0.0.0:8080       0.0.0.0:*    users:(("python3",pid=12539,fd=3))
```
→ Each `LISTEN` row is an open door. **`0.0.0.0:8080`** = reachable from the whole network and owned by **`python3` pid=12539** — take that PID straight to `ps -p 12539` or `kill`. **`127.0.0.1:42569`** = localhost-only (not exposed). An unexpected `0.0.0.0` LISTEN owned by an unfamiliar program is exactly how you spot a backdoor. (Deeper packet analysis of those sockets: [Tcpdump](../Recon%20Tools/Tcpdump.md).)

## Exam tips & gotchas
- **`enable --now`** is the one-liner they want for "make it run now and survive reboot."
- Forgot **`daemon-reload`** after editing a unit → your change silently does nothing.
- **SIGTERM (15) then SIGKILL (9)** — never lead with `-9`. State `D` won't die even with `-9`.
- `ps aux` **and** `ps -ef` both exist — know both column sets; `PPID` only shows in `-ef`.
- `sudo ss -tulpn` is the first thing to run on an unknown box: every listening port + its process.
- `systemctl --failed` is the fastest "what's broken" triage.

## References
- `man 1 systemctl`, `man 1 top`, `man 1 ps`, `man 1 kill`, `man 8 ss`
- systemd: https://systemd.io/  •  https://www.freedesktop.org/software/systemd/man/systemctl.html
- signal(7): https://man7.org/linux/man-pages/man7/signal.7.html

## Related
- [Logs and journalctl](Logs%20and%20journalctl.md)
- [Tcpdump](../Recon%20Tools/Tcpdump.md)
- [cron](cron.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
