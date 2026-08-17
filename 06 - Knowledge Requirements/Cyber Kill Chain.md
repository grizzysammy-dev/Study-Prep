---
tags: [jcu, module2, knowledge]
jqr: "Describe the Lockheed Martin Cyber Kill Chain (7 stages) with a defensive countermeasure at each stage; contrast it with MITRE ATT&CK and the Unified Kill Chain."
---

# Cyber Kill Chain

Lockheed Martin's 7-stage model of how an intrusion unfolds. The JQR verb is *describe*, so this note is built to be quoted: the seven stages in order, one defensive countermeasure per stage, and how it differs from ATT&CK and the Unified Kill Chain.

## TL;DR
- **7 stages, in order:** Reconnaissance → Weaponization → Delivery → Exploitation → Installation → Command & Control (C2) → Actions on Objectives.
- **The whole thesis:** the attacker must complete **all seven** stages to win; the defender only has to **break one link** to stop the intrusion.
- **Courses of Action (per stage):** **Detect · Deny · Disrupt · Degrade · Deceive · Destroy.**
- **Contrast in one line each:** Kill Chain = linear intrusion *story* (APT/malware). **MITRE ATT&CK** = non-linear *matrix* of real observed tactics & techniques (**and where the Mxxxx mitigations live**). **Unified Kill Chain** = 18 phases, explicitly adds lateral movement / pivoting.

## Concept
Lockheed Martin adapted the military "kill chain" (find → fix → track → target → engage → assess) to network intrusions in 2011. The insight is defensive, not offensive: because a successful intrusion is a **sequence** where each stage depends on the last, you don't have to be perfect — you have to break the chain **once**, as early as possible. It is an **intrusion-centric, linear** model, best fitted to APT-style campaigns that deliver malware through a perimeter. That linearity is also its main limitation (see the contrasts below).

Handy order mnemonic: **R**eal **W**eapons **D**estroy **E**very **I**ntruder's **C2** **A**dvantage.

## The 7 stages + a defensive countermeasure for each

| # | Stage | What the attacker is doing | Defensive countermeasure (example) |
|---|-------|-----------------------------|-------------------------------------|
| 1 | **Reconnaissance** | Harvests targets — OSINT, email/employee lists, domains, exposed services. | Attack-surface reduction; scrub public metadata; monitor for scanning; web-log analytics. |
| 2 | **Weaponization** | Couples an exploit with a backdoor into a deliverable payload (malicious PDF, Office macro). | Can't observe directly; harden using threat intel on weaponizer toolmarks + malware analysis. |
| 3 | **Delivery** | Transmits the weapon — phishing email, malicious link/USB, watering-hole. | Email filtering/sandboxing, web proxy, user-awareness training, disable macros, block removable media. |
| 4 | **Exploitation** | Triggers the exploit to run code (software, OS, or human vulnerability). | Patch management, exploit mitigations (DEP/ASLR/CFG), least privilege, endpoint hardening. |
| 5 | **Installation** | Installs persistence — implant, service, Run key, webshell. | EDR, application allow-listing, file-integrity monitoring, detect autoruns, HIPS. |
| 6 | **Command & Control (C2)** | Opens a channel out to the operator for hands-on control. | Egress filtering, DNS/proxy inspection, block known C2, segmentation, detect beaconing. |
| 7 | **Actions on Objectives** | Achieves the goal — exfiltration, ransomware, lateral movement, destruction. | DLP, segmentation, honeytokens, anomaly detection, immutable backups, rapid IR. |

**The line to quote:** *"The defender only has to break one link; the attacker has to complete all seven."*

## Courses of Action matrix
Lockheed pairs the seven stages against six defensive actions — **Detect, Deny, Disrupt, Degrade, Deceive, Destroy** — producing a grid you can populate with the specific control that applies at each stage (e.g. *Deny* Delivery with an email proxy; *Disrupt* C2 with egress filtering; *Deceive* Actions-on-Objectives with honeytokens). The grid is the practical output of the model: it turns "break the chain" into a checklist of where you can act.

## Contrast with other models

**MITRE ATT&CK** — *not* a linear chain. It is a **knowledge base / matrix** of adversary **Tactics** (the "why" — ~14 columns such as Initial Access, Persistence, Lateral Movement, Exfiltration), **Techniques / Sub-techniques** (the "how" — Txxxx IDs), plus documented **Mitigations (Mxxxx)** and **Detections**. It describes *real observed behaviour* at far higher post-compromise granularity than the Kill Chain's single "Actions on Objectives" bucket. **The JQR points at ATT&CK for mitigations** — remember that ATT&CK is where the mitigation catalogue lives. Rule of thumb: **Kill Chain = the strategy/story; ATT&CK = the encyclopedic detail.**

**Unified Kill Chain (UKC)** — Paul Pols (2017, updated 2022) merges the Kill Chain with ATT&CK into **18 phases** grouped in three arcs: **In** (gain a foothold), **Through** (network propagation / **pivoting** and lateral movement), **Out** (act on objectives). It fixes the two big Lockheed gaps: it isn't strictly perimeter/malware-centric, and it **explicitly models lateral movement and pivoting inside the network** — the part the linear chain compresses into a single final stage.

## Exam tips & gotchas
- If asked for "the" kill chain unqualified, they mean **Lockheed Martin's 7 stages** — recite them **in order**.
- Don't confuse **Weaponization** (build the payload — offline, attacker-side, undetectable to you) with **Delivery** (send it — the first stage you can actually filter).
- **C2 is stage 6, not the last** — Actions on Objectives (stage 7) is the payoff. A beaconing detection is a stage-6 win.
- Know *which model owns mitigations*: **ATT&CK (Mxxxx)**. The Kill Chain gives you *where* to act; ATT&CK gives you the specific technique-level fix.
- **UKC's headline addition = lateral movement / pivoting** — the phrase graders look for.

## References
- Lockheed Martin — *The Cyber Kill Chain*: https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html
- MITRE ATT&CK: https://attack.mitre.org
- Unified Kill Chain (Paul Pols): https://www.unifiedkillchain.com

## Related
- [Common Software Vulnerabilities](Common%20Software%20Vulnerabilities.md)
- [Network Security Devices](Network%20Security%20Devices.md)
- [Pivoting and Tunneling](Pivoting%20and%20Tunneling.md)
- [Vulnerability Sources (CVE CWE MITRE)](Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md)
- [Privilege Escalation Concepts](../05%20-%20Metasploit%20and%20Exploitation/Privilege%20Escalation%20Concepts.md)
