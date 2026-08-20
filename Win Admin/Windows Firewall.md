---
tags: [cyber, module3, windows, networking]
jqr: "Windows Defender Firewall: disabling via GUI (wf.msc), netsh advfirewall, and Set-NetFirewallProfile; plus adding an allow rule via netsh and New-NetFirewallRule"
---

# Windows Firewall

Two things here: how to turn the **Windows Defender Firewall** off (really just a lab/troubleshooting move), and the more useful skill of **adding a rule** to let specific traffic through. Three ways to do each, GUI, `netsh advfirewall`, and PowerShell. All firewall changes need an **elevated** shell.

## Quick reference
```cmd
netsh advfirewall show allprofiles                       :: view state
netsh advfirewall set allprofiles state off              :: DISABLE all profiles   (admin)
netsh advfirewall firewall add rule name="Allow RDP" dir=in action=allow protocol=TCP localport=3389
```
```powershell
Set-NetFirewallProfile -All -Enabled False               # DISABLE all profiles
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389
```
> I'd rather **add a rule** than disable the firewall. Disabling is a troubleshooting step, not a fix. Turning it *off* drops **all** filtering (every port open to anyone who can route to me), while a rule opens exactly one port to exactly the hosts I name. On the blue side a disabled firewall is a finding, but a scoped allow rule is just hygiene.

## How the firewall actually works
The firewall itself is a **stateful packet filter** in the kernel's Windows Filtering Platform: every packet gets checked against rules that match on direction, protocol, port, and address. *Stateful* means it remembers connections **I** started, so replies to my own outbound traffic are let back in without a rule. That's the key asymmetry: Windows **default-allows outbound** and **default-blocks unsolicited inbound**, which is why the rules I actually end up writing are almost always *inbound allow* rules poking a hole for a service I'm hosting.

The Defender Firewall has **three profiles**, and each network I connect to gets tagged with one:
- **Domain**: the NIC is on a network where a domain controller is reachable.
- **Private**: a trusted network I marked private (home/lab).
- **Public**: untrusted (cafe, hotel), and the most restrictive by default.

Rules are per-profile, so "it's blocked on Public but works on Private" is totally normal. When I'm chasing "can't reach the service," I check *which profile the adapter is on* and whether the rule even covers that profile. This is the Windows counterpart to [iptables](../IP%20Tables%20CentOS/iptables.md).

> **Why profiles exist:** it's one laptop but many networks with different trust levels. Windows auto-tags each connection with exactly one profile (*Domain* if it can reach the org's domain controller, *Private* if I marked it trusted, otherwise *Public*) and scopes rules to profiles so my relaxed home rules don't follow me onto café Wi-Fi. `Get-NetConnectionProfile` tells me which one is live right now.

## Disable via the GUI
- **`wf.msc`** (Win+R) → *Windows Defender Firewall with Advanced Security* → **Windows Defender Firewall Properties** → on each profile tab set **Firewall state = Off**.
- **Control Panel** → *System and Security* → *Windows Defender Firewall* → **Turn Windows Defender Firewall on or off** → *Turn off* for each network type.
- **Windows Security app** → *Firewall & network protection* → pick a profile → toggle **off**.

`wf.msc` is also where I see and edit **individual rules** in the GUI (Inbound Rules / Outbound Rules).

## Disable via cmd (`netsh advfirewall`)
```cmd
netsh advfirewall show allprofiles              :: view state of all profiles
netsh advfirewall set allprofiles state off     :: DISABLE on all profiles   (admin)
netsh advfirewall set allprofiles state on      :: re-enable
netsh advfirewall set publicprofile state off   :: just one profile
```
(run this on the Windows VM when I get a chance, but it matches the docs). `netsh advfirewall` is fully supported in 2026, not deprecated.

## Disable via PowerShell
```powershell
Get-NetFirewallProfile | Select Name,Enabled             # view state
Set-NetFirewallProfile -All -Enabled False               # DISABLE all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False   # explicit form
Set-NetFirewallProfile -All -Enabled True                # re-enable
```
`-All` and the explicit `-Profile Domain,Public,Private` do the same thing.

## Add a rule (preferred over disabling)
**cmd / netsh:**
```cmd
netsh advfirewall firewall add rule name="Allow RDP" dir=in action=allow protocol=TCP localport=3389
netsh advfirewall firewall add rule name="Allow Ping" dir=in action=allow protocol=icmpv4
netsh advfirewall firewall delete rule name="Allow RDP"
```
**PowerShell:**
```powershell
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389
New-NetFirewallRule -DisplayName "Allow Ping" -Direction Inbound -Action Allow -Protocol ICMPv4
Get-NetFirewallRule -DisplayName "Allow RDP"
Remove-NetFirewallRule -DisplayName "Allow RDP"
```
The four things a rule needs: a **name**, a **direction** (`dir=in`/`-Direction Inbound`), an **action** (allow/block), and the **match** (protocol + port). Add `-Profile` / `profile=` to scope it to Domain/Private/Public.

**Allow inbound on a specific port from one host only (tighter):**
```powershell
New-NetFirewallRule -DisplayName "Allow SMB from mgmt" -Direction Inbound -Action Allow `
  -Protocol TCP -LocalPort 445 -RemoteAddress 192.168.1.20
```
Scoping `-RemoteAddress` is the difference between "open to the world" and "open to one admin box."

## Gotchas
- **Disabling isn't the answer.** If the task is "let RDP through," add a rule. Only disable the firewall when I'm explicitly told to for troubleshooting.
- **Profiles are separate.** A rule on Private won't help a NIC that's on Public, so I check the active profile (`Get-NetConnectionProfile`).
- **Re-enable when done.** Leaving `state off` after a test is a finding against me.
- **ICMP (ping) isn't a port.** I allow it by protocol (`protocol=icmpv4` / `-Protocol ICMPv4`), not a `localport`. Ports are a TCP/UDP thing; ICMP is its own IP protocol with no ports at all, so there's nothing to put in `localport`.
- **`netsh advfirewall` vs old `netsh firewall`:** the bare `netsh firewall` context is legacy, so I use `netsh advfirewall`.
- Every change needs **Administrator**.

## References
- Configure Windows Firewall with command line: https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure-with-command-line
- netsh advfirewall firewall: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/netsh-advfirewall-firewall-control-firewall-behavior
- NetSecurity module (New-NetFirewallRule): https://learn.microsoft.com/en-us/powershell/module/netsecurity/

## Related
- [iptables](../IP%20Tables%20CentOS/iptables.md)
- [Windows Networking and Interfaces](Windows%20Networking%20and%20Interfaces.md)
- [Windows CLI and net Commands](Windows%20CLI%20and%20net%20Commands.md)
- [Network Security Devices](../Knowledge%20Req/Network%20Security%20Devices.md)
- [PsExec and Sysinternals](PsExec%20and%20Sysinternals.md)
