---
tags: [jcu, module3, linux]
jqr: "Configure an rsyslog client to forward logs (@@ TCP / @ UDP) and a server to receive them (imtcp/imudp); restart, verify end-to-end, and explain the use case"
---

# rsyslog Remote Logging

Ship a host's logs to a central collector so they survive even if the box itself is wiped. Two roles: the **client sends**, the **server receives**. This is a blue-team backbone (tamper-evidence + one place to correlate the whole fleet) and a standard Module 3 task.

## TL;DR
```text
@@host:514   = TCP (two @ = reliable, does a handshake)     # client-side forwarding
@host:514    = UDP (one @ = fire-and-forget, can drop lines)
module(load="imtcp") input(type="imtcp" port="514")         # server-side listener (TCP)
sudo rsyslogd -N1                                            # syntax-check config FIRST
sudo systemctl restart rsyslog                              # apply after EVERY change
sudo ss -tulnp | grep 514                                   # confirm the listener is up
logger "test message"                                       # inject a test log line
```
Config lives in `/etc/rsyslog.conf` or a drop-in under `/etc/rsyslog.d/*.conf`. Collector in the examples below: `192.168.1.10`.

## Concept
- **syslog** is the classic Linux logging protocol (every message carries a *facility* + *severity*). **rsyslog** is the modern daemon that implements it and can route messages to files, the journal, or **over the network**.
- **Client → Server** over **TCP 514** (reliable, recommended) or **UDP 514** (lighter, but lossy).
- Central logging means an attacker who roots a box and wipes `/var/log` **can't erase the copy already on the server** — that's the whole defensive point, and the feed a SIEM consumes.
- Mnemonic that wins marks: **`@@` = TCP, `@` = UDP** (two @'s = the "stronger"/reliable one).

## Server — receive logs (open the listener)
Enable an input module: **`imtcp`** (TCP listener) and/or **`imudp`** (UDP listener). TCP is reliable; UDP is lighter but can drop lines.

> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. (Needs a second host acting as collector + root.)

```text
# /etc/rsyslog.d/10-remote-server.conf   (modern module syntax)
module(load="imtcp")
input(type="imtcp" port="514")

# optional UDP too:
module(load="imudp")
input(type="imudp" port="514")

# optional: file each client's logs separately instead of mixing them together:
template(name="RemoteLogs" type="string" string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
*.* ?RemoteLogs
& stop
```
```bash
sudo systemctl restart rsyslog       # apply the config
sudo ss -tulnp | grep 514            # expect rsyslogd on tcp/udp 514
```
→ The template files each client's logs under `/var/log/remote/<host>/`; `& stop` ends processing for those remote lines so they don't *also* get written into the server's own local logs.

Open the firewall for it (ties to [iptables](../IP%20Tables%20CentOS/iptables.md)):
```bash
sudo iptables -A INPUT -p tcp --dport 514 -j ACCEPT     # TCP collector
sudo iptables -A INPUT -p udp --dport 514 -j ACCEPT     # if using UDP
```

> ✅ **Tested output** (Ubuntu 24.04, 2026): `ss -tulnp` listing listening TCP/UDP sockets and the owning process — the exact command you use to confirm the collector is bound. (Here it shows the sandbox's own services; on your log server you'd look for `rsyslogd` on `:514`.)
```
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
tcp   LISTEN 0      128          0.0.0.0:2025       0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2024       0.0.0.0:*
tcp   LISTEN 0      512        127.0.0.1:42569      0.0.0.0:*    users:(("claude",pid=461,fd=13))
tcp   LISTEN 0      4096       127.0.0.1:34007      0.0.0.0:*    users:(("environment-man",pid=473,fd=13))
tcp   LISTEN 0      5            0.0.0.0:8080       0.0.0.0:*    users:(("python3",pid=12539,fd=3))
```
→ Read it left to right: proto, state, queues, **Local Address:Port** (`0.0.0.0:*` = bound on all interfaces), then the owning **process**. For rsyslog you want a `:514` line owned by `rsyslogd`; if it's absent, the listener didn't load — recheck the `module(load=...)` lines and restart.

## Client — forward logs to the server
`@@` = TCP, `@` = UDP. Drop it in a client-side config file.
```text
# /etc/rsyslog.d/90-forward.conf
*.* @@192.168.1.10:514           # send EVERYTHING to the collector over TCP (recommended)
# *.* @192.168.1.10:514          # UDP alternative (fire-and-forget, lossy)
# authpriv.*  @@192.168.1.10:514 # only the auth/security facility, over TCP
```
```bash
sudo rsyslogd -N1                 # syntax-check BEFORE restarting
sudo systemctl restart rsyslog    # apply
```
→ `*.*` = all facilities, all severities. Narrow it (e.g. `authpriv.*` for just auth/sudo/SSH events) to ship only what you care about.
> **Reading `facility.severity`:** every syslog message is stamped at birth with a *facility* (who emitted it — `auth`, `authpriv`, `cron`, `kern`, `mail`…) and a *severity* (`debug`→`emerg`). That stamp is the only thing the selector matches on, so a forwarding rule is literally "which stamps do I ship, and where": `*.*` = every stamp, `authpriv.*` = the security facility at any severity. It's the same grammar rsyslog uses to sort messages into the `/var/log/*` files locally — you're just pointing the destination at a network host instead of a file.

## Verify end-to-end
```bash
# on the CLIENT — inject a test line:
logger "test-from-client rsyslog check $(hostname)"

# on the SERVER — watch it arrive:
sudo tail -f /var/log/remote/*/*.log     # per-host template output
sudo journalctl -u rsyslog -f            # rsyslog service health — see [Logs and journalctl](Logs%20and%20journalctl.md)
sudo tcpdump -ni any 'port 514'          # confirm packets on the wire — see [Tcpdump](../Recon%20Tools/Tcpdump.md)
```
→ Your `test-from-client` string appearing **on the server** = the pipeline works. `logger` is the standard way to hand-craft a syslog message for testing.

## Use case (why the JQR cares)
Central logging is the feed for a SIEM and the first thing that makes an intrusion *reconstructable*: logs already shipped off-host can't be edited by whoever owns the box now, so you keep evidence even after `/var/log` is tampered with. It also collapses "grep 40 servers" into "grep one." Pair it with disciplined firewalling ([iptables](../IP%20Tables%20CentOS/iptables.md) on port 514) so only your own hosts can write to the collector.

## Exam tips & gotchas
- **`@@` = TCP, `@` = UDP** — swapping them is the classic trip-up. Two @'s = the reliable one.
- **Restart after every change** — `sudo systemctl restart rsyslog`; syntax-check first with `rsyslogd -N1`.
- **Server not receiving? Check in this order:** (1) listener up — `ss -tulnp | grep 514`; (2) firewall allows 514 — [iptables](../IP%20Tables%20CentOS/iptables.md); (3) on CentOS, SELinux may block the port — `sudo semanage port -a -t syslogd_port_t -p tcp 514`.
- **Port 514** is the default for both TCP and UDP; if you change it, change it on **both** ends.
- **Prefer TCP (`@@`)** for security logging — UDP silently loses messages under load.
- **`& stop`** on the server keeps remote logs out of the server's own local files.

## References
- rsyslog documentation — https://www.rsyslog.com/doc/
- `imtcp` (TCP input module) — https://www.rsyslog.com/doc/configuration/modules/imtcp.html
- `imudp` (UDP input module) — https://www.rsyslog.com/doc/configuration/modules/imudp.html
- `omfwd` (forwarding output module) — https://www.rsyslog.com/doc/configuration/modules/omfwd.html
- `logger`(1) — https://man7.org/linux/man-pages/man1/logger.1.html

## Related
- [Logs and journalctl](Logs%20and%20journalctl.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Tcpdump](../Recon%20Tools/Tcpdump.md)
