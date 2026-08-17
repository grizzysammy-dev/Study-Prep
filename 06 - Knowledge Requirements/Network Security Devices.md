---
tags: [jcu, module2, knowledge, networking]
jqr: "Describe network security devices and controls (firewall/NGFW, IDS vs IPS, EDR/XDR, PSP, proxy, WAF, SIEM, DLP, NAC, honeypot) and detection/prevention techniques (signature vs anomaly, segmentation, allow/deny-listing)."
---

# Network Security Devices

The device/control zoo and the detection techniques behind them. As a defender you already run half of these — this note nails the crisp definitions and the offensive term **PSP** the JQR expects you to state plainly.

## TL;DR
- **IDS watches; IPS acts.** IDS = passive/out-of-band alerting; IPS = inline, can drop traffic.
- **NGFW** = firewall + L7 app awareness + user-ID + integrated IPS + TLS inspection.
- **EDR** = endpoint agent (detect/hunt/respond on the host); **XDR** = correlates endpoint + network + email + cloud + identity.
- **PSP = Personal Security Product** = the endpoint's host AV / endpoint-protection stack an *operator must evade* (offensive/DoD term).
- **Signature** = known-bad, precise, blind to 0-day. **Anomaly/behavioral** = catches unknown, more false positives.
- **Allow-list (default-deny) beats deny-list.** **Segmentation** limits lateral movement/pivoting.

## Concept
Two questions organize this whole topic: **where does the control sit** (network boundary, endpoint host, or across the estate) and **how does it decide what's bad** (matching known signatures vs modelling normal and flagging deviations). Get those two axes and every device below slots in.

## Devices / controls

- **Firewall** — enforces an allow/deny policy at network boundaries.
  - *Stateful firewall* — tracks connection state (the TCP session table), auto-allowing return traffic for established flows. Beyond simple stateless packet filtering.
  - *NGFW (Next-Gen Firewall)* — adds **application awareness (L7)**, user-ID, integrated **IPS**, TLS inspection, and threat-intel feeds.
- **IDS vs IPS** — **IDS (Intrusion Detection System)** is **passive / out-of-band**: it *detects and alerts* on a copy of traffic (SPAN/tap). **IPS (Intrusion Prevention System)** is **inline / active**: it can *block/drop* malicious traffic in real time. → *"IDS watches; IPS acts."*
- **EDR / XDR** — **EDR (Endpoint Detection & Response)**: host agent recording process/file/network telemetry for detection, threat-hunting, and response (isolate/kill/roll-back). **XDR (Extended Detection & Response)**: correlates across endpoint **+ network + email + cloud + identity** for unified detection/response.
- **PSP — Personal Security Product.** State it plainly: **PSP = the endpoint's host AV / endpoint-protection product(s).** In an **offensive / DoD red-team context**, "PSP" is the operator's term for the host-based protection they must be *aware of and evade* — **AV / anti-malware / EDR / host firewall / HIPS** on the target endpoint. Defensively it's just your endpoint stack; offensively it's the thing that flags tooling — hence tradecraft like **AV evasion** and **AMSI bypass**.
- **Proxy** — an intermediary for requests. *Forward proxy* controls/monitors **outbound** user traffic (URL filtering, caching, egress control). *Reverse proxy* fronts servers (load-balancing, TLS termination, hides origin).
- **WAF — Web Application Firewall.** An **L7 filter for HTTP(S)** targeting **web attacks** (SQLi/XSS/traversal) via signatures + anomaly rules (e.g. the OWASP Core Rule Set). Mitigates OWASP Top 10 classes — see [Common Software Vulnerabilities](Common%20Software%20Vulnerabilities.md).
- **SIEM — Security Information & Event Management.** Central **log aggregation, correlation, alerting, and retention** across the estate — the analyst's single pane and the backbone of a SOC.
- **DLP — Data Loss Prevention.** Detects/blocks **sensitive-data exfiltration** (PII, secrets) across endpoint, network, and cloud via content inspection.
- **NAC — Network Access Control.** Gates devices joining the network by **posture/identity** (often **802.1X** — see [802.11 Wireless](802.11%20Wireless.md)), quarantining non-compliant hosts.
- **Honeypot** — a **decoy** system/service with no legitimate use; *any* interaction is inherently suspicious → high-fidelity detection + attacker intel. (**Honeytokens** = the data-object equivalent — a fake credential/file whose use trips an alarm.)

## Detection / prevention techniques

- **Signature-based** — matches **known-bad** patterns (IOCs, rules). Precise, low false-positive — but **blind to novel / 0-day** threats (see [Zero-Day Exploits](Zero-Day%20Exploits.md)).
- **Anomaly / heuristic / behavioral** — models "normal," flags deviations (unusual beaconing, odd process behavior). Catches **unknown** threats but generates **more false positives**; underpins UEBA / ML detection.
- **Network segmentation** (VLANs, micro-segmentation, zero-trust) — contains blast radius, limits **lateral movement / pivoting** (see [Pivoting and Tunneling](Pivoting%20and%20Tunneling.md)), enforces least-privilege reachability.
- **Allow-listing vs deny-listing** — an **allow-list** (default-deny; only approved apps/IPs run) is **stronger** than a **deny-list** (block known-bad), because it resists *unknown* threats too. Default-deny is the goal.
- **Logging & monitoring** — comprehensive, **time-synced, centralized** logs feeding a SIEM: the precondition for detection, IR, and forensics (maps to OWASP A09).

## Exam tips & gotchas
- **IDS vs IPS** is the guaranteed question: **passive detect/alert vs inline block**. IPS sits *in* the traffic path; IDS sits *beside* it.
- **Say what PSP is without hedging:** **Personal Security Product = host AV/endpoint protection** the operator must evade. Graders want the expansion *and* the plain-English meaning.
- **Signature can't catch a true 0-day** (no signature exists yet) — that's the pairing case for anomaly/behavioral detection.
- **Allow-list > deny-list** — if asked "which is more secure," it's the default-deny allow-list.
- **NGFW vs stateful firewall:** the differentiator is **L7 application awareness** (plus user-ID, integrated IPS, TLS inspection).
- **EDR = endpoint only; XDR = cross-domain correlation.** Don't use them interchangeably.

## References
- MITRE ATT&CK (mitigations & detections): https://attack.mitre.org
- OWASP Core Rule Set (WAF rules): https://coreruleset.org
- NIST SP 800-94 — Guide to IDS/IPS: https://csrc.nist.gov/pubs/sp/800/94/final
- CISA — Network segmentation guidance: https://www.cisa.gov

## Related
- [Cyber Kill Chain](Cyber%20Kill%20Chain.md)
- [Pivoting and Tunneling](Pivoting%20and%20Tunneling.md)
- [iptables](../03%20-%20Linux%20Skills/iptables.md)
- [Zero-Day Exploits](Zero-Day%20Exploits.md)
- [Common Software Vulnerabilities](Common%20Software%20Vulnerabilities.md)
