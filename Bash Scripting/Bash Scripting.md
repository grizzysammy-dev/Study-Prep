---
tags: [cyber, module1, scripting, linux]
jqr: "Module 1: Bash scripting basics on the Ubuntu VM (variables, conditionals, loops, arguments, cron)"
---

# Bash Scripting

This is my note for automating the shell. The JQR wants me comfortable writing small scripts, plus two specific projects (those live in [Bash - JQR Projects](Bash%20-%20JQR%20Projects.md)). This note is the language itself; that one is the graded deliverables. I did all of this on the Ubuntu VM.

> The way it finally clicked for me: a shell script is nothing more than the exact commands I'd type at the prompt, saved in a file and run top to bottom for me. Bash is a real programming language, but its "standard library" is every command already on the box (`ls`, `grep`, `nmap`, ...) and its whole job is to glue them together. I think recipe, not app: the shell reads one line, does literally what it says, moves to the next. Once I saw it that way, "scripting" was just "typing, but saved and repeatable."

## The cheat sheet
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
`date` `pwd` `ls` `cat` `echo` `which` `vi`/`vim`, plus the structural pieces:
- **`#!/bin/bash`** is the *shebang*, the first line that tells the OS which interpreter runs the file.
- **`.sh`** is the conventional extension for a shell script (not required, just convention).
- **`bash script.sh`** runs it with bash even without `+x`; `./script.sh` needs the execute bit.

> Why the shebang matters: when I run `./script.sh`, the kernel peeks at the first two bytes of the file. If they're `#!`, it reads the rest of that line and hands the file to that interpreter. So the shebang is how a plain text file gets to declare "I'm a bash program" (or python, or perl). Without it, the OS is left guessing.

## Make a script and run it
```bash
vim hello.sh          # or: nano hello.sh
chmod +x hello.sh     # add execute permission for your user (see Files Search and Permissions)
./hello.sh            # run it
```
That `chmod +x` is what flips a text file into something my user can actually run.

> Why the `./`? The shell won't run a script from the current folder just because I typed its name. If it did, a malicious file named `ls` dropped in a directory could hijack me. `./hello.sh` says "yes, run this file, right here, on purpose."

## Variables & expansion
```bash
greeting="Hello World"     # assign — no spaces around the =
echo "$greeting"           # use — always double-quote to keep spaces safe
today=$(date)              # command substitution: capture a command's output
echo "It is $today"
num=$((3 + 4))             # arithmetic
```
User-set shell variables live in memory; anything I want to persist across logins goes in **`~/.bashrc`**. I reference a variable with `$name`, or `${name}` when it bumps up against other text.

> Why no spaces around `=`? The shell decides what a line is by its first word. `x=1` has no spaces, so it reads as an assignment; `x = 1` looks like "run the command `x` with arguments `=` and `1`." Quoting matters for the same reason: the shell splits unquoted values on spaces before the command ever sees them, so `"$greeting"` stays one argument instead of becoming two. `$(...)` is the quiet workhorse, it runs a command and drops its output straight into the line, which is how I wire tools into each other.

## Arguments & input
```bash
#!/bin/bash
echo "Script name : $0"     # $0 = the script itself
echo "First arg   : $1"     # $1..$9 = positional args
echo "All args    : $@"     # every argument
echo "How many    : $#"     # argument count
read -p "Your age: " age    # interactive input into $age
```
Run `./args.sh alpha bravo` and `$1`=alpha, `$2`=bravo, `$#`=2.

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
`[ ]` is the classic test; `[[ ]]` is the bash-only upgrade (safer with strings, supports `&&`, `||`, `=~` regex). Always quote my variables inside tests.

> Why `[ ]` needs the spaces: `[` isn't punctuation, it's literally a command (there's a real `/usr/bin/[` on the box) and `]` is just its final argument. So `[ "$num" -gt 0 ]` is me running a little program with four arguments, which is exactly why it breaks without the spaces and why an unquoted empty variable makes it choke. `[[ ]]` is a bash built-in and sidesteps those footguns.

## Loops
```bash
for i in 1 2 3; do echo "num $i"; done          # for over a list
for f in *.log; do echo "file $f"; done         # for over files (globbing)
while read line; do echo "$line"; done < in.txt # while, reading a file line by line
until ping -c1 192.168.1.20 &>/dev/null; do sleep 1; done  # until success
```
"Do this to every host / port / line" is most of what recon and log-parsing actually are, and the loop is the engine. That last one, `until ping ... do sleep 1`, is a whole wait-for-the-box-to-come-up watcher in a single line.

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
Every command returns an **exit code**: `0` means success, non-zero means failure. Scripts and `if` use it to decide what happened.

> Why exit codes are the backbone: `if`, `&&`, and `||` don't test "true/false", they test the exit code of the last command. `cmd && echo ok` means "run echo only if cmd returned 0"; `||` fires only on failure. That one convention, 0 means success, is what lets me wire commands into logic with no glue code at all.

## Redirects (send output where you want)
```bash
echo "line" >  file.txt     # overwrite
echo "more" >> file.txt     # append
command 2> errors.txt       # stderr only
command &> all.txt          # stdout + stderr
command | grep foo          # pipe stdout into another command
```
> Why the number in `2>`: every process is born with three streams, stdin (0), stdout (1), stderr (2). Normal output flows out 1, errors out 2, kept apart on purpose so I can throw away the noise and keep the signal. A pipe `|` just wires one program's stdout straight into the next one's stdin, an assembly line where each tool does one job and passes the work along.

## Safer scripts + scheduling
```bash
set -euo pipefail           # exit on error / undefined var / failed pipe — put near the top
```
Schedule a script with **cron** (full detail in [cron](../Linux%20Admin/cron.md)):
```bash
crontab -e
@reboot      /home/sam/setup.sh          # run once at every boot
*/5 * * * *  /home/sam/check.sh           # every 5 minutes
```
> Why `set -euo pipefail`: by default bash shrugs off errors and marches on, so a script whose `cd` failed will cheerfully run the next line in the wrong directory. This line makes it stop on the first error, treat an unset variable as the mistake it usually is, and refuse to hide a failure buried in a pipe. Blue-team aside for myself: those same cron entries are prime persistence real estate, and a stray `@reboot` line in someone's crontab is exactly what I'd hunt for as an attacker's foothold, so it pays to read them from both chairs.

## What keeps tripping me up
- **No spaces around `=`** in assignments (`x=1`, not `x = 1`).
- **Quote my variables**: `"$var"`, because unquoted vars break on spaces and empties.
- `[ ]` needs spaces inside the brackets: `[ "$a" = "$b" ]`.
- `chmod +x` before `./script.sh`, or run it with `bash script.sh`.
- `$?` right after a command tells me if it worked, which is great for `if` logic.
- Test destructive scripts on throwaway files first (see `dd`/`rm` warnings in [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)).

## References
- Bash scripting tutorial (JQR-named): https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/
- Bash reference manual: https://www.gnu.org/software/bash/manual/bash.html
- ShellCheck (lint your scripts): https://www.shellcheck.net/

## Related
- [Bash - JQR Projects](Bash%20-%20JQR%20Projects.md)
- [cron](../Linux%20Admin/cron.md)
- [Files Search and Permissions](../Linux%20Admin/Files%20Search%20and%20Permissions.md)
- [RegEx](../RegEx/RegEx.md)
- [Vim](../Vim/Vim.md)
