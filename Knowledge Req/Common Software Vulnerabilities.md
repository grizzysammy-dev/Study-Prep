---
tags: [jcu, module2, knowledge]
jqr: "Describe common software vulnerability classes (memory-corruption and web/app-logic), the memory-corruption-to-code-execution idea, and map them to OWASP Top 10 (2025, cross-ref 2021) and CWE."
---

# Common Software Vulnerabilities

The vulnerability zoo you're expected to name and explain, split into **memory-corruption** (native-code) bugs and **web / application-logic** bugs, each mapped to its **CWE** and its **OWASP Top 10** slot. The JQR explicitly names **use-after-free, heap overflow, and SQL injection** — those are anchored inside the full set below.

## TL;DR
- **Vulnerability** = the flaw. **Exploit** = the code/technique that abuses it. (Full treatment in [Zero-Day Exploits](Zero-Day%20Exploits.md).)
- **JQR-named three:** **Use-after-free** (CWE-416), **Heap overflow** (CWE-122), **SQL injection** (CWE-89).
- **Fix mantras:** SQLi → **parameterized queries / prepared statements**; XSS → context-aware output encoding; XXE → **disable DTD/external entities**; CSRF → **anti-CSRF token + SameSite cookies**; deserialization → don't deserialize untrusted data.
- **Memory bug → code execution pipeline:** corrupt a value the CPU trusts (return address / function pointer / vtable) → **ROP** to bypass **DEP/NX** → run **shellcode**. Broken by **ASLR, stack canaries, CFG/CET**.
- **OWASP: lead with 2025** (Injection is now **A05**; SSRF no longer standalone) — but be ready for a **2021** answer key (Injection was A03).

## Concept
A **vulnerability** is a flaw — in code, design, or configuration — that can be abused to violate confidentiality, integrity, or availability. Two broad families matter for this JQR:

- **Memory-corruption / native-code bugs** live in C/C++-style software with manual memory management. *Picture memory as a row of labeled mailboxes: a buffer overflow stuffs so much into one box that it spills into the next — and if that neighbor holds the "where do I go next?" address the CPU trusts, you've just steered the program.* They let an attacker overwrite memory the program didn't intend to expose, and — in the worst case — hijack execution. This is the family behind most browser/kernel "0-click" exploits.
- **Web / application-logic bugs** live in how an app handles untrusted input and trust boundaries. They rarely need memory tricks; they abuse the app doing exactly what it was (badly) told to do — *you're not picking the lock, you're tricking the doorman who trusts whatever you tell him.*

## Memory-corruption / native-code bugs

| Vulnerability | Plain explanation | CWE |
|---|---|---|
| **Buffer overflow — stack** | Write past a fixed-size stack buffer, overwriting adjacent data — classically the **saved return address** — to redirect execution. | CWE-121 (parent CWE-787 out-of-bounds write) |
| **Buffer overflow — heap** *(JQR)* | Overflow a heap-allocated buffer, corrupting **heap metadata or adjacent objects** (function pointers / C++ vtables) to gain control. | CWE-122 |
| **Use-after-free (UAF)** *(JQR)* | Program keeps using a pointer to memory it already `free()`d; the attacker reallocates that slot with a controlled fake object/vtable → control-flow hijack. Dominant browser/kernel bug class. | CWE-416 (see also CWE-415 double-free) |
| **Integer overflow / underflow** | Arithmetic wraps past the type's max/min; a size calc becomes tiny or huge → under-allocation and a later overflow. | CWE-190 / CWE-191 |
| **Format string** | Untrusted input used as the format argument (`printf(user)`); `%x` / `%n` leak memory or write to arbitrary addresses. | CWE-134 |
| **Race condition / TOCTOU** | Time-Of-Check to Time-Of-Use gap: state (e.g. a file's identity via a symlink) changes between the check and the use, defeating the check. | CWE-362 / CWE-367 |

### How a memory bug becomes code execution (high level — the *idea*, not a weapon)
> **Memory corruption → control-flow hijack → payload.** A bug lets the attacker overwrite a value the CPU trusts for control flow — a **return address**, a **function pointer**, or a **C++ vtable** pointer — and point it at code they influence. Because modern OSes mark data pages non-executable (**DEP/NX**), the attacker can't just drop shellcode and jump to it. So they first use **ROP (Return-Oriented Programming)** — chaining tiny snippets ("gadgets") of the program's own existing code — to disable protections or allocate executable memory, then run **shellcode** (a small position-independent payload). Defences that break this chain: **ASLR** (randomizes addresses so gadgets can't be located), **stack canaries** (detect stack overwrites), **CFG/CET** (control-flow integrity), and **DEP/NX**. The exam wants this pipeline described conceptually — not a working exploit.

## Web / application-logic bugs

| Vulnerability | Plain explanation | CWE | OWASP 2025 |
|---|---|---|---|
| **SQL injection (SQLi)** *(JQR)* | Untrusted input concatenated into a SQL query alters query logic — read/modify/delete data, sometimes RCE. Fix: **parameterized queries**. | CWE-89 | A05 Injection |
| **Command injection** | Input passed to an OS shell (`system()`) runs attacker commands with the app's privileges. | CWE-78 | A05 Injection |
| **Cross-Site Scripting (XSS)** | Attacker script runs in the victim's browser in the site's origin (stored/reflected/DOM). Steals sessions, rewrites pages. | CWE-79 | A05 Injection |
| **Cross-Site Request Forgery (CSRF)** | Tricks an authenticated victim's browser into sending an unwanted state-changing request. Fix: anti-CSRF tokens, SameSite cookies. | CWE-352 | (Broken Access Control) |
| **Server-Side Request Forgery (SSRF)** | App is coerced into making server-side requests to attacker-chosen URLs — reaches internal services / cloud metadata (`169.254.169.254`). | CWE-918 | Folded into Access Control / Injection in 2025* |
| **Path / directory traversal** | `../` sequences escape the intended directory to read/write arbitrary files (`/etc/passwd`). | CWE-22 | A05 Injection (Broken Access Control) |
| **Insecure deserialization** | Untrusted serialized objects get deserialized, instantiating attacker-controlled objects → RCE / logic abuse. | CWE-502 | A08 Software or Data Integrity Failures |
| **XML External Entity (XXE)** | XML parser resolves external entities → file disclosure, SSRF, DoS. Fix: **disable DTD/external entities**. | CWE-611 | A05 Injection |

\* In OWASP **2025**, SSRF lost its standalone Top-10 slot; the community data folded it under access-control/injection, though it remains a tracked weakness (CWE-918).

> **The one idea behind "injection":** SQLi, command injection, XSS, XXE, and traversal are the *same* mistake in different clothes — untrusted **data** bleeds into a **control channel** (a SQL query, a shell command, an HTML page, an XML parser, a file path) and the interpreter can't tell your data from its own instructions. That's why the fix always has the same shape: keep data and code in separate lanes. **Parameterized queries** kill SQLi precisely because they hand the database the query and the values *separately*, so user input can never *become* SQL.

## Map to OWASP Top 10 — 2025 (current) vs 2021 (still widely cited)

| Rank | **OWASP Top 10:2025 (final)** | OWASP Top 10:2021 |
|---|---|---|
| A01 | **Broken Access Control** | Broken Access Control |
| A02 | **Security Misconfiguration** ▲ | Cryptographic Failures |
| A03 | **Software Supply Chain Failures** ★ (expands "Vulnerable & Outdated Components") | Injection |
| A04 | **Cryptographic Failures** | Insecure Design |
| A05 | **Injection** (SQLi, XSS, cmd, XXE, traversal) | Security Misconfiguration |
| A06 | **Insecure Design** | Vulnerable and Outdated Components |
| A07 | **Authentication Failures** (renamed) | Identification and Authentication Failures |
| A08 | **Software or Data Integrity Failures** | Software and Data Integrity Failures |
| A09 | **Security Logging and Alerting Failures** (renamed) | Security Logging and Monitoring Failures |
| A10 | **Mishandling of Exceptional Conditions** ★ NEW | Server-Side Request Forgery (SSRF) |

★ = new in 2025 (Software Supply Chain Failures; Mishandling of Exceptional Conditions). ▲ = moved up.

### CWE vs OWASP — don't conflate them
- **CWE** (Common Weakness Enumeration, MITRE) is the exhaustive **taxonomy of weakness *types*** — 900+ entries, e.g. CWE-89 for SQLi. It names the *category of flaw*.
- **OWASP Top 10** is a **prioritized awareness list** of the ten most critical **web** risk *categories*, each mapping to a cluster of CWEs. It's about attention, not completeness.
- Also worth knowing: the annual **CWE Top 25 Most Dangerous Software Weaknesses** — a ranked CWE list, distinct from OWASP's web-focused ten.
- Naming and scoring of specific instances (CVE, NVD, CVSS) is covered in [Vulnerability Sources (CVE CWE MITRE)](Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md).

## Real-world anchor
**CISA AA21-209A** ("Top Routinely Exploited Vulnerabilities," Jul 2021, joint US/AU/UK) showed attackers overwhelmingly reuse **known, unpatched CVEs** rather than burn fresh zero-days — the practical argument for patch management over exotic-bug paranoia.

## Exam tips & gotchas
- The three the JQR calls out by name: **use-after-free, heap overflow, SQL injection.** Have their one-line explanations ready.
- **OWASP year trap:** lead with **2025** but state both — if the answer key predates late-2025, Injection is **A03** and **SSRF is A10**. In 2025 Injection is **A05** and SSRF is folded in.
- **CSRF vs XSS:** XSS runs *attacker code in the victim's browser*; CSRF makes the victim's browser send a *request the attacker chose* — no script execution needed.
- **SSRF vs CSRF:** SSRF abuses the **server** into making requests (internal/cloud-metadata reach); CSRF abuses the **client/browser**.
- Memory-corruption answer: name the pipeline — **corrupt control data → ROP past DEP/NX → shellcode**, defeated by **ASLR / canaries / CFG**. Don't get pulled into writing an exploit.

## References
- OWASP Top 10: https://owasp.org/www-project-top-ten/ · 2025 edition: https://owasp.org/Top10/2025/
- MITRE CWE: https://cwe.mitre.org · CWE Top 25: https://cwe.mitre.org/top25/
- Cloudflare — *What is a buffer overflow?*: https://www.cloudflare.com/learning/security/threats/buffer-overflow/
- CISA AA21-209A — Top Routinely Exploited Vulnerabilities: https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-209a

## Related
- [Zero-Day Exploits](Zero-Day%20Exploits.md)
- [Vulnerability Sources (CVE CWE MITRE)](Vulnerability%20Sources%20%28CVE%20CWE%20MITRE%29.md)
- [Cyber Kill Chain](Cyber%20Kill%20Chain.md)
- [DevOps Testing Automation](DevOps%20Testing%20Automation.md)
- [Privilege Escalation Concepts](Privilege%20Escalation%20Concepts.md)
