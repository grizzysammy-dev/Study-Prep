---
tags: [cyber, module1, setup]
jqr: "Module 1: install VMware and get the four required VMs (Ubuntu, Kali, Windows 11, Debian), then build a safe lab network"
---

# VM Lab Setup

Pretty much the whole JQR runs on VMs I set up myself. Get the lab right once and every later task (scanning, tunneling, iptables, Metasploit) has somewhere safe to happen. This is my actual lab.

> The way I think about it: a hypervisor (VMware) is just a program that fakes a whole computer in software, CPU and disk and network card and all, so a "VM" is really a folder of files pretending to be hardware. That fakery is what makes the lab safe. The guest believes it's a real machine, but I own the walls around it. I treat the whole thing like a sealed terrarium: I can detonate malware inside and the blast never reaches my real host or network, as long as I wired the network mode correctly. That one setting decides what the VMs can actually touch, so it's the part worth understanding instead of just clicking through.

## The short version
- Hypervisor I use: VMware Workstation Pro (free for personal use now).
- The four the JQR requires: Ubuntu, Kali, Windows 11, Debian. I also added CentOS Stream 10 and pfSense (a router/firewall for pivoting practice).
- Network: keep targets on an isolated Host-only / LAN segment so scans and exploits never touch the real network.
- Snapshot every VM clean before I attack it, so I can roll back in seconds.

## My lab (what's actually installed)
| VM | Version | Role | Get it from |
|---|---|---|---|
| Kali | 2026.2 | Attacker (nmap, Metasploit, msfvenom) | kali.org/get-kali (VMware image) |
| Ubuntu | 24.04 LTS (or 26.04) | Scripting, OpenVPN/WireGuard, general Linux | ubuntu.com/download/desktop |
| Debian | 13 "Trixie" (Cinnamon) | Second Linux host / routing peer | debian.org/CD |
| Windows 11 | Dev/Eval | Windows admin, SMB, PsExec targets | developer.microsoft.com (eval VMs) |
| CentOS | Stream 10 | iptables + rpm/yum practice | centos.org / mirror.stream.centos.org |
| pfSense | CE 2.7.2 | Router/firewall between segments (pivoting) | pfsense.org |

> Quick correction to myself: my original setup note said "Ubuntu 24.06", but the real LTS is **24.04**. Either 24.04 LTS or the current 26.04 works fine for everything here.

## Install VMware + build the VMs
1. Install VMware Workstation Pro. Broadcom offers it free for personal use now, so grab the official installer and don't use random mirrors.
2. Kali: I grabbed the prebuilt **VMware image** (a `.7z` you extract to a `.vmwarevm`/`.vmx`) instead of installing from ISO. It's faster and already ships the toolset. Open the `.vmx` in Workstation.
3. Ubuntu / Debian / CentOS / Windows 11: create a new VM and install from the official ISO. Give each ≥2 vCPU / 4 GB RAM / 40 GB disk where you can.
4. Install Open VM Tools / VMware Tools in each guest for clipboard and better networking (`sudo apt install open-vm-tools open-vm-tools-desktop` on Linux).

## Lab networking (the part I had to get right)
VMware gives each VM a network **mode**, and it's worth picking deliberately:

| Mode | What it does | Use it for |
|---|---|---|
| **NAT** | VM shares the host's IP to reach the internet; isolated from your LAN | updating packages, downloading tools |
| **Host-only** | Private network **host ⇄ VMs only**, no internet | safe attacker↔target scanning/exploiting |
| **LAN Segment** | Private switch **VM ⇄ VM only** (not even the host) | clean multi-VM subnets, pivoting labs |
| **Bridged** | VM appears as a real device on your physical LAN | avoid for attack practice; it exposes your real network |

> Why the mode is the whole game: it decides which virtual switch your fake network card plugs into. Host-only and LAN Segment are switches with no uplink to the outside, so traffic physically can't leave and a scan that misfires just hits my own targets. Bridged splices the VM straight onto the physical LAN, where (thinking about it from the blue-team side) my attack box looks exactly like a rogue unmanaged device and my noisy nmap sweep is lighting up the real IDS. That's the mistake I never want to make on a work network.

Layout I went with:
- Give each VM **two NICs**: one NAT (for updates and downloads) and one Host-only or LAN Segment (the "lab" network where I scan and exploit).
- Put Kali and the Linux/Windows targets on the same Host-only net (e.g. `192.168.x.0/24`).
- Use **pfSense** with two NICs to sit between two LAN Segments. That gives me a real "reach subnet B through router A" setup for the routing, [iptables](../IP%20Tables%20CentOS/iptables.md), and [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md) tasks.

> Why two NICs? A machine with one foot in each network is dual-homed, the same shape as a real jump box or firewall. Give pfSense two NICs, turn on forwarding, and I've basically built a router, since a router is just a host that passes packets between the networks it's attached to. That's the exact setup the pivoting and iptables tasks assume, so building the lab is practicing them.

> [!tip] Snapshots are my undo button
> In Workstation: **VM → Snapshot → Take Snapshot** on a clean, patched VM before I attack it. After I pop a shell or brick a config, **Revert** gets me back to clean in seconds. I keep one snapshot per VM named `clean-baseline`.
> Why it's instant: the snapshot freezes the current disk and writes every later change into a separate delta file, so reverting just throws that delta away and a wrecked box snaps right back to pristine.

## Gotchas and reminders
- The JQR wants the repo of my Bash/Python work to be **public** so instructors can see progress. That's this vault ([Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md)).
- Two NICs per VM is itself a JQR skill (see [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md) and [Windows Networking and Interfaces](../Win%20Admin/Windows%20Networking%20and%20Interfaces.md)), so building the lab is practicing the objective.
- Don't bridge attack VMs onto the home/work LAN. Host-only or LAN Segment keeps noisy scans contained.
- If a VM won't boot after a snapshot revert, check it isn't still "suspended" (`.vmss`/`.vmem` present), then power off fully and start again.

## References
- VMware Workstation Pro (official download): https://knowledge.broadcom.com/external/article/344595/downloading-vmware-workstation-pro.html
- Kali VMware images: https://www.kali.org/get-kali/#kali-virtual-machines
- Ubuntu Desktop: https://ubuntu.com/download/desktop
- Debian ISOs: https://www.debian.org/CD/http-ftp/
- Windows 11 dev/eval VMs: https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/
- pfSense CE: https://www.pfsense.org/download/

## Related
- [Git and GitHub](../Git%20and%20GitHub/Git%20and%20GitHub.md)
- [Interfaces IPs and Routing](../Linux%20Admin/Interfaces%20IPs%20and%20Routing.md)
- [Pivoting and Tunneling](../Knowledge%20Req/Pivoting%20and%20Tunneling.md)
- [iptables](../IP%20Tables%20CentOS/iptables.md)
