---
tags: [jcu, module3, linux]
jqr: "Module 3 — mount CIFS/ISO, persist mounts in /etc/fstab (_netdev), partition (parted), fsck, GRUB boot order"
---

# Disks Mounts and fstab

Attaching storage — a Windows share, a disk image, a new partition — making it survive reboot via `/etc/fstab`, repairing it with `fsck`, and choosing what boots via GRUB. A bad fstab line can stop a machine from booting, so the `mount -a` test is non-negotiable.

## TL;DR
```bash
sudo mount -t cifs //192.168.1.20/Shared /mnt/winshare -o credentials=/etc/cifs-creds,vers=3.1.1
sudo mount -o loop file.iso /mnt/iso            # mount a disc image via a loop device
sudo mount -a                                   # mount everything in fstab — TEST after every edit
sudo umount /dev/sdb1 && sudo fsck -y /dev/sdb1 # unmount FIRST, then check/repair
sudo parted -l                                  # list disks + partition tables
```
- **`/etc/fstab` field 6 (pass):** `1` = root `/`, `2` = other local disks, **`0`** = network/removable.
- **Network mount → always add `_netdev`** so boot waits for the NIC.

## Concept
A device (`/dev/sdb1`), a network share, or an image file becomes usable only after it's **mounted** onto a directory (the *mount point*). A hand-run `mount` vanishes at reboot; **`/etc/fstab`** makes it permanent. **GRUB** is the bootloader that picks which kernel/OS runs. **`fsck`** checks/repairs a filesystem — but only when it's **unmounted**.

## Mount a remote Windows share (CIFS/SMB)
Windows shares use **SMB/CIFS**; Linux mounts them with `mount -t cifs`.
```bash
sudo apt install cifs-utils      # Debian/Ubuntu   (dnf install cifs-utils on RHEL)
sudo mkdir -p /mnt/winshare
sudo mount -t cifs //192.168.1.20/Shared /mnt/winshare \
     -o username=sam,password=P@ss,vers=3.1.1,uid=$(id -u),gid=$(id -g)
```
- `-t cifs` = the CIFS/SMB driver. `//192.168.1.20/Shared` = `//WIN-IP/ShareName` (forward slashes).
- `-o username=,password=` = Windows creds; add `domain=CORP` for a domain account.
- **`vers=3.1.1`** = SMB version — **matters**: modern Windows disables insecure SMBv1. On mismatch force a modern version (`3.1.1`, `3.0`, `2.1`); avoid `vers=1.0`.
- `uid=/gid=` = make mounted files owned by you locally.

**Safer than a plaintext password on the command line — a credentials file:**
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
> **Gotcha:** a password on the command line shows up in `ps`/shell history — use a `credentials=` file `chmod 600`. "Permission denied" often = wrong `vers=` or the share needs a `domain=`.
> 🧪 **Run this on your lab** — verified against current docs, confirm on your box. Needs a real Windows/second host serving the share.

## /etc/fstab — persistent mounts at boot
**`/etc/fstab`** lists filesystems to mount automatically at boot. **Six fields:**
```
<device/source>            <mount point>   <fstype>  <options>              <dump> <pass>
UUID=abcd-1234             /               ext4      defaults               0      1
//192.168.1.20/Shared      /mnt/winshare   cifs      credentials=/etc/cifs-creds,vers=3.1.1,_netdev  0  0
```
1. **Source** — a device, `UUID=…` (preferred — stable; get it with `blkid`), or a network share.
2. **Mount point** — where it appears.
3. **Filesystem type** — `ext4`, `xfs`, `cifs`, `nfs`, `vfat`, `swap`…
4. **Options** — `defaults` plus extras.
5. **dump** — backup flag, almost always `0`.
6. **pass (fsck order)** — `1` for root `/`, `2` for other local disks, **`0`** = don't fsck (network/removable).

**Adding a REMOTE share — the key detail is `_netdev`:**
```
//192.168.1.20/Shared      /mnt/winshare  cifs  credentials=/etc/cifs-creds,vers=3.1.1,_netdev  0  0
172.16.5.30:/exports/data  /mnt/nfs       nfs   defaults,_netdev                                0  0
```
- **`_netdev`** = "needs the **network** first" — systemd waits for networking before mounting, so the box doesn't hang trying to mount a share before the NIC is up. **Always add `_netdev` for CIFS/NFS.**
- `x-systemd.automount` (optional) = mount lazily on first access — even more boot-hang-proof.

**Test WITHOUT rebooting — do this every time:**
```bash
sudo mount -a          # mount everything in fstab not already mounted — catches typos NOW
```
> **CRITICAL gotcha:** a bad `/etc/fstab` line can make the machine **fail to boot** (drops to emergency mode). ALWAYS `sudo mount -a` after editing; for network mounts never forget `_netdev`. Keep a backup: `sudo cp /etc/fstab /etc/fstab.bak`.

## Mount an ISO — the corrected find + for-loop one-liner
An **ISO** is a disc image; mount it read-only via a **loop device** (`-o loop`).
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
- `find / -name '*.iso' 2>/dev/null` = search the whole tree; `2>/dev/null` hides "Permission denied" noise.
- `mount -o loop "$i" /mnt/iso` = **`-o loop`** wraps the file as a virtual block device. Quote `"$i"` so spaces don't break it.
- **`break`** = the fix for the classic bug: without it, several ISOs all target the *same* `/mnt/iso` and only the last stays visible (the rest error as "already mounted").

**To mount MANY ISOs, give each its own directory:**
```bash
i=0
for iso in $(find / -name '*.iso' 2>/dev/null); do
    m="/mnt/iso$i"; sudo mkdir -p "$m"
    sudo mount -o loop "$iso" "$m" && echo "$iso -> $m"
    i=$((i+1))
done
```
> **Gotcha:** the raw loop `for i in $(find …); do mount -o loop "$i" /mnt/iso; done` "works" but silently mounts only one usable ISO — add `break` or per-ISO dirs. `$(...)` also splits on spaces; for robustness use `find … -print0 | while IFS= read -r -d '' i; do …; done`.
> 🧪 **Run this on your lab** — verified against current docs; needs an actual `.iso` present and root.

## parted and gparted — partitioning
Both create/resize/delete **partitions**. `parted` = command line; `gparted` = the GUI of the same job.
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
After creating a partition, **make a filesystem** and mount it:
```bash
sudo mkfs.ext4 /dev/sdb1
sudo mount /dev/sdb1 /mnt/data
```
**`gparted` (GUI):** `sudo apt install gparted`, launch, pick the disk top-right, right-click space to Create/Resize/Delete, then click the **green check ✓** to apply queued changes.

**When to use which:** **parted/CLI** for servers, SSH, no GUI, automation, precise repeatable commands; **gparted/GUI** for a desktop/live-USB, visual resizing, preview before applying.
> **DANGER:** a wrong `/dev/sdX` can wipe data — confirm the target with `lsblk` first. When resizing data: shrink the **filesystem before** the partition, grow the **partition before** the filesystem (gparted handles the ordering).
> 🧪 **Run this on your lab** — verified against current docs; needs a real spare disk.

## fsck — check / repair a filesystem
**`fsck`** = **f**ile**s**ystem **c**hec**k**: scans for corruption (bad inodes, lost blocks, dirty state after a crash) and can repair it.
```bash
sudo umount /dev/sdb1        # 1) UNMOUNT first — NEVER fsck a mounted, in-use filesystem
sudo fsck /dev/sdb1          # 2) check (prompts y/n per fix)
sudo fsck -y /dev/sdb1       # auto-answer YES to every repair (unattended)
sudo fsck -n /dev/sdb1       # check only, make NO changes (safe read-only look)
sudo fsck -A -y              # check ALL filesystems in /etc/fstab (per pass number)
sudo fsck.ext4 -f /dev/sdb1  # -f = force even if it looks clean
```
**Reading it:** "clean" = healthy; it reports passes (inodes, directories, block bitmaps…) then either "FILE SYSTEM WAS MODIFIED" or nothing to do. At boot, Linux auto-runs fsck based on the fstab **pass** field.
> **CRITICAL gotcha:** running `fsck` on a **mounted** filesystem can **destroy** it — always `umount` first. You can't unmount `/` while running; force a check at next boot (`sudo touch /forcefsck`) or run from a live USB. Bad superblock? try a backup: `sudo fsck -b 32768 /dev/sdb1`.
> 🧪 **Run this on your lab** — verified against current docs; needs a real unmounted filesystem.

## GRUB — boot order / default kernel
GRUB2 is the bootloader. To change which entry boots by default:

**Step 1 — edit `/etc/default/grub`:**
```
GRUB_DEFAULT=0          # boot the FIRST menu entry (counting from 0)
GRUB_DEFAULT=2          # boot the THIRD entry
GRUB_DEFAULT=saved      # boot whatever was last chosen / set with grub-set-default
GRUB_TIMEOUT=5          # seconds the menu waits before auto-booting the default
```
For a specific kernel, `GRUB_DEFAULT` can be the exact menu title or a `"submenu>entry"` path.

**Step 2 — regenerate the real config** (never edit the generated file directly):
```bash
sudo update-grub                                       # Debian/Ubuntu
sudo grub2-mkconfig -o /boot/grub2/grub.cfg            # RHEL/CentOS/Fedora (BIOS)
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg   # RHEL/CentOS/Fedora (UEFI)
```
(`update-grub` just wraps `grub-mkconfig -o /boot/grub/grub.cfg`.)

**Set default by name on RHEL (`GRUB_DEFAULT=saved`):**
```bash
sudo grubby --info=ALL              # list kernels + indexes
sudo grub2-set-default 0            # pick default by index
sudo grub2-editenv list             # show the saved default
```
**Choosing at boot:** hold **Shift** (BIOS) or tap **Esc** (UEFI) to force the menu; arrow to pick; press **`e`** to edit boot params for a single boot (e.g. add `single` or `init=/bin/bash` for recovery), **Ctrl-X**/**F10** to boot. That edit isn't saved.
> **Gotcha:** forgetting `update-grub`/`grub2-mkconfig` after editing `/etc/default/grub` means your change does nothing — the file you edited is only the *template*.
> 🧪 **Run this on your lab** — verified against current docs; affects a real bootloader, don't rehearse on a box you can't recover.

## Exam tips & gotchas
- **After every `/etc/fstab` edit: `sudo mount -a`.** A typo here can make the box unbootable.
- **`_netdev`** on every CIFS/NFS line, or boot may hang waiting on a share before the network is up.
- **`fsck` only on an unmounted filesystem** — `umount` first, or force at next boot for `/`.
- ISO mount needs **`-o loop`**; the find+for-loop needs **`break`** or per-ISO dirs.
- Confirm the disk with **`lsblk`** before any `parted`/`mkfs`/`dd` — wrong `/dev/sdX` wipes data.
- GRUB change = edit `/etc/default/grub` **then** regenerate with `update-grub`/`grub2-mkconfig`.

## References
- `man 8 mount`, `man 5 fstab`, `man 8 fsck`, `man 8 parted`, `man 8 mount.cifs`
- GRUB manual: https://www.gnu.org/software/grub/manual/grub/
- Ubuntu CIFS/SMB: https://help.ubuntu.com/community/MountWindowsSharesPermanently

## Related
- [chroot and Python venv](chroot%20and%20Python%20venv.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
- [Processes and systemd](Processes%20and%20systemd.md)
