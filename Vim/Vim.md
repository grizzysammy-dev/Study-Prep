---
tags: [cyber, module1, linux, editor]
jqr: "Module 1 — VIM Adventures; be able to open, edit, save, and quit files in vim"
---

# Vim

The editor that's on *every* box, including stripped target machines where nano isn't. You don't need to be fast — you need to never get *stuck* in it. (Practice muscle memory at vim-adventures.com.)

> **The mental model:** vim is *modal* — the same keys mean different things depending on the mode. In **Normal** mode your keyboard is a remote control (keys are commands: move, delete, copy); in **Insert** mode it's a typewriter (keys are text). That's the whole reason beginners get "stuck": they start typing in Normal mode and every letter fires a command instead. `Esc` always drops you back to the remote control. Internalize that one idea and vim stops being scary — everything else is just vocabulary.

## TL;DR — the survival kit
```
vim file.txt     open
i                start typing (INSERT mode)
Esc              stop typing (back to NORMAL mode)
:w               save          :q      quit
:wq   (or  ZZ)   save & quit   :q!     quit WITHOUT saving  <- the "get me out" button
```
> If you're ever stuck: press **`Esc`** then type **`:q!`** and Enter. That always escapes.

## My original notes (kept)
- Vim isn't always preinstalled — I installed it with **`sudo apt install vim`**.
- Open a file to view/edit: **`vim test.txt`**.
- Enter editing by pressing **`A`** (append) or **`i`** (insert), then type your text.
- Save & quit with **`:`** then **`w`** (write) then **`q`** (quit) → `:wq`.
- If you're a sudo user and a write is blocked, add **`!`** to force it (e.g. `:w!`).

## The one concept: modes
Vim has modes — this is the whole learning curve.

| Mode | You're doing | Get there |
|---|---|---|
| **Normal** | moving / commands (default) | `Esc` |
| **Insert** | typing text | `i` `a` `A` `o` |
| **Visual** | selecting text | `v` (char) `V` (line) |
| **Command** | `:` line commands (save/quit/search-replace) | `:` |

→ Entering insert: `i` before cursor · `a` after · `A` end of line · `o` open new line below.

> **Why bother with modes at all?** Because when every key in Normal mode is a command, editing becomes a fast keyboard language — `dd` deletes a line, `3dd` deletes three — no Ctrl chords, no reaching for a mouse. That efficiency is why vim has survived 30+ years and why it's the guaranteed fallback editor on literally every Unix box, even a broken one you SSH into over a flaky link.

## Move around (Normal mode)
```
h j k l     left / down / up / right
w  b        next / previous word
0  $        start / end of line
gg  G       top / bottom of file
:42         jump to line 42
Ctrl-f/-b   page down / up
```

## Edit (Normal mode)
```
x           delete character
dd          delete (cut) a line        yy   copy a line       p   paste
u           undo                       Ctrl-r  redo
r<char>     replace one character
```

## Search & replace
```
/text       search forward (n = next, N = previous)
:%s/old/new/g     replace ALL 'old' with 'new' in the file
:%s/old/new/gc    ...asking to confirm each
```
→ `:%s/.../.../g` uses [RegEx](../RegEx/RegEx.md) — the same patterns you use in grep/sed.

## Exam tips & gotchas
- **Stuck = `Esc` then `:q!`.** Memorise it before anything else.
- Editing a system file and "can't save"? You opened it without root — `:w !sudo tee %` writes it via sudo, or reopen with `sudoedit`.
- `:set number` shows line numbers; `:set paste` stops auto-indent mangling pasted blocks.
- `vimtutor` (run it in a terminal) is a free 30-minute built-in lesson.

## References
- VIM Adventures (JQR-named game) — https://vim-adventures.com
- `vimtutor` — ships with vim; just run `vimtutor`
- Vim docs — https://www.vim.org/docs.php

## Related
- [Bash Scripting](../Bash%20Scripting/Bash%20Scripting.md)
- [RegEx](../RegEx/RegEx.md)
- [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
