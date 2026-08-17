---
tags: [jcu, module1, setup]
jqr: "Module 1 — Install VMware and procure the 4 required VMs (Ubuntu, Kali, Windows 11, Debian); build a safe lab network"
---

# VM Lab Setup

The whole JQR runs on your own VMs. Get the lab right once and every later task (scanning, tunneling, iptables, Metasploit) has somewhere safe to happen. This is my actual lab.

## TL;DR
- **Hypervisor:** VMware Workstation Pro (free for personal use).
- **Required by the JQR (4):** Ubuntu, Kali, Windows 11, Debian. **My lab also adds:** CentOS Stream 10 and pfSense (router/firewall for pivoting practice).
- **Network:** keep targets on an isolated **Host-only / LAN segment** so scans and exploits never touch the real network.
- **Snapshot every VM clean** *before* you attack it, so you can roll back in seconds.

## My lab (what's actually installed)
| VM | Version | Role | Get it from |
|---|---|---|---|
| Kali | 2026.2 | Attacker (nmap, Metasploit, msfvenom) | kali.org/get-kali (VMware image) |
| Ubuntu | 24.04 LTS (or 26.04) | Scripting, OpenVPN/WireGuard, general Linux | ubuntu.com/download/desktop |
| Debian | 13 "Trixie" (Cinnamon) | Second Linux host / routing peer | debian.org/CD |
| Windows 11 | Dev/Eval | Windows admin, SMB, PsExec targets | developer.microsoft.com (eval VMs) |
| CentOS | Stream 10 | iptables + rpm/yum practice | centos.org / mirror.stream.centos.org |
| pfSense | CE 2.7.2 | Router/firewall between segments (pivoting) | pfsense.org |

> Note: my original setup note said "Ubuntu 24.06" — the real LTS is **24.04**. Use 24.04 LTS or the current 26.04; either is fine for every task here.

## Install VMware + build the VMs
1. **Install VMware Workstation Pro** (Broadcom now offers it free for personal use — grab the official installer, don't use random mirrors).
2. **Kali:** download the prebuilt **VMware image** (a `.7z` you extract to a `.vmwarevm`/`.vmx`) rather than installing from ISO — it's faster and ships the toolset. Open the `.vmx` in Workstation.
3. **Ubuntu / Debian / CentOS / Windows 11:** create a new VM and install from the official ISO. Give each ≥2 vCPU / 4 GB RAM / 40 GB disk where you can.
4. **Open VM Tools / VMware Tools** in each guest for clipboard + better networking (`sudo apt install open-vm-tools open-vm-tools-desktop` on Linux).

## Lab networking (the part people get wrong)
VMware gives each VM a network **mode** — pick deliberately:

| Mode | What it does | Use it for |
|---|---|---|
| **NAT** | VM shares the host's IP to reach the internet; isolated from your LAN | updating packages, downloading tools |
| **Host-only** | Private network **host ⇄ VMs only**, no internet | safe attacker↔target scanning/exploiting |
| **LAN Segment** | Private switch **VM ⇄ VM only** (not even the host) | clean multi-VM subnets, pivoting labs |
| **Bridged** | VM appears as a real device on your physical LAN | avoid for attack practice — it exposes your real network |

**Recommended layout for the JQR:**
- Give each VM **two NICs**: one **NAT** (to update/download) and one **Host-only or LAN Segment** (the "lab" network where you scan/exploit).
- Put Kali + the Linux/Windows targets on the same Host-only net (e.g. `192.168.x.0/24`).
- Use **pfSense** with two NICs to sit *between* two LAN Segments — that gives you a real "reach subnet B through router A" setup for the routing, [iptables](../03%20-%20Linux%20Skills/iptables.md), and [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md) tasks.

> [!tip] Snapshots are your undo button
> In Workstation: **VM → Snapshot → Take Snapshot** on a clean, patched VM *before* you attack it. After you pop a shell or brick a config, **Revert** to get back to clean in seconds. Take one snapshot per VM named `clean-baseline`.

## Exam tips & gotchas
- The JQR requires the repo of your Bash/Python work to be **public** so instructors can see progress — that's this vault ([Git and GitHub](Git%20and%20GitHub.md)).
- Two NICs per VM is also literally a JQR skill (see [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md) and [Windows Networking and Interfaces](../04%20-%20Windows%20Skills/Windows%20Networking%20and%20Interfaces.md)) — building the lab *is* practicing the objective.
- Don't bridge attack VMs onto your home/work LAN. Host-only/LAN Segment keeps noisy scans contained.
- If a VM won't boot after a snapshot revert, check it isn't still "suspended" (`.vmss`/`.vmem` present) — power off fully, then start.

## References
- VMware Workstation Pro (official download) — https://knowledge.broadcom.com/external/article/344595/downloading-vmware-workstation-pro.html
- Kali VMware images — https://www.kali.org/get-kali/#kali-virtual-machines
- Ubuntu Desktop — https://ubuntu.com/download/desktop
- Debian ISOs — https://www.debian.org/CD/http-ftp/
- Windows 11 dev/eval VMs — https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/
- pfSense CE — https://www.pfsense.org/download/

## Related
- [Git and GitHub](Git%20and%20GitHub.md)
- [Interfaces IPs and Routing](../03%20-%20Linux%20Skills/Interfaces%20IPs%20and%20Routing.md)
- [Pivoting and Tunneling](../06%20-%20Knowledge%20Requirements/Pivoting%20and%20Tunneling.md)
- [iptables](../03%20-%20Linux%20Skills/iptables.md)
