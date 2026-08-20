---
tags: [cyber, module3, linux]
jqr: "Module 3 — install/remove/query software: apt, dnf/yum, dpkg, rpm, pip+PEP 668, wheels, repo config"
---

# Package Management

How software gets on and off a Linux box, on both major families. Know the high-level manager (resolves dependencies) *and* the low-level tool (installs one local file) for each.

## TL;DR
```bash
sudo apt update && sudo apt upgrade     # Debian/Ubuntu: refresh index, THEN install updates
sudo apt install ./pkg.deb              # install a local .deb + resolve its deps (note ./)
sudo dnf install httpd                  # RHEL/CentOS/Fedora (yum -> dnf)
sudo dnf install ./pkg.rpm              # install a local .rpm + resolve deps
dpkg -i / -l / -L / -S                  # low-level Debian: install / list / files / owner
rpm  -ivh / -qa / -ql / -qf             # low-level RHEL: install / list / files / owner
```
- **Golden rule:** high-level (`apt`/`dnf`) pulls dependencies from repos; low-level (`dpkg`/`rpm`) installs a single file you already have and does **not** fetch deps.

## Concept
Two ecosystems:
- **Debian family** (Debian, Ubuntu, Kali) → `.deb` packages, **`apt`** front-end over **`dpkg`** engine.
- **RHEL family** (RHEL, CentOS Stream, Rocky, Alma, Fedora) → `.rpm` packages, **`dnf`** front-end (yum is a symlink to it) over the **`rpm`** engine.

The front-end talks to configured **repositories**, resolves dependencies, and downloads. The engine just unpacks one file onto disk.

> **Why the split matters:** the engine (`dpkg`/`rpm`) only knows how to unpack *one* file you hand it — give it a package with unmet dependencies and it stops half-done with an error. The front-end (`apt`/`dnf`) is the brain: it reads each package's declared dependency list, walks the whole graph, pulls every missing piece from the repos, then calls the engine on each in the right order. That's why raw `dpkg -i` can strand you "half-installed" and `apt-get install -f` (below) is the cleanup. A **repository** itself is just a web server hosting packages plus a signed index of what's available — `apt update` downloads that index, which is why it must come *before* `upgrade`.

## Debian/Ubuntu — apt
```bash
sudo apt update                 # REFRESH the package index (does NOT upgrade). Always first.
sudo apt upgrade                # install available updates
sudo apt full-upgrade           # upgrade, allowing removals if deps require it
sudo apt install nginx          # install (add -y to auto-confirm)
sudo apt install nginx vim tmux # several at once
sudo apt remove nginx           # uninstall (keep config)
sudo apt purge nginx            # uninstall + delete config
sudo apt autoremove             # drop now-unneeded dependencies
sudo apt search keyword         # find a package
apt show nginx                  # details
apt list --installed            # everything installed
```
> **Gotcha:** `apt update` (refresh lists) and `apt upgrade` (install updates) are DIFFERENT — the sequence is always `update` **then** `upgrade`. `apt` (interactive) vs `apt-get` (scriptable classic) — both work.

## RHEL/CentOS/Fedora — dnf (and yum)
On all modern RHEL-family systems the manager is **`dnf`**. **`yum` is just a symlink to `dnf`** kept for muscle memory — identical syntax.
```bash
sudo dnf check-update           # what updates are available
sudo dnf upgrade                # install all updates (older alias: dnf update — same)
sudo dnf install httpd          # install (-y to auto-confirm)
sudo dnf remove httpd           # uninstall
sudo dnf search keyword         # find a package
dnf info httpd                  # details
dnf list installed              # everything installed
dnf provides /usr/bin/dig       # which package provides a file/command
sudo dnf group install "Development Tools"   # install a package group
dnf history                     # transaction log (dnf history undo N to roll back!)
```
> **Gotcha:** unlike apt, you do **not** run a separate "update the index" step — dnf refreshes metadata automatically. There is no `apt update` equivalent you must run first.

## Download a package WITHOUT installing it
Useful for offline installs, staging, or inspecting.
```bash
# Debian/Ubuntu:
sudo apt-get install --download-only nginx    # fetch .deb + deps to /var/cache/apt/archives/
apt download nginx                             # just this one .deb to the CURRENT dir (no deps)
# RHEL/CentOS:
sudo dnf install --downloadonly httpd                    # cache the RPMs, don't install
sudo dnf download httpd                                   # drop the .rpm here (dnf-plugins-core)
sudo dnf download --resolve --destdir /tmp/rpms httpd     # package AND deps into /tmp/rpms
```

## dpkg — low-level Debian tool
`apt` resolves deps and downloads; **`dpkg`** installs a single **`.deb`** already on disk and does **not** fetch dependencies.
```bash
sudo dpkg -i package.deb        # INSTALL a local .deb
dpkg -l                         # LIST all installed packages
dpkg -l | grep nginx            # is nginx installed?
dpkg -L nginx                   # LIST every file that package installed (capital L)
dpkg -S /usr/sbin/nginx         # SEARCH: which package OWNS this file (capital S)
dpkg -s nginx                   # status/details of an installed package
sudo dpkg -r nginx              # remove (keep config); -P = purge config too
```
**Remember the four:** `-i` install, `-l` list installed, `-L` list a package's files, `-S` which package owns a file.

## rpm — low-level RHEL tool
```bash
sudo rpm -ivh package.rpm       # i=install, v=verbose, h=hash progress bar
sudo rpm -Uvh package.rpm       # Upgrade (or install if absent) — usually preferred
rpm -qa                         # query all installed (like dpkg -l)
rpm -ql httpd                   # list a package's files (like dpkg -L)
rpm -qf /usr/sbin/httpd         # which package owns this file (like dpkg -S)
sudo rpm -e httpd               # erase/uninstall
```
> **Best practice:** install a local RPM with **dnf** so deps come along automatically — `sudo dnf install ./package.rpm`. Raw `rpm -ivh` errors out with "Failed dependencies" if anything's missing.

## Install a local .deb (the clean way)
```bash
sudo apt install ./package.deb        # PREFERRED — installs the local .deb AND resolves deps
# or the two-step classic:
sudo dpkg -i package.deb              # install (may complain about missing deps)
sudo apt-get install -f              # "-f" = FIX broken: pulls the missing deps
```
> **Gotcha:** the `./` (or a full path) in `apt install ./file.deb` is **required** — without it apt thinks you're naming a repo package.

## pip and the 2026 "externally managed" reality (PEP 668)
`pip` installs **Python** packages from PyPI.
```bash
pip install requests            # into the current environment
pip install requests==2.31.0    # a specific version
pip install -r requirements.txt # everything in a file
pip list                        # what's installed
pip show requests               # details
pip download requests           # fetch package (+deps) WITHOUT installing
```
**The 2026 reality — PEP 668:** on Ubuntu 23.04+ / Debian 12+ (so all of Ubuntu 24.04/26.04 and Debian 13) and recent Fedora, a **system-wide** `pip install` is **blocked** to protect OS-managed Python:
```
error: externally-managed-environment
```
The OS is saying "don't let pip fight `apt`/`dnf` over the system Python." Three correct fixes:
1. **A virtual environment** (best for a project): `python3 -m venv .venv && source .venv/bin/activate`, then `pip install` works inside it. Full walkthrough + tested proof in [chroot and Python venv](chroot%20and%20Python%20venv.md).
2. **`pipx`** (best for a standalone CLI *app* — each gets its own isolated venv): `sudo apt install pipx` then `pipx install httpie`.
3. **`--break-system-packages`** (escape hatch, can conflict with apt/dnf): `pip install --break-system-packages requests`.

> **Rule of thumb:** *library for a project* → **venv**. *Standalone CLI tool* → **pipx**. *Must override* → `--break-system-packages`. Prefer the distro package (`apt install python3-requests`) when one exists.

## What is a .whl (wheel) file?
A **wheel** is the modern **pre-built binary package format for Python** (`name-1.2.3-py3-none-any.whl`). Pre-built means pip just unzips it — no compiler needed — so installs are fast. (The old format was a source `.tar.gz` "sdist" that had to be built.)
```bash
pip install ./requests-2.31.0-py3-none-any.whl
```
The filename encodes compatibility: `{name}-{version}-{python}-{abi}-{platform}.whl`; `py3-none-any` = pure Python, any OS/arch.

## WHERE repo/source config lives
**Debian/Ubuntu** — two styles coexist in 2026:
- **`/etc/apt/sources.list`** — classic single file, one-line entries: `deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse`
- **`/etc/apt/sources.list.d/`** — add-on repo files (one per third-party repo).
- **deb822 format** (default on Ubuntu 24.04+ / Debian 13): multi-line `*.sources` files, e.g. `/etc/apt/sources.list.d/ubuntu.sources`:
  ```
  Types: deb
  URIs: http://archive.ubuntu.com/ubuntu
  Suites: noble noble-updates noble-security
  Components: main restricted universe multiverse
  Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
  ```
  After editing any of these, run `sudo apt update`.

**RHEL/CentOS/Fedora:**
- **`/etc/yum.repos.d/*.repo`** — one file per repo (yum and dnf share it). A stanza:
  ```
  [baseos]
  name=CentOS Stream 10 - BaseOS
  baseurl=http://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/
  enabled=1
  gpgcheck=1
  gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
  ```
- Main config: **`/etc/dnf/dnf.conf`** (older: `/etc/yum.conf`).
- Manage without hand-editing: `sudo dnf config-manager --add-repo <url>` / `--set-enabled <repo>`.

## Exam tips & gotchas
- Mixing up `apt update` vs `apt upgrade` is the #1 beginner slip — refresh, *then* install.
- To install a downloaded file: **`apt install ./x.deb`** or **`dnf install ./x.rpm`** — let the front-end pull deps. Raw `dpkg -i` / `rpm -ivh` won't.
- "Which package owns this file?" → `dpkg -S <path>` (Debian) or `rpm -qf <path>` (RHEL).
- On 2026 Ubuntu/Debian, a bare `pip install` fails with `externally-managed-environment` — reach for a **venv** ([chroot and Python venv](chroot%20and%20Python%20venv.md)), not `--break-system-packages`.
- After editing repo files, Debian needs `apt update`; dnf refreshes on its own.

## References
- Debian apt: https://manpages.debian.org/apt (also `man 8 apt`, `man 1 dpkg`)
- DNF: https://dnf.readthedocs.io/  •  `man 8 dnf`, `man 8 rpm`
- PEP 668: https://peps.python.org/pep-0668/
- pip: https://pip.pypa.io/  •  Python packaging (wheels): https://packaging.python.org/

## Related
- [chroot and Python venv](chroot%20and%20Python%20venv.md)
- [Processes and systemd](Processes%20and%20systemd.md)
- [Linux Filesystem (FHS)](Linux%20Filesystem%20%28FHS%29.md)
- [Files Search and Permissions](Files%20Search%20and%20Permissions.md)
