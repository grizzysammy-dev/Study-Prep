---
tags: [jcu, module3, networking]
jqr: "Module 3 — the 7-layer OSI model: layers, protocols, devices, mnemonic, and mapping to TCP/IP"
---

# OSI Model

A 7-layer map of how network communication is split into jobs. You need it to answer "what layer is this?" fast and to reason about *where* a problem lives — the defender's real payoff is knowing which tool checks which layer.

## TL;DR
- **7 layers, top→bottom:** Application, Presentation, Session, Transport, Network, Data Link, Physical.
- **Mnemonic (7→1):** *All People Seem To Need Data Processing.*
- **The two address layers:** **L3 = IP** (logical, routable) vs **L2 = MAC** (physical, local link). **ARP** translates between them.
- Data going **out** travels 7→1 (each layer **encapsulates** the one above); coming **in**, 1→7 (unwrapping).

## Concept
The OSI model is a **teaching** model: it breaks one network conversation into seven independent jobs so you can talk about each in isolation. Each layer adds its own header as data goes down the stack (**encapsulation**) and strips it on the way up. Real Internet traffic runs the leaner **TCP/IP** model (below), which merges several OSI layers — but interviews, docs, and exam questions still speak in OSI numbers.

## The 7 layers
| # | Layer | Job | Protocols / data unit | Devices |
|---|---|---|---|---|
| **7** | **Application** | What the user/app sees | HTTP(S), DNS, SSH, FTP, SMTP, DHCP — *data* | Host, proxy, L7/app firewall |
| **6** | **Presentation** | Format, **encryption**, encoding, compression | TLS/SSL, ASCII/Unicode, JPEG, JSON | (software) |
| **5** | **Session** | Set up / maintain / tear down conversations | Sockets, RPC, NetBIOS, TLS session mgmt | (software) |
| **4** | **Transport** | End-to-end delivery, ports, reliability | **TCP** (reliable, handshake) / **UDP** (fast, best-effort) — *segments* | Firewall, load balancer (L4) |
| **3** | **Network** | Logical addressing + **routing** between networks | **IP**, ICMP (ping), OSPF/BGP — *packets* | **Router**, L3 switch |
| **2** | **Data Link** | Local delivery on one link via **MAC** | Ethernet, ARP, Wi-Fi (802.11), VLAN — *frames* | **Switch**, bridge, NIC |
| **1** | **Physical** | Actual bits on the medium | Cables, fiber, radio, voltages — *bits* | Hub, repeater, cable, NIC |

**Data unit by layer (worth memorising):** L4 = **segments**, L3 = **packets**, L2 = **frames**, L1 = **bits**.

**Mnemonics:**
- Top→bottom (7→1): **"All People Seem To Need Data Processing."**
- Bottom→top (1→7): **"Please Do Not Throw Sausage Pizza Away."**

## Defender's cheat notes — what breaks where
| Layer | Symptom | Check with |
|---|---|---|
| **L1** | Cable unplugged / no link light | `ip link` → `state DOWN`, no `LOWER_UP` |
| **L2** | MAC/ARP/switch issues, ARP spoofing | `ip neigh` (the ARP table) |
| **L3** | Wrong IP/subnet/gateway/route; ping-by-IP fails | `ip a`, `ip route` |
| **L4** | Port blocked / service not listening | `ss -tulpn`, `nc -zv`; firewall rules act here (and L3) |
| **L7** | DNS not resolving / app not talking | `dig`/`nslookup`, `curl -v` ("it's always DNS") |

## TCP/IP model — the 4-layer version the Internet actually uses
OSI is the teaching model; real networks run the **TCP/IP** model, which collapses OSI's layers:

| TCP/IP layer | Maps to OSI | Examples |
|---|---|---|
| **Application** | 7 + 6 + 5 | HTTP, DNS, SSH, TLS |
| **Transport** | 4 | TCP, UDP (ports) |
| **Internet** | 3 | IP, ICMP (routing) |
| **Link / Network Access** | 2 + 1 | Ethernet, Wi-Fi, MAC, cabling |

> **The two "address" layers to never confuse:** **L2 = MAC** (physical, fixed per NIC, local link only, shown as `link/ether …`) vs **L3 = IP** (logical, routable across networks, shown as `inet …`). **ARP** is the L2↔L3 translator: "who has this IP? tell me your MAC."

## Exam tips & gotchas
- Know the layer **number both ways** — name→number and number→name — plus one protocol and one device per layer.
- **Encryption/TLS is L6** (presentation); **ports and TCP/UDP are L4**; **routing/IP is L3**; **switching/MAC is L2**. These four are the most-asked.
- **Router = L3, Switch = L2, Hub = L1.** A "L3 switch" routes, so it straddles 2–3.
- Data units: **segment (4) → packet (3) → frame (2) → bits (1)**.
- TCP/IP folds OSI 5+6+7 into one **Application** layer and 1+2 into **Link** — expect a "map OSI to TCP/IP" question.
- **ARP = L2↔L3 glue.** Pick the address layers apart: MAC local/fixed, IP routable/logical.

## References
- RFC 1122 (TCP/IP layering): https://www.rfc-editor.org/rfc/rfc1122
- Cloudflare OSI explainer: https://www.cloudflare.com/learning/ddos/glossary/open-systems-interconnection-model-osi/
- `man 7 arp`

## Related
- [Interfaces IPs and Routing](Interfaces%20IPs%20and%20Routing.md)
- [Tcpdump](../02%20-%20Recon%20and%20Network%20Tools/Tcpdump.md)
- [Network Security Devices](../06%20-%20Knowledge%20Requirements/Network%20Security%20Devices.md)
- [iptables](iptables.md)
- [Nmap](../02%20-%20Recon%20and%20Network%20Tools/Nmap.md)
