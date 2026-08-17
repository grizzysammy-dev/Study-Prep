---
tags: [jcu, module2, knowledge, networking]
jqr: "Describe cellular technology generations (1G-5G), core standards (GSM/CDMA/LTE/5G NR), subscriber/device identity (SIM/IMSI/IMEI), base stations, and cellular attacks (IMSI catchers, SS7)."
---

# Cellular Technologies

Generations 1G→5G, the standards and acronyms, how a subscriber and a device are identified, and the two attacks you're expected to name — **IMSI catchers** and **SS7 abuse**.

## TL;DR
- **Generations:** 1G analog → **2G GSM/CDMA** (digital + SMS + SIM) → **3G UMTS** (data) → **4G LTE** (all-IP, VoLTE) → **5G NR** (mmWave, low latency, slicing).
- **IMSI = subscriber** (who you are, on the SIM). **IMEI = device** (the handset). *IMSI = who; IMEI = what.*
- **Base station chain:** BTS (2G) → NodeB (3G) → eNodeB (4G) → **gNodeB (5G)**.
- **IMSI catcher / Stingray** = **rogue base station** — forces a **2G downgrade**, harvests IMSIs, enables tracking/interception.
- **SS7** = legacy inter-carrier signaling with **no origin authentication** → location tracking, call/SMS interception, **OTP theft**.

## Concept
Each cellular "generation" is a leap in what the air interface can carry: analog voice → digital voice+text → mobile data → all-IP broadband → ultra-low-latency/massive-IoT. Two things ride on top and matter for security: **how you're identified** (subscriber vs device) and **how weakly older generations authenticate the network** — which is exactly what the classic attacks exploit. *For the identity split, a plain analogy: the **IMSI** is your account number — tied to you, the subscriber, and living on the SIM; the **IMEI** is the serial number stamped on the handset (swap SIMs and it doesn't change). Steal the account number and you can impersonate the person; blocklist the serial number and you brick the stolen phone.*

## Generations (1G → 5G)

| Gen | Era | Core tech | Hallmark |
|---|---|---|---|
| **1G** | 1980s | Analog (AMPS) | Analog voice only; **no encryption**. |
| **2G** | 1990s | **GSM** (TDMA) & **CDMA** (IS-95) | **Digital** voice, **SMS**, **SIM** cards; weak/broken crypto (A5/1). |
| **3G** | 2000s | **UMTS** (WCDMA), CDMA2000 | Mobile **data** / broadband; mutual-auth improvements. |
| **4G** | 2010s | **LTE** / LTE-Advanced | **All-IP**, high-speed data, **VoLTE** (voice over LTE). |
| **5G** | 2019– | **5G NR** (New Radio) | sub-6 GHz + **mmWave**; ultra-low latency, massive IoT, **network slicing**. |

**Key terms:** **GSM** (dominant 2G standard) · **CDMA** (competing 2G/3G air interface) · **UMTS** (= 3G) · **LTE** (= 4G) · **5G NR** (5G radio) · **VoLTE** (carries voice as data over 4G/5G, replacing 2G/3G circuit-switched fallback).

## Identity & hardware
- **SIM — Subscriber Identity Module:** smartcard holding subscriber credentials/keys (**eSIM** = embedded).
- **IMSI — International Mobile Subscriber Identity:** uniquely identifies the **subscriber** (stored on the SIM). Sensitive → 5G encrypts it as the **SUCI**.
- **IMEI — International Mobile Equipment Identity:** uniquely identifies the **device/handset** (used to blocklist stolen phones).

> **The distinction to quote:** *IMSI = who you are (subscriber); IMEI = what device you use (handset).*

**Base station naming across generations:** **BTS** (2G) → **NodeB** (3G) → **eNodeB / eNB** (4G LTE) → **gNodeB / gNB** (5G). The base station is the radio access node bridging the handset and the core network.

## Security concerns
- **IMSI catchers / "Stingray"** — a **rogue base station** (fake cell tower) a nearby phone attaches to. It forces a **downgrade to weak 2G**, harvests **IMSIs**, and enables **tracking and interception**. It works because pre-5G devices authenticate the network *weakly* (the phone proves itself to the tower, but not vice-versa). *In plain terms, the phone shows ID to a caller claiming to be the bank but never asks the caller to prove they're the bank — a Stingray just shouts "I'm the tower" louder than the real one.*
- **SS7 (Signaling System 7)** — the legacy inter-carrier signaling protocol, built for a trusted-operator world with **no origin authentication**. Abuse enables **location tracking, call/SMS interception, and OTP theft** across networks — which is why **SMS-based 2FA is weak**. **Diameter** (the 4G signaling successor) inherits similar risks. *SS7 runs on the honor system: it was built when every carrier on it was assumed trustworthy — like a staff-only corridor with no locks because "everyone back here is staff." Once anyone gets into that corridor, the whole assumption collapses.*

## Exam tips & gotchas
- **IMSI vs IMEI** is the guaranteed trap: **subscriber vs device.** Mnemonic — IMS**I** = **I**dentity (subscriber/SIM); IM**E**I = **E**quipment (device).
- Map generation ↔ standard fast: **2G = GSM/CDMA, 3G = UMTS, 4G = LTE, 5G = 5G NR.**
- **IMSI catcher = rogue base station whose trick is the 2G downgrade.** Say "downgrade" — that's the mechanism.
- **SS7's root flaw = no authentication between carriers** → interception/tracking/OTP theft. It's why SMS OTP is discouraged.
- **5G protects the IMSI** by encrypting it as the **SUCI** — a concrete improvement over the plaintext-IMSI eras that IMSI catchers exploited.
- Base-station names in order: **BTS → NodeB → eNodeB → gNodeB.**

## References
- Daniel Miessler — *Cellular Study Guide*: https://danielmiessler.com/study/cellular
- 3GPP (the cellular standards body): https://www.3gpp.org
- CISA — guidance on SS7/Diameter and SMS-based authentication risks: https://www.cisa.gov

## Related
- [802.11 Wireless](802.11%20Wireless.md)
- [OSI Model](../Linux%20Admin/OSI%20Model.md)
- [Network Security Devices](Network%20Security%20Devices.md)
