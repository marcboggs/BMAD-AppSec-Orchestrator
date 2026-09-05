# Architecture Review Reference

Reference material for the security-architecture agent. Use this to drive a systematic,
principle-based, framework-grounded design review. This is the design-level analogue of
`stride-reference.md` — where STRIDE enumerates threats per component, this enumerates
*design principles and control families* the architecture as a whole must satisfy.

---

## Review categories

Each finding is filed under one category with the matching cross-reference prefix.

| Category | Prefix | Core question | Common failure modes |
|----------|--------|---------------|----------------------|
| Authentication architecture | `SA-AUTHN` | Where and how is identity established, and is it consistent? | Auth enforced only at edge; inconsistent session models; MFA optional on privileged paths; long-lived tokens; no federation strategy |
| Authorization architecture | `SA-AUTHZ` | Where are authz decisions made, and is least privilege enforced across boundaries? | Authz at gateway only, internal calls implicitly trusted; coarse roles; missing object-level checks by design; ambient authority |
| Cryptography & key management | `SA-CRYPTO` | Are algorithms, key lifecycle, and TLS posture sound by design? | Home-grown crypto; no key rotation; keys in code/config; weak TLS; no KMS/HSM; signing and encryption keys shared |
| Secrets management | `SA-SECRETS` | How are secrets stored, distributed, injected, and rotated? | Secrets in env files/images/repos; no central secret store; no rotation; secrets logged; broad read scope |
| Segmentation & blast radius | `SA-SEGMENT` | Is the system segmented so one compromise doesn't cascade? | Flat network; shared credentials across tiers; no tenant isolation; wildcard trust; lateral movement unrestricted |
| Defense-in-depth | `SA-DEFENSE` | Are there layered, independent controls, or a single point of security failure? | One control guarding everything; validation only client-side; security relies solely on the perimeter |
| Attack-surface exposure | `SA-EXPOSURE` | Is anything exposed externally that need not be? | Admin/management plane internet-facing; debug endpoints in prod; unauthenticated internal APIs reachable; overbroad CORS |
| Resilience & availability | `SA-RESILIENCE` | Does the design resist DoS and fail safe? | No rate limiting at the edge; unbounded resource use; fail-open auth; no circuit breakers; retries amplify load |
| Data protection architecture | `SA-DATA` | Is data classified, encrypted, isolated, and retained correctly by design? | No data classification; no encryption at rest; PII commingled across tenants; unbounded retention; no field-level protection for sensitive data |

---

## Security design principles (Saltzer & Schroeder + modern)

Judge the architecture against these. Cite the principle a finding violates.

1. **Least privilege** — every component operates with the minimum rights it needs.
2. **Defense in depth** — no single control is the only thing standing between attacker and asset.
3. **Fail safe / fail closed** — on error, deny by default (esp. authn/authz).
4. **Complete mediation** — every access to every object is checked, not cached-and-trusted.
5. **Separation of duties / privilege separation** — split powerful capabilities across boundaries.
6. **Economy of mechanism** — the security design is as simple as possible.
7. **Least common mechanism** — minimize shared state/credentials across trust zones.
8. **Open design** — security does not depend on secrecy of the architecture.
9. **Psychological acceptability** — secure path is the easy/default path for developers.
10. **Zero trust** — never trust based on network location; authenticate and authorize every request.
11. **Secure defaults** — the default configuration is the safe configuration.
12. **Minimize attack surface** — expose only what must be exposed.

---

## Framework quick-reference

Pick ONE primary framework with the user; map every finding to a control/requirement in it.

### OWASP ASVS (Application Security Verification Standard)
- **L1** — baseline, opportunistic; **L2** — most apps, standard; **L3** — high-value/high-assurance.
- Key chapters for architecture review: V1 Architecture, V2 Authentication, V3 Session
  Management, V4 Access Control, V6 Cryptography, V8 Data Protection, V9 Communications,
  V12 Files/Resources, V13 API/Web Service.

### AWS / Azure Well-Architected — Security Pillar
- Design questions: identity foundation (least privilege, centralized identity),
  detective controls, infrastructure protection (defense-in-depth, segmentation),
  data protection (classification, encryption at rest/in transit), incident response.

### NIST SP 800-53 — relevant control families for design review
| Family | Focus | Example controls |
|--------|-------|------------------|
| AC | Access Control | AC-2, **AC-6 (Least Privilege)**, AC-4 (Information Flow) |
| IA | Identification & Authentication | IA-2, IA-5 (Authenticator Mgmt), IA-8 |
| SC | System & Communications Protection | **SC-7 (Boundary Protection)**, SC-8 (Transmission Confidentiality), **SC-12/SC-13 (Key Mgmt & Crypto)**, SC-28 (Protection at Rest) |
| SI | System & Information Integrity | SI-10 (Input Validation), SI-4 (Monitoring) |
| CM | Configuration Management | CM-6 (Secure Config), CM-7 (Least Functionality) |
| CP | Contingency Planning | CP-10 (Recovery) — resilience findings |

---

## Severity guidance (likelihood × impact)

Use the unified suite scale (see `reports-schema.md`). For *design-level* findings:

- **Critical** — a design decision that, if built as specified, yields a directly
  exploitable, high-impact weakness with no compensating control (e.g., no authz between
  tiers holding regulated data). Bump here when secreview confirms it in code.
- **High** — a missing or misplaced control that materially weakens the security posture
  and lacks defense-in-depth backup.
- **Medium** — a weakness mitigated by another layer but still below good practice.
- **Low** — hardening/best-practice gap with limited real-world impact.

Always distinguish **design-level (no corroborating scan finding)** from **confirmed in
code** (secreview finding cited). Confirmed findings get a severity bump and a citation.

---

## Handoff mapping (who consumes what)

- **→ threat-model:** every `SA-*` risk should be traceable into a STRIDE entry. Provide
  the trust-zone diagram and the risk register so threat-model doesn't re-derive the
  architecture. threat-model may cite your IDs (`[SA-AUTHZ-002]`).
- **→ compliance:** framework-mapped control gaps map directly onto SOC2/PCI/HIPAA/NIST.
- **→ pentest-planner:** design weaknesses flagged as "worth probing" become candidate
  test cases (`[PP-TC-*]` referencing `[SA-*]`).
- **← secreview:** corroborates design risks with concrete SAST/SCA instances.
- **← threat-model:** may send a second-pass request when a threat traces to a design
  gap you should assess in more depth.
