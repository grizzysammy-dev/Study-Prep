---
tags: [cyber, module3, recon, networking]
jqr: "Secure remote admin over SSH: connect (non-standard port, IPv6), agent forwarding, ProxyJump/jump hosts, and -L/-R/-D port forwarding"
---

# SSH - Tunneling and Jump Hosts

The OpenSSH client (`ssh`) is really one connection doing two jobs: an **encrypted shell** on a remote box, and an **encrypted pipe** I can shove other traffic through (port forwarding, SOCKS, multi-hop). This note is my exam-ready reference for both.

## The connections I reach for

```bash
ssh sam@192.168.1.20                        # basic encrypted shell
ssh -p 2222 sam@192.168.1.20                # non-standard port (lowercase -p!)
ssh -J sam@10.10.10.5 sam@172.16.5.20       # jump through bastion, one-off
ssh -L 8080:172.16.5.30:80 sam@10.10.10.5   # local listen  -> reach a remote svc
ssh -R 3000:localhost:3000 sam@10.10.10.5   # remote listen -> expose a local svc
ssh -D 1080 sam@10.10.10.5                  # dynamic SOCKS5 proxy on :1080
ssh -A sam@10.10.10.5                       # forward agent (trusted hosts only)
```

- `-p` is lowercase for ssh, while [SCP](SCP.md) uses uppercase `-P`. Opposite cases, same job.
- `-L` means Local listens (traffic exits the *remote* side); `-R` means Remote listens (traffic exits *your* side). Mirror images, and the classic trap.
- `-D` is a SOCKS5 proxy; pair it with `proxychains4` to push arbitrary TCP tools through.
- **ProxyJump** (`-J` / `~/.ssh/config`) is the clean way to reach a box behind a bastion.
- Verify config resolution **before** I dial out with `ssh -G <host>`.

## The two ideas that make it click

SSH encrypts the whole session, so `ssh`, [SCP](SCP.md), and every tunnel ride one authenticated, encrypted channel, unlike cleartext tools like [Netcat](../Recon%20Tools/Netcat.md). I picture the connection as a sealed tube already strung between me and the server. A forward stuffs a *second* stream of traffic into that tube, and at the far end **sshd acts as my proxy**: it opens a fresh, ordinary TCP connection to the real destination *on my behalf*, so the destination sees the traffic arriving **from the SSH server**, not from me. That one fact explains everything below.

Two ideas cover the rest:

- Port forwarding is just "poke a hole through the SSH pipe." The only thing I have to get right is **which end opens the listening socket**. The tube is already strung, so a forward just decides *whose wall gets the mail slot*. `-L` puts the slot on **my** wall (I drop traffic in, it emerges at the server's end); `-R` puts it on the **server's** wall (traffic dropped in there travels back to me). Delivery always happens at the *opposite* end from the slot.
- Multi-hop: when I can't reach a target directly, I bounce through an intermediate host (the **bastion**). SSH does this with **ProxyJump**, and the real key handshake happens **end-to-end** with the final target while the bastion only relays bytes (it never sees my credentials).

Config precedence: command-line flags **override** `~/.ssh/config` which **overrides** `/etc/ssh/ssh_config`. I prefer `ed25519` keys over passwords in the lab.

## Connect

```bash
ssh sam@192.168.1.20
```
Opens an interactive encrypted shell on hostB as `sam`. The first connect shows a host-key fingerprint (TOFU, trust-on-first-use) and pins it in `~/.ssh/known_hosts`. A later "REMOTE HOST IDENTIFICATION HAS CHANGED" means either a rebuild or a real MITM, so I don't blindly delete the line.

```bash
ssh -p 2222 sam@192.168.1.20
```
Connects to `sshd` on TCP **2222**. The port flag is **lowercase `-p`** for `ssh`.

```bash
ssh sam@2001:db8::20            # global / ULA IPv6 address
ssh -6 sam@hostb.lab           # force the IPv6 family even if a hostname has an A record
ssh sam@fe80::20%eth0          # link-local MUST carry the %interface zone
```
Connects over IPv6. Link-local `fe80::/10` isn't globally unique, so the `%eth0` **zone index** (which interface the address lives on) is mandatory. On the command line a bare IPv6 needs **no brackets** for `ssh` (the port is a separate `-p` flag); brackets are only for `:port` URIs and for [SCP](SCP.md) targets. Forget the `%interface` on a link-local and I get "Invalid argument" or "no route to host."

## Agent forwarding (`-A` / `ForwardAgent`)

`ssh-agent` holds my decrypted private keys in memory so I type the passphrase once. **Agent forwarding** lets a *remote* host I'm logged into use *my local* agent to authenticate onward, without ever copying the private key onto that host.

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
This exposes a forwarded agent socket on the remote host, so an onward `ssh` from there uses *my* keys, still held on *my* machine.
- Caution: root on that host, or anyone who compromises it while I'm connected, can talk to my forwarded agent socket (`$SSH_AUTH_SOCK`) and impersonate me to any host my keys unlock, **for the whole life of the session**. They can't steal the key, but they can *use* it live.
- I prefer ProxyJump for plain multi-hop since the bastion never sees my agent at all. I only reach for `-A` when I genuinely need a *new* auth from the middle host (e.g. `git pull` on the bastion). Never set `ForwardAgent yes` globally (`Host *`).

## Jump hosts / ProxyJump

I can't reach `172.16.5.20` directly; it lives on the management subnet behind the bastion. SSH bounces me through.

### One-off on the command line: `-J`

```bash
ssh -J sam@10.10.10.5 sam@172.16.5.20                    # single jump
ssh -J sam@10.10.10.5,sam@172.16.5.99 sam@172.16.5.20    # chained, left-to-right
ssh -J sam@10.10.10.5:2222 sam@172.16.5.20               # jump host on a non-standard port
```
This transparently opens a TCP tunnel *through* the bastion and runs the real SSH handshake **end-to-end** with the target. My credentials are verified by the final host, not the bastion. The target only has to be reachable **from the bastion**, and nothing beyond a working `ssh`/`sshd` is needed on the bastion itself.

### Persistent, in `~/.ssh/config` (mode 600)

This is my exam-ready reference config: at least two `Host` blocks, one reaching an internal host by jumping the bastion.

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
`ProxyJump bastion` establishes the connection to `mgmt-box` *through* the `bastion` block, and because it references the alias, all of the bastion's settings (user, port, key) get reused with no duplication. `ProxyJump` is the modern directive; the old `ProxyCommand ssh -W %h:%p bastion` does the same thing and shows up in older notes, but I stick with `ProxyJump`. Keep `~/.ssh/config` at `600` or SSH may refuse it.

I can confirm SSH parsed the jump **without connecting** by using `ssh -G`, which dumps the effective, fully-resolved config:

Made a `~/.ssh/config` with ProxyJump and read it back with `ssh -G` (Ubuntu 24.04):
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
`ssh -G <host>` prints the settings SSH *would* use. Here it confirms `internal-web` resolves `proxyjump bastion` plus the right hostname and user, so the jump is wired correctly before I ever connect. (The internal host in this capture is `172.16.0.20`; in this vault's scheme that role is `172.16.5.20`, same idea, different last octet.)

And here's an end-to-end key-auth login on a **non-standard port** actually working, plus a file copied right after with `scp -P`:

Real `ssh` and `scp` to a local `sshd` on port 2222, key auth (Ubuntu 24.04):
```
$ ssh -o StrictHostKeyChecking=no -p 2222 root@127.0.0.1 'hostname; id -un; uname -r'
vm
root
6.18.5-fc-v20
$ scp -P 2222 /tmp/xfer.txt root@127.0.0.1:/tmp/xfer_copy.txt   (note capital -P)
copied OK -> hello-from-scp 04:03:46
```
The three lines right after the `ssh` command are the remote host's `hostname`, `id -un`, and `uname -r` (a one-shot remote command over `ssh -p 2222`). Then the same box gets used with `scp -P 2222`. Note the **case flip on one host**: `ssh -p` vs `scp -P`.

## Port forwarding, reaching internal services

Same mental model everywhere: **which end opens the listening port?**

### Local `-L`, *my* end listens

Syntax: `-L [bind_addr:]LOCAL_PORT:TARGET_HOST:TARGET_PORT`
```bash
ssh -L 8080:172.16.5.30:80 sam@10.10.10.5
# then browse http://localhost:8080 on your laptop
```
Opens a listener on **my** box at `localhost:8080`, and anything I send there is pushed through the pipe to the bastion, which opens a fresh connection to `172.16.5.30:80` and relays. `TARGET_HOST` is resolved **from the SSH server's side**, so it only needs to be reachable by the bastion, not by me.
- By default the local listener binds `127.0.0.1` only (good). To let other machines on my LAN use the forward, I prefix `0.0.0.0:` (e.g. `-L 0.0.0.0:8080:...`) or set `GatewayPorts`, but deliberately, because it exposes the tunnel.
- `localhost` in the *target* position means "localhost as the bastion sees it," which is the bastion itself.

### Remote `-R`, the *remote* end listens

Syntax: `-R [bind_addr:]REMOTE_PORT:TARGET_HOST:TARGET_PORT`
```bash
# run FROM hostA to publish hostA's 127.0.0.1:3000 onto the bastion
ssh -R 3000:localhost:3000 sam@10.10.10.5
# now on the bastion:  curl http://localhost:3000   hits hostA's service
```
Opens a listener on the **bastion** at `localhost:3000`, and connections the bastion makes there get pushed back through the pipe to hostA, which relays to its own `127.0.0.1:3000`. The listening socket is on the *remote* end, but traffic emerges on *my* end. **Remote listens, traffic flows back toward me.** It's the mirror of `-L`, and the classic exam trap.

Why I'd reach for `-R`, and the blue-side view: it's the escape hatch for a host I can't dial *into*. The box reaches *out* and hands one of its local services back to me over that outbound session. That's the classic pivot/exfil primitive, same shape as a reverse shell, and on the defender's side the tell is an *outbound* SSH connection from a server that has no business initiating one.
- Binds the bastion's **loopback only** by default. To let other management hosts connect I need **both** a wide bind (`-R 0.0.0.0:3000:localhost:3000`) **and** `GatewayPorts yes` (or `clientspecified`) in the bastion's `/etc/ssh/sshd_config`, then `systemctl reload ssh`. Without `GatewayPorts` the wide bind gets silently clamped back to loopback.

### Dynamic `-D`, a SOCKS proxy

Syntax: `-D [bind_addr:]LOCAL_PORT`
```bash
ssh -D 1080 sam@10.10.10.5
```
Opens a **SOCKS5** proxy on my laptop at `localhost:1080`. Unlike `-L`, I don't hard-code one destination. Each app hands the proxy a *(host, port)* and the bastion opens that connection on its side. One tunnel, arbitrary internal destinations.

Why `-D` is the pivot workhorse: SOCKS is just a tiny "dial *this* (host, port) for me, whatever it is" protocol. Where `-L` is one fixed pipe to one service, `-D` turns the bastion into a general-purpose exit node onto the internal network, so I can map the subnet and reach any host/port through the single SSH session. That's why it pairs with `proxychains`: point un-proxy-aware tools at the one SOCKS port and they all ride the tunnel.

Pair it with **proxychains** (official repo: `sudo apt install proxychains4`). Ensure the last line of `/etc/proxychains4.conf` reads:
```
socks5  127.0.0.1  1080
```
then prefix commands:
```bash
proxychains4 curl http://172.16.5.30/       # internal web console via the bastion
proxychains4 ssh sam@172.16.5.20            # onward SSH through the SOCKS tunnel
```
`proxychains` intercepts each app's network calls (via `LD_PRELOAD`) and routes them through the SOCKS proxy, so tools with no proxy setting of their own still traverse the tunnel.
- SOCKS carries TCP cleanly, but raw ICMP (`ping`) and most UDP do **not** traverse a standard `-D` proxy. Use `proxychains4` with TCP tools, not `ping`.
- Set `proxy_dns` in `proxychains4.conf` to resolve names *through* the tunnel and avoid leaking DNS lookups from my laptop.

### Handy modifiers

```bash
ssh -fN -L 8080:172.16.5.30:80 sam@10.10.10.5
```
`-N` runs **no** remote command (just holds the tunnel) and `-f` drops it to the background after auth. Great for "set it and forget it." I add `ExitOnForwardFailure yes` so SSH fails loudly if the port is already taken instead of silently connecting with no forward. A `-fN` tunnel has no shell to close, so I kill it by PID (`pgrep -af 'ssh -fN'`).

## The slips that get me

- `ssh -p` (lowercase) vs `scp -P` (uppercase) for the port: opposite cases, same job. My single most common slip.
- `-L` Local listens (traffic exits remote); `-R` Remote listens (traffic exits local). I say it out loud before I type.
- `-R` to a non-loopback address needs `GatewayPorts yes` (or `clientspecified`) **and** a `0.0.0.0:` bind; either one alone isn't enough.
- IPv6 link-local always needs `%interface` (`fe80::20%eth0`); bare `ssh` needs no brackets, but [SCP](SCP.md) does.
- ProxyJump beats agent forwarding for plain multi-hop; `-A` only to hosts I fully trust and control.
- `-D` SOCKS is TCP-only, so don't try to `ping` through it; use `proxychains4` with TCP tools.
- Routing a whole subnet across a tunnel (not just one service) needs `net.ipv4.ip_forward=1` on the forwarding box, see [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md).
- Use `ssh -G <host>` to verify config resolution (including ProxyJump) *before* I connect.

## References

- `ssh(1)` and `ssh_config(5)` man pages: https://man.openbsd.org/ssh · https://man.openbsd.org/ssh_config
- SSH jump host / ProxyJump: https://wiki.gentoo.org/wiki/SSH_jump_host · https://www.ssh.com/academy/ssh/tunneling
- proxychains-ng (official): https://github.com/rofl0r/proxychains-ng

## Related

- [SCP](SCP.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- [Chisel](Chisel.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
