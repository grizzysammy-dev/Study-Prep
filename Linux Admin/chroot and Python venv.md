---
tags: [cyber, module3, linux]
jqr: "Module 3 - chroot into another root (repair/recovery) and isolate Python deps with venv (PEP 668)"
---

# chroot and Python venv

Two different "contained environment" tools that I kept confusing because both feel like a smaller world inside the system. **`chroot`** fakes a new filesystem root (recovery, contained builds), while **`venv`** gives one Python project its own packages. Neither one is a security jail, which is the thing to remember.

## The quick set
```bash
sudo chroot /mnt/target /bin/bash     # run a shell that treats /mnt/target as /
python3 -m venv .venv                 # create a project-local Python environment
source .venv/bin/activate             # activate it (prompt shows "(.venv)")
pip install requests                  # installs INSIDE the venv — dodges PEP 668
deactivate                            # leave the venv
```
- **chroot** = "pretend this directory is `/`." Main use: repair a broken install from a live USB.
- **venv** = "this project's Python + its own site-packages." The sanctioned fix for the 2026 `externally-managed-environment` error.

## Same idea, different scope
Both create a smaller world, just at different scopes. **`chroot`** changes what a process thinks **`/`** is, re-pointing the whole filesystem root at a directory so you can operate on another install (a mounted broken disk, a build root) as if you'd booted into it. **`venv`** doesn't touch the filesystem root at all; it just gives one project a private Python interpreter and package directory so `pip install` stays out of the system Python. chroot needs `sudo` and bind-mounts; venv is unprivileged and per-shell. And again, **neither is a security jail**.

## chroot (change root)
**`chroot`** runs a command with a *different directory treated as `/`*. Inside, the process can't see anything above that directory, so it's a contained, self-standing environment.
```bash
sudo chroot /mnt/target /bin/bash
```
That starts a bash shell that believes `/mnt/target` is the whole filesystem.

When I actually use it:
1. **Repair / recovery (the number one use):** I booted a broken machine from a USB/live ISO, mounted its real disk at `/mnt`, and want to run commands *as if booted into that install*, so reinstall GRUB, reset a password, fix `/etc/fstab`. First bind-mount the kernel virtual filesystems so programs work:
   ```bash
   sudo mount /dev/sda2 /mnt              # the broken root partition
   sudo mount --bind /dev  /mnt/dev
   sudo mount --bind /proc /mnt/proc
   sudo mount --bind /sys  /mnt/sys
   sudo chroot /mnt /bin/bash            # now "inside" the installed system
   # ...fix things: passwd, update-grub, grub2-install /dev/sda ...
   exit                                   # leave, then umount the binds
   ```
2. **Contained environments:** build/test software against a clean root, or confine a service so a compromise can't reach the real filesystem (a basic sandbox; containers/namespaces are the modern, stronger version).

Commands fail inside a chroot if the target is missing the binary or its libraries, or if I skipped the `/dev` `/proc` `/sys` bind-mounts. chroot is **not** a security boundary against root, because root inside can often break out. It's isolation for convenience, not a jail.

Why it's not a jail: all `chroot` changes is what the *pathname* `/` resolves to during lookups. It does nothing about syscalls, capabilities, the process table, or the network. A root process inside can still open a raw device, `chroot` a second time, or reach out through an inherited file handle and climb back above the new root. Real isolation (containers) stacks *namespaces* on top to also fake the process list, network, users, and mounts, whereas chroot fakes only the filesystem root. That's the whole reason I say "isolation for convenience, not a sandbox."

(The recovery workflow needs a live USB plus the target's real disk, which the sandbox doesn't have, so I still need to run it there.)

Mounting the partitions this depends on lives in [Disks Mounts and fstab](Disks%20Mounts%20and%20fstab.md).

## Python virtual environment (venv)
A **venv** is a private, throwaway copy of Python plus its own `site-packages` for one project. Packages I `pip install` go *inside it*, not into system Python.
```bash
python3 -m venv .venv        # create a venv in a folder named .venv
source .venv/bin/activate    # ACTIVATE it (prompt now shows "(.venv)")
pip install requests flask   # installs INTO the venv only
python app.py                # runs with the venv's packages
deactivate                   # leave the venv (back to system Python)
```
- After activating, `which python` points inside `.venv/bin/`.
- Delete the whole thing with `rm -rf .venv` and nothing else is affected.
- Save/recreate exact deps: `pip freeze > requirements.txt`, then later `pip install -r requirements.txt`.

Why activation works is mostly a `$PATH` trick: `activate` just puts `.venv/bin` at the front of my `$PATH`, so `python` and `pip` now resolve to the copies *inside* the venv, and those copies are wired to read from the venv's own `site-packages`. No container, no kernel magic. That's exactly why `which python` (below) is the honest test of whether I'm really in one, why a new terminal needs `activate` again (fresh `$PATH`), and why moving the folder breaks it (the paths are baked into those files).

When to use one, which is basically always for Python work:
- **Isolate** each project's dependencies (Project A needs Flask 2, Project B needs Flask 3, no conflict).
- Keep the **system Python clean** so I don't break OS tools that depend on it.
- It's the sanctioned way past the **PEP 668 `externally-managed-environment`** error (see [Package Management](Package%20Management.md)); inside a venv, `pip install` just works.

Output when I ran it (Ubuntu 24.04):
```
$ which python  (inside venv)
/tmp/venvdemo/bin/python
requests 2.34.2 installed ONLY inside venv
$ deactivate; python3 -c 'import requests' (outside venv):
```
Inside the activated venv, `which python` resolves to `/tmp/venvdemo/bin/python` (not `/usr/bin/python3`) and `requests` imports fine. After `deactivate`, the same `import requests` runs against **system** Python, where the package was never installed, so it fails with `ModuleNotFoundError`. That proves the install was contained to the venv, which is the whole point: nothing leaked into system Python, so nothing `apt`/`dnf` manage got disturbed.

A venv is tied to its folder path, so if I move it I recreate it. Activation only affects the **current shell**, and a new terminal needs `source .venv/bin/activate` again. For a standalone CLI *app* (not a project library) I reach for `pipx` instead, see [Package Management](Package%20Management.md).

## chroot vs venv, don't mix them up
| | chroot | venv |
|---|---|---|
| Isolates | the whole **filesystem** (fakes `/`) | one project's **Python packages** |
| Needs root | yes (`sudo`) | no |
| Typical use | boot-repair, recovery, contained build | Python dev; dodging PEP 668 |
| Undo | `exit` + `umount` the binds | `deactivate`; `rm -rf .venv` |
| A security jail? | **No** (root can escape) | **No** (just path/packages) |

## What I keep forgetting
- chroot recovery **only works after** the `--bind` mounts of `/dev`, `/proc`, `/sys`; skip them and half my commands break.
- Neither tool is a security boundary, so I say "isolation for convenience," not "sandbox/jail," if asked.
- On 2026 Ubuntu/Debian a bare `pip install` errors with `externally-managed-environment`; the exam-correct answer is **venv** (or `pipx` for apps), not `--break-system-packages`.
- `which python` inside an active venv is the quick proof I'm really in it.
- venv is **path-bound** and **per-shell**, so moving the folder or opening a new terminal means re-create or re-activate.

## Docs
- `man 1 chroot`
- Python venv: https://docs.python.org/3/library/venv.html
- PEP 668: https://peps.python.org/pep-0668/
- Arch Wiki chroot (distro-neutral recovery walkthrough): https://wiki.archlinux.org/title/Chroot

## Related
- [Package Management](Package%20Management.md)
- [Disks Mounts and fstab](Disks%20Mounts%20and%20fstab.md)
- [Python Scripting](../Python%20Scripting/Python%20Scripting.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
