---
tags: [jcu, module3, recon, networking]
jqr: "Secure remote administration over SSH — connect (non-standard port, IPv6), agent forwarding, ProxyJump/jump hosts, and -L/-R/-D port forwarding"
---

# SSH - Tunneling and Jump Hosts

The OpenSSH client (`ssh`) is one connection doing two jobs: an **encrypted shell** on a remote box, and an **encrypted pipe** you can push other traffic through (port forwarding, SOCKS, multi-hop). This note is the exam-ready reference for both.

## TL;DR

```bash
ssh sam@192.168.1.20                        # basic encrypted shell
ssh -p 2222 sam@192.168.1.20                # non-standard port (lowercase -p!)
ssh -J sam@10.10.10.5 sam@172.16.5.20       # jump through bastion, one-off
ssh -L 8080:172.16.5.30:80 sam@10.10.10.5   # local listen  -> reach a remote svc
ssh -R 3000:localhost:3000 sam@10.10.10.5   # remote listen -> expose a local svc
ssh -D 1080 sam@10.10.10.5                  # dynamic SOCKS5 proxy on :1080
ssh -A sam@10.10.10.5                       # forward agent (trusted hosts only)
```

- **`-p` is lowercase for ssh** — [SCP](SCP.md) uses uppercase `-P`. Opposite cases, same job.
- **`-L` = Local listens** (traffic exits the *remote* side); **`-R` = Remote listens** (traffic exits *your* side). Mirror images — the classic trap.
- **`-D` = SOCKS5**; pair with `proxychains4` to push arbitrary TCP tools through.
- **ProxyJump** (`-J` / `~/.ssh/config`) is the clean way to reach a box behind a bastion.
- Verify config resolution **before** you dial out with **`ssh -G <host>`**.

## Concept

SSH encrypts the whole session, so `ssh`, [SCP](SCP.md), and every tunnel ride one authenticated, encrypted channel — unlike cleartext tools like [Netcat](Netcat.md). Two ideas cover everything below:

- **Port forwarding = "poke a hole through the SSH pipe."** The only thing you must get right is **which end opens the listening socket**; everything else follows from that.
- **Multi-hop:** when you can't reach a target directly, you bounce through an intermediate host (the **bastion**). SSH does this with **ProxyJump** — the real key handshake happens **end-to-end** with the final target, and the bastion only relays bytes (it never sees your credentials).

Config precedence: command-line flags **override** `~/.ssh/config` **override** `/etc/ssh/ssh_config`. Prefer `ed25519` keys over passwords in the lab.

## Connect

```bash
ssh sam@192.168.1.20
```
→ Opens an interactive encrypted shell on hostB as `sam`. First connect shows a host-key fingerprint (TOFU — trust-on-first-use) and pins it in `~/.ssh/known_hosts`. A later "REMOTE HOST IDENTIFICATION HAS CHANGED" means a rebuild **or** a real MITM — don't blindly delete the line.

```bash
ssh -p 2222 sam@192.168.1.20
```
→ Connects to `sshd` on TCP **2222**. Port flag is **lowercase `-p`** for `ssh`.

```bash
ssh sam@2001:db8::20            # global / ULA IPv6 address
ssh -6 sam@hostb.lab           # force the IPv6 family even if a hostname has an A record
ssh sam@fe80::20%eth0          # link-local MUST carry the %interface zone
```
→ Connects over IPv6. Link-local `fe80::/10` isn't globally unique, so the `%eth0` **zone index** (which interface the address lives on) is mandatory. On the *command line* a bare IPv6 needs **no brackets** for `ssh` (the port is a separate `-p` flag) — brackets are only for `:port` URIs and for [SCP](SCP.md) targets. Forget the `%interface` on a link-local and you get "Invalid argument" / "no route to host."

## Agent forwarding (`-A` / `ForwardAgent`)

`ssh-agent` holds your decrypted private keys in memory so you type the passphrase once. **Agent forwarding** lets a *remote* host you're logged into use *your local* agent to authenticate onward — without ever copying the private key onto that host.

```bash
eval "$(ssh-agent -s)"          # start an agent (once per login session)
ssh-add ~/.ssh/id_ed25519       # load a key
ssh -A sam@10.10.10.5           # forward the agent to the bastion
```
Per-host in `~/.ssh/config`:
```sshconfig
Host bastion
    ForwardAgent yes
```
→ Exposes a forwarded agent socket on the remote host; onward `ssh` from there uses *your* keys, held on *your* machine.
- **Caution:** root on that host — or anyone who compromises it while you're connected — can talk to your forwarded agent socket (`$SSH_AUTH_SOCK`) and impersonate you to any host your keys unlock, **for the life of the session**. They can't steal the key, but they can *use* it live.
- **Prefer ProxyJump** for plain multi-hop — the bastion never sees your agent at all. Reach for `-A` only when you genuinely need a *new* auth from the middle host (e.g. `git pull` on the bastion). Never set `ForwardAgent yes` globally (`Host *`).

## Jump hosts / ProxyJump

You can't reach `172.16.5.20` directly — it lives on the management subnet behind the bastion. SSH bounces you through.

### One-off on the command line: `-J`

```bash
ssh -J sam@10.10.10.5 sam@172.16.5.20                    # single jump
ssh -J sam@10.10.10.5,sam@172.16.5.99 sam@172.16.5.20    # chained, left-to-right
ssh -J sam@10.10.10.5:2222 sam@172.16.5.20               # jump host on a non-standard port
```
→ Transparently opens a TCP tunnel *through* the bastion and runs the real SSH handshake **end-to-end** with the target. Your credentials are verified by the final host, not the bastion. The target must be reachable **from the bastion**; nothing beyond a working `ssh`/`sshd` is needed on the bastion.

### Persistent, in `~/.ssh/config` (mode 600)

This is the exam-ready reference config — at least two `Host` blocks, one reaching an internal host by jumping the bastion:

```sshconfig
# ~/.ssh/config      (chmod 600 ~/.ssh/config)

# ---- the bastion / jump host itself (reached directly) ----
Host bastion
    HostName      10.10.10.5
    User          sam
    Port          22
    IdentityFile  ~/.ssh/id_ed25519

# ---- an internal box reached ONLY by ProxyJumping the bastion ----
Host mgmt-box
    HostName      172.16.5.20
    User          sam
    IdentityFile  ~/.ssh/id_ed25519
    ProxyJump     bastion          # reuses the bastion block by its alias

# ---- the internal web-admin panel, same jump ----
Host webadmin
    HostName      172.16.5.30
    User          admin
    IdentityFile  ~/.ssh/id_ed25519
    ProxyJump     bastion
```
Now the multi-hop is invisible:
```bash
ssh mgmt-box                       # laptop -> bastion -> 172.16.5.20, one command
scp report.txt webadmin:/tmp/      # scp inherits ProxyJump automatically
```
→ `ProxyJump bastion` establishes the connection to `mgmt-box` *through* the `bastion` block; because it references the alias, all of the bastion's settings (user, port, key) are reused — no duplication. `ProxyJump` is the modern directive; the old `ProxyCommand ssh -W %h:%p bastion` does the same and you'll see it in older notes — prefer `ProxyJump`. Keep `~/.ssh/config` at `600` or SSH may refuse it.

You can confirm SSH parsed the jump **without connecting** using `ssh -G`, which dumps the effective, fully-resolved config:

> ✅ **Tested output** (Ubuntu 24.04, 2026) — a `~/.ssh/config` with ProxyJump, read back with `ssh -G`:
```
$ cat ~/.ssh/config
Host bastion
    HostName 10.10.10.5
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519

Host internal-web
    HostName 172.16.0.20
    User sam
    ProxyJump bastion
    IdentityFile ~/.ssh/id_ed25519

$ ssh -G internal-web | grep -Ei 'proxyjump|hostname|user |port '
user sam
hostname 172.16.0.20
port 22
proxyjump bastion
```
`ssh -G <host>` prints the settings SSH *would* use — here it confirms `internal-web` resolves `proxyjump bastion` plus the right hostname/user, so the jump is wired correctly before you ever connect. (This capture's internal host is `172.16.0.20`; in this vault's scheme that role is `172.16.5.20` — same idea, different last octet.)

And here is an end-to-end key-auth login on a **non-standard port** actually working — plus a file copied straight after with `scp -P`:

> ✅ **Tested output** (Ubuntu 24.04, 2026) — real `ssh` + `scp` to a local `sshd` on port 2222 (key auth):
```
$ ssh -o StrictHostKeyChecking=no -p 2222 root@127.0.0.1 'hostname; id -un; uname -r'
vm
root
6.18.5-fc-v20
$ scp -P 2222 /tmp/xfer.txt root@127.0.0.1:/tmp/xfer_copy.txt   (note capital -P)
copied OK -> hello-from-scp 04:03:46
```
The three lines after the `ssh` command are the remote host's `hostname` / `id -un` / `uname -r` (a one-shot remote command over `ssh -p 2222`). Then the same box is used with `scp -P 2222`. Note the **case flip on one host**: `ssh -p` vs `scp -P`.

## Port forwarding — reaching internal services

Same mental model everywhere: **which end opens the listening port?**

### Local `-L` — *your* end listens

Syntax: `-L [bind_addr:]LOCAL_PORT:TARGET_HOST:TARGET_PORT`
```bash
ssh -L 8080:172.16.5.30:80 sam@10.10.10.5
# then browse http://localhost:8080 on your laptop
```
→ Opens a listener on **your** box at `localhost:8080`; anything you send there is pushed through the pipe to the bastion, which opens a fresh connection to `172.16.5.30:80` and relays. `TARGET_HOST` is resolved **from the SSH server's side**, so it only needs to be reachable by the bastion, not by you.
- By default the local listener binds `127.0.0.1` only (good). To let other machines on your LAN use the forward, prefix `0.0.0.0:` (e.g. `-L 0.0.0.0:8080:...`) or set `GatewayPorts` — do it deliberately, it exposes the tunnel.
- `localhost` in the *target* position means "localhost as the bastion sees it" — i.e. the bastion itself.

### Remote `-R` — the *remote* end listens

Syntax: `-R [bind_addr:]REMOTE_PORT:TARGET_HOST:TARGET_PORT`
```bash
# run FROM hostA to publish hostA's 127.0.0.1:3000 onto the bastion
ssh -R 3000:localhost:3000 sam@10.10.10.5
# now on the bastion:  curl http://localhost:3000   hits hostA's service
```
→ Opens a listener on the **bastion** at `localhost:3000`; connections the bastion makes there are pushed back through the pipe to hostA, which relays to its own `127.0.0.1:3000`. The listening socket is on the *remote* end; traffic emerges on *your* end. **Remote listens, traffic flows back toward you** — the mirror of `-L`, and the classic exam trap.
- Binds the bastion's **loopback only** by default. To let other management hosts connect you need **both** a wide bind (`-R 0.0.0.0:3000:localhost:3000`) **and** `GatewayPorts yes` (or `clientspecified`) in the bastion's `/etc/ssh/sshd_config`, then `systemctl reload ssh`. Without `GatewayPorts` the wide bind is silently clamped back to loopback.

### Dynamic `-D` — a SOCKS proxy

Syntax: `-D [bind_addr:]LOCAL_PORT`
```bash
ssh -D 1080 sam@10.10.10.5
```
→ Opens a **SOCKS5** proxy on your laptop at `localhost:1080`. Unlike `-L`, you don't hard-code one destination — each app hands the proxy a *(host, port)* and the bastion opens that connection on its side. One tunnel, arbitrary internal destinations.

Pair it with **proxychains** (official repo: `sudo apt install proxychains4`). Ensure the last line of `/etc/proxychains4.conf` reads:
```
socks5  127.0.0.1  1080
```
then prefix commands:
```bash
proxychains4 curl http://172.16.5.30/       # internal web console via the bastion
proxychains4 ssh sam@172.16.5.20            # onward SSH through the SOCKS tunnel
```
→ `proxychains` intercepts each app's network calls (via `LD_PRELOAD`) and routes them through the SOCKS proxy, so tools with no proxy setting of their own still traverse the tunnel.
- **SOCKS carries TCP cleanly; raw ICMP (`ping`) and most UDP do NOT** traverse a standard `-D` proxy. Use `proxychains4` with TCP tools, not `ping`.
- Set `proxy_dns` in `proxychains4.conf` to resolve names *through* the tunnel and avoid leaking DNS lookups from your laptop.

### Handy modifiers

```bash
ssh -fN -L 8080:172.16.5.30:80 sam@10.10.10.5
```
→ `-N` = run **no** remote command (just hold the tunnel); `-f` = drop to background after auth. Great for "set it and forget it." Add `ExitOnForwardFailure yes` so SSH fails loudly if the port is already taken instead of silently connecting with no forward. A `-fN` tunnel has no shell to close — kill it by PID (`pgrep -af 'ssh -fN'`).

## Exam tips & gotchas

- **`ssh -p` (lowercase) vs `scp -P` (uppercase)** for port — opposite cases, same job. The single most common slip.
- **`-L` Local listens** (traffic exits remote); **`-R` Remote listens** (traffic exits local). Say it out loud before you type.
- **`-R` to a non-loopback address** needs `GatewayPorts yes` (or `clientspecified`) **and** a `0.0.0.0:` bind — either alone isn't enough.
- **IPv6 link-local always needs `%interface`** (`fe80::20%eth0`); bare `ssh` needs no brackets, [SCP](SCP.md) does.
- **ProxyJump > agent forwarding** for plain multi-hop; `-A` only to hosts you fully trust and control.
- **`-D` SOCKS is TCP-only** — don't try to `ping` through it; use `proxychains4` with TCP tools.
- **Routing a whole subnet** across a tunnel (not just one service) needs `net.ipv4.ip_forward=1` on the forwarding box — see [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md).
- Use **`ssh -G <host>`** to verify config resolution (including ProxyJump) *before* you connect.

## References

- `ssh(1)` and `ssh_config(5)` man pages — https://man.openbsd.org/ssh · https://man.openbsd.org/ssh_config
- SSH jump host / ProxyJump — https://wiki.gentoo.org/wiki/SSH_jump_host · https://www.ssh.com/academy/ssh/tunneling
- proxychains-ng (official) — https://github.com/rofl0r/proxychains-ng

## Related

- [SCP](SCP.md)
- [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
- [Chisel](Chisel.md)
- [iptables](../03%20-%20Linux%20Skills/iptables.md)
- [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md)
