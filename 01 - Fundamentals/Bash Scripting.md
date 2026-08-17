---
tags: [jcu, module1, scripting, linux]
jqr: "Module 1 — Bash scripting fundamentals on the Ubuntu VM (variables, conditionals, loops, arguments, cron)"
---

# Bash Scripting

Automating the shell. The JQR wants you comfortable writing small scripts, and two specific projects (in [Bash - JQR Projects](Bash%20-%20JQR%20Projects.md)). This note is the language; that note is the graded deliverables. Done on the Ubuntu VM.

## TL;DR
```bash
#!/bin/bash                      # shebang: run this file with bash
name="Sam"                       # variable (NO spaces around =)
echo "Hello $name"               # $ expands it
read -p "Path? " p               # prompt + read into $p
if [ -d "$p" ]; then echo yes; fi   # test: is $p a directory?
for f in *.txt; do echo "$f"; done  # loop over files
chmod +x script.sh && ./script.sh   # make executable, then run
```

## The basics (JQR command list)
`date` `pwd` `ls` `cat` `echo` `which` `vi`/`vim` — and the structural pieces:
- **`#!/bin/bash`** — the *shebang*; the first line that tells the OS which interpreter runs the file.
- **`.sh`** — conventional extension for a shell script (not required, just convention).
- **`bash script.sh`** runs it with bash even without `+x`; `./script.sh` needs the execute bit.

## Make a script and run it
```bash
vim hello.sh          # or: nano hello.sh
chmod +x hello.sh     # add execute permission for your user (see Files Search and Permissions)
./hello.sh            # run it
```
→ `chmod +x` is what turns a text file into a runnable script for your user.

## Variables & expansion
```bash
greeting="Hello World"     # assign — no spaces around the =
echo "$greeting"           # use — always double-quote to keep spaces safe
today=$(date)              # command substitution: capture a command's output
echo "It is $today"
num=$((3 + 4))             # arithmetic
```
→ User-set shell variables live in memory; things you want to persist across logins go in **`~/.bashrc`**. Reference a variable with `$name` (or `${name}` when it touches other text).

## Arguments & input
```bash
#!/bin/bash
echo "Script name : $0"     # $0 = the script itself
echo "First arg   : $1"     # $1..$9 = positional args
echo "All args    : $@"     # every argument
echo "How many    : $#"     # argument count
read -p "Your age: " age    # interactive input into $age
```
→ Run `./args.sh alpha bravo` → `$1`=alpha, `$2`=bravo, `$#`=2.

## Conditionals (test operators)
```bash
if [ "$num" -gt 0 ]; then
  echo "positive"
elif [ "$num" -lt 0 ]; then
  echo "negative"
else
  echo "zero"
fi
```
Common tests: numbers `-eq -ne -lt -le -gt -ge` · strings `=  !=  -z(empty)  -n(non-empty)` · files `-f(file) -d(dir) -e(exists) -r/-w/-x(perm)`.
→ `[ ]` is the classic test; `[[ ]]` is the bash-only upgrade (safer with strings, supports `&&`, `||`, `=~` regex). **Always quote your variables** inside tests.

## Loops
```bash
for i in 1 2 3; do echo "num $i"; done          # for over a list
for f in *.log; do echo "file $f"; done         # for over files (globbing)
while read line; do echo "$line"; done < in.txt # while, reading a file line by line
until ping -c1 192.168.1.20 &>/dev/null; do sleep 1; done  # until success
```

## case
```bash
case "$1" in
  start) echo "starting" ;;
  stop)  echo "stopping" ;;
  *)     echo "usage: $0 {start|stop}" ;;
esac
```

## Functions & exit codes
```bash
greet() { echo "hi $1"; }     # define
greet Sam                     # call

ls /nope 2>/dev/null
echo "exit code was $?"       # $? = exit status of last command (0 = success)
```
→ Every command returns an **exit code**: `0` = success, non-zero = failure. Scripts and `if` use it to decide what happened.

## Redirects (send output where you want)
```bash
echo "line" >  file.txt     # overwrite
echo "more" >> file.txt     # append
command 2> errors.txt       # stderr only
command &> all.txt          # stdout + stderr
command | grep foo          # pipe stdout into another command
```

## Safer scripts + scheduling
```bash
set -euo pipefail           # exit on error / undefined var / failed pipe — put near the top
```
Schedule a script with **cron** (full detail in [cron](../03%20-%20Linux%20Skills/cron.md)):
```bash
crontab -e
@reboot      /home/sam/setup.sh          # run once at every boot
*/5 * * * *  /home/sam/check.sh           # every 5 minutes
```

## Exam tips & gotchas
- **No spaces around `=`** in assignments (`x=1`, not `x = 1`).
- **Quote your variables**: `"$var"` — unquoted vars break on spaces/empties.
- `[ ]` needs spaces inside the brackets: `[ "$a" = "$b" ]`.
- `chmod +x` before `./script.sh`, or run with `bash script.sh`.
- `$?` right after a command tells you if it worked — great for `if` logic.
- Test destructive scripts on throwaway files first (see `dd`/`rm` warnings in [Files Search and Permissions](../03%20-%20Linux%20Skills/Files%20Search%20and%20Permissions.md)).

## References
- Bash scripting tutorial (JQR-named) — https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/
- Bash reference manual — https://www.gnu.org/software/bash/manual/bash.html
- ShellCheck (lint your scripts) — https://www.shellcheck.net/

## Related
- [Bash - JQR Projects](Bash%20-%20JQR%20Projects.md)
- [cron](../03%20-%20Linux%20Skills/cron.md)
- [Files Search and Permissions](../03%20-%20Linux%20Skills/Files%20Search%20and%20Permissions.md)
- [RegEx](RegEx.md)
- [Vim](Vim.md)
