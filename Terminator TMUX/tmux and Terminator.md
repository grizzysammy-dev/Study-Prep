---
tags: [jcu, module1, linux, terminal]
jqr: "Module 1 — pick Terminator or tmux and use it proficiently every session"
---

# tmux and Terminator

Both let you split one terminal into many and keep work organized. The JQR says **pick one and make it your default**. My recommendation: **tmux** — it works over SSH and survives disconnects, which matters the moment you're on a remote box. Terminator is the friendlier GUI option if you stay local.

> **The mental model:** tmux is a *terminal multiplexer* — it runs your shells inside a long-lived session on the machine, and your keyboard and screen just "attach" to it as a viewport. The shells are parented to the tmux server, not to your SSH connection — which is *exactly* why they keep running when SSH drops. Picture leaving all your programs open on a desktop and just unplugging the monitor; `tmux attach` plugs the monitor back in and nothing missed a beat.

## Why it matters
In a real task you'll want nmap running in one pane, a listener in another, and notes in a third. And on a remote box, **tmux keeps your session alive if SSH drops** — you reconnect and everything's still running.

## tmux (recommended)
Everything starts with the **prefix**: `Ctrl-b`, release, then a key.

> **Why a prefix key?** tmux lives *inside* your terminal, wrapping programs that already use plenty of Ctrl-shortcuts of their own. The prefix (`Ctrl-b`) is a "the next keystroke is for tmux, not the app" signal — it stops tmux from stealing keys out from under vim, your shell, or whatever's running in the pane.

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

→ The killer move: `Ctrl-b d` to **detach** on a remote host, log off, come back later, `tmux attach` — your scans are still running. (`screen` is the older equivalent if tmux isn't installed.)

## Terminator (GUI alternative)
A graphical terminal that tiles panes in one window. Good when you're working locally on Kali/Ubuntu desktop.

| Do this | Keys |
|---|---|
| Split **vertical** | `Ctrl-Shift-E` |
| Split **horizontal** | `Ctrl-Shift-O` |
| Move between panes | `Ctrl-Shift-` arrow (or click) |
| Close pane | `Ctrl-Shift-W` |
| New tab | `Ctrl-Shift-T` |
| Toggle a pane fullscreen | `Ctrl-Shift-X` (zoom) |

→ Install: `sudo apt install terminator`. No remote-persistence like tmux — it's about layout, not survival.

## Exam tips & gotchas
- **tmux for anything remote** (survives SSH drops); Terminator for local convenience — but pick ONE and use it always, as the JQR says.
- tmux beginners forget the **prefix** — every tmux shortcut is `Ctrl-b` *then* the key, not held together.
- Detached tmux sessions keep using RAM/CPU — `tmux ls` and kill stale ones (`tmux kill-session -t name`).
- Pair tmux with an [SSH](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md) session for long-running scans on a jump host.

## References
- tmux wiki (JQR-named) — https://github.com/tmux/tmux/wiki
- tmux intro (JQR-named) — https://www.redhat.com/sysadmin/introduction-tmux-linux
- Terminator docs (JQR-named) — https://terminator-gtk3.readthedocs.io/en/latest/

## Related
- [SSH - Tunneling and Jump Hosts](../SSH%20Kali/SSH%20-%20Tunneling%20and%20Jump%20Hosts.md)
- [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md)
- [Vim](../Vim/Vim.md)
