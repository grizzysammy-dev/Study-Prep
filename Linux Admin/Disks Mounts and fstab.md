---
tags: [cyber, module3, linux]
jqr: "Module 3 - mount CIFS/ISO, persist mounts in /etc/fstab (_netdev), partition (parted), fsck, GRUB boot order"
---

# Disks Mounts and fstab

Attaching storage (a Windows share, a disk image, a new partition), making it survive reboot through `/etc/fstab`, repairing it with `fsck`, and choosing what boots via GRUB. A bad fstab line can stop a machine from booting, so I treat the `mount -a` test as non-negotiable.

## The quick set
```bash
sudo mount -t cifs //192.168.1.20/Shared /mnt/winshare -o credentials=/etc/cifs-creds,vers=3.1.1
sudo mount -o loop file.iso /mnt/iso            # mount a disc image via a loop device
sudo mount -a                                   # mount everything in fstab — TEST after every edit
sudo umount /dev/sdb1 && sudo fsck -y /dev/sdb1 # unmount FIRST, then check/repair
sudo parted -l                                  # list disks + partition tables
```
- **`/etc/fstab` field 6 (pass):** `1` = root `/`, `2` = other local disks, **`0`** = network/removable.
- **Network mount always gets `_netdev`** so boot waits for the NIC.

## What mounting actually is
A device (`/dev/sdb1`), a network share, or an image file only becomes usable after it's **mounted** onto a directory (the *mount point*). A hand-run `mount` vanishes at reboot; **`/etc/fstab`** makes it permanent. **GRUB** is the bootloader that picks which kernel/OS runs. **`fsck`** checks and repairs a filesystem, but only when it's **unmounted**.

Here's what "mount" is really doing: a raw disk or share is just a pile of blocks with a filesystem written on them, and the kernel can't reach those files until you *graft* that filesystem onto an existing directory (the **mount point**). After `mount`, stepping into that directory transparently drops you into the other device's files; unmount and the directory is empty again. That grafting is why Linux is one tree with no `C:`/`D:` letters, since every disk, share, and image is just another branch hanging off `/`.

## Mounting a Windows share (CIFS/SMB)
Windows shares use **SMB/CIFS**, and Linux mounts them with `mount -t cifs`.
```bash
sudo apt install cifs-utils      # Debian/Ubuntu   (dnf install cifs-utils on RHEL)
sudo mkdir -p /mnt/winshare
sudo mount -t cifs //192.168.1.20/Shared /mnt/winshare \
     -o username=sam,password=P@ss,vers=3.1.1,uid=$(id -u),gid=$(id -g)
```
- `-t cifs` is the CIFS/SMB driver. `//192.168.1.20/Shared` is `//WIN-IP/ShareName` (forward slashes).
- `-o username=,password=` are the Windows creds; add `domain=CORP` for a domain account.
- **`vers=3.1.1`** is the SMB version and it **matters**, because modern Windows disables insecure SMBv1. On a mismatch, force a modern version (`3.1.1`, `3.0`, `2.1`) and avoid `vers=1.0`.
- `uid=/gid=` make the mounted files owned by me locally.

Safer than a plaintext password on the command line is a credentials file:
```bash
sudo tee /etc/cifs-creds >/dev/null <<'EOF'
username=sam
password=P@ss
domain=CORP
EOF
sudo chmod 600 /etc/cifs-creds
sudo mount -t cifs //192.168.1.20/Shared /mnt/winshare -o credentials=/etc/cifs-creds,vers=3.1.1
```
Unmount with `sudo umount /mnt/winshare`.

A password on the command line shows up in `ps` and shell history, so I use a `credentials=` file at `chmod 600`. "Permission denied" is usually a wrong `vers=` or a share that needs a `domain=`.

(Need a real Windows or second host serving the share to try this for real.)

## /etc/fstab (persistent mounts)
**`/etc/fstab`** lists filesystems to mount automatically at boot. There are **six fields**:
```
<device/source>            <mount point>   <fstype>  <options>              <dump> <pass>
UUID=abcd-1234             /               ext4      defaults               0      1
//192.168.1.20/Shared      /mnt/winshare   cifs      credentials=/etc/cifs-creds,vers=3.1.1,_netdev  0  0
```
1. **Source:** a device, `UUID=...` (preferred, since it's stable; get it with `blkid`), or a network share.
2. **Mount point:** where it appears.
3. **Filesystem type:** `ext4`, `xfs`, `cifs`, `nfs`, `vfat`, `swap`...
4. **Options:** `defaults` plus extras.
5. **dump:** backup flag, almost always `0`.
6. **pass (fsck order):** `1` for root `/`, `2` for other local disks, **`0`** = don't fsck (network/removable).

Adding a REMOTE share, the key detail is `_netdev`:
```
//192.168.1.20/Shared      /mnt/winshare  cifs  credentials=/etc/cifs-creds,vers=3.1.1,_netdev  0  0
172.16.5.30:/exports/data  /mnt/nfs       nfs   defaults,_netdev                                0  0
```
- **`_netdev`** means "needs the **network** first," so systemd waits for networking before mounting and the box doesn't hang trying to mount a share before the NIC is up. **Always add `_netdev` for CIFS/NFS.**
- `x-systemd.automount` (optional) mounts lazily on first access, which is even more boot-hang-proof.

Test without rebooting, every single time:
```bash
sudo mount -a          # mount everything in fstab not already mounted — catches typos NOW
```
> **CRITICAL gotcha:** a bad `/etc/fstab` line can make the machine **fail to boot** (drops to emergency mode). ALWAYS `sudo mount -a` after editing; for network mounts never forget `_netdev`. Keep a backup: `sudo cp /etc/fstab /etc/fstab.bak`.

## Mounting an ISO (the find + loop one-liner)
An **ISO** is a disc image, and I mount it read-only via a **loop device** (`-o loop`).
```bash
sudo mkdir -p /mnt/iso
for i in $(find / -name '*.iso' 2>/dev/null); do
    echo "Mounting $i -> /mnt/iso"
    sudo mount -o loop "$i" /mnt/iso
    break            # stop after the FIRST ISO (don't stack mounts on one dir)
done
ls /mnt/iso          # verify contents
sudo umount /mnt/iso # when done
```
- `find / -name '*.iso' 2>/dev/null` searches the whole tree; `2>/dev/null` hides the "Permission denied" noise.
- `mount -o loop "$i" /mnt/iso` uses **`-o loop`** to wrap the file as a virtual block device. Quote `"$i"` so spaces don't break it.
- **`break`** is the fix for the classic bug: without it, several ISOs all target the *same* `/mnt/iso` and only the last one stays visible (the rest error as "already mounted").

To mount MANY ISOs, give each its own directory:
```bash
i=0
for iso in $(find / -name '*.iso' 2>/dev/null); do
    m="/mnt/iso$i"; sudo mkdir -p "$m"
    sudo mount -o loop "$iso" "$m" && echo "$iso -> $m"
    i=$((i+1))
done
```
The raw loop `for i in $(find ...); do mount -o loop "$i" /mnt/iso; done` "works" but silently mounts only one usable ISO, so add `break` or per-ISO dirs. `$(...)` also splits on spaces; for robustness use `find ... -print0 | while IFS= read -r -d '' i; do ...; done`.

(Need an actual .iso present and root to run this.)

## parted / gparted (partitioning)
Both create, resize, and delete **partitions**. `parted` is the command line; `gparted` is the GUI of the same job.
```bash
sudo parted -l                       # list all disks + partition tables
sudo parted /dev/sdb                 # interactive mode on a disk
(parted) print                       # show partitions
(parted) mklabel gpt                 # partition table (gpt modern, msdos = old MBR)
(parted) mkpart primary ext4 1MiB 20GiB   # create a partition
(parted) resizepart 1 40GiB          # grow partition 1's end to 40GiB
(parted) rm 2                        # delete partition 2
(parted) quit
sudo parted /dev/sdb --script mkpart primary ext4 1MiB 100%   # non-interactive
```
After creating a partition, make a filesystem and mount it:
```bash
sudo mkfs.ext4 /dev/sdb1
sudo mount /dev/sdb1 /mnt/data
```
For **gparted** (GUI): `sudo apt install gparted`, launch it, pick the disk top-right, right-click space to Create/Resize/Delete, then click the green checkmark to apply the queued changes.

When to use which: parted/CLI for servers, SSH, no GUI, automation, and precise repeatable commands; gparted/GUI for a desktop or live-USB, visual resizing, and previewing before applying.
> **DANGER:** a wrong `/dev/sdX` can wipe data, so confirm the target with `lsblk` first. When resizing data, shrink the **filesystem before** the partition and grow the **partition before** the filesystem (gparted handles the ordering for you).

(Need a real spare disk for this one.)

## fsck (check / repair)
**`fsck`** is **f**ile**s**ystem **c**hec**k**: it scans for corruption (bad inodes, lost blocks, dirty state after a crash) and can repair it.

Why it has to be unmounted: `fsck` reads and rewrites the filesystem's on-disk bookkeeping *directly*. A mounted filesystem is being written by the kernel at the same time, and the kernel also holds a cached copy of that metadata in RAM, so fsck's repairs and the kernel's flushes stomp on each other and the stale cache overwrites your fixes. Two writers on the same structures is how "a few bad inodes" becomes a dead disk; unmounting makes fsck the only writer.
```bash
sudo umount /dev/sdb1        # 1) UNMOUNT first — NEVER fsck a mounted, in-use filesystem
sudo fsck /dev/sdb1          # 2) check (prompts y/n per fix)
sudo fsck -y /dev/sdb1       # auto-answer YES to every repair (unattended)
sudo fsck -n /dev/sdb1       # check only, make NO changes (safe read-only look)
sudo fsck -A -y              # check ALL filesystems in /etc/fstab (per pass number)
sudo fsck.ext4 -f /dev/sdb1  # -f = force even if it looks clean
```
Reading it: "clean" means healthy; it reports passes (inodes, directories, block bitmaps...) then either "FILE SYSTEM WAS MODIFIED" or nothing to do. At boot, Linux auto-runs fsck based on the fstab **pass** field.
> **CRITICAL gotcha:** running `fsck` on a **mounted** filesystem can **destroy** it, so always `umount` first. You can't unmount `/` while running, so force a check at next boot (`sudo touch /forcefsck`) or run from a live USB. Bad superblock? Try a backup: `sudo fsck -b 32768 /dev/sdb1`.

(Need a real unmounted filesystem to actually run this.)

## GRUB (boot order / default kernel)
GRUB2 is the bootloader. To change which entry boots by default:

Step 1, edit `/etc/default/grub`:
```
GRUB_DEFAULT=0          # boot the FIRST menu entry (counting from 0)
GRUB_DEFAULT=2          # boot the THIRD entry
GRUB_DEFAULT=saved      # boot whatever was last chosen / set with grub-set-default
GRUB_TIMEOUT=5          # seconds the menu waits before auto-booting the default
```
For a specific kernel, `GRUB_DEFAULT` can be the exact menu title or a `"submenu>entry"` path.

Step 2, regenerate the real config (never edit the generated file directly):
```bash
sudo update-grub                                       # Debian/Ubuntu
sudo grub2-mkconfig -o /boot/grub2/grub.cfg            # RHEL/CentOS/Fedora (BIOS)
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg   # RHEL/CentOS/Fedora (UEFI)
```
(`update-grub` just wraps `grub-mkconfig -o /boot/grub/grub.cfg`.)

Set default by name on RHEL (`GRUB_DEFAULT=saved`):
```bash
sudo grubby --info=ALL              # list kernels + indexes
sudo grub2-set-default 0            # pick default by index
sudo grub2-editenv list             # show the saved default
```
Choosing at boot: hold **Shift** (BIOS) or tap **Esc** (UEFI) to force the menu, arrow to pick, press **`e`** to edit boot params for a single boot (e.g. add `single` or `init=/bin/bash` for recovery), then **Ctrl-X**/**F10** to boot. That edit isn't saved.
> **Gotcha:** forgetting `update-grub`/`grub2-mkconfig` after editing `/etc/default/grub` means your change does nothing, because the file you edited is only the *template*.

(This touches a real bootloader, so I won't rehearse it on a box I can't recover.)

## What I keep forgetting
- **After every `/etc/fstab` edit: `sudo mount -a`.** A typo here can make the box unbootable.
- **`_netdev`** on every CIFS/NFS line, or boot may hang waiting on a share before the network is up.
- **`fsck` only on an unmounted filesystem**, so `umount` first, or force at next boot for `/`.
- ISO mount needs **`-o loop`**; the find+for-loop needs **`break`** or per-ISO dirs.
- Confirm the disk with **`lsblk`** before any `parted`/`mkfs`/`dd`, because a wrong `/dev/sdX` wipes data.
- GRUB change = edit `/etc/default/grub` **then** regenerate with `update-grub`/`grub2-mkconfig`.

## Docs
- `man 8 mount`, `man 5 fstab`, `man 8 fsck`, `man 8 parted`, `man 8 mount.cifs`
- GRUB manual: https://www.gnu.org/software/grub/manual/grub/
- Ubuntu CIFS/SMB: https://help.ubuntu.com/community/MountWindowsSharesPermanently

## Related
- [chroot and Python venv](chroot%20and%20Python%20venv.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
- [Processes and systemd](Processes%20and%20systemd.md)
