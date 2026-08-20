---
tags: [cyber, module3, linux]
jqr: "Module 3 - find/locate/grep, cp, dd; chmod/chown + reading permission strings; tar/xz/7z/zip archiving"
---

# Files Search and Permissions

Finding files, copying and imaging them, searching inside them, and controlling who can touch them, plus bundling and compressing. Permissions are the part the exam loves, usually as a `drwxr-xr-x` to number conversion, so I drill that both directions.

## The quick set
```bash
find / -type f -name "sshd_config" 2>/dev/null   # search the live filesystem by name
grep -rin "failed password" /var/log             # search INSIDE files (recursive, no-case, line #)
locate sshd_config                               # instant name search from an index (run updatedb first)
cp -a src/ dst/                                  # copy preserving perms/owner/timestamps
chmod 640 file ; chmod -R 755 dir                # set perms (numeric); -R = recursive
chown -R sam:sam /home/sam                        # set owner:group recursively
tar czvf out.tar.gz dir/  |  tar xzvf out.tar.gz  # bundle+gzip  |  extract
```
- **Permission math:** r=4, w=2, x=1 per triad. `rwxr-xr-x` = 7,5,5 = **755**. `777` = everyone read/write/execute (red flag).

## The shape of it
On Linux everything is a file, and every file has an **owner**, a **group**, and a 3×3 grid of read/write/execute bits (owner / group / other). There are two search tools worth keeping straight: `find` walks the disk **live** (accurate, slower), while `locate` queries a prebuilt **index** (instant, possibly stale). `grep` searches file *contents*. And `tar` *bundles* while `gzip`/`xz`/`bzip2` *compress*, so I combine them for `.tar.gz` and friends.

## find (search live)
```bash
find /etc -name "*.conf"              # by NAME (case-sensitive); -iname = case-insensitive
find / -type f -name "sshd_config"    # -type f (file), d (dir), l (symlink)
find /var -size +100M                 # by SIZE: bigger than 100 MB (+/-; k, M, G)
find /home -mtime -1                  # MODIFIED in the last 1 day (+7 = older than 7 days)
find . -mmin -30                      # modified in the last 30 minutes
find / -perm -4000 -type f 2>/dev/null  # SUID binaries (classic priv-esc hunt)
find /path -user sam                  # owned by a user
find . -name "*.tmp" -delete          # find and delete
find . -type f -name "*.log" -exec gzip {} \;      # -exec: run a command per match
find . -type f -name "*.txt" -exec grep -l "TODO" {} +   # + batches files (faster)
```
`-exec cmd {} \;` runs once per file; `-exec cmd {} +` batches many files into one call. Tests stack, so `find / -type f -size +50M -mtime -7` is large files changed this week.

Why `-perm -4000` is a priv-esc hunt: a file with the **setuid** bit runs as its *owner*, not as whoever launched it. That's how an unprivileged user running `passwd` can edit root-owned `/etc/shadow`. So "find SUID binaries" really means "show me every program that lends out its owner's privileges." On offense that's a hunt for a root-owned one with a known escape (GTFOBins, in the refs); from the defender's chair it's an integrity check, since an unexpected SUID-root bit is how a foothold quietly becomes root.

## grep (search inside files)
```bash
grep "error" file.log             # lines containing "error" (case-sensitive)
grep -i "error" file.log          # -i = case-INSENSITIVE
grep -r "TODO" /project           # -r = RECURSIVE through a tree
grep -rn "password" /etc          # -n = line NUMBERS (with -r)
grep -v "debug" file.log          # -v = INVERT: lines that do NOT match
grep -E "err|fail|crit" file.log  # -E = extended regex (alternation, +, ?)
grep -o "user=[a-z]*" auth.log    # -o = print ONLY the matched text
grep -c "404" access.log          # -c = COUNT matching lines
grep -l "TODO" *.py               # -l = list FILENAMES that match
grep -w "root" /etc/passwd        # -w = whole word (not "chroot")
grep -A3 -B1 "panic" kern.log     # 3 lines After / 1 Before each match
```
The core flags I keep are `-i -r -n -v -E -o -c`, and the everyday combo for logs is `grep -rin "phrase" /var/log`.

Output when I ran it (Ubuntu 24.04):
```
$ find /etc -name '*.conf' -type f 2>/dev/null | head -3
/etc/selinux/semanage.conf
/etc/ld.so.conf.d/x86_64-linux-gnu.conf
/etc/ld.so.conf.d/libc.conf

$ grep -rin 'listen' /etc/rsyslog.conf | head -3
```
`find` printed the first three matching config files; the `grep` returned nothing, because `/etc/rsyslog.conf` has no line containing "listen" (a no-match is silent, not an error). Honest reminder to myself: an empty `grep` result means "not found here," so widen the path (`grep -rin listen /etc/rsyslog.d/`) before concluding anything.

## locate / updatedb (indexed name search)
```bash
sudo apt install plocate          # or: dnf install mlocate
sudo updatedb                     # BUILD/refresh the index (cron does this nightly)
locate sshd_config                # instant search
locate -i readme                  # case-insensitive
```
Catch with `locate`: it only knows what existed at the **last `updatedb`**, so a file created 5 minutes ago won't show until I re-run it. `find` for real-time, `locate` for speed.

## cp (copy)
```bash
cp file.txt /tmp/                 # copy a file
cp -r dir/ /backup/               # -r = recursive (a directory tree)
cp -a src/ dst/                   # -a = ARCHIVE: recursive + preserve perms/owner/timestamps/links
cp -i file /tmp/                  # -i = prompt before overwriting (safe)
cp -v file /tmp/                  # -v = verbose
```
For backups and migrations I use `cp -a` so ownership and timestamps survive.

## dd (raw copy / imaging, careful)
`dd` copies raw blocks, so I use it to image a whole disk, write an ISO to USB, or back up a partition bit-for-bit.
```bash
sudo dd if=/dev/sda of=/mnt/backup/sda.img bs=4M status=progress     # image a disk to a file
sudo dd if=ubuntu.iso of=/dev/sdb bs=4M status=progress oflag=sync   # write ISO to a USB stick
sudo dd if=/dev/sda of=/dev/sdb bs=64K conv=noerror,sync             # clone disk A -> disk B
```
`if=` is input, `of=` is output, `bs=` is block size (bigger = faster), `status=progress` gives live progress.
> [!danger] The "disk destroyer": `dd` writes exactly where `of=` points with **no confirmation**. Swapping `if`/`of` or getting `/dev/sdX` wrong **instantly and irrecoverably overwrites** a disk, so I triple-check device names with `lsblk` first.

(Need real disks/USB to actually try this; the sandbox doesn't have them.)

## vim, the bare minimum
Just enough to edit a config and get out. Full note: [Vim](../Vim/Vim.md).
```
vim file.txt      # open
i                 # enter INSERT mode (now you can type)
Esc               # back to NORMAL mode
:w   :q   :wq     # save / quit / save+quit          :q! = quit WITHOUT saving
```
The trap that got me early: you can't type until `i`, and can't quit until `Esc` then `:q`. `:q!` is the emergency exit.

## Reading permissions (drwxr-xr-x)
`ls -l` shows 10 characters, e.g. **`drwxr-xr-x`**:
```
d  rwx  r-x  r-x
│   │    │    └── OTHER (everyone else):  r-x
│   │    └─────── GROUP:                  r-x
│   └──────────── OWNER (user):           rwx
└──────────────── TYPE:  d=directory  -=file  l=symlink  b=block  c=char dev
```
- **r**=read (4), **w**=write (2), **x**=execute (1). On a **directory**, `x` means "may enter/cd in" and `r` means "may list names."
- Add per triad: `rwx`=7, `r-x`=5, `rw-`=6, `r--`=4. So **`drwxr-xr-x`** = directory, owner **7**, group **5**, other **5** = **755**.

The part I found surprising is that the kernel does *not* add the triads up. It asks in order: are you the file's owner? If yes, only the **owner** bits apply and it stops looking. If not, are you in its group? Then only the **group** bits apply. Neither? You're **other**. Exactly one triad decides, first-match, which is why a file can be `r--` for its group yet `---` for its owner and the owner is genuinely locked out despite "outranking" the group.

**What `777` means:** `rwxrwxrwx` = **everyone** (owner, group, other) can read, write, AND execute.
> [!warning] 777 lets *any user on the system* modify or run the file, almost never what you want. Sensible defaults: files **644** (`rw-r--r--`), directories **755**, private key/secret **600** (`rw-------`), scripts **755** or **700**.

## chmod
```bash
chmod 644 file            # numeric (absolute): owner rw, group r, other r
chmod 600 secret.key      # owner rw only — lock down a secret
chmod +x script.sh        # symbolic: add execute for all
chmod u+x,go-w script.sh  # u/g/o/a  +add -remove =set-exactly
chmod -R 755 /var/www     # -R = RECURSIVE through a tree
# safer recursive — dirs 755, files 644 separately:
find /var/www -type d -exec chmod 755 {} \;
find /var/www -type f -exec chmod 644 {} \;
```

Output when I ran it (Ubuntu 24.04):
```
$ chmod 754 file1 ; chmod 755 dir1 ; ls -l
total 4
drwxr-xr-x 2 root root 4096 Aug 17 04:02 dir1
-rwxr-xr-- 1 root root    0 Aug 17 04:02 file1

754 = rwx r-x r--  (owner7=rwx group5=r-x other4=r--)
drwxr-xr-x: d=directory, then owner rwx, group r-x, other r-x
$ chmod 777 file1 ; ls -l file1
-rwxrwxrwx 1 root root 0 Aug 17 04:02 file1
```
That confirms the mapping: `754` on the file renders as `-rwxr-xr--`, `755` on the dir as `drwxr-xr-x`, and `777` opens it wide to `-rwxrwxrwx`. To go backwards, read the string right-to-left in triads to reverse it into the number.

## chown
```bash
sudo chown sam file             # set owner to sam
sudo chown sam:developers file  # owner sam, group developers (user:group)
sudo chown :developers file     # change only the group (or use chgrp)
sudo chown -R sam:sam /home/sam # -R = recursively (whole tree)
sudo chown --reference=a.txt b.txt   # copy a.txt's owner/group onto b.txt
```
`chmod -R 777` on a whole tree is the classic "just make it work" mistake: it opens the tree *and* makes every data file executable. I prefer the `find ... -type d/-type f` split above. Only **root** (or the owner, for chmod) can change ownership.

## Compressing and archiving
The thing to keep straight: **`tar`** *bundles* many files into one archive (`.tar`) but doesn't compress, while **`gzip`/`xz`/`bzip2`** are *compressors* that shrink a stream. Combine them and you get `.tar.gz`, `.tar.xz`, `.tar.bz2`.

`tar` is the workhorse (I mainly learn `czvf` / `xzvf`):
```bash
tar czvf backup.tar.gz  /home/sam/   # CREATE gzip: c=create z=gzip v=verbose f=file
tar xzvf backup.tar.gz               # EXTRACT gzip: x=extract
tar cJvf backup.tar.xz  dir/         # create with xz  (capital J)
tar xJvf backup.tar.xz               # extract xz
tar cjvf backup.tar.bz2 dir/         # create with bzip2 (lowercase j)
tar xjvf backup.tar.bz2              # extract bzip2
tar tzvf backup.tar.gz               # t = LIST contents without extracting
tar xzvf backup.tar.gz -C /restore/  # -C = extract INTO a target directory
```
Memory hook: **c**reate / e**x**tract / lis**t**; **f** means "filename next" (always last); `v` is verbose. Modern `tar xf file.tar.*` often auto-detects the compressor anyway.

The individual compressors, one example each:
```bash
gzip file            # -> file.gz;   gunzip file.gz  (or gzip -d)   to reverse
xz file              # -> file.xz (best ratio, slower);  unxz file.xz (or xz -d) to reverse
bzip2 file           # -> file.bz2;  bunzip2 file.bz2 (or bzip2 -d)  to reverse
zip -r archive.zip dir/     # ZIP (cross-platform, talks to Windows); unzip archive.zip
unzip -l archive.zip        # list a zip without extracting
7z a archive.7z dir/        # 7-Zip: a=ADD/create (great ratio, can encrypt); x=extract
7z x archive.7z             # extract preserving full paths (install: p7zip-full)
7z a -p archive.7z dir/     # -p = password-protect (AES-256)
```
Quick chooser: `.zip` for sharing with **Windows**; `.tar.gz` is the universal Linux default; `.tar.xz`/`.7z` are **smallest**; `.tar.bz2` is the older middle-ground.

Output when I ran it (Ubuntu 24.04):
```
tar czf -> 131 bytes
xz -k    -> created data.txt.xz
7z a     -> created data.7z
zip      -> created data.zip
total 24
-rw-r--r-- 1 root root  136 Aug 17 04:02 data.7z
-rw-r--r-- 1 root root  131 Aug 17 04:02 data.tar.gz
-rw-r--r-- 1 root root   10 Aug 17 04:02 data.txt
-rw-r--r-- 1 root root   68 Aug 17 04:02 data.txt.xz
-rw-r--r-- 1 root root  176 Aug 17 04:02 data.zip
drwxr-xr-x 2 root root 4096 Aug 17 04:02 dir1
-rwxrwxrwx 1 root root    0 Aug 17 04:02 file1
```
Same 10-byte `data.txt` bundled four ways. On a payload this tiny the container overhead dominates (zip is biggest at 176 B), so ratios only mean something on real data. The point here was just that each format produced its file and round-tripped.

## What I keep forgetting
- **`drwxr-xr-x` → 755** and **`-rw-r--r--` → 644**: practice both directions, it's a near-guaranteed question.
- `find` = live/accurate/slower; `locate` = indexed/instant/maybe-stale (`updatedb` first). Don't confuse them.
- Quote wildcards in `find` (`-name "*.conf"`) so the shell doesn't expand them first; add `2>/dev/null` to hide permission noise.
- An empty `grep` result is a **no-match**, not a failure, so broaden the path/pattern before concluding.
- `dd` and `chmod -R 777` are the two "one keystroke wrecks it" traps: verify device with `lsblk`, prefer the dirs-755/files-644 split.
- `tar` letters: **c**/**x**/**t** for create/extract/list, **f** always immediately before the filename.

## Docs
- `man 1 find`, `man 1 grep`, `man 1 cp`, `man 1 dd`, `man 1 chmod`, `man 1 chown`, `man 1 tar`
- GNU findutils: https://www.gnu.org/software/findutils/
- GTFOBins (SUID/`find` abuse for priv-esc, lab use): https://gtfobins.github.io/

## Related
- [Vim](../Vim/Vim.md)
- [Logs and journalctl](Logs%20and%20journalctl.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
- [Disks Mounts and fstab](Disks%20Mounts%20and%20fstab.md)
