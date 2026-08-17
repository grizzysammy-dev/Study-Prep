---
tags: [jcu, module3, recon, networking]
jqr: "Secure file transfer with scp — local<->remote, recursive (-r), non-standard port (-P), IPv6 brackets, and the rsync-over-SSH alternative"
---

# SCP

`scp` copies files over an SSH transport — same auth, same encryption as [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md), just moving files instead of running a shell. On 2026 distros (OpenSSH ≥ 9.0) `scp` runs over the **SFTP protocol** by default; the old custom SCP wire protocol is deprecated (force it with `-O` only for a legacy server). The syntax below is unchanged by that switch.

## TL;DR

```bash
scp ./report.txt sam@192.168.1.20:/home/sam/           # local -> remote
scp sam@192.168.1.20:/var/log/syslog ./                # remote -> local
scp -r ./configs sam@192.168.1.20:/home/sam/backup/    # whole directory (recursive)
scp -P 2222 ./report.txt sam@192.168.1.20:/home/sam/   # non-standard port (CAPITAL -P!)
scp ./report.txt sam@[2001:db8::20]:/home/sam/         # IPv6 needs [brackets]
rsync -avz -e ssh ./configs/ sam@192.168.1.20:/home/sam/backup/   # modern alternative
```

- **`scp -P` is UPPERCASE** for port (lowercase `-p` = *preserve* mtime/mode). Exact opposite of `ssh -p`.
- **The last argument is always the destination.** Reversing source/dest silently overwrites the wrong side.
- **IPv6 targets need `[ ]` brackets** — unlike bare `ssh`.
- `scp` inherits **`~/.ssh/config`**, so keys, aliases, and `ProxyJump` bastion hops apply automatically.

## Concept

General form: `scp [opts] SOURCE ... DEST`, where a remote path is `[user@]host:/path`. The **colon is what makes a path "remote"**: `host:/path` copies over SSH, but `host/path` (no colon) is just a local file with an odd name. Because it rides SSH, `scp` reuses your whole SSH setup — keys, `known_hosts`, and `~/.ssh/config` (including `ProxyJump`), so `scp file webadmin:/tmp/` transparently hops a bastion if `webadmin` is configured that way in [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md).

## Copy local -> remote

```bash
scp ./report.txt sam@192.168.1.20:/home/sam/
```
→ Copies local `report.txt` to hostB under `/home/sam/`. A **trailing `:` with no path** (`sam@192.168.1.20:`) drops the file in the remote user's home — easy to do by accident. Quote remote wildcards (they glob on the *remote* side).

## Copy remote -> local

```bash
scp sam@192.168.1.20:/var/log/syslog ./syslog-hostB
```
→ Pulls `/var/log/syslog` from hostB into the current directory, renamed. You run this **from your local machine** — `scp` opens the SSH session for you. The **last** argument is the destination; reversing source/dest silently overwrites the wrong file.

## Copy a whole directory (`-r`)

```bash
scp -r ./configs sam@192.168.1.20:/home/sam/backup/
```
→ Recursively copies the whole `configs/` tree to hostB. `configs` (no trailing slash) creates `/home/sam/backup/configs/…`. Trailing-slash behaviour is fiddlier than `rsync`'s — if directory nesting matters, prefer `rsync` (below).

## Non-standard port (**capital `-P`**)

```bash
scp -P 2222 ./report.txt sam@192.168.1.20:/home/sam/
```
→ Copies via `sshd` on port **2222**. `scp` uses **uppercase `-P`** for port; lowercase `-p` means *preserve times/mode*. This is the exact opposite of `ssh` (lowercase `-p`) and the single most common scp mistake.

> ✅ **Tested output** (Ubuntu 24.04, 2026) — `scp -P 2222` to a local `sshd`, key auth:
```
$ scp -P 2222 /tmp/xfer.txt root@127.0.0.1:/tmp/xfer_copy.txt   (note capital -P)
copied OK -> hello-from-scp 04:03:46
```
The file copied over SSH on the non-standard port; the `copied OK -> hello-from-scp …` line is the destination file's contents read back after the transfer, proving the bytes landed. Capital `-P` confirmed.

## IPv6 (**bracket syntax**)

```bash
scp ./report.txt sam@[2001:db8::20]:/home/sam/         # local -> remote over IPv6
scp sam@[2001:db8::20]:/var/log/syslog ./syslog-hostB  # remote -> local over IPv6
scp ./report.txt sam@[fe80::20%eth0]:/home/sam/        # link-local: zone inside the brackets
scp -6 ./report.txt sam@[2001:db8::20]:/home/sam/      # force the IPv6 family
```
→ The **`[ ]` brackets are mandatory**: the target already uses a colon to separate host from `:path`, so without brackets `scp` can't tell where the address ends and the path begins. Link-local still needs `%interface` *inside* the brackets. (Bare `ssh` doesn't need brackets — see [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) IPv6 section.)

## Modern alternative: `rsync` over SSH

```bash
rsync -avz -e ssh ./configs/ sam@192.168.1.20:/home/sam/backup/
rsync -avz -e "ssh -p 2222" ./configs/ sam@192.168.1.20:/home/sam/backup/   # non-standard port
```
→ `-a` archive (perms/times/symlinks), `-v` verbose, `-z` compress; `-e ssh` runs it over the SSH transport. Copies **only the differences**, resumes cleanly — far better for large trees and repeat syncs.
- **A trailing slash on the source matters:** `./configs/` copies the *contents* into the dest; `./configs` (no slash) copies the *directory itself*.
- `rsync` must be installed on **both** ends (it's in every base repo). Note the port flag lives *inside* `-e "ssh -p 2222"`, not as a bare `-P`.
- Keep `scp` primary for the skills check, but `rsync -avz -e ssh` is the common modern go-to for anything bigger than a couple of files.

## Exam tips & gotchas

- **`scp -P` (uppercase) for port** — the opposite of `ssh -p`. Burn this in.
- **Destination is always the last argument.** Reversed args overwrite the wrong file with no warning.
- **IPv6 -> `[brackets]`**, link-local -> `[fe80::20%eth0]` (zone *inside*). `ssh` needs neither.
- **`scp` inherits `~/.ssh/config`** — ProxyJump, keys, and host aliases all apply, so a bastion hop is automatic when configured.
- **SFTP-by-default** since OpenSSH 9.0; `-O` forces the legacy protocol only if a crusty server needs it.
- **Large / repeat transfers -> `rsync -avz -e ssh`**, and mind the source trailing slash.

## References

- `scp(1)` man page — https://man.openbsd.org/scp
- `rsync(1)` man page — https://download.samba.org/pub/rsync/rsync.1
- OpenSSH release notes (SFTP-by-default since 9.0) — https://www.openssh.com/releasenotes.html

## Related

- [SSH - Tunneling and Jump Hosts](SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
- [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md)
