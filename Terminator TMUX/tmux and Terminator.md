---
tags: [cyber, module1, linux, terminal]
jqr: "Module 1: pick Terminator or tmux and use it proficiently every session"
---

# tmux and Terminator

Both let me split one terminal into many and keep work organized. The JQR says to **pick one and make it your default**. I went with **tmux** because it works over SSH and survives disconnects, which matters the moment I'm on a remote box. Terminator is the friendlier GUI option if I stay local.

> The way I think about it: tmux is a terminal multiplexer. It runs my shells inside a long-lived session on the machine, and my keyboard and screen just "attach" to it as a viewport. The shells are parented to the tmux server, not to my SSH connection, which is exactly why they keep running when SSH drops. Picture leaving all my programs open on a desktop and just unplugging the monitor; `tmux attach` plugs the monitor back in and nothing missed a beat.

## Why it matters
In a real task I'll want nmap running in one pane, a listener in another, and notes in a third. And on a remote box, **tmux keeps the session alive if SSH drops**, so I reconnect and everything's still running.

## tmux (recommended)
Everything starts with the **prefix**: `Ctrl-b`, release, then a key.

> Why a prefix key? tmux lives inside my terminal, wrapping programs that already use plenty of Ctrl-shortcuts of their own. The prefix (`Ctrl-b`) is a "the next keystroke is for tmux, not the app" signal, so it stops tmux from stealing keys out from under vim, my shell, or whatever's running in the pane.

```bash
tmux                 # start a session
tmux new -s lab      # start a NAMED session 'lab'
tmux ls              # list sessions
tmux attach -t lab   # re-attach to 'lab'
```

| Do this | Keys (prefix = `Ctrl-b`) |
|---|---|
| Split **left/right** | `Ctrl-b %` |
| Split **top/bottom** | `Ctrl-b "` |
| Move between panes | `Ctrl-b` then arrow key |
| New window (tab) | `Ctrl-b c` |
| Next / previous window | `Ctrl-b n` / `Ctrl-b p` |
| **Detach** (leave it running) | `Ctrl-b d` |
| Rename window | `Ctrl-b ,` |
| Close pane | `exit` or `Ctrl-d` |

The killer move: `Ctrl-b d` to **detach** on a remote host, log off, come back later, `tmux attach`, and my scans are still running. (`screen` is the older equivalent if tmux isn't installed.)

## Terminator (GUI alternative)
A graphical terminal that tiles panes in one window. Good when I'm working locally on the Kali/Ubuntu desktop.

| Do this | Keys |
|---|---|
| Split **vertical** | `Ctrl-Shift-E` |
| Split **horizontal** | `Ctrl-Shift-O` |
| Move between panes | `Ctrl-Shift-` arrow (or click) |
| Close pane | `Ctrl-Shift-W` |
| New tab | `Ctrl-Shift-T` |
| Toggle a pane fullscreen | `Ctrl-Shift-X` (zoom) |

Install with `sudo apt install terminator`. It has no remote-persistence like tmux, it's about layout, not survival.

## What I keep reminding myself
- **tmux for anything remote** (survives SSH drops); Terminator for local convenience. But pick ONE and use it always, like the JQR says.
- The thing tmux beginners forget is the **prefix**: every tmux shortcut is `Ctrl-b` then the key, not held together.
- Detached tmux sessions keep using RAM/CPU, so `tmux ls` and kill stale ones (`tmux kill-session -t name`).
- Pair tmux with an [SSH](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) session for long-running scans on a jump host.

## References
- tmux wiki (JQR-named): https://github.com/tmux/tmux/wiki
- tmux intro (JQR-named): https://www.redhat.com/sysadmin/introduction-tmux-linux
- Terminator docs (JQR-named): https://terminator-gtk3.readthedocs.io/en/latest/

## Related
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md)
- [Vim](../Vim/Vim.md)
