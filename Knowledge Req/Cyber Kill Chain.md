---
tags: [cyber, module2, knowledge]
jqr: "Describe the Lockheed Martin Cyber Kill Chain (7 stages) with a defensive countermeasure at each stage; contrast it with MITRE ATT&CK and the Unified Kill Chain."
---

# Cyber Kill Chain

Lockheed Martin's 7-stage model of how an intrusion actually unfolds. The JQR verb here is *describe*, so I'm writing this one to be quoted straight back: the seven stages in order, one defensive countermeasure at each, and how it stacks up against ATT&CK and the Unified Kill Chain.

## The gist
- Seven stages, in order: Reconnaissance → Weaponization → Delivery → Exploitation → Installation → Command & Control (C2) → Actions on Objectives.
- The whole point of the model: the attacker has to complete **all seven** stages to win, but I only have to **break one link** to stop the intrusion.
- Courses of Action, one set per stage: **Detect · Deny · Disrupt · Degrade · Deceive · Destroy.**
- One-line contrasts: Kill Chain = a linear intrusion *story* (APT/malware). **MITRE ATT&CK** = a non-linear *matrix* of real observed tactics and techniques (and it's where the Mxxxx mitigations live). **Unified Kill Chain** = 18 phases, and it explicitly adds lateral movement / pivoting.

## How I picture it
The way I keep it straight is a line of dominoes that has to topple *in order*: case the target, build the payload, deliver it, pop the box, dig in, call home, then act on the goal. The attacker needs every domino to fall. I win by pulling out any single one. That asymmetry is the entire idea and it's the defender's edge: I don't have to catch everything, just one thing, as early as I can.

Lockheed adapted the military "kill chain" (find, fix, track, target, engage, assess) to network intrusions back in 2011. The insight is defensive, not offensive. Because a successful intrusion is a **sequence** where each stage depends on the one before it, I don't have to be perfect, I have to break the chain **once**, as early as possible. It's an **intrusion-centric, linear** model, and it fits APT-style campaigns that push malware through a perimeter. That linearity is also its main weakness, which is what the contrasts further down are about.

Order mnemonic I use: **R**eal **W**eapons **D**estroy **E**very **I**ntruder's **C2** **A**dvantage.

## The 7 stages and how I break each one

| # | Stage | What the attacker is doing | Defensive countermeasure (example) |
|---|-------|-----------------------------|-------------------------------------|
| 1 | **Reconnaissance** | Harvests targets - OSINT, email/employee lists, domains, exposed services. | Attack-surface reduction; scrub public metadata; monitor for scanning; web-log analytics. |
| 2 | **Weaponization** | Couples an exploit with a backdoor into a deliverable payload (malicious PDF, Office macro). | Can't observe directly; harden using threat intel on weaponizer toolmarks + malware analysis. |
| 3 | **Delivery** | Transmits the weapon - phishing email, malicious link/USB, watering-hole. | Email filtering/sandboxing, web proxy, user-awareness training, disable macros, block removable media. |
| 4 | **Exploitation** | Triggers the exploit to run code (software, OS, or human vulnerability). | Patch management, exploit mitigations (DEP/ASLR/CFG), least privilege, endpoint hardening. |
| 5 | **Installation** | Installs persistence - implant, service, Run key, webshell. | EDR, application allow-listing, file-integrity monitoring, detect autoruns, HIPS. |
| 6 | **Command & Control (C2)** | Opens a channel out to the operator for hands-on control. | Egress filtering, DNS/proxy inspection, block known C2, segmentation, detect beaconing. |
| 7 | **Actions on Objectives** | Achieves the goal - exfiltration, ransomware, lateral movement, destruction. | DLP, segmentation, honeytokens, anomaly detection, immutable backups, rapid IR. |

Line I want to land in the board: *"The defender only has to break one link; the attacker has to complete all seven."*

## The Courses of Action grid
Lockheed pairs the seven stages against six defensive actions (**Detect, Deny, Disrupt, Degrade, Deceive, Destroy**) to make a grid I can fill in with the specific control that applies at each stage. So I *Deny* Delivery with an email proxy, *Disrupt* C2 with egress filtering, *Deceive* Actions-on-Objectives with honeytokens. The grid is the practical payoff of the model: it turns "break the chain" into an actual checklist of where I can act.

## How it differs from ATT&CK and the UKC
**MITRE ATT&CK** isn't a linear chain at all. It's a **knowledge base / matrix** of adversary **Tactics** (the "why," roughly 14 columns like Initial Access, Persistence, Lateral Movement, Exfiltration), **Techniques / Sub-techniques** (the "how," the Txxxx IDs), plus documented **Mitigations (Mxxxx)** and **Detections**. It describes *real observed behaviour* at way higher post-compromise granularity than the Kill Chain's single "Actions on Objectives" bucket. And the JQR points at ATT&CK for mitigations, so I need to remember that ATT&CK is where the mitigation catalogue actually lives. My rule of thumb: Kill Chain is the strategy/story, ATT&CK is the encyclopedic detail.

**Unified Kill Chain (UKC)** is Paul Pols (2017, updated 2022) merging the Kill Chain with ATT&CK into **18 phases** grouped in three arcs: **In** (gain a foothold), **Through** (network propagation, so **pivoting** and lateral movement), and **Out** (act on objectives). It fixes the two big Lockheed gaps: it isn't strictly perimeter/malware-centric, and it **explicitly models lateral movement and pivoting inside the network**, which is the part the linear chain crams into a single final stage.

## Gotchas I need to watch
- If someone just says "the kill chain" with no qualifier, they mean **Lockheed's 7 stages**, and I should recite them **in order**.
- Don't confuse **Weaponization** (building the payload, offline, attacker-side, invisible to me) with **Delivery** (sending it, which is the first stage I can actually filter).
- **C2 is stage 6, not the last one.** Actions on Objectives (stage 7) is the payoff. Catching a beacon is a stage-6 win.
- Know which model owns mitigations: **ATT&CK (Mxxxx)**. The Kill Chain tells me *where* to act, ATT&CK gives me the specific technique-level fix.
- **UKC's headline addition is lateral movement / pivoting.** That's the phrase graders are listening for.

## Sources
- Lockheed Martin, *The Cyber Kill Chain*: https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html
- MITRE ATT&CK: https://attack.mitre.org
- Unified Kill Chain (Paul Pols): https://www.unifiedkillchain.com

## Related
- [Common Software Vulnerabilities](Common%20Software%20Vulnerabilities.md)
- [Network Security Devices](Network%20Security%20Devices.md)
- [Pivoting and Tunneling](Pivoting%20and%20Tunneling.md)
- [Vulnerability Sources (CVE CWE MITRE)](Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md)
- [Privilege Escalation Concepts](Privilege%20Escalation%20Concepts.md)
